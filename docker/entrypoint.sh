#!/bin/sh
set -eu

# Cloud Run injects PORT; scoring_api reads SCORING_API_PORT.
export SCORING_API_PORT="${PORT:-${SCORING_API_PORT:-8080}}"
export SCORING_API_HOST="${SCORING_API_HOST:-0.0.0.0}"
export PYTHONUNBUFFERED=1

echo "Starting agent scheduler (background)…"
python -m agents.scheduler &
agent_pid=$!

echo "Starting ML scoring API on ${SCORING_API_HOST}:${SCORING_API_PORT}…"
python -m ml.scoring_api &
api_pid=$!

term_handler() {
  echo "Shutting down…"
  kill -TERM "$api_pid" "$agent_pid" 2>/dev/null || true
  wait "$api_pid" "$agent_pid" 2>/dev/null || true
}

trap term_handler TERM INT

# Cloud Run health checks hit the ML API; exit if it stops.
wait "$api_pid"
exit_code=$?
kill -TERM "$agent_pid" 2>/dev/null || true
wait "$agent_pid" 2>/dev/null || true
exit "$exit_code"
