#!/usr/bin/env bash
# AUTO-GENERATED wrapper — delegates to PowerShell on Windows, bash fallback on Unix
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

if command -v powershell.exe >/dev/null 2>&1; then
  powershell.exe -ExecutionPolicy Bypass -File "$ROOT/.aetherstack/scripts/sync-config.ps1" "$@"
  exit $?
fi

BANNER="<!-- AUTO-GENERATED — edit .aetherstack/ then make sync-config -->"
mkdir -p .cursor/rules .codex .claude

cat .aetherstack/rules/core.md > /tmp/aether-core.md
{
  echo "$BANNER"
  echo "# AetherStack — Cursor Rules"
  cat /tmp/aether-core.md
  echo ""
  echo "See AGENTS.md and .aetherstack/rules/"
} > .cursorrules

for f in .aetherstack/rules/*.md; do
  base=$(basename "$f" .md)
  {
    echo "---"
    echo "description: AetherStack ${base} rules"
    echo "alwaysApply: true"
    echo "---"
    cat "$f"
  } > ".cursor/rules/aether-${base}.mdc"
done

cp AGENTS.md .codex/AGENTS.md
echo "sync-config (bash fallback) completed"
