from __future__ import annotations
from dataclasses import dataclass
from pathlib import Path
import hashlib
import html
import math
import re
import subprocess
import tempfile
import fitz
from bs4 import BeautifulSoup
from markdownify import markdownify as md
from slugify import slugify
from app.document_processing.structured_blocks import build_structured_blocks
from app.document_processing.types import (
    ExtractedAsset,
    ExtractedDocument,
    ExtractedSection,
    ExtractedTable,
)

_BULLET_RE = re.compile(r"^(?:[-*]\s+|[~•●○▪■□◦]+\s*)")
_LOC_CODE_RE = re.compile(r"^(?:HC ?[1-4IVX]+|RRH?|NRH|H|NA)$", re.I)
_COMMON_SUBHEADINGS = {
    "assessment",
    "care",
    "cause",
    "causes",
    "causes and clinical features",
    "classification",
    "clinical features",
    "comments",
    "complications",
    "definition",
    "diagnosis",
    "differential diagnosis",
    "features",
    "follow up",
    "investigations",
    "management",
    "monitoring",
    "note",
    "notes",
    "prevention",
    "referral",
    "supportive care",
    "treatment",
}
_TABLE_HEAD_BG = "#dbe5f1"
_TABLE_BORDER = "#667085"
_ROMAN_NUMERAL_RE = re.compile(r"^[IVXLCDM]+$", re.I)
_GENERIC_TABLE_TERMS = {
    "comments",
    "features",
    "loc",
    "management",
    "question",
    "treatment",
}
_CHAPTER_HEADING_RE = re.compile(r"^CHAPTER\s+(\d+)\s*:?\s+(.+)$", re.I)
_NUMBERED_HEADING_RE = re.compile(r"^(\d{1,3}(?:\.\d{1,3}){0,5}\.?)\s+(.+)$")
_TOC_DOT_LEADER_RE = re.compile(r"\.{4,}\s*\d+\s*$")
_TRAILING_PAGE_RE = re.compile(r"(?:\s+|\.{1,})\d{1,4}\s*$")
_DOT_LEADER_ONLY_RE = re.compile(r"\.{6,}\s*$")


@dataclass
class HeadingInfo:
    title: str
    level: int
    primary: bool = False


def _clean_text(text: str) -> str:
    text = text.replace("\x00", " ").replace("\u00ad", "")
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()


def _clean_line(text: str) -> str:
    return _clean_text(text).replace("­", "").strip()


def _alpha_words(text: str) -> list[str]:
    return re.findall(r"[A-Za-z]{3,}", text)


def _has_meaningful_content(text: str) -> bool:
    words = [word.lower() for word in _alpha_words(text)]
    if len(words) < 12:
        return False
    if len(set(words)) <= 3:
        return False
    return True


def _is_noise_line(line: str) -> bool:
    if not line:
        return True
    if re.fullmatch(r"Uganda Clinical Guidelines 2023", line, re.I):
        return True
    if re.fullmatch(r"CHAPTER \d+:\s+.+", line, re.I):
        return True
    if re.fullmatch(r"\d{1,4}", line):
        return True
    if _ROMAN_NUMERAL_RE.fullmatch(line):
        return True
    if _TOC_DOT_LEADER_RE.search(line):
        return True
    if _DOT_LEADER_ONLY_RE.search(line):
        return True
    return False


def _looks_like_toc_entry(line: str) -> bool:
    if _TOC_DOT_LEADER_RE.search(line):
        return True
    if _DOT_LEADER_ONLY_RE.search(line):
        return True
    if _NUMBERED_HEADING_RE.match(line) and _TRAILING_PAGE_RE.search(line):
        return True
    return False


def _is_semantic_subheading_title(title: str) -> bool:
    normalized = title.strip().rstrip(":")
    if not normalized:
        return False
    if _NUMBERED_HEADING_RE.match(normalized) or _CHAPTER_HEADING_RE.match(normalized):
        return False
    lowered = normalized.lower()
    if lowered in _COMMON_SUBHEADINGS:
        return True
    return normalized.isupper() and 1 < len(normalized.split()) <= 10


def _is_upperish_heading_title(title: str) -> bool:
    words = re.findall(r"[A-Za-z][A-Za-z0-9'/-]*", title)
    if not words:
        return False
    emphasized = 0
    for word in words:
        letters = [char for char in word if char.isalpha()]
        if not letters:
            continue
        upper = sum(1 for char in letters if char.isupper())
        lower = sum(1 for char in letters if char.islower())
        if upper >= max(1, lower * 2):
            emphasized += 1
    return emphasized >= 2 and emphasized * 2 >= len(words)


def _content_lines(text: str) -> list[str]:
    lines: list[str] = []
    for raw in text.splitlines():
        line = _clean_line(raw)
        if not line or _is_noise_line(line):
            continue
        lines.append(line)
    return _explode_inline_bullets(lines)


