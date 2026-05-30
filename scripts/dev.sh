#!/usr/bin/env bash
# 一键开发辅助
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
docker compose up -d
echo "Backend:  cd backend && mvn spring-boot:run"
echo "Frontend: cd frontend && npm install && npm run dev"
echo "Governance (openspec/.aetherstack) works offline."
