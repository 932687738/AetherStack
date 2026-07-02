# Phase 3 — CI / Superpowers 门禁硬化

> Harness + OpenSpec + Superpowers 集成 Phase 3。Phase 1–2 见 [PLANS.md](../PLANS.md)。

## 目标

| 项 | 状态 |
|----|------|
| `check-superpowers-steps.ps1` 接入 `completion-gate.ps1` | ✅ |
| `completion-gate.yml` PR / workflow_dispatch | ✅ |
| 修复 CI「full」仍 `-SkipVerify` 的逻辑 bug | ✅ |
| 关联仓探测 `check-linked-repos.ps1` | ✅ |
| CI 可选 clone 关联仓 `setup-linked-repos-ci.ps1` | ✅ |
| 全量 verify 工作流 `verify-linked.yml` | ✅ |
| `make verify-strict` / `completion-gate-skip` | ✅ |
| 自托管 runner 全量 verify（需仓库 Variables） | 📋 运维配置 |

## 本地命令

```powershell
make doctor
make verify
make verify-strict          # 与 completion-gate 内 verify 一致（含 Spring AI -Strict）
make completion-gate CHANGE=<id>
make completion-gate-skip CHANGE=<id>   # 等同 CI 默认 smoke
```

## GitHub Actions

| Workflow | 用途 |
|----------|------|
| `completion-gate.yml` | OpenSpec 变更 PR 门禁；默认 SkipVerify |
| `verify-linked.yml` | 手动/定时全量 `verify-all`（需关联仓） |

### 仓库 Variables（Settings → Actions → Variables）

| 变量 | 说明 |
|------|------|
| `COMPLETION_GATE_ENABLED` | `false` 关闭 completion-gate |
| `COMPLETION_GATE_FULL_VERIFY` | `true` 且关联仓可用时跑全量 verify |
| `VERIFY_LINKED_ENABLED` | `false` 关闭 verify-linked 定时任务 |
| `CHECKOUT_LINKED_REPOS` | `true` 在 CI 中 clone 关联仓到 `.linked/` |
| `AETHER_AI_REPOSITORY` | 如 `org/ai` |
| `AETHER_FRONTEND_REPOSITORY` | 如 `org/ai_react` |
| `AETHER_LINKED_REF` | clone 分支，默认 `main` |
| `AETHER_SELF_HOSTED` | `true` 时使用 `runs-on: self-hosted` |

### Secrets

| Secret | 说明 |
|--------|------|
| `GH_PAT` | 跨仓 clone 私有 repo（可选；公开仓可用 `GITHUB_TOKEN`） |

### 自托管 Runner（推荐全量 verify）

Runner 机器上已 checkout `ai` / `ai_react` 时，设置环境变量或 `repos.yaml` 路径即可，无需 clone：

```text
AETHER_BACKEND_REPO=D:/cache/workspace/ai
AETHER_FRONTEND_REPO=D:/cache/workspace/ai_react
AETHER_SELF_HOSTED=true
COMPLETION_GATE_FULL_VERIFY=true
```

## Superpowers 记录

归档前须：

```powershell
# apply 结束后 invoke verification-before-completion，然后：
.aetherstack/scripts/record-completion-step.ps1 -Change <id> -Step superpowersVerification -Status done
/opsx-verify
.aetherstack/scripts/record-completion-step.ps1 -Change <id> -Step openspecVerify -Status pass -ReportPath verification-report.md
make completion-gate CHANGE=<id>
```

`check-superpowers-steps.ps1` 会校验 `superpowersVerification=done` 与 `verification-report.md` 结构。

## Phase 4 — 明确不做（2026-07-02）

以下能力 **不在路线内**；OpenSpec apply 继续 **Mode B**（主 Agent 兼岗 hev-*），跨仓 PR 由人工 `record-code-review.ps1` + 各仓 CI 保障：

- ~~跨仓 PR 与 OpenSpec change 自动绑定~~
- ~~Mode A spawn hev-* 子 Agent~~
