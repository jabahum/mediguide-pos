import pytest

from app.document_processing.types import ExtractedAsset
from app.repositories.guideline_repo import GuidelineRepository


def test_replace_extraction_rejects_incomplete_embedding_results():
    repo = GuidelineRepository()

    with pytest.raises(ValueError, match="Embedding count does not match chunk count"):
        repo.replace_extraction(
            version_id="version-id",
            version={"id": "version-id"},
            sections=[],
            tables=[],
            chunks=[object()],
            embeddings=[],
            html_key="extracted.html",
            markdown_key="extracted.md",
        )


def extracted_asset(
    *,
    source_key: str,
    source_fingerprint: str,
    checksum: str = "content-checksum",
):
    return ExtractedAsset(
        type="figure",
        source_key=source_key,
        source_fingerprint=source_fingerprint,
        mime_type="image/jpeg",
        checksum=checksum,
        size_bytes=128,
        storage_key=f"guidelines/version-id/assets/{checksum}.jpeg",
        page_start=2,
        page_end=2,
    )


def test_prepare_asset_rows_reuses_content_addressed_asset_for_all_source_keys():
    aliases, rows = GuidelineRepository._prepare_asset_rows(
        version_id="version-id",
        assets=[
            extracted_asset(source_key="page-2-image-1", source_fingerprint="source-one"),
            extracted_asset(source_key="page-8-image-3", source_fingerprint="source-two"),
        ],
        section_id_by_order={},
    )

    assert len(rows) == 1
    assert aliases["page-2-image-1"] == aliases["page-8-image-3"]
    assert rows[0][6] == "guidelines/version-id/assets/content-checksum.jpeg"


def test_prepare_asset_rows_rejects_conflicting_metadata_for_one_storage_key():
    canonical = extracted_asset(
        source_key="page-2-image-1",
        source_fingerprint="source-one",
    )
    conflicting = extracted_asset(
        source_key="page-8-image-3",
        source_fingerprint="source-two",
    )
    conflicting.mime_type = "image/png"

    with pytest.raises(ValueError, match="Conflicting extracted asset metadata"):
        GuidelineRepository._prepare_asset_rows(
            version_id="version-id",
            assets=[canonical, conflicting],
            section_id_by_order={},
        )


def test_prepare_asset_rows_rejects_one_fingerprint_for_different_objects():
    with pytest.raises(ValueError, match="fingerprint maps to multiple objects"):
        GuidelineRepository._prepare_asset_rows(
            version_id="version-id",
            assets=[
                extracted_asset(
                    source_key="first",
                    source_fingerprint="same-source",
                    checksum="first",
                ),
                extracted_asset(
                    source_key="second",
                    source_fingerprint="same-source",
                    checksum="second",
                ),
            ],
            section_id_by_order={},
        )
