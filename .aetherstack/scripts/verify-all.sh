#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BACKEND="${AETHER_BACKEND_REPO:-D:/cache/workspace/ai}"
FRONTEND="${AETHER_FRONTEND_REPO:-D:/cache/workspace/ai_react}"

echo "=== AetherStack verify (associated repos) ==="
echo "backend:  $BACKEND"
echo "frontend: $FRONTEND"

if command -v mvn >/dev/null 2>&1 && [ -d "$BACKEND" ]; then
  echo "[backend] mvn test"
  (cd "$BACKEND" && mvn -B -q test) || { echo "backend test failed"; exit 1; }
else
  echo "[backend] skip (mvn missing or path not found)"
fi

if command -v npm >/dev/null 2>&1 && [ -d "$FRONTEND" ]; then
  echo "[frontend] npm run lint && npm run build"
  (cd "$FRONTEND" && npm run lint && npm run build) || { echo "frontend verify failed"; exit 1; }
else
  echo "[frontend] skip (npm missing or path not found)"
fi

echo "verify completed"