def _explode_inline_bullets(lines: list[str]) -> list[str]:
    exploded: list[str] = []
    for line in lines:
        if "~" in line:
            normalized = line.strip()
            if normalized.startswith("~"):
                normalized = normalized[1:].strip()
                parts = [part.strip() for part in re.split(r"\s+~\s+", normalized) if part.strip()]
                exploded.extend(f"~ {part}" for part in parts)
                continue
            if " ~ " in normalized:
                parts = [part.strip() for part in re.split(r"\s+~\s+", normalized) if part.strip()]
                if parts:
                    exploded.append(parts[0])
                    exploded.extend(f"~ {part}" for part in parts[1:])
                    continue
        exploded.append(line)
    return exploded


def _header_signature(cells: list[str]) -> list[str]:
    return [_normalize_for_match(cell) for cell in cells if cell]


def _remove_matching_heading_runs(soup: BeautifulSoup, header_cells: list[str]) -> None:
    signature = _header_signature(header_cells)
    if not signature:
        return
    removed = True
    while removed:
        removed = False
        headings = list(soup.find_all(re.compile(r"^h[1-6]$")))
        for idx in range(len(headings) - len(signature) + 1):
            texts = [_normalize_for_match(headings[idx + offset].get_text(" ", strip=True)) for offset in range(len(signature))]
            if texts == signature:
                for offset in range(len(signature)):
                    headings[idx + offset].decompose()
                removed = True
                continue
            if removed:
                break


def _guess_heading(line: str) -> int:
    s = line.strip()
    if not s or len(s) > 140:
        return 0
    if re.match(r"^(chapter|section)\s+\d+", s, re.I):
        return 1
    # Numbered section headings: require ≤ 12 words to avoid misclassifying
    # body text like "1 tablet twice daily" as a heading.
    if re.match(r"^\d{1,3}(\.\d{1,3}){0,3}\s+[A-Za-z]", s) and len(s.split()) <= 12:
        return min(1 + s.split()[0].count("."), 4)
    if s.isupper() and 1 < len(s.split()) <= 10:
        return 2
    return 0


def _heading_info(line: str, current_level: int, current_title: str | None = None) -> HeadingInfo | None:
    s = line.strip()
    if not s or len(s) > 160:
        return None
    if _BULLET_RE.match(s) or _LOC_CODE_RE.fullmatch(s):
        return None
    if _looks_like_toc_entry(s):
        return None

    chapter = _CHAPTER_HEADING_RE.match(s)
    if chapter:
        number, title = chapter.groups()
        return HeadingInfo(title=f"Chapter {number}: {_clean_line(title)}", level=1, primary=True)

    numbered = _NUMBERED_HEADING_RE.match(s)
    if numbered and len(s.split()) <= 16:
        numbering, title = numbered.groups()
        normalized_numbering = numbering.rstrip(".")
        parts = [int(part) for part in normalized_numbering.split(".")]
        if parts[0] > 40 or any(part > 100 for part in parts[1:]):
            return None
        if _TRAILING_PAGE_RE.search(title):
            return None
        clean_title = _clean_line(title)
        if len(parts) == 1 and not _is_upperish_heading_title(clean_title):
            return None
        level = normalized_numbering.count(".") + 1
        return HeadingInfo(title=f"{normalized_numbering} {clean_title}", level=level, primary=True)

    candidate = s.rstrip(":")
    if candidate.upper() in {"TREATMENT", "LOC"}:
        return None
    lowered = candidate.lower()
    if lowered in _COMMON_SUBHEADINGS:
        level = current_level if current_title and _is_semantic_subheading_title(current_title) else current_level + 1
        return HeadingInfo(title=candidate, level=min(max(level, 2), 6))

    if candidate.isupper() and 1 < len(candidate.split()) <= 10:
        level = current_level if current_title and _is_semantic_subheading_title(current_title) else current_level + 1
        return HeadingInfo(title=candidate, level=min(max(level, 2), 6))

    return None


def _finalize_section(section: ExtractedSection | None) -> ExtractedSection | None:
    if section is None:
        return None
    section.text = _clean_text(section.text)
    section.html = _section_html(section.title, section.level, section.text)
    return section


def _populate_breadcrumbs(sections: list[ExtractedSection]) -> None:
    by_order = {section.sort_order: section for section in sections}
    cache: dict[int, list[str]] = {}

    def build_titles(section: ExtractedSection) -> list[str]:
        cached = cache.get(section.sort_order)
        if cached is not None:
            return cached
        titles: list[str] = []
        if section.parent_sort_order is not None and section.parent_sort_order in by_order:
            titles.extend(build_titles(by_order[section.parent_sort_order]))
        titles.append(section.title)
        cache[section.sort_order] = titles
        return titles

    for section in sections:
        section.breadcrumb = " > ".join(build_titles(section))


