from __future__ import annotations

import hashlib
import html
import json
import re
import shlex
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import yaml

from app.document_processing.types import (
    ExtractedContentBlock,
    ExtractedDocument,
    ExtractedSection,
)

_HEADING_RE = re.compile(r"^(#{1,6})\s+(.+?)\s*#*\s*$")
_UNORDERED_RE = re.compile(r"^\s*[-*+]\s+(.+)$")
_ORDERED_RE = re.compile(r"^\s*\d+[.)]\s+(.+)$")
_TABLE_SEPARATOR_RE = re.compile(r"^\s*\|?\s*:?-{3,}:?\s*(?:\|\s*:?-{3,}:?\s*)+\|?\s*$")
_ASSET_IMAGE_RE = re.compile(
    r"^!\[([^\]]*)\]\(guideline-asset://"
    r"([0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12})"
    r'(?:\s+"((?:[^"\\]|\\.)*)")?\)\s*$'
)
_CALLOUT_RE = re.compile(
    r"^(?:>\s*)?(recommendation|recommended action|warning|caution|key point|important note)\s*[:\-]?\s*(.*)$",
    re.IGNORECASE,
)
_FENCED_CALLOUT_RE = re.compile(r"^:::([a-z][a-z-]*)(?:\s+(.*))?$", re.IGNORECASE)
_CALLOUT_TYPES = {
    "recommendation": "recommendation",
    "warning": "warning",
    "caution": "caution",
    "key-point": "key_point",
    "contraindication": "contraindication",
    "dosage": "dosage",
    "evidence": "evidence",
    "definition": "definition",
    "procedure": "procedure",
    "algorithm-reference": "algorithm_reference",
    "clinical-note": "clinical_note",
    "referral-criteria": "referral_criteria",
}


@dataclass
class _MarkdownSection:
    title: str
    level: int
    lines: list[tuple[int, str]]
    sort_order: int
    parent_sort_order: int | None
    breadcrumb: str


def extract_markdown(path: Path, fallback_title: str = "Guideline") -> ExtractedDocument:
    raw = path.read_bytes()
    try:
        markdown = raw.decode("utf-8-sig")
    except UnicodeDecodeError as exc:
        raise ValueError("Markdown source must be valid UTF-8") from exc
    markdown = markdown.replace("\r\n", "\n").replace("\r", "\n").strip()
    if not markdown:
        raise ValueError("Markdown source is empty")

    body, metadata = _front_matter(markdown)
    sections = _split_sections(body, str(metadata.get("title") or fallback_title).strip())
    extracted_sections: list[ExtractedSection] = []
    blocks: list[ExtractedContentBlock] = []

    for section in sections:
        section_blocks = _section_blocks(section)
        blocks.extend(section_blocks)
        text = "\n".join(
            _block_text(block) for block in section_blocks if _block_text(block)
        ).strip()
        extracted_sections.append(
            ExtractedSection(
                title=section.title,
                level=section.level,
                html="".join(_block_html(block) for block in section_blocks),
                text=text or section.title,
                sort_order=section.sort_order,
                parent_sort_order=section.parent_sort_order,
                breadcrumb=section.breadcrumb,
                extraction_confidence=1.0,
                provenance={
                    "extraction_method": "markdown_source",
                    "review_required": True,
                },
            )
        )

    for index, block in enumerate(blocks):
        block.sort_order = index
        block.source_fingerprint = _fingerprint(block)

    title = str(metadata.get("title") or sections[0].title or fallback_title).strip()
    document_html = (
        "<article>" + "".join(section.html for section in extracted_sections) + "</article>"
    )
    return ExtractedDocument(
        title=title,
        pages=0,
        html=document_html,
        markdown=markdown,
        text="\n\n".join(section.text for section in extracted_sections),
        sections=extracted_sections,
        tables=[],
        blocks=blocks,
        assets=[],
        metadata={
            **metadata,
            "source_format": "markdown",
            "heading_count": len(sections),
            "page_citations_available": False,
        },
        warnings=[
            "Markdown-only source: PDF page citations and original-PDF access are unavailable."
        ],
    )


