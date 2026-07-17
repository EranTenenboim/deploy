# Prism deploy

Runs both Prism solutions via Docker Compose (local) or Render free tier.

| Service | Local | Render |
|---------|-------|--------|
| Chief of Staff (Indeedee) | http://localhost:8787 | `prism-indeedee` |
| Oracle Property UI | http://localhost:3000 | `prism-oracle-ui` |
| Oracle Property MCP | http://localhost:8000/mcp | `prism-oracle-mcp` |

## Deploy on Render (free)

1. Open [Render Dashboard](https://dashboard.render.com) → **New** → **Blueprint**
2. Connect repo `EranTenenboim/deploy` (this repo)
3. Apply the Blueprint (`render.yaml`) — creates 3 free web services
4. For Oracle, set **PARQUET_URL** on `prism-oracle-ui` and `prism-oracle-mcp` to a public HTTPS URL of `properties.parquet`, then redeploy those two services

Free-tier notes: services sleep after ~15 minutes idle (cold start ~1 min); no persistent disks (demo DB/data reset on restart); 512 MB RAM each.

## Local Docker Compose

```bash
git clone --recurse-submodules https://github.com/EranTenenboim/deploy.git
cd deploy
cp .env.example .env
docker compose up --build
```

### Oracle dataset (local)

```bash
cd oracle-property-intelligence-platform-pipeline-completion
./scripts/run.sh setup
./scripts/run.sh pipeline
```

Or set `PARQUET_URL` / `PARQUET_S3_URI` in `.env`.