def _split_sections(page_lines: list[tuple[int, str]]) -> list[ExtractedSection]:
    sections: list[ExtractedSection] = []
    current: ExtractedSection | None = None
    fallback_order = 0
    next_sort_order = 0
    stack: list[ExtractedSection] = []
    seen_primary_heading = False

    for page, raw in page_lines:
        for line in _content_lines(raw):
            info = _heading_info(line, current.level if current else 1, current.title if current else None)
            if info:
                if info.primary:
                    seen_primary_heading = True
                elif not seen_primary_heading and current is None:
                    continue
                finalized = _finalize_section(current)
                if finalized:
                    finalized.page_end = page
                    sections.append(finalized)
                while stack and stack[-1].level >= info.level:
                    stack.pop()
                parent_sort_order = stack[-1].sort_order if stack else None
                current = ExtractedSection(
                    title=info.title,
                    level=info.level,
                    page_start=page,
                    page_end=page,
                    sort_order=next_sort_order,
                    parent_sort_order=parent_sort_order,
                )
                next_sort_order += 1
                stack.append(current)
            else:
                if current is None and not seen_primary_heading:
                    continue
                if current is None:
                    fallback_order += 1
                    current = ExtractedSection(
                        title="Introduction" if fallback_order == 1 else f"Section {fallback_order}",
                        level=1,
                        page_start=page,
                        page_end=page,
                        sort_order=next_sort_order,
                    )
                    next_sort_order += 1
                    stack = [current]
                current.text += line + "\n"
                current.page_end = page

    finalized = _finalize_section(current)
    if finalized:
        sections.append(finalized)

    if not sections:
        combined_lines: list[str] = []
        last_page = 1
        for page, raw in page_lines:
            last_page = page
            combined_lines.extend(_content_lines(raw))
        combined_text = "\n".join(combined_lines)
        if _has_meaningful_content(combined_text):
            sections = [
                ExtractedSection(
                    title="Introduction",
                    level=1,
                    text=_clean_text(combined_text),
                    html=_section_html("Introduction", 1, combined_text),
                    page_start=1,
                    page_end=last_page,
                    sort_order=0,
                )
            ]

    sections = [s for s in sections if s.text or s.title]
    _populate_breadcrumbs(sections)
    return sections


def _section_html(title: str, level: int, text: str) -> str:
    h_level = max(1, min(level, 4))
    body = _render_section_body(_content_lines(text), min(h_level + 1, 6))
    return f"<h{h_level} id=\"{slugify(title)}\">{html.escape(title)}</h{h_level}>{body}"


def _is_subheading(line: str) -> bool:
    candidate = line.strip().rstrip(":")
    if not candidate or len(candidate) > 80 or _LOC_CODE_RE.fullmatch(candidate):
        return False
    if _BULLET_RE.fullmatch(candidate):
        return False
    if not re.search(r"[A-Za-z]", candidate):
        return False
    if candidate.lower() in _COMMON_SUBHEADINGS:
        return True
    if re.match(r"^\d", candidate):
        return False
    words = candidate.split()
    if len(words) > 6 or candidate.endswith((".", ";", ",")):
        return False
    if candidate.upper() == candidate and 1 <= len(words) <= 5:
        return True
    significant = [w for w in words if re.search(r"[A-Za-z]", w)]
    if not significant:
        return False
    return all(
        w[0].isupper() or w.lower() in {"and", "of", "in", "to", "for", "with"}
        for w in significant
    )


def _strip_bullet(line: str) -> str | None:
    if not _BULLET_RE.match(line):
        return None
    cleaned = _BULLET_RE.sub("", line).strip()
    return cleaned or None


def _is_management_table_header(lines: list[str], index: int) -> bool:
    if index + 1 >= len(lines):
        return False
    return lines[index].upper() == "TREATMENT" and lines[index + 1].upper() == "LOC"


def _render_section_body(lines: list[str], subheading_level: int) -> str:
    parts: list[str] = []
    paragraph: list[str] = []
    items: list[str] = []
    index = 0

    def flush_paragraph() -> None:
        if paragraph:
            parts.append(f"<p>{html.escape(' '.join(paragraph).strip())}</p>")
            paragraph.clear()

    def flush_list() -> None:
        if items:
            rendered = "".join(f"<li>{html.escape(item)}</li>" for item in items if item)
            if rendered:
                parts.append(f"<ul>{rendered}</ul>")
            items.clear()

    while index < len(lines):
        line = lines[index]
        bullet = _strip_bullet(line)

        if _is_management_table_header(lines, index):
            flush_paragraph()
            flush_list()
            table_html, consumed = _parse_management_table(lines, index)
            if table_html:
                parts.append(table_html)
                index = consumed
                continue

        if _is_subheading(line):
            flush_paragraph()
            flush_list()
            parts.append(f"<h{subheading_level}>{html.escape(line.rstrip(':'))}</h{subheading_level}>")
            index += 1
            continue

        if bullet is not None:
            flush_paragraph()
            items.append(bullet)
            index += 1
            while index < len(lines):
                next_line = lines[index]
                if _strip_bullet(next_line) is not None or _is_subheading(next_line) or _is_management_table_header(lines, index):
                    break
                items[-1] = f"{items[-1]} {next_line}".strip()
                index += 1
            continue

        flush_list()
        paragraph.append(line)
        index += 1

    flush_paragraph()
    flush_list()
    return "".join(parts)