def _front_matter(markdown: str) -> tuple[str, dict[str, Any]]:
    if not markdown.startswith("---\n"):
        return markdown, {}
    end = markdown.find("\n---\n", 4)
    if end < 0:
        return markdown, {}
    try:
        value = yaml.safe_load(markdown[4:end]) or {}
    except yaml.YAMLError as exc:
        raise ValueError("Markdown front matter is invalid YAML") from exc
    if not isinstance(value, dict):
        raise ValueError("Markdown front matter must be an object")
    return markdown[end + 5 :].strip(), {str(key): _json_value(item) for key, item in value.items()}


def _split_sections(markdown: str, fallback_title: str) -> list[_MarkdownSection]:
    sections: list[_MarkdownSection] = []
    current_lines: list[tuple[int, str]] = []
    current_title = fallback_title or "Guideline"
    current_level = 1
    current_parent: int | None = None
    stack: list[tuple[int, int, str]] = []

    def append_current() -> None:
        nonlocal current_lines
        if sections or current_lines:
            breadcrumb_parts = [item[2] for item in stack if item[0] < current_level]
            breadcrumb = " > ".join([*breadcrumb_parts, current_title])
            sections.append(
                _MarkdownSection(
                    title=current_title,
                    level=current_level,
                    lines=current_lines,
                    sort_order=len(sections),
                    parent_sort_order=current_parent,
                    breadcrumb=breadcrumb,
                )
            )
            current_lines = []

    for line_number, line in enumerate(markdown.splitlines(), start=1):
        match = _HEADING_RE.match(line)
        if not match:
            current_lines.append((line_number, line))
            continue
        append_current()
        current_level = len(match.group(1))
        current_title = match.group(2).strip()
        while stack and stack[-1][0] >= current_level:
            stack.pop()
        current_parent = stack[-1][1] if stack else None
        stack.append((current_level, len(sections), current_title))

    append_current()
    if not sections:
        sections.append(
            _MarkdownSection(fallback_title or "Guideline", 1, [], 0, None, fallback_title)
        )
    return sections


