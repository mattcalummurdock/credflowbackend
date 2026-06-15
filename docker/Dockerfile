# CredFlow backend — ML scoring API + agent scheduler for Cloud Run.
#
# Build (from repo root):
#   docker build -f docker/Dockerfile -t credflow-backend .
#
# Run locally:
#   docker run --rm -p 8080:8080 --env-file .env credflow-backend
#
# Deploy:
#   gcloud run deploy credflow-backend \
#     --source . \
#     --dockerfile docker/Dockerfile \
#     --port 8080 \
#     --memory 2Gi \
#     --cpu 2 \
#     --set-env-vars "FRONTEND_ORIGIN=https://your-frontend.example,RECLAIM_CALLBACK_URL=https://your-service-xyz.run.app/receive-proof"

FROM python:3.11-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PYTHONPATH=/app

WORKDIR /app

# torch-geometric needs a compiler; Node.js is required for Reclaim bank proofs.
RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential nodejs npm \
    && rm -rf /var/lib/apt/lists/*

COPY docker/requirements-backend.txt /tmp/requirements-backend.txt

# CPU-only PyTorch keeps the image smaller than the default CUDA wheels.
RUN pip install --upgrade pip \
    && pip install torch --index-url https://download.pytorch.org/whl/cpu \
    && pip install torch-geometric \
    && pip install -r /tmp/requirements-backend.txt \
    && apt-get purge -y build-essential \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/* /tmp/requirements-backend.txt

# Application code (includes committed XGBoost + sybil model artifacts under ml/).
COPY ml/ ml/
COPY agents/ agents/
COPY indexer/ indexer/
COPY layerzero/ layerzero/
COPY docs/addresses.json docs/addresses.json
COPY docs/spoke-arbitrum-addresses.json docs/spoke-arbitrum-addresses.json
COPY docs/spoke-base-addresses.json docs/spoke-base-addresses.json
COPY docs/abis/ docs/abis/

# Reclaim bank balance (ml/reclaim_service.py → scripts/reclaim_helper.js)
COPY docker/package-reclaim.json package.json
COPY scripts/reclaim_helper.js scripts/reclaim_helper.js
RUN npm install --omit=dev && npm cache clean --force

COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8080

# Cloud Run sets PORT=8080; entrypoint maps it to SCORING_API_PORT.
ENTRYPOINT ["/entrypoint.sh"]
