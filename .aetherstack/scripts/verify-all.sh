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
  for script in check-spring-ai-tools.ps1 check-spring-ai-rag.ps1 check-spring-ai-react-graph.ps1; do
    sp="$ROOT/.aetherstack/scripts/$script"
    if [ -f "$sp" ] && command -v pwsh >/dev/null 2>&1; then
      pwsh -NoProfile -ExecutionPolicy Bypass -File "$sp" || true
    fi
  done
else
  echo "[backend] skip (mvn missing or path not found)"
fi

HARNESS_JS="$FRONTEND/scripts/harness.mjs"
if command -v node >/dev/null 2>&1 && [ -f "$HARNESS_JS" ]; then
  echo "[frontend] harness lint"
  (cd "$FRONTEND" && node scripts/harness.mjs lint) || { echo "frontend harness lint failed"; exit 1; }
  echo "[frontend] harness build (max build + playwright e2e)"
  (cd "$FRONTEND" && node scripts/harness.mjs build) || { echo "frontend harness build failed"; exit 1; }
elif [ -d "$FRONTEND" ]; then
  echo "[frontend] skip (node or scripts/harness.mjs not found)"
fi

echo "verify completed"