def _section_blocks(section: _MarkdownSection) -> list[ExtractedContentBlock]:
    blocks = [
        _block(
            section,
            "heading",
            {"type": "heading", "text": section.title, "level": section.level},
            0,
        )
    ]
    lines = section.lines
    index = 0
    local_order = 1
    paragraph: list[tuple[int, str]] = []

    def flush_paragraph() -> None:
        nonlocal local_order, paragraph
        text = "\n".join(line.strip() for _, line in paragraph).strip()
        if text:
            blocks.append(
                _block(
                    section,
                    "paragraph",
                    {"type": "paragraph", "text": text},
                    local_order,
                    paragraph[0][0],
                    paragraph[-1][0],
                )
            )
            local_order += 1
        paragraph = []

    while index < len(lines):
        line_number, line = lines[index]
        stripped = line.strip()
        if not stripped:
            flush_paragraph()
            index += 1
            continue
        fenced_callout = _FENCED_CALLOUT_RE.match(stripped)
        if fenced_callout and fenced_callout.group(1).lower() in _CALLOUT_TYPES:
            flush_paragraph()
            name = fenced_callout.group(1).lower()
            metadata = _callout_metadata(fenced_callout.group(2) or "")
            body_lines: list[str] = []
            start_line = line_number
            index += 1
            while index < len(lines) and lines[index][1].strip() != ":::":
                body_lines.append(lines[index][1])
                index += 1
            if index >= len(lines):
                raise ValueError(f"Clinical callout opened on line {start_line} is not closed")
            end_line = lines[index][0]
            index += 1
            body = "\n".join(body_lines).strip()
            if not body:
                raise ValueError(f"Clinical callout opened on line {start_line} is empty")
            block_type = _CALLOUT_TYPES[name]
            content = {"type": block_type, "content": body, **metadata}
            blocks.append(_block(section, block_type, content, local_order, start_line, end_line))
            local_order += 1
            continue
        if stripped.startswith("```") or stripped.startswith("~~~"):
            flush_paragraph()
            marker = stripped[:3]
            code_lines: list[str] = []
            start_line = line_number
            index += 1
            while index < len(lines) and not lines[index][1].strip().startswith(marker):
                code_lines.append(lines[index][1])
                index += 1
            if index < len(lines):
                index += 1
            blocks.append(
                _block(
                    section,
                    "paragraph",
                    {"type": "paragraph", "text": "\n".join(code_lines)},
                    local_order,
                    start_line,
                    lines[min(index - 1, len(lines) - 1)][0],
                )
            )
            local_order += 1
            continue
        asset_image = _ASSET_IMAGE_RE.match(stripped)
        if asset_image:
            flush_paragraph()
            alternative_text = asset_image.group(1).strip()
            caption = (asset_image.group(3) or "").replace(r'\"', '"').replace(r"\\", "\\")
            if not alternative_text:
                raise ValueError(f"Guideline image on line {line_number} requires alternative text")
            blocks.append(
                _block(
                    section,
                    "figure",
                    {
                        "type": "figure",
                        "asset_id": asset_image.group(2).lower(),
                        "caption": caption,
                        "alternative_text": alternative_text,
                    },
                    local_order,
                    line_number,
                    line_number,
                )
            )
            local_order += 1
            index += 1
            continue
        if (
            index + 1 < len(lines)
            and "|" in stripped
            and _TABLE_SEPARATOR_RE.match(lines[index + 1][1])
        ):
            flush_paragraph()
            columns = _table_cells(stripped)
            start_line = line_number
            index += 2
            rows: list[list[str]] = []
            while index < len(lines) and "|" in lines[index][1] and lines[index][1].strip():
                rows.append(_table_cells(lines[index][1]))
                index += 1
            blocks.append(
                _block(
                    section,
                    "table",
                    {
                        "type": "table",
                        "columns": columns,
                        "rows": rows,
                        "footnotes": [],
                    },
                    local_order,
                    start_line,
                    lines[index - 1][0],
                )
            )
            local_order += 1
            continue
        list_match = _UNORDERED_RE.match(line) or _ORDERED_RE.match(line)
        if list_match:
            flush_paragraph()
            ordered = _ORDERED_RE.match(line) is not None
            matcher = _ORDERED_RE if ordered else _UNORDERED_RE
            items: list[str] = []
            start_line = line_number
            while index < len(lines):
                match = matcher.match(lines[index][1])
                if not match:
                    break
                items.append(match.group(1).strip())
                index += 1
            block_type = "ordered_list" if ordered else "unordered_list"
            blocks.append(
                _block(
                    section,
                    block_type,
                    {"type": block_type, "items": items},
                    local_order,
                    start_line,
                    lines[index - 1][0],
                )
            )
            local_order += 1
            continue
        callout = _CALLOUT_RE.match(stripped)
        if callout:
            flush_paragraph()
            label = callout.group(1).lower()
            if label in {"warning", "caution"}:
                block_type = "warning"
            elif label in {"key point", "important note"}:
                block_type = "key_point"
            else:
                block_type = "recommendation"
            blocks.append(
                _block(
                    section,
                    block_type,
                    {
                        "type": block_type,
                        "title": callout.group(1),
                        "content": callout.group(2),
                    },
                    local_order,
                    line_number,
                    line_number,
                )
            )
            local_order += 1
            index += 1
            continue
        paragraph.append((line_number, line))
        index += 1

    flush_paragraph()
    return blocks


def _block(
    section: _MarkdownSection,
    block_type: str,
    content: dict[str, Any],
    local_order: int,
    line_start: int | None = None,
    line_end: int | None = None,
) -> ExtractedContentBlock:
    return ExtractedContentBlock(
        type=block_type,
        sort_order=section.sort_order * 100_000 + local_order,
        content=content,
        source_fingerprint="",
        section_order=section.sort_order,
        extraction_confidence=1.0,
        provenance={
            "extraction_method": "markdown_source",
            "line_start": line_start,
            "line_end": line_end,
            "review_required": True,
        },
    )


