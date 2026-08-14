# syntax=docker/dockerfile:1.7

FROM python:3.12.12-slim-bookworm AS build

ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=0 \
    PIP_DEFAULT_TIMEOUT=300 \
    PIP_RETRIES=10 \
    PIP_RESUME_RETRIES=10

WORKDIR /build

COPY requirements.txt .

RUN python -m venv /opt/venv && \
    /opt/venv/bin/python -m pip install --upgrade pip setuptools wheel

RUN --mount=type=cache,target=/root/.cache/pip \
    /opt/venv/bin/pip install \
    --retries 10 \
    --timeout 300 \
    --resume-retries 10 \
    -r requirements.txt

FROM python:3.12.12-slim-bookworm AS production

ARG BUILD_VERSION=development
ARG BUILD_REVISION=unknown

ENV BUILD_VERSION=${BUILD_VERSION} \
    BUILD_REVISION=${BUILD_REVISION} \
    PATH=/opt/venv/bin:${PATH}

LABEL org.opencontainers.image.title="MediGuide AI Worker" \
      org.opencontainers.image.version="${BUILD_VERSION}" \
      org.opencontainers.image.revision="${BUILD_REVISION}"

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    HOME=/home/mediguide

WORKDIR /app

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    tesseract-ocr \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --system --gid 10001 mediguide \
    && useradd --system --uid 10001 --gid mediguide --home-dir /home/mediguide --create-home mediguide

COPY --from=build /opt/venv /opt/venv
COPY --chown=mediguide:mediguide app ./app
COPY --chown=mediguide:mediguide mediguide ./mediguide

USER 10001:10001
EXPOSE 8090
EXPOSE 50051

HEALTHCHECK --interval=10s --timeout=5s --start-period=15s --retries=6 \
  CMD curl --fail --silent http://127.0.0.1:8090/readyz >/dev/null || exit 1

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8090"]
