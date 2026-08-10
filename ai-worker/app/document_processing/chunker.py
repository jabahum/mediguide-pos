from dataclasses import dataclass
from typing import Any
import structlog
from app.core.config import get_settings
from app.document_processing.types import ExtractedContentBlock, ExtractedSection

log = structlog.get_logger()


@dataclass
class Chunk:
    title: str | None
    content: str
    html: str
    page_start: int | None
    page_end: int | None
    section_order: int
    chunk_order: int
    block_order: int | None = None


def _split_words(text: str, chunk_size: int, overlap: int) -> list[str]:
    words = text.split()
    if not words:
        return []
    chunks = []
    start = 0
    while start < len(words):
        end = min(start + chunk_size, len(words))
        chunks.append(" ".join(words[start:end]))
        if end == len(words):
            break
        start = max(0, end - overlap)
    return chunks


def chunk_sections(sections: list[ExtractedSection]) -> list[Chunk]:
    settings = get_settings()
    chunks: list[Chunk] = []
    for section in sections:
        pieces = _split_words(section.text, settings.chunk_size, settings.chunk_overlap)
        if not pieces and section.title:
            pieces = [section.title]
        chunk_title = section.breadcrumb or section.title
        for idx, piece in enumerate(pieces):
            if len(piece) < settings.min_chunk_chars and len(pieces) > 1:
                log.warning(
                    "chunk_discarded_too_short",
                    section_title=section.title,
                    chunk_index=idx,
                    chunk_length=len(piece),
                    min_required=settings.min_chunk_chars,
                )
                continue
            html = f"<h{min(max(section.level, 1), 4)}>{section.title}</h{min(max(section.level, 1), 4)}><p>{piece}</p>"
            chunks.append(
                Chunk(
                    title=chunk_title,
                    content=piece,
                    html=html,
                    page_start=section.page_start,
                    page_end=section.page_end,
                    section_order=section.sort_order,
                    chunk_order=idx,
                )
            )
    return chunks


def chunk_blocks(blocks: list[ExtractedContentBlock]) -> list[Chunk]:
    settings = get_settings()
    chunks: list[Chunk] = []
    for block in blocks:
        text = _block_text(block)
        if not text:
            continue
        pieces = _split_words(text, settings.chunk_size, settings.chunk_overlap)
        for index, piece in enumerate(pieces):
            if len(piece) < settings.min_chunk_chars and len(pieces) > 1:
                continue
            chunks.append(
                Chunk(
                    title=_block_title(block),
                    content=piece,
                    html="",
                    page_start=block.page_start,
                    page_end=block.page_end,
                    section_order=block.section_order or 0,
                    chunk_order=index,
                    block_order=block.sort_order,
                )
            )
    return chunks


def _block_title(block: ExtractedContentBlock) -> str | None:
    value = block.content.get("title") or block.content.get("text")
    if not value:
        return None
    return str(value)[:180]


def _block_text(block: ExtractedContentBlock) -> str:
    content: dict[str, Any] = block.content
    if block.type in {"heading", "paragraph", "unknown"}:
        return str(content.get("text") or "").strip()
    if block.type in {"ordered_list", "unordered_list"}:
        return "\n".join(str(item) for item in content.get("items") or []).strip()
    if block.type in {"recommendation", "warning", "key_point"}:
        return " ".join(
            value for value in (str(content.get("title") or "").strip(), str(content.get("content") or "").strip()) if value
        )
    if block.type == "table":
        rows = [content.get("columns") or [], *(content.get("rows") or [])]
        return "\n".join(" | ".join(str(cell) for cell in row) for row in rows).strip()
    if block.type == "reference":
        return str(content.get("citation") or "").strip()
    return ""
