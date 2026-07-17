# Lean Oracle UI image for Render free tier (no AWS CLI).
FROM python:3.11-slim-bookworm

RUN apt-get update \
 && apt-get install -y --no-install-recommends curl \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY ui/ ui/
COPY pipeline/ pipeline/
COPY config/ config/
COPY manifest.json /app/manifest.json

RUN mkdir -p /app/data \
 && printf '%s\n' \
  '#!/bin/sh' \
  'set -eu' \
  'mkdir -p /app/data' \
  'if [ -n "${PARQUET_URL:-}" ]; then' \
  '  curl -fsSL "$PARQUET_URL" -o /app/data/properties.parquet || true' \
  'fi' \
  'export UI_BASE_URL="${UI_BASE_URL:-${RENDER_EXTERNAL_URL:-http://localhost:10000}}"' \
  'if [ -n "${MCP_ORIGIN:-}" ]; then' \
  '  export MCP_BASE_URL="${MCP_ORIGIN%/}/mcp"' \
  'fi' \
  'export PYTHONPATH=/app' \
  'exec gunicorn --bind 0.0.0.0:${PORT:-10000} --workers 1 --threads 2 ui.app:app' \
  > /app/entrypoint.sh \
 && chmod +x /app/entrypoint.sh

ENV DATA_DIR=/app/data \
    PARQUET_PATH=/app/data/properties.parquet \
    RUN_SUMMARY_PATH=/app/data/run_summary.json \
    MANIFEST_PATH=/app/manifest.json \
    PYTHONPATH=/app

EXPOSE 10000

CMD ["/app/entrypoint.sh"]
