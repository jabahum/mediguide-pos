import pytest
from collections import defaultdict, deque

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


def test_review_identity_requires_matching_type_and_content():
    previously_reviewed = defaultdict(deque)
    identity = GuidelineRepository._stable_block_identity(
        "paragraph", {"type": "paragraph", "text": "same content"}
    )
    previously_reviewed[identity].append(("reviewed", "reviewer-id", "reviewed-at"))

    review = GuidelineRepository._regenerated_block_review

    assert review(
        block_type="paragraph",
        content={"text": "same content", "type": "paragraph"},
        previous_reviews=previously_reviewed,
    ) == ("reviewed", "reviewer-id", "reviewed-at")
    assert review(
        block_type="table",
        content={"text": "same content", "type": "paragraph"},
        previous_reviews=previously_reviewed,
    ) == ("draft", None, None)


def test_review_identity_preserves_occurrence_order_for_duplicate_content():
    previous_reviews = defaultdict(deque)
    identity = GuidelineRepository._stable_block_identity(
        "heading", {"type": "heading", "text": "Summary", "level": 3}
    )
    previous_reviews[identity].extend(
        [
            ("draft", None, None),
            ("reviewed", "reviewer-id", "reviewed-at"),
        ]
    )

    review = GuidelineRepository._regenerated_block_review
    assert review(
        block_type="heading",
        content={"level": 3, "text": "Summary", "type": "heading"},
        previous_reviews=previous_reviews,
    ) == ("draft", None, None)
    assert review(
        block_type="heading",
        content={"level": 3, "text": "Summary", "type": "heading"},
        previous_reviews=previous_reviews,
    ) == ("reviewed", "reviewer-id", "reviewed-at")


def test_regenerated_chunk_inherits_its_block_review_status():
    status = GuidelineRepository._regenerated_chunk_review_status

    assert status(
        block_order=42,
        block_review_status_by_order={42: "reviewed"},
    ) == "reviewed"
    assert status(
        block_order=43,
        block_review_status_by_order={42: "reviewed"},
    ) == "draft"
    assert status(
        block_order=None,
        block_review_status_by_order={42: "reviewed"},
    ) == "draft"


def test_authored_asset_metadata_enriches_figure_content():
    content = {
        "type": "figure",
        "asset_id": "asset-id",
        "caption": "Markdown fallback",
        "alternative_text": "Markdown alternative text",
    }

    enriched = GuidelineRepository._enrich_authored_figure_content(
        content,
        {
            "caption": "Reviewed asset caption",
            "alternative_text": "Reviewed asset alternative text",
        },
    )

    assert enriched == {
        "type": "figure",
        "asset_id": "asset-id",
        "caption": "Reviewed asset caption",
        "alternative_text": "Reviewed asset alternative text",
    }
    assert content["caption"] == "Markdown fallback"
