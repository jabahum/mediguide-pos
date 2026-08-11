from pathlib import Path

import pytest

from app.document_processing.markdown_extractor import extract_markdown
from app.services.ingestion_service import IngestionService


def test_markdown_source_builds_hierarchy_and_typed_blocks(tmp_path: Path):
    path = tmp_path / "guideline.md"
    path.write_text(
        """---
title: Malaria Care
version: 2026.1
---
# Assessment
Assess the patient before treatment.

## Danger signs
- Altered consciousness
- Severe weakness

Warning: Refer immediately when danger signs are present.

| Test | Result |
| --- | --- |
| RDT | Positive |
""",
        encoding="utf-8",
    )

    extracted = extract_markdown(path)

    assert extracted.title == "Malaria Care"
    assert [section.title for section in extracted.sections] == ["Assessment", "Danger signs"]
    assert extracted.sections[1].parent_sort_order == 0
    assert {block.type for block in extracted.blocks} >= {
        "heading",
        "paragraph",
        "unordered_list",
        "warning",
        "table",
    }
    assert all(block.page_start is None and block.page_end is None for block in extracted.blocks)
    assert extracted.metadata["source_format"] == "markdown"
    assert extracted.metadata["page_citations_available"] is False
    assert extracted.warnings


def test_markdown_html_output_escapes_raw_html(tmp_path: Path):
    path = tmp_path / "unsafe.md"
    path.write_text("# Safety\n<script>alert('unsafe')</script>", encoding="utf-8")

    extracted = extract_markdown(path)

    assert "<script>" not in extracted.html
    assert "&lt;script&gt;" in extracted.html


def test_markdown_fenced_clinical_callouts_are_typed_and_preserved(tmp_path: Path):
    path = tmp_path / "callouts.md"
    path.write_text(
        '# Safety\n\n:::dosage title="Reviewed dose" severity=high evidence_grade=A\n'
        'Give 5 mg exactly as clinically reviewed.\n:::\n\n'
        ':::contraindication\nDo not use in the documented condition.\n:::\n',
        encoding="utf-8",
    )

    extracted = extract_markdown(path)
    callouts = [block for block in extracted.blocks if block.type in {"dosage", "contraindication"}]

    assert [block.type for block in callouts] == ["dosage", "contraindication"]
    assert callouts[0].content["title"] == "Reviewed dose"
    assert callouts[0].content["severity"] == "high"
    assert ":::dosage" in extracted.markdown


def test_markdown_rejects_unclosed_or_empty_clinical_callouts(tmp_path: Path):
    path = tmp_path / "invalid-callout.md"
    path.write_text("# Safety\n\n:::warning\n", encoding="utf-8")

    with pytest.raises(ValueError, match="not closed"):
        extract_markdown(path)


def test_markdown_source_requires_utf8(tmp_path: Path):
    path = tmp_path / "invalid.md"
    path.write_bytes(b"# Guidance\n\xff")

    with pytest.raises(ValueError, match="valid UTF-8"):
        extract_markdown(path)


def test_ingestion_job_payload_accepts_json_and_rejects_non_objects():
    assert IngestionService._job_payload({
        "payload_json": '{"file_key":"guidelines/source.md","source_format":"markdown"}'
    })["source_format"] == "markdown"

    with pytest.raises(ValueError, match="must be an object"):
        IngestionService._job_payload({"payload_json": "[]"})
