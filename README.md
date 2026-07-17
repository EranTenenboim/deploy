# Prism deploy

Docker Compose stack that runs both Prism solutions on different ports.

| Service | URL |
|---------|-----|
| Chief of Staff (Indeedee) | http://localhost:8787 |
| Oracle Property UI | http://localhost:3000 |
| Oracle Property MCP | http://localhost:8000/mcp |

## Quick start

```bash
git clone --recurse-submodules git@github.com:EranTenenboim/deploy.git
cd deploy
cp .env.example .env
docker compose up --build
```

If you already cloned without submodules:

```bash
git submodule update --init --recursive
```

## Oracle dataset

Oracle UI/MCP need `oracle-property-intelligence-platform-pipeline-completion/data/properties.parquet`.

Either:

```bash
cd oracle-property-intelligence-platform-pipeline-completion
./scripts/run.sh setup
./scripts/run.sh pipeline
```

Or set `PARQUET_URL` / `PARQUET_S3_URI` in `.env`.

## Update solution code

```bash
git submodule update --remote --merge
docker compose up --build
```
