import app.repositories.search_repo as search_module


class FakeCursor:
    def __init__(self, capture: dict):
        self.capture = capture

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, tb):
        return False

    def execute(self, sql: str, params: tuple):
        self.capture["sql"] = sql
        self.capture["params"] = params

    def fetchall(self):
        return []


class FakeConnection:
    def __init__(self, capture: dict):
        self.capture = capture

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, tb):
        return False

    def cursor(self):
        return FakeCursor(self.capture)


def test_keyword_search_applies_language_and_country_filters(monkeypatch):
    capture: dict = {}
    monkeypatch.setattr(search_module, "db_conn", lambda: FakeConnection(capture))

    repo = search_module.SearchRepository()
    repo.keyword_search(
        "severe malaria",
        top_k=5,
        program_area="Malaria",
        language="en",
        country="Uganda",
        national_first=False,
    )

    assert "lower(gc.language) = lower(%s)" in capture["sql"]
    assert "lower(coalesce(gd.country, '')) = lower(%s)" in capture["sql"]
    assert "gv.status = 'published'" in capture["sql"]
    assert "gd.current_version_id = gv.id" in capture["sql"]
    assert capture["params"] == ("severe malaria", "severe malaria", "Malaria", "en", "Uganda", 5)


def test_vector_search_prioritizes_requested_country_when_national_first(monkeypatch):
    capture: dict = {}
    monkeypatch.setattr(search_module, "db_conn", lambda: FakeConnection(capture))

    repo = search_module.SearchRepository()
    repo.vector_search(
        [0.1, 0.2],
        top_k=4,
        language="en",
        country="Uganda",
        national_first=True,
    )

    assert (
        "CASE WHEN lower(coalesce(gd.country, '')) = lower(%s) THEN 0 ELSE 1 END AS country_rank"
        in capture["sql"]
    )
    assert "ORDER BY country_rank ASC, gc.embedding <=> %s::vector" in " ".join(
        capture["sql"].split()
    )
    assert "gv.status = 'published'" in capture["sql"]
    assert "gd.current_version_id = gv.id" in capture["sql"]
    assert capture["params"] == (
        "Uganda",
        "[0.10000000,0.20000000]",
        "en",
        "[0.10000000,0.20000000]",
        4,
    )
