#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

resolve_repo() {
  local repo="$1"
  if command -v pwsh >/dev/null 2>&1; then
    pwsh -NoProfile -ExecutionPolicy Bypass -File "$ROOT/scripts/resolve-repos.ps1" -Repo "$repo"
    return
  fi
  if command -v powershell >/dev/null 2>&1; then
    powershell -NoProfile -ExecutionPolicy Bypass -File "$ROOT/scripts/resolve-repos.ps1" -Repo "$repo"
    return
  fi
  echo "resolve-repos.ps1 requires PowerShell (pwsh or powershell)" >&2
  exit 1
}

BACKEND="$(resolve_repo backend)"
FRONTEND="$(resolve_repo frontend)"

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