def _parse_management_table(lines: list[str], start_index: int) -> tuple[str, int]:
    rows: list[tuple[str, str]] = []
    current_text: list[str] = []
    current_loc = ""
    index = start_index + 2

    while index < len(lines):
        line = lines[index]
        bullet = _strip_bullet(line)

        if _is_subheading(line) and not current_text:
            break
        if _is_management_table_header(lines, index):
            break

        if bullet is not None:
            if current_text:
                rows.append((" ".join(current_text).strip(), current_loc))
            current_text = [bullet]
            current_loc = ""
            index += 1
            continue

        if _LOC_CODE_RE.fullmatch(line):
            if current_text:
                current_loc = line.upper().replace(" ", "")
                rows.append((" ".join(current_text).strip(), current_loc))
                current_text = []
                current_loc = ""
            index += 1
            continue

        if current_text:
            current_text.append(line)
            index += 1
            continue

        break

    if current_text:
        rows.append((" ".join(current_text).strip(), current_loc))

    if not rows:
        return "", start_index + 2

    body_rows = [
        [f"&#x2610; {html.escape(treatment)}", html.escape(loc)]
        for treatment, loc in rows
    ]
    return _render_table_html([["TREATMENT", "LOC"], *body_rows], title=None, already_escaped=True), index


def _clean_table_rows(rows: list[list[object]]) -> list[list[str]]:
    cleaned: list[list[str]] = []
    for row in rows:
        normalized = [_clean_line(str(cell or "")) for cell in row]
        if any(cell for cell in normalized):
            cleaned.append(normalized)
    return cleaned


def _is_management_table_data(rows: list[list[str]]) -> bool:
    if not rows:
        return False
    header = [cell.upper() for cell in rows[0] if cell]
    return "TREATMENT" in header and "LOC" in header


def _non_empty_cells(row: list[str]) -> list[str]:
    return [cell for cell in row if cell]


def _looks_like_header_row(row: list[str]) -> bool:
    cells = _non_empty_cells(row)
    if len(cells) < 2:
        return False
    shortish = 0
    for cell in cells:
        if len(cell) <= 40 and not cell.endswith("."):
            shortish += 1
    return shortish == len(cells)


def _table_column_count(rows: list[list[str]]) -> int:
    return max((len(_non_empty_cells(row)) for row in rows), default=0)


def _is_low_signal_table(rows: list[list[str]]) -> bool:
    if len(rows) < 2:
        return True
    non_empty_counts = [len(_non_empty_cells(row)) for row in rows]
    max_cols = max(non_empty_counts, default=0)
    if max_cols <= 1:
        return True
    if sum(non_empty_counts) <= max_cols + 1:
        return True
    return False


def _split_table_parts(rows: list[list[str]]) -> tuple[str | None, list[str] | None, list[list[str]]]:
    if not rows:
        return None, None, []

    title: str | None = None
    working = [list(row) for row in rows]
    max_cols = _table_column_count(working)

    if (
        len(working) >= 2
        and len(_non_empty_cells(working[0])) == 1
        and _table_column_count(working[1:]) >= 2
    ):
        title = _non_empty_cells(working[0])[0]
        working = working[1:]
        max_cols = _table_column_count(working)

    if max_cols <= 1:
        return title, None, working

    header: list[str] | None = None
    if working and _looks_like_header_row(working[0]):
        header = working[0]
        working = working[1:]

    return title, header, working


def _looks_like_inline_table_value(token: str) -> bool:
    token = token.strip()
    if not token:
        return False
    if len(token) > 18:
        return False
    return any(ch.isdigit() for ch in token) or token[0].isalpha()


def _extract_inline_table(lines: list[str]) -> tuple[list[list[str]] | None, int]:
    candidate_lines: list[str] = []
    for line in lines:
        if _strip_bullet(line) is not None:
            break
        if line.endswith("."):
            break
        candidate_lines.append(line)
    if len(candidate_lines) < 3:
        return None, 0

    tokenized = [line.split() for line in candidate_lines]
    for cols in range(6, 1, -1):
        rows: list[list[str]] = []
        for tokens in tokenized:
            if len(tokens) < cols + 1:
                rows = []
                break
            label = " ".join(tokens[:-cols]).strip()
            values = [value.strip() for value in tokens[-cols:]]
            if not label or not all(_looks_like_inline_table_value(value) for value in values):
                rows = []
                break
            rows.append([label, *values])
        if rows and len(rows) >= 2:
            return rows, len(rows)
    return None, 0


