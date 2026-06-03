.PHONY: sync-config verify verify-ps completion-gate dev docker-up help

help:
	@echo "AetherStack (governance repo - backend/frontend are external)"
	@echo "  make sync-config  - sync .aetherstack -> Cursor/Codex/Claude"
	@echo "  make verify       - test/lint in associated ai + ai_react repos"
	@echo "  make completion-gate CHANGE=<id> - unified pre-archive gate"
	@echo "  make dev          - hint: start docker/backend/frontend in linked repos"
	@echo "  Repos: see LOCALPATH.md and docs/REPOS.md"

sync-config:
	powershell -ExecutionPolicy Bypass -File .aetherstack/scripts/sync-config.ps1

verify:
	powershell -ExecutionPolicy Bypass -File .aetherstack/scripts/verify-all.ps1

completion-gate:
ifndef CHANGE
	$(error Usage: make completion-gate CHANGE=<openspec-change-id>)
endif
	powershell -ExecutionPolicy Bypass -File .aetherstack/scripts/completion-gate.ps1 -Change "$(CHANGE)"

dev:
	powershell -ExecutionPolicy Bypass -File scripts/dev.ps1

docker-up:
	powershell -ExecutionPolicy Bypass -File scripts/dev.ps1 -DockerOnly
