from app.document_processing.pdf_extractor import (
    _split_sections,
    _clean_table_rows,
    _is_noise_line,
    _looks_like_toc_entry,
    _page_text_from_blocks,
    _render_table_cell_content,
    _render_table_html,
    _section_html,
    _table_anchor_phrases,
)


def test_section_html_renders_management_table_with_header_styling():
    html = _section_html(
        "Benign Prostatic Hyperplasia",
        2,
        "\n".join(
            [
                "Management",
                "TREATMENT",
                "LOC",
                " Treat with antibiotics if infection present",
                "HC2",
                " Surgical management if severe symptoms",
                "RR",
            ]
        ),
    )

    assert "<table" in html
    assert "TREATMENT" in html
    assert "LOC" in html
    assert "background:#dbe5f1" in html
    assert "Treat with antibiotics if infection present" in html
    assert "Surgical management if severe symptoms" in html
    assert "HC2" in html
    assert "RR" in html


def test_section_html_renders_bullets_as_list_items():
    html = _section_html(
        "Investigations",
        2,
        "\n".join(
            [
                "Investigations",
                " Urine analysis (blood, leucocytes)",
                " Renal function",
                " Abdominal ultrasound",
            ]
        ),
    )

    assert "<ul>" in html
    assert html.count("<li>") == 3
    assert "Urine analysis (blood, leucocytes)" in html


def test_clean_table_rows_discards_empty_rows():
    rows = _clean_table_rows(
        [
            ["", "", ""],
            ["TREATMENT", "LOC", ""],
            ["Treat infection", "HC2", None],
        ]
    )

    assert rows == [
        ["TREATMENT", "LOC", ""],
        ["Treat infection", "HC2", ""],
    ]


def test_render_table_html_preserves_untitled_multi_column_tables():
    html = _render_table_html(
        [
            ["DRUG", "DOSE", "ROUTE"],
            ["Diazepam", "10 mg", "IV"],
            ["Paracetamol", "1 g", "PO"],
        ],
        title=None,
    )

    assert "<table" in html
    assert "<caption" not in html
    assert "background:#dbe5f1" in html
    assert "DRUG" in html
    assert "Diazepam" in html


def test_render_table_html_skips_single_column_noise_tables():
    html = _render_table_html(
        [
            ["The Seven Steps in a Primary Care Consultation"],
            ["01 Greet 02 Look 03 Listen 04 Examine 05 Suspect diagnosis"],
        ],
        title=None,
    )

    assert html == ""


def test_section_html_does_not_promote_bullet_glyphs_to_headings():
    html = _section_html(
        "Chronic Care",
        3,
        "\n".join(
            [
                "~ Health workers are faced with an increasing number of chronic diseases",
                "~ Communication is even more important",
            ]
        ),
    )

    assert "<h4>~</h4>" not in html
    assert html.count("<li>") == 2


def test_is_noise_line_ignores_page_markers():
    assert _is_noise_line("LIII")
    assert _is_noise_line("465")
    assert _is_noise_line(
        "1 EMERGENCIES AND TRAUMA.....................................................1"
    )


def test_looks_like_toc_entry_matches_numbered_rows_with_trailing_page_numbers():
    assert _looks_like_toc_entry(
        "2.1.5.2 Cryptococcal Meningitis........................................................................213"
    )
    assert _looks_like_toc_entry(
        "3.1 HIV Infection And Acquired Immunodeficiency Syndrome (AIDS) .186"
    )


def test_render_table_cell_content_preserves_bullet_lists():
    html = _render_table_cell_content(
        "~ Accurate diagnosis of the condition\n~ Selection of the most appropriate medicine"
    )

    assert "<ul>" in html
    assert "Accurate diagnosis of the condition" in html
    assert "Selection of the most appropriate medicine" in html


def test_render_table_cell_content_reconstructs_inline_mini_table():
    html = _render_table_cell_content(
        "\n".join(
            [
                "Age (Months) <4 4-12 13-24 25-60",
                "Weight (Kg) <6 6-9.9 10-11.9 12-19",
                "ORS (Ml) 200-400 400-700 700-900 900-1400",
                "- Only use child's age if weight is not known",
            ]
        )
    )

    assert "guideline-inline-grid" in html
    assert "<table" not in html
    assert "Age (Months)" in html
    assert "700-900" in html
    assert "Only use child&#x27;s age if weight is not known" in html


def test_render_table_cell_content_does_not_turn_wrapped_phrase_into_nested_table():
    html = _render_table_cell_content("Drinks poorly or not\nable to drink")

    assert "guideline-inline-grid" not in html
    assert "<table" not in html
    assert "Drinks poorly or not able to drink" in html