def _render_inline_grid_html(rows: list[list[str]]) -> str:
    if not rows:
        return ""

    normalized = []
    max_cols = 0
    for row in rows:
        cells = [html.escape(cell) for cell in row if cell]
        if not cells:
            continue
        normalized.append(cells)
        max_cols = max(max_cols, len(cells))
    if not normalized or max_cols == 0:
        return ""

    rendered_rows = []
    for index, row in enumerate(normalized):
        padded = row + [""] * (max_cols - len(row))
        cell_tag = "strong" if index == 0 else "span"
        cells = "".join(
            f"<div style=\"padding:4px 8px;border:1px solid {_TABLE_BORDER};background:{_TABLE_HEAD_BG if index == 0 else '#ffffff'};\"><{cell_tag}>{cell}</{cell_tag}></div>"
            for cell in padded
        )
        rendered_rows.append(
            f"<div style=\"display:grid;grid-template-columns:repeat({max_cols}, minmax(0,1fr));\">{cells}</div>"
        )
    return (
        "<div class=\"guideline-inline-grid\" "
        "style=\"margin:8px 0 10px 0;border:1px solid #667085;border-bottom:none;overflow-x:auto;\">"
        + "".join(rendered_rows) +
        "</div>"
    )


def _render_table_cell_content(value: str, already_escaped: bool = False) -> str:
    if not value:
        return ""
    lines = [_clean_line(part) for part in value.splitlines()]
    lines = [line for line in lines if line]
    if not lines:
        return ""

    inline_table_html = ""
    inline_table_rows, consumed = _extract_inline_table(lines)
    if inline_table_rows:
        inline_table_html = _render_inline_grid_html(inline_table_rows)
        lines = lines[consumed:]

    def esc(text: str) -> str:
        return text if already_escaped else html.escape(text)

    parts: list[str] = []
    if inline_table_html:
        parts.append(inline_table_html)

    paragraph: list[str] = []
    bullets: list[str] = []

    def flush_paragraph() -> None:
        if paragraph:
            parts.append(f"<p>{esc(' '.join(paragraph).strip())}</p>")
            paragraph.clear()

    def flush_bullets() -> None:
        if bullets:
            rendered = "".join(f"<li>{esc(item)}</li>" for item in bullets)
            parts.append(f"<ul>{rendered}</ul>")
            bullets.clear()

    for line in lines:
        bullet = _strip_bullet(line)
        if bullet is not None:
            flush_paragraph()
            bullets.append(bullet)
            continue
        flush_bullets()
        paragraph.append(line)

    flush_paragraph()
    flush_bullets()
    return "".join(parts) if parts else esc(value)


def _render_table_html(
    rows: list[list[str]],
    title: str | None,
    already_escaped: bool = False,
) -> str:
    if not rows or _is_low_signal_table(rows):
        return ""

    def cell(value: str) -> str:
        return value if already_escaped else html.escape(value)

    inferred_title, header, body = _split_table_parts(rows)
    title = title or inferred_title
    all_rows = ([header] if header else []) + body
    column_count = _table_column_count(all_rows)
    if column_count <= 1:
        return ""

    caption_html = (
        f"<caption style=\"caption-side:top;text-align:left;font-weight:600;padding:0 0 8px 0;\">{cell(title)}</caption>"
        if title else ""
    )
    thead = ""
    if header:
        padded_header = header + [""] * (column_count - len(header))
        thead_cells = "".join(
            f"<th style=\"border:1px solid {_TABLE_BORDER};background:{_TABLE_HEAD_BG};padding:8px 10px;text-align:left;vertical-align:top;font-weight:600;\">{cell(col)}</th>"
            for col in padded_header[:column_count]
        )
        thead = f"<thead><tr>{thead_cells}</tr></thead>"
    tbody_rows = []
    for row in body:
        padded = row + [""] * (column_count - len(row))
        tds = "".join(
            f"<td style=\"border:1px solid {_TABLE_BORDER};padding:8px 10px;vertical-align:top;\">{_render_table_cell_content(col, already_escaped=already_escaped)}</td>"
            for col in padded[:column_count]
        )
        tbody_rows.append(f"<tr>{tds}</tr>")
    tbody = f"<tbody>{''.join(tbody_rows)}</tbody>" if tbody_rows else ""
    return (
        "<div class=\"guideline-table\" style=\"margin:16px 0;overflow-x:auto;\">"
        f"<table style=\"width:100%;border-collapse:collapse;border:1px solid {_TABLE_BORDER};\">"
        f"{caption_html}{thead}{tbody}</table></div>"
    )


def _normalize_for_match(text: str) -> str:
    return " ".join((text or "").lower().split())


def _table_anchor_phrases(rows: list[list[str]]) -> list[str]:
    anchors: list[str] = []
    for row_index, row in enumerate(rows[:6]):
        for cell_index, cell in enumerate(row):
            normalized = _normalize_for_match(cell)
            if not normalized or normalized in _GENERIC_TABLE_TERMS:
                continue
            if _LOC_CODE_RE.fullmatch(normalized.upper().replace(" ", "")):
                continue
            is_first_column_label = (
                cell_index == 0
                and len(normalized) >= 4
                and any(ch.isalpha() for ch in normalized)
            )
            if (
                len(normalized) >= 18
                or is_first_column_label
                or any(ch.isdigit() for ch in normalized)
            ) and normalized not in anchors:
                anchors.append(normalized)
    return anchors


