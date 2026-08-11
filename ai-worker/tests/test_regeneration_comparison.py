from app.repositories.guideline_repo import GuidelineRepository


def test_regeneration_comparison_reports_clinically_relevant_changes():
    before = {
        "sections": [{"slug": "care", "title": "Care", "level": 2}],
        "block_type_counts": {"warning": 1, "paragraph": 2},
        "table_count": 1,
        "chunk_count": 2,
        "assets": [{"type": "original_pdf", "source_fingerprint": "pdf"}],
    }
    after = {
        "sections": [
            {"slug": "care", "title": "Clinical care", "level": 3},
            {"slug": "dose", "title": "Dose", "level": 2},
        ],
        "block_type_counts": {"warning": 2, "table": 1},
        "table_count": 2,
        "chunk_count": 4,
        "assets": [{"type": "figure", "source_fingerprint": "figure-1"}],
    }

    result = GuidelineRepository._compare_projection_snapshots(before, after)

    assert result["sections"]["added"][0]["slug"] == "dose"
    assert result["sections"]["renamed"][0]["after"]["title"] == "Clinical care"
    assert result["sections"]["hierarchy_changed"]
    assert {change["type"] for change in result["block_types"]} == {"paragraph", "table", "warning"}
    assert result["tables"] == {"before": 1, "after": 2}
    assert result["chunks"] == {"before": 2, "after": 4}
    assert result["pdf_citations_unavailable"] is True