def test_table_anchor_phrases_include_short_first_column_labels():
    anchors = _table_anchor_phrases(
        [
            ["Age (Months)", "<4", "4-12", "13-24", "25-60"],
            ["Weight (Kg)", "<6", "6-9.9", "10-11.9", "12-19"],
            ["ORS (Ml)", "200-400", "400-700", "700-900", "900-1400"],
        ]
    )

    assert "age (months)" in anchors
    assert "weight (kg)" in anchors
    assert "ors (ml)" in anchors


def test_page_text_from_blocks_excludes_table_regions():
    blocks = [
        (0.0, 0.0, 120.0, 20.0, "Clinical features\n", 0, 0),
        (0.0, 50.0, 300.0, 200.0, "Age (Months) <4 4-12\nWeight (Kg) <6 6-9.9\n", 1, 0),
        (0.0, 220.0, 240.0, 260.0, "Continue feeding.\n", 2, 0),
    ]

    text = _page_text_from_blocks(blocks, [(0.0, 40.0, 320.0, 210.0)])

    assert "Clinical features" in text
    assert "Continue feeding." in text
    assert "Age (Months)" not in text


def test_split_sections_builds_chapter_and_subsection_hierarchy():
    sections = _split_sections(
        [
            (
                1,
                "\n".join(
                    [
                        "CHAPTER 1 : General Principles",
                        "1.1 Assessment",
                        "Clinical features",
                        "Fever and cough",
                        "Management",
                        "Hydrate and monitor",
                        "1.1.1 Severe Disease",
                        "Investigations",
                        "Blood count",
                    ]
                ),
            )
        ]
    )

    assert [section.title for section in sections] == [
        "Chapter 1: General Principles",
        "1.1 Assessment",
        "Clinical features",
        "Management",
        "1.1.1 Severe Disease",
        "Investigations",
    ]
    assert [section.level for section in sections] == [1, 2, 3, 3, 3, 4]
    assert sections[1].parent_sort_order == 0
    assert sections[2].parent_sort_order == 1
    assert sections[3].parent_sort_order == 1
    assert sections[4].parent_sort_order == 1
    assert sections[5].parent_sort_order == 4
    assert sections[5].breadcrumb == (
        "Chapter 1: General Principles > 1.1 Assessment > 1.1.1 Severe Disease > Investigations"
    )
    assert sections[2].text == "Fever and cough"
    assert sections[3].text == "Hydrate and monitor"
    assert sections[5].text == "Blood count"


def test_split_sections_skips_cover_headings_before_first_real_section():
    sections = _split_sections(
        [
            (
                1,
                "\n".join(
                    [
                        "THE REPUBLIC OF UGANDA",
                        "MINISTRY OF HEALTH",
                        "1 EMERGENCIES AND TRAUMA",
                        "1.1 Common Emergencies",
                        "Overview text",
                    ]
                ),
            )
        ]
    )

    assert [section.title for section in sections] == [
        "1 EMERGENCIES AND TRAUMA",
        "1.1 Common Emergencies",
    ]
    assert sections[1].parent_sort_order == 0


def test_split_sections_does_not_treat_large_numeric_table_values_as_headings():
    sections = _split_sections(
        [
            (
                1,
                "\n".join(
                    [
                        "100 Kcals/100 Ml",
                        "1 EMERGENCIES AND TRAUMA",
                        "Overview text",
                    ]
                ),
            )
        ]
    )

    assert [section.title for section in sections] == ["1 EMERGENCIES AND TRAUMA"]
    assert sections[0].text == "Overview text"


def test_split_sections_accepts_trailing_dot_numbered_headings():
    sections = _split_sections(
        [
            (
                1,
                "\n".join(
                    [
                        "1. SOPs FOR INDIVIDUAL LEVEL",
                        "Purpose",
                        "To provide guidance to individuals and households.",
                        "2. SOPs FOR MASS GATHERINGS",
                        "To provide guidance to organizers of public events.",
                    ]
                ),
            )
        ]
    )

    assert [section.title for section in sections] == [
        "1 SOPs FOR INDIVIDUAL LEVEL",
        "2 SOPs FOR MASS GATHERINGS",
    ]
    assert sections[0].text == "Purpose\nTo provide guidance to individuals and households."
    assert sections[1].text == "To provide guidance to organizers of public events."


def test_split_sections_falls_back_to_introduction_when_no_headings_exist():
    sections = _split_sections(
        [
            (
                1,
                "\n".join(
                    [
                        "This guidance provides detailed operational steps for outbreak response.",
                        "Health workers should isolate suspected cases and notify district surveillance teams.",
                        "Community members should avoid direct contact with body fluids.",
                    ]
                ),
            )
        ]
    )

    assert [section.title for section in sections] == ["Introduction"]
    assert sections[0].text.startswith("This guidance provides detailed operational steps")