def _bbox_area(bbox: tuple[float, float, float, float]) -> float:
    return max(0.0, bbox[2] - bbox[0]) * max(0.0, bbox[3] - bbox[1])


def _bbox_intersection_area(
    left: tuple[float, float, float, float],
    right: tuple[float, float, float, float],
) -> float:
    x0 = max(left[0], right[0])
    y0 = max(left[1], right[1])
    x1 = min(left[2], right[2])
    y1 = min(left[3], right[3])
    if x1 <= x0 or y1 <= y0:
        return 0.0
    return (x1 - x0) * (y1 - y0)


def _point_in_bbox(x: float, y: float, bbox: tuple[float, float, float, float]) -> bool:
    return bbox[0] <= x <= bbox[2] and bbox[1] <= y <= bbox[3]


def _block_overlaps_table(
    block_bbox: tuple[float, float, float, float],
    table_bboxes: list[tuple[float, float, float, float]],
) -> bool:
    area = _bbox_area(block_bbox)
    if area <= 0:
        return False
    center_x = (block_bbox[0] + block_bbox[2]) / 2
    center_y = (block_bbox[1] + block_bbox[3]) / 2
    for table_bbox in table_bboxes:
        if _point_in_bbox(center_x, center_y, table_bbox):
            return True
        overlap = _bbox_intersection_area(block_bbox, table_bbox)
        if overlap / area >= 0.35:
            return True
    return False


def _page_text_from_blocks(
    blocks: list[tuple[float, float, float, float, str, int, int]],
    table_bboxes: list[tuple[float, float, float, float]],
    page_width: float | None = None,
) -> str:
    kept: list[tuple[float, float, str]] = []
    for block in blocks:
        text = (block[4] or "").strip()
        if not text:
            continue
        block_bbox = (float(block[0]), float(block[1]), float(block[2]), float(block[3]))
        if table_bboxes and _block_overlaps_table(block_bbox, table_bboxes):
            continue
        kept.append((float(block[0]), float(block[1]), text))
    if page_width and _is_multi_column_layout(blocks, page_width):
        midpoint = page_width / 2
        kept.sort(key=lambda item: (0 if item[0] < midpoint else 1, item[1], item[0]))
    else:
        kept.sort(key=lambda item: (item[1], item[0]))
    return _clean_text("\n".join(item[2] for item in kept))


def _is_multi_column_layout(
    blocks: list[tuple[float, float, float, float, str, int, int]],
    page_width: float,
) -> bool:
    if page_width <= 0:
        return False
    substantial = [
        block for block in blocks
        if len(_clean_text(block[4] or "")) >= 40
        and float(block[2]) - float(block[0]) < page_width * 0.72
    ]
    left = [block for block in substantial if float(block[0]) < page_width * 0.42]
    right = [block for block in substantial if float(block[0]) > page_width * 0.42]
    return len(left) >= 2 and len(right) >= 2


def _remove_repeated_margin_lines(page_lines: list[tuple[int, str]]) -> list[tuple[int, str]]:
    if len(page_lines) < 3:
        return page_lines
    candidates: dict[str, int] = {}
    for _, text in page_lines:
        lines = [_clean_line(line) for line in text.splitlines() if _clean_line(line)]
        for line in set([*lines[:2], *lines[-2:]]):
            if 2 <= len(line) <= 120:
                candidates[line] = candidates.get(line, 0) + 1
    threshold = max(2, math.ceil(len(page_lines) * 0.6))
    repeated = {line for line, count in candidates.items() if count >= threshold}
    if not repeated:
        return page_lines
    cleaned: list[tuple[int, str]] = []
    for page, text in page_lines:
        lines = text.splitlines()
        retained = [line for line in lines if _clean_line(line) not in repeated]
        cleaned.append((page, _clean_text("\n".join(retained))))
    return cleaned


def _image_caption(page: fitz.Page, rect: fitz.Rect) -> str:
    candidates: list[tuple[float, str]] = []
    for block in page.get_text("blocks") or []:
        text = _clean_text(block[4] or "")
        if not re.match(r"^(?:figure|fig\.)\s*\d*", text, re.I):
            continue
        y0 = float(block[1])
        if rect.y1 - 12 <= y0 <= rect.y1 + 100:
            candidates.append((abs(y0 - rect.y1), text[:500]))
    return min(candidates, default=(0.0, ""), key=lambda item: item[0])[1]


