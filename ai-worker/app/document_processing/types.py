from dataclasses import dataclass, field
from typing import Any


@dataclass
class ExtractedBlock:
    text: str
    page: int
    level: int = 0
    html: str = ""
    kind: str = "paragraph"  # heading, paragraph, table


@dataclass
class ExtractedSection:
    title: str
    level: int
    page_start: int | None = None
    page_end: int | None = None
    html: str = ""
    text: str = ""
    sort_order: int = 0
    parent_sort_order: int | None = None
    breadcrumb: str = ""
    extraction_confidence: float = 0.0
    provenance: dict[str, Any] = field(default_factory=dict)


@dataclass
class ExtractedTable:
    title: str | None
    page: int
    html: str
    data: list[list[Any]] = field(default_factory=list)
    bbox: tuple[float, float, float, float] | None = None
    extraction_confidence: float = 0.0
    provenance: dict[str, Any] = field(default_factory=dict)


@dataclass
class ExtractedContentBlock:
    type: str
    sort_order: int
    content: dict[str, Any]
    source_fingerprint: str
    section_order: int | None = None
    page_start: int | None = None
    page_end: int | None = None
    extraction_confidence: float = 0.0
    provenance: dict[str, Any] = field(default_factory=dict)


@dataclass
class ExtractedAsset:
    type: str
    source_key: str
    source_fingerprint: str
    mime_type: str
    checksum: str
    size_bytes: int
    storage_key: str | None = None
    original_filename: str | None = None
    section_order: int | None = None
    page_start: int | None = None
    page_end: int | None = None
    data: bytes | None = field(default=None, repr=False)
    provenance: dict[str, Any] = field(default_factory=dict)


@dataclass
class ExtractedDocument:
    title: str | None
    pages: int
    html: str
    markdown: str
    text: str
    sections: list[ExtractedSection]
    tables: list[ExtractedTable]
    blocks: list[ExtractedContentBlock] = field(default_factory=list)
    assets: list[ExtractedAsset] = field(default_factory=list)
    metadata: dict[str, Any] = field(default_factory=dict)
    toc_entries: list[str] = field(default_factory=list)
    ocr_pages: list[int] = field(default_factory=list)
    multi_column_pages: list[int] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)
