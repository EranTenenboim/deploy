# Lean MCP image for Render free tier (no AWS CLI).
FROM node:22-bookworm-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends git ca-certificates curl \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY mcp/package.json mcp/start.mjs ./
RUN npm install --omit=dev

RUN mkdir -p /app/data \
 && printf '%s\n' \
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
