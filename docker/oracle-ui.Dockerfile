# Lean Oracle UI image for Render free tier — ships with a demo parquet.
FROM python:3.11-slim-bookworm

RUN apt-get update \
 && apt-get install -y --no-install-recommends curl \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY oracle-property-intelligence-platform-pipeline-completion/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY oracle-property-intelligence-platform-pipeline-completion/ui/ ui/
COPY oracle-property-intelligence-platform-pipeline-completion/pipeline/ pipeline/
COPY oracle-property-intelligence-platform-pipeline-completion/config/ config/
COPY oracle-property-intelligence-platform-pipeline-completion/manifest.json /app/manifest.json
COPY docker/build_demo_parquet.py /tmp/build_demo_parquet.py

# Make "Load dataset" rebuild the lightweight demo sample on free tier.
RUN python - <<'PY'
from pathlib import Path
path = Path("ui/app.py")
text = path.read_text()
old = """        result = subprocess.run(
            [sys.executable, "-m", "pipeline.run"],
            cwd=PROJECT_ROOT,
            check=True,
            capture_output=True,
            text=True,
            timeout=3600,
        )"""
new = """        if os.environ.get("ORACLE_DEMO_MODE", "").lower() in ("1", "true", "yes"):
            result = subprocess.run(
                [sys.executable, "/tmp/build_demo_parquet.py", "--out", str(DATA_DIR), "--rows", "600"],
                check=True,
                capture_output=True,
                text=True,
                timeout=120,
            )
        else:
            result = subprocess.run(
                [sys.executable, "-m", "pipeline.run"],
                cwd=PROJECT_ROOT,
                check=True,
                capture_output=True,
                text=True,
                timeout=3600,
            )"""
if old not in text:
    raise SystemExit("failed to patch ui/app.py for ORACLE_DEMO_MODE")
path.write_text(text.replace(old, new, 1))
PY

RUN mkdir -p /app/data \
 && python /tmp/build_demo_parquet.py --out /app/data --rows 600 \
 && printf '%s\n' \
  '#!/bin/sh' \
  'set -eu' \
  'mkdir -p /app/data' \
  'if [ -n "${PARQUET_URL:-}" ]; then' \
  '  curl -fsSL "$PARQUET_URL" -o /app/data/properties.parquet || true' \
  'fi' \
  'if [ ! -f /app/data/properties.parquet ]; then' \
  '  python /tmp/build_demo_parquet.py --out /app/data --rows 600' \
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
    PYTHONPATH=/app \
    ORACLE_DEMO_MODE=1

EXPOSE 10000

CMD ["/app/entrypoint.sh"]
