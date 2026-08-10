from __future__ import annotations

import hashlib
import json
import re
from typing import Any

from app.document_processing.types import (
    ExtractedAsset,
    ExtractedContentBlock,
    ExtractedSection,
    ExtractedTable,
)

_BULLET_RE = re.compile(r"^(?:[-*]|[~•●○▪■□◦])\s*(.+)$")
_ORDERED_RE = re.compile(r"^\s*\d{1,3}[.)]\s+(.+)$")
_RECOMMENDATION_RE = re.compile(r"^(?:recommendation|recommended action)\s*[:\-]?\s*(.*)$", re.I)
_WARNING_RE = re.compile(r"^(?:warning|caution|contraindication|contraindications)\s*[:\-]?\s*(.*)$", re.I)
_KEY_POINT_RE = re.compile(r"^(?:key point|important note)\s*[:\-]?\s*(.*)$", re.I)


def build_structured_blocks(
    sections: list[ExtractedSection],
    tables: list[ExtractedTable],
    assets: list[ExtractedAsset],
    page_methods: dict[int, str] | None = None,
    multi_column_pages: list[int] | None = None,
) -> list[ExtractedContentBlock]:
    page_methods = page_methods or {}
    multi_column_pages = multi_column_pages or []
    blocks: list[ExtractedContentBlock] = []
    tables_by_section = _tables_by_section(sections, tables)
    assets_by_section = _assets_by_section(sections, assets)

    for section in sections:
        confidence = _section_confidence(section, page_methods)
        provenance = _provenance(
            section.page_start,
            section.page_end,
            "heading_heuristic",
            page_methods,
            multi_column_pages,
        )
        blocks.append(
            _block(
                block_type="heading",
                content={"type": "heading", "text": section.title, "level": section.level},
                section=section,
                local_order=0,
                confidence=confidence,
                provenance=provenance,
            )
        )
        blocks.extend(
            _text_blocks(section, confidence, page_methods, multi_column_pages)
        )

        local_order = 10_000
        for table in tables_by_section.get(section.sort_order, []):
            payload, warning = _table_payload(table)
            table_provenance = {
                **_provenance(table.page, table.page, "pdfplumber_table", page_methods, multi_column_pages),
                "bbox": list(table.bbox) if table.bbox else None,
                "warning": warning,
            }
            blocks.append(
                _block(
                    block_type="table",
                    content=payload,
                    section=section,
                    local_order=local_order,
                    confidence=table.extraction_confidence or 0.72,
                    provenance=table_provenance,
                    page_start=table.page,
                    page_end=table.page,
                )
            )
            local_order += 1

        for asset in assets_by_section.get(section.sort_order, []):
            caption = str(asset.provenance.get("caption") or "").strip()
            blocks.append(
                _block(
                    block_type="figure",
                    content={
                        "type": "figure",
                        "asset_source_key": asset.source_key,
                        "caption": caption,
                        "alternative_text": caption,
                    },
                    section=section,
                    local_order=local_order,
                    confidence=0.75 if caption else 0.55,
                    provenance={
                        **asset.provenance,
                        "extraction_method": "embedded_image",
                        "requires_alternative_text_review": not bool(caption),
                    },
                    page_start=asset.page_start,
                    page_end=asset.page_end,
                )
            )
            local_order += 1

    ordered = sorted(
        blocks,
        key=lambda block: (
            block.section_order if block.section_order is not None else 2**31,
            block.sort_order,
        ),
    )
    for index, block in enumerate(ordered):
        block.sort_order = index
        block.source_fingerprint = _fingerprint(block)
    return ordered


def _text_blocks(
    section: ExtractedSection,
    confidence: float,
    page_methods: dict[int, str],
    multi_column_pages: list[int],
) -> list[ExtractedContentBlock]:
    blocks: list[ExtractedContentBlock] = []
    paragraph: list[str] = []
    unordered: list[str] = []
    ordered: list[str] = []
    local_order = 1

    def emit(block_type: str, content: dict[str, Any], modifier: float = 0.0) -> None:
        nonlocal local_order
        blocks.append(
            _block(
                block_type=block_type,
                content=content,
                section=section,
                local_order=local_order,
                confidence=max(0.0, min(1.0, confidence + modifier)),
                provenance=_provenance(
                    section.page_start,
                    section.page_end,
                    "reading_order_text",
                    page_methods,
                    multi_column_pages,
                ),
            )
        )
        local_order += 1

    def flush_paragraph() -> None:
        if paragraph:
            emit("paragraph", {"type": "paragraph", "text": " ".join(paragraph).strip()})
            paragraph.clear()

    def flush_lists() -> None:
        if unordered:
            emit("unordered_list", {"type": "unordered_list", "items": list(unordered)})
            unordered.clear()
        if ordered:
            emit("ordered_list", {"type": "ordered_list", "items": list(ordered)})
            ordered.clear()

    for raw_line in section.text.splitlines():
        line = raw_line.strip()
        if not line:
            flush_paragraph()
            flush_lists()
            continue
        bullet = _BULLET_RE.match(line)
        numbered = _ORDERED_RE.match(line)
        callout = _callout(line)
        if bullet:
            flush_paragraph()
            if ordered:
                flush_lists()
            unordered.append(bullet.group(1).strip())
        elif numbered:
            flush_paragraph()
            if unordered:
                flush_lists()
            ordered.append(numbered.group(1).strip())
        elif callout:
            flush_paragraph()
            flush_lists()
            block_type, title, content, severity = callout
            emit(
                block_type,
                {"type": block_type, "title": title, "content": content, "severity": severity},
                modifier=-0.15,
            )
        else:
            flush_lists()
            paragraph.append(line)

    flush_paragraph()
    flush_lists()
    return blocks