def _extract_embedded_images(doc: fitz.Document) -> list[ExtractedAsset]:
    assets: list[ExtractedAsset] = []
    seen: set[str] = set()
    for page_number, page in enumerate(doc, start=1):
        for image_index, image in enumerate(page.get_images(full=True) or []):
            xref = int(image[0])
            try:
                extracted = doc.extract_image(xref)
                data = extracted.get("image") or b""
                width = int(extracted.get("width") or 0)
                height = int(extracted.get("height") or 0)
                if len(data) < 1024 or width < 48 or height < 48:
                    continue
                checksum = hashlib.sha256(data).hexdigest()
                fingerprint = hashlib.sha256(f"{page_number}:{xref}:{checksum}".encode()).hexdigest()
                if fingerprint in seen:
                    continue
                seen.add(fingerprint)
                extension = str(extracted.get("ext") or "bin").lower()
                mime_type = {
                    "png": "image/png",
                    "jpg": "image/jpeg",
                    "jpeg": "image/jpeg",
                    "jp2": "image/jp2",
                    "tiff": "image/tiff",
                }.get(extension, "application/octet-stream")
                rects = page.get_image_rects(xref)
                rect = rects[0] if rects else fitz.Rect(0, 0, 0, 0)
                caption = _image_caption(page, rect)
                source_key = f"page-{page_number}-image-{image_index}-{checksum[:12]}"
                asset_type = "diagram" if re.search(r"algorithm|flowchart|flow chart", caption, re.I) else "figure"
                assets.append(
                    ExtractedAsset(
                        type=asset_type,
                        source_key=source_key,
                        source_fingerprint=fingerprint,
                        mime_type=mime_type,
                        checksum=checksum,
                        size_bytes=len(data),
                        original_filename=f"{source_key}.{extension}",
                        page_start=page_number,
                        page_end=page_number,
                        data=data,
                        provenance={
                            "page": page_number,
                            "xref": xref,
                            "bbox": [rect.x0, rect.y0, rect.x1, rect.y1],
                            "width": width,
                            "height": height,
                            "caption": caption,
                            "review_required": True,
                        },
                    )
                )
            except Exception:
                continue
    return assets


def _dedupe_section_html(section_html: str, tables: list[ExtractedTable]) -> str:
    if not tables:
        return section_html

    soup = BeautifulSoup(section_html, "html.parser")
    for table in tables:
        rows = _clean_table_rows(table.data)
        if not rows:
            continue

        title, header, _ = _split_table_parts(rows)
        header_cells = [cell for cell in (header or []) if cell]
        if not header_cells and title:
            header_cells = [title]

        if header_cells:
            _remove_matching_heading_runs(soup, header_cells)

        anchors = _table_anchor_phrases(rows)
        if not anchors:
            continue
        for paragraph in list(soup.find_all("p")):
            text = _normalize_for_match(paragraph.get_text(" ", strip=True))
            matches = sum(1 for anchor in anchors if anchor in text)
            header_hits = sum(1 for cell in _header_signature(header_cells) if cell and cell in text)
            if matches >= 2 or (len(text) > 280 and (matches >= 1 or header_hits >= 1)):
                paragraph.decompose()

    return str(soup)


def _extract_tables_pdfplumber(path: Path) -> list[ExtractedTable]:
    tables: list[ExtractedTable] = []
    try:
        import pdfplumber
        with pdfplumber.open(str(path)) as pdf:
            for i, page in enumerate(pdf.pages, start=1):
                for table in page.find_tables() or []:
                    cleaned_rows = _clean_table_rows(table.extract() or [])
                    if _is_low_signal_table(cleaned_rows):
                        continue
                    title, _, _ = _split_table_parts(cleaned_rows)
                    html_table = _render_table_html(cleaned_rows, title=title)
                    if not html_table:
                        continue
                    tables.append(
                        ExtractedTable(
                            title=title,
                            page=i,
                            html=html_table,
                            data=cleaned_rows,
                            bbox=tuple(float(value) for value in table.bbox),
                        )
                    )
    except Exception:
        # Table extraction is best-effort. The PDF text extraction should continue.
        return tables
    return tables


