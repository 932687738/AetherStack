.PHONY: sync-config verify verify-ps completion-gate doctor dev docker-up codegraph-init codegraph-status help

help:
	@echo "AetherStack (governance repo - backend/frontend are external)"
	@echo "  make sync-config  - sync .aetherstack -> Cursor/Codex/Claude"
	@echo "  make doctor       - workflow health check (repos, CLI, optional smoke)"
	@echo "  make codegraph-init   - build CodeGraph indexes (governance + linked repos)"
	@echo "  make codegraph-status - show CodeGraph index status for all repos"
	@echo "  make verify       - test/lint in associated ai + ai_react repos"
	@echo "  make completion-gate CHANGE=<id> - unified pre-archive gate"
	@echo "  make dev          - hint: start docker/backend/frontend in linked repos"
	@echo "  Repos: edit .aetherstack/context/repos.yaml then make sync-config"

sync-config:
	powershell -ExecutionPolicy Bypass -File .aetherstack/scripts/sync-config.ps1

codegraph-init:
	powershell -ExecutionPolicy Bypass -File .aetherstack/scripts/codegraph-init.ps1

codegraph-status:
	powershell -ExecutionPolicy Bypass -File .aetherstack/scripts/codegraph-init.ps1 -StatusOnly

verify:
	powershell -ExecutionPolicy Bypass -File .aetherstack/scripts/verify-all.ps1

completion-gate:
ifndef CHANGE
	$(error Usage: make completion-gate CHANGE=<openspec-change-id>)
endif
	powershell -ExecutionPolicy Bypass -File .aetherstack/scripts/completion-gate.ps1 -Change "$(CHANGE)"

doctor:
	powershell -ExecutionPolicy Bypass -File .aetherstack/scripts/doctor.ps1

dev:
	powershell -ExecutionPolicy Bypass -File scripts/dev.ps1

docker-up:
	powershell -ExecutionPolicy Bypass -File scripts/dev.ps1 -DockerOnly