def _callout(line: str) -> tuple[str, str, str, str] | None:
    for pattern, block_type, title, severity in (
        (_RECOMMENDATION_RE, "recommendation", "Recommendation", "standard"),
        (_WARNING_RE, "warning", "Warning", "high"),
        (_KEY_POINT_RE, "key_point", "Key point", "important"),
    ):
        match = pattern.match(line)
        if match:
            content = (match.group(1) or line).strip()
            return block_type, title, content, severity
    return None


def _table_payload(table: ExtractedTable) -> tuple[dict[str, Any], str | None]:
    rows = [[str(cell or "") for cell in row] for row in table.data if any(str(cell or "").strip() for cell in row)]
    width = max((len(row) for row in rows), default=0)
    if width == 0:
        return {"type": "table", "title": table.title or "", "columns": [], "rows": [], "footnotes": []}, "empty_table"
    normalized = [row + [""] * (width - len(row)) for row in rows]
    columns = normalized[0]
    body = normalized[1:]
    return {
        "type": "table",
        "title": table.title or "",
        "columns": columns,
        "rows": body,
        "footnotes": [],
    }, "header_inferred_from_first_row"


def _tables_by_section(sections: list[ExtractedSection], tables: list[ExtractedTable]) -> dict[int, list[ExtractedTable]]:
    result: dict[int, list[ExtractedTable]] = {}
    for table in tables:
        section = _section_for_page(sections, table.page)
        if section is not None:
            result.setdefault(section.sort_order, []).append(table)
    return result


def _assets_by_section(sections: list[ExtractedSection], assets: list[ExtractedAsset]) -> dict[int, list[ExtractedAsset]]:
    result: dict[int, list[ExtractedAsset]] = {}
    for asset in assets:
        page = asset.page_start or asset.page_end
        section = _section_for_page(sections, page) if page else None
        if section is not None:
            asset.section_order = section.sort_order
            result.setdefault(section.sort_order, []).append(asset)
    return result


def _section_for_page(sections: list[ExtractedSection], page: int) -> ExtractedSection | None:
    candidates = [
        section for section in sections
        if (section.page_start or 0) <= page <= (section.page_end or section.page_start or 0)
    ]
    return candidates[-1] if candidates else None


def _section_confidence(section: ExtractedSection, page_methods: dict[int, str]) -> float:
    methods = {
        page_methods.get(page, "embedded_text")
        for page in range(section.page_start or 1, (section.page_end or section.page_start or 1) + 1)
    }
    return 0.68 if "ocr" in methods else 0.9


def _provenance(
    page_start: int | None,
    page_end: int | None,
    extraction_method: str,
    page_methods: dict[int, str],
    multi_column_pages: list[int],
) -> dict[str, Any]:
    pages = list(range(page_start or 1, (page_end or page_start or 1) + 1))
    return {
        "page_start": page_start,
        "page_end": page_end,
        "extraction_method": extraction_method,
        "page_methods": {str(page): page_methods.get(page, "embedded_text") for page in pages},
        "multi_column": any(page in multi_column_pages for page in pages),
        "review_required": True,
    }


def _block(
    *,
    block_type: str,
    content: dict[str, Any],
    section: ExtractedSection,
    local_order: int,
    confidence: float,
    provenance: dict[str, Any],
    page_start: int | None = None,
    page_end: int | None = None,
) -> ExtractedContentBlock:
    return ExtractedContentBlock(
        type=block_type,
        sort_order=local_order,
        content=content,
        source_fingerprint="",
        section_order=section.sort_order,
        page_start=page_start or section.page_start,
        page_end=page_end or section.page_end,
        extraction_confidence=confidence,
        provenance=provenance,
    )


def _fingerprint(block: ExtractedContentBlock) -> str:
    payload = json.dumps(
        {
            "type": block.type,
            "section_order": block.section_order,
            "page_start": block.page_start,
            "page_end": block.page_end,
            "sort_order": block.sort_order,
            "content": block.content,
        },
        sort_keys=True,
        ensure_ascii=False,
        separators=(",", ":"),
    ).encode("utf-8")
    return hashlib.sha256(payload).hexdigest()