def _should_use_raw_page_text(filtered_text: str, raw_text: str) -> bool:
    return len(raw_text) >= 500 and len(filtered_text) < max(120, len(raw_text) // 4)


def _is_low_signal_page_text(text: str) -> bool:
    words = [word.lower() for word in _alpha_words(text)]
    if not words:
        return True
    if len(words) < 12:
        return True
    unique = set(words)
    return len(unique) <= 3 and "camscanner" in unique


def _ocr_page_text(page: fitz.Page) -> str:
    try:
        pixmap = page.get_pixmap(matrix=fitz.Matrix(2, 2), alpha=False)
        with tempfile.TemporaryDirectory(prefix="mediguide-ocr-") as tmp:
            image_path = Path(tmp) / "page.png"
            image_path.write_bytes(pixmap.tobytes("png"))
            proc = subprocess.run(
                ["tesseract", str(image_path), "stdout", "-l", "eng"],
                check=True,
                capture_output=True,
                text=True,
            )
            return _clean_text(proc.stdout)
    except Exception:
        return ""


def extract_pdf(path: Path) -> ExtractedDocument:
    tables = _extract_tables_pdfplumber(path)
    table_bboxes_by_page: dict[int, list[tuple[float, float, float, float]]] = {}
    for table in tables:
        if table.bbox:
            table_bboxes_by_page.setdefault(table.page, []).append(table.bbox)

    doc = fitz.open(str(path))
    page_lines: list[tuple[int, str]] = []
    all_text: list[str] = []
    title = None
    page_methods: dict[int, str] = {}
    ocr_pages: list[int] = []
    multi_column_pages: list[int] = []
    toc_entries: list[str] = []
    warnings: list[str] = []

    for page_number, page in enumerate(doc, start=1):
        blocks = page.get_text("blocks") or []
        raw_text = _clean_text(page.get_text("text"))
        multi_column = _is_multi_column_layout(blocks, float(page.rect.width))
        if multi_column:
            multi_column_pages.append(page_number)
        text = _clean_text(
            _page_text_from_blocks(
                blocks,
                table_bboxes_by_page.get(page_number, []),
                float(page.rect.width),
            )
        )
        method = "embedded_text"
        if _should_use_raw_page_text(text, raw_text):
            text = raw_text
        if _is_low_signal_page_text(text):
            ocr_text = _ocr_page_text(page)
            if len(ocr_text) > len(text):
                text = ocr_text
                method = "ocr"
                ocr_pages.append(page_number)
            elif not text:
                warnings.append(f"Page {page_number} has no extractable text and OCR produced no result")
        page_methods[page_number] = method
        toc_entries.extend(
            line[:500] for line in raw_text.splitlines() if _looks_like_toc_entry(_clean_line(line))
        )
        if page_number == 1:
            for line in text.splitlines():
                if len(line.strip()) > 8:
                    title = line.strip()[:180]
                    break
        page_lines.append((page_number, text))
        all_text.append(text)

    page_lines = _remove_repeated_margin_lines(page_lines)
    sections = _split_sections(page_lines)
    for section in sections:
        methods = {
            page_methods.get(page, "embedded_text")
            for page in range(section.page_start or 1, (section.page_end or section.page_start or 1) + 1)
        }
        section.extraction_confidence = 0.68 if "ocr" in methods else 0.9
        section.provenance = {
            "page_start": section.page_start,
            "page_end": section.page_end,
            "page_methods": sorted(methods),
            "heading_detection": "heuristic",
            "review_required": True,
        }
    section_by_page: dict[int, ExtractedSection] = {}
    for section in sections:
        start = section.page_start or 0
        end = section.page_end or start
        for page in range(start, end + 1):
            section_by_page.setdefault(page, section)

    orphan_table_html: list[str] = []
    section_tables: dict[int, list[ExtractedTable]] = {}
    for table in tables:
        section = section_by_page.get(table.page)
        if section and not _is_management_table_data(_clean_table_rows(table.data)):
            section.html += table.html
            section_tables.setdefault(id(section), []).append(table)
        elif not _is_management_table_data(_clean_table_rows(table.data)):
            orphan_table_html.append(table.html)

    for section in sections:
        attached = section_tables.get(id(section), [])
        if attached:
            section.html = _dedupe_section_html(section.html, attached)

    body_html = "\n".join(s.html for s in sections)
    if orphan_table_html:
        body_html += "\n<section><h2>Tables</h2>" + "\n".join(orphan_table_html) + "</section>"

    soup = BeautifulSoup(f"<article>{body_html}</article>", "html.parser")
    clean_html = str(soup)
    markdown = md(clean_html, heading_style="ATX")
    text = _clean_text("\n\n".join(all_text))
    assets = _extract_embedded_images(doc)
    blocks = build_structured_blocks(
        sections,
        tables,
        assets,
        page_methods=page_methods,
        multi_column_pages=multi_column_pages,
    )
    for table in tables:
        table.extraction_confidence = 0.72
        table.provenance = {
            "page": table.page,
            "bbox": list(table.bbox) if table.bbox else None,
            "extraction_method": "pdfplumber",
            "review_required": True,
        }
    if ocr_pages:
        warnings.append("OCR-derived text requires additional editorial comparison with the source PDF")
    if any(asset.provenance.get("caption") == "" for asset in assets):
        warnings.append("One or more extracted figures require caption and alternative-text review")
    metadata = {
        key: value
        for key, value in (doc.metadata or {}).items()
        if value not in (None, "")
    }
    metadata.update(
        {
            "page_count": len(doc),
            "text_mode": "ocr_required" if ocr_pages else "embedded_text",
            "ocr_pages": ocr_pages,
            "multi_column_pages": multi_column_pages,
            "toc_detected": bool(toc_entries),
        }
    )

    return ExtractedDocument(
        title=title,
        pages=len(doc),
        html=clean_html,
        markdown=markdown,
        text=text,
        sections=sections,
        tables=tables,
        blocks=blocks,
        assets=assets,
        metadata=metadata,
        toc_entries=toc_entries,
        ocr_pages=ocr_pages,
        multi_column_pages=multi_column_pages,
        warnings=warnings,
    )
