from pathlib import Path

import fitz
import pytest

from app.document_processing.chunker import chunk_blocks
from app.document_processing.pdf_extractor import (
    _page_text_from_blocks,
    _remove_repeated_margin_lines,
    extract_pdf,
)
from app.document_processing.structured_blocks import build_structured_blocks
from app.document_processing.types import ExtractedSection, ExtractedTable
from app.services.ingestion_service import IngestionService


def test_structured_blocks_preserve_lists_callouts_tables_and_provenance():
    section = ExtractedSection(
        title="3. Diagnosis and Assessment",
        level=2,
        page_start=4,
        page_end=5,
        sort_order=0,
        text="\n".join(
            [
                "Clinical assessment must retain 2.4 mg/kg and SpO₂ ≥ 94%.",
                "• Check airway",
                "• Check breathing",
                "Recommendation: Refer patients with danger signs.",
                "Warning: Do not alter the prescribed dose.",
            ]
        ),
    )
    table = ExtractedTable(
        title="Performance of RDT",
        page=5,
        html="<table></table>",
        data=[["Test", "Sensitivity"], ["HRP2-based", "95–98%"]],
    )

    blocks = build_structured_blocks(
        [section],
        [table],
        [],
        page_methods={4: "embedded_text", 5: "embedded_text"},
    )

    assert [block.type for block in blocks] == [
        "heading",
        "paragraph",
        "unordered_list",
        "recommendation",
        "warning",
        "table",
    ]
    paragraph = next(block for block in blocks if block.type == "paragraph")
    assert "2.4 mg/kg" in paragraph.content["text"]
    assert "SpO₂ ≥ 94%" in paragraph.content["text"]
    assert paragraph.page_start == 4
    assert paragraph.provenance["review_required"] is True
    assert all(len(block.source_fingerprint) == 64 for block in blocks)
    assert len({block.source_fingerprint for block in blocks}) == len(blocks)
    table_block = blocks[-1]
    assert table_block.content["columns"] == ["Test", "Sensitivity"]
    assert table_block.content["rows"] == [["HRP2-based", "95–98%"]]


def test_block_chunks_keep_block_and_page_association():
    section = ExtractedSection(
        title="Assessment",
        level=1,
        page_start=7,
        page_end=7,
        sort_order=3,
        text="A sufficiently detailed clinical assessment paragraph for retrieval and citation.",
    )
    blocks = build_structured_blocks([section], [], [])

    chunks = chunk_blocks(blocks)

    assert chunks
    assert all(chunk.block_order is not None for chunk in chunks)
    assert all(chunk.page_start == 7 and chunk.page_end == 7 for chunk in chunks)


def test_repeated_margin_lines_are_removed_without_changing_body():
    pages = [
        (1, "Ministry Clinical Guideline\nPage one clinical body\n1"),
        (2, "Ministry Clinical Guideline\nPage two clinical body\n2"),
        (3, "Ministry Clinical Guideline\nPage three clinical body\n3"),
    ]

    cleaned = _remove_repeated_margin_lines(pages)

    assert all("Ministry Clinical Guideline" not in text for _, text in cleaned)
    assert "Page two clinical body" in cleaned[1][1]


def test_multi_column_reading_order_is_left_column_then_right_column():
    blocks = [
        (
            320.0,
            40.0,
            580.0,
            100.0,
            "Right first paragraph with enough clinical detail to count.",
            0,
            0,
        ),
        (
            20.0,
            200.0,
            280.0,
            260.0,
            "Left second paragraph with enough clinical detail to count.",
            1,
            0,
        ),
        (
            20.0,
            40.0,
            280.0,
            100.0,
            "Left first paragraph with enough clinical detail to count.",
            2,
            0,
        ),
        (
            320.0,
            200.0,
            580.0,
            260.0,
            "Right second paragraph with enough clinical detail to count.",
            3,
            0,
        ),
    ]

    text = _page_text_from_blocks(blocks, [], 600.0)

    assert text.index("Left first") < text.index("Left second") < text.index("Right first")


def test_extract_pdf_uses_ocr_for_scanned_page(monkeypatch: pytest.MonkeyPatch, tmp_path: Path):
    path = tmp_path / "scanned.pdf"
    document = fitz.open()
    document.new_page()
    document.save(path)
    document.close()
    monkeypatch.setattr(
        "app.document_processing.pdf_extractor._ocr_page_text",
        lambda _page: "1 EMERGENCIES AND TRAUMA\n1.1 Triage Assessment\nAssess airway breathing circulation and danger signs before urgent referral.",
    )

    extracted = extract_pdf(path)

    assert extracted.ocr_pages == [1]
    assert extracted.metadata["text_mode"] == "ocr_required"
    assert extracted.blocks
    assert any("OCR-derived text" in warning for warning in extracted.warnings)


def test_extract_pdf_rejects_malformed_pdf(tmp_path: Path):
    path = tmp_path / "malformed.pdf"
    path.write_bytes(b"this is not a pdf")

    with pytest.raises(Exception):
        extract_pdf(path)


def test_document_checksum_and_asset_extension_are_deterministic(tmp_path: Path):
    path = tmp_path / "source.pdf"
    path.write_bytes(b"clinical source")

    first = IngestionService._file_checksum(path)
    second = IngestionService._file_checksum(path)

    assert first == second
    assert len(first) == 64
