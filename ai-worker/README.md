# MediGuide AI Worker

Python AI/document-processing worker for the MediGuide platform.

It processes uploaded clinical guideline PDFs and Markdown files into:

- cleaned HTML
- Markdown
- structured sections
- extracted tables
- searchable chunks
- vector embeddings for `guideline_chunks.embedding`
- RAG answers with citations

This project is designed to plug into the Go backend scaffold generated earlier.

## Features

- FastAPI service for health checks, manual job runs, extraction preview, embeddings, and RAG answers
- Background worker that polls `ingestion_jobs` from PostgreSQL
- MinIO/S3 file download and upload
- PDF extraction using PyMuPDF and optional pdfplumber
- UTF-8 Markdown parsing with heading hierarchy, lists, callouts, and GFM tables
- HTML cleaning using BeautifulSoup
- Section detection from PDF heading/font structure
- Chunking with overlap
- pgvector-compatible embeddings
- Optional providers:
  - deterministic local hash embeddings for development
  - Ollama embeddings
  - SentenceTransformers embeddings
  - OpenAI embeddings
  - Ollama generation
  - OpenAI generation
- Safe RAG prompt that answers only from retrieved guideline chunks
- Notebooks for experimentation
- Dockerfile and docker-compose override

## Quick start

```bash
cd ai-worker
cp .env.example .env
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8090
```

If you use the default Ollama embeddings, pull the model before running ingestion or RAG:

```bash
ollama pull mxbai-embed-large:latest
```

If you switch `EMBEDDING_PROVIDER=sentence_transformers`, install the optional model stack separately:

```bash
pip install sentence-transformers
```

Run the worker loop:

```bash
python -m app.worker
```

Run tests:

```bash
pytest
```

## Docker

From the repo root:

```bash
docker compose -f backend/docker-compose.yml -f ai-worker/docker-compose.override.yml up --build
```

## Integration with Go backend

The Go backend creates rows in `ingestion_jobs` after a guideline PDF/Markdown upload or a
Markdown editor save.

The worker polls jobs with:

```sql
status = 'queued'
job_type IN ('pdf_ingestion', 'markdown_ingestion')
```

For each job, it:

1. Reads the immutable source key from the job payload and validates that it is still current.
2. Downloads the PDF or Markdown source from MinIO.
3. Extracts or parses text, hierarchy, typed blocks, HTML, and Markdown.
4. Stores HTML and Markdown back to MinIO
5. Inserts records into:
   - `guideline_sections`
   - `guideline_chunks`
   - `guideline_tables`
6. Updates `guideline_versions.html_file_key` and `markdown_file_key`
7. Marks the job as `completed`

Superseded Markdown jobs exit without overwriting a newer edit. Markdown-only guidelines have no
PDF page provenance; the worker records that limitation in extraction metadata and warnings.

## Recommended first production mode

For clinical safety, start with:

```env
EMBEDDING_PROVIDER=ollama
OLLAMA_EMBEDDING_MODEL=mxbai-embed-large:latest
EMBEDDING_DIM=1024
LLM_PROVIDER=ollama
OLLAMA_MODEL=qwen2.5:7b-instruct
```

For lightweight development without model downloads:

```env
EMBEDDING_PROVIDER=hash
EMBEDDING_DIM=1024
LLM_PROVIDER=extractive
```

## Important clinical safety rule

The RAG service should only answer from retrieved approved guideline chunks. If relevant context is not found, it returns an insufficient-evidence response instead of guessing.
