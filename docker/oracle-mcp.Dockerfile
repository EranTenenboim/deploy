# Lean MCP image for Render free tier — ships with a demo parquet.
FROM node:22-bookworm-slim AS nodebase

RUN apt-get update \
 && apt-get install -y --no-install-recommends git ca-certificates curl \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY oracle-property-intelligence-platform-pipeline-completion/mcp/package.json \
     oracle-property-intelligence-platform-pipeline-completion/mcp/start.mjs ./
RUN npm install --omit=dev

FROM python:3.11-slim-bookworm AS demodata
RUN pip install --no-cache-dir duckdb pyarrow
COPY docker/build_demo_parquet.py /tmp/build_demo_parquet.py
RUN mkdir -p /data && python /tmp/build_demo_parquet.py --out /data --rows 600

FROM nodebase
COPY --from=demodata /data/properties.parquet /app/data/properties.parquet
COPY --from=demodata /data/run_summary.json /app/data/run_summary.json

RUN printf '%s\n' \
  '#!/bin/sh' \
  'set -eu' \
  'mkdir -p /app/data' \
  'if [ -n "${PARQUET_URL:-}" ]; then' \
  '  curl -fsSL "$PARQUET_URL" -o /app/data/properties.parquet || true' \
  'fi' \
  'exec node start.mjs' \
  > /app/entrypoint.sh \
 && chmod +x /app/entrypoint.sh

ENV DATA_DIR=/app/data \
    PARQUET_PATH=/app/data/properties.parquet \
    COUNTY=santa-clara

EXPOSE 10000

CMD ["/app/entrypoint.sh"]
