.PHONY: sync-config verify verify-strict verify-ps completion-gate completion-gate-skip doctor dev docker-up codegraph-init codegraph-status help

help:
	@echo "AetherStack (governance repo - backend/frontend are external)"
	@echo "  make sync-config  - sync .aetherstack -> Cursor/Codex/Claude"
	@echo "  make doctor       - workflow health check (repos, CLI, optional smoke)"
	@echo "  make codegraph-init   - build CodeGraph indexes (governance + linked repos)"
	@echo "  make codegraph-status - show CodeGraph index status for all repos"
	@echo "  make verify       - test/lint in associated ai + ai_react repos"
	@echo "  make verify-strict - verify + Spring AI -Strict (completion-gate parity)"
	@echo "  make completion-gate CHANGE=<id> - unified pre-archive gate"
	@echo "  make completion-gate-skip CHANGE=<id> - gate without mvn/npm (CI smoke)"
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

verify-strict:
	powershell -ExecutionPolicy Bypass -File .aetherstack/scripts/verify-all.ps1 -SpringAiStrict

completion-gate:
ifndef CHANGE
	$(error Usage: make completion-gate CHANGE=<openspec-change-id>)
endif
	powershell -ExecutionPolicy Bypass -File .aetherstack/scripts/completion-gate.ps1 -Change "$(CHANGE)"

completion-gate-skip:
ifndef CHANGE
	$(error Usage: make completion-gate-skip CHANGE=<openspec-change-id>)
endif
	powershell -ExecutionPolicy Bypass -File .aetherstack/scripts/completion-gate.ps1 -Change "$(CHANGE)" -SkipVerify

doctor:
	powershell -ExecutionPolicy Bypass -File .aetherstack/scripts/doctor.ps1

dev:
	powershell -ExecutionPolicy Bypass -File scripts/dev.ps1

docker-up:
	powershell -ExecutionPolicy Bypass -File scripts/dev.ps1 -DockerOnly
