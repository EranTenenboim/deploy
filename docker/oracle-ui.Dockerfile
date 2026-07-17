# Lean Oracle UI image for Render free tier (no AWS CLI).
FROM python:3.11-slim-bookworm

RUN apt-get update \
 && apt-get install -y --no-install-recommends curl \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY ui/ ui/
COPY manifest.json /app/manifest.json

RUN mkdir -p /app/data

ENV DATA_DIR=/app/data \
    PARQUET_PATH=/app/data/properties.parquet \
    RUN_SUMMARY_PATH=/app/data/run_summary.json \
    MANIFEST_PATH=/app/manifest.json

EXPOSE 10000

CMD ["gunicorn", "--bind", "0.0.0.0:10000", "--workers", "1", "--threads", "2", "ui.app:app"]