def _fingerprint(block: ExtractedContentBlock) -> str:
    value = {
        "type": block.type,
        "content": block.content,
        "section_order": block.section_order,
        "sort_order": block.sort_order,
    }
    return hashlib.sha256(
        json.dumps(value, sort_keys=True, ensure_ascii=False).encode()
    ).hexdigest()


def _table_cells(line: str) -> list[str]:
    return [cell.strip() for cell in line.strip().strip("|").split("|")]


def _block_text(block: ExtractedContentBlock) -> str:
    if block.type in {"heading", "paragraph"}:
        return str(block.content.get("text") or "")
    if block.type in {"ordered_list", "unordered_list"}:
        return "\n".join(str(item) for item in block.content.get("items") or [])
    if block.type in set(_CALLOUT_TYPES.values()):
        return str(block.content.get("content") or "")
    if block.type == "table":
        rows = [block.content.get("columns") or [], *(block.content.get("rows") or [])]
        return "\n".join(" | ".join(str(cell) for cell in row) for row in rows)
    if block.type == "figure":
        return str(block.content.get("alternative_text") or block.content.get("caption") or "")
    return ""


def _block_html(block: ExtractedContentBlock) -> str:
    content = block.content
    if block.type == "heading":
        level = min(max(int(content.get("level") or 1), 1), 6)
        return f"<h{level}>{html.escape(str(content.get('text') or ''))}</h{level}>"
    if block.type == "paragraph":
        return f"<p>{html.escape(str(content.get('text') or ''))}</p>"
    if block.type in {"ordered_list", "unordered_list"}:
        tag = "ol" if block.type == "ordered_list" else "ul"
        items = "".join(f"<li>{html.escape(str(item))}</li>" for item in content.get("items") or [])
        return f"<{tag}>{items}</{tag}>"
    if block.type in set(_CALLOUT_TYPES.values()):
        title = html.escape(str(content.get("title") or ""))
        body = html.escape(str(content.get("content") or ""))
        return f"<aside><strong>{title}</strong><p>{body}</p></aside>"
    if block.type == "table":
        columns = "".join(
            f"<th>{html.escape(str(cell))}</th>" for cell in content.get("columns") or []
        )
        rows = "".join(
            "<tr>" + "".join(f"<td>{html.escape(str(cell))}</td>" for cell in row) + "</tr>"
            for row in content.get("rows") or []
        )
        return f"<table><thead><tr>{columns}</tr></thead><tbody>{rows}</tbody></table>"
    if block.type == "figure":
        alternative_text = html.escape(str(content.get("alternative_text") or ""))
        return (
            f'<figure><span role="img" aria-label="{alternative_text}"></span>'
            f"<figcaption>{alternative_text}</figcaption></figure>"
        )
    return ""


def _callout_metadata(value: str) -> dict[str, str]:
    """Parse a deliberately small key=value grammar; HTML is never interpreted."""
    allowed = {"title", "severity", "evidence_grade", "source"}
    result: dict[str, str] = {}
    try:
        tokens = shlex.split(value)
    except ValueError as exc:
        raise ValueError("Clinical callout metadata contains invalid quoting") from exc
    for token in tokens:
        if "=" not in token:
            raise ValueError("Clinical callout metadata must use key=value")
        key, item = token.split("=", 1)
        if key not in allowed:
            raise ValueError(f"Unsupported clinical callout metadata field: {key}")
        if not item.strip():
            raise ValueError(f"Clinical callout metadata field {key} cannot be empty")
        result[key] = item
    return result


def _json_value(value: Any) -> Any:
    if value is None or isinstance(value, (str, int, float, bool)):
        return value
    if isinstance(value, list):
        return [_json_value(item) for item in value]
    if isinstance(value, dict):
        return {str(key): _json_value(item) for key, item in value.items()}
    return str(value)
