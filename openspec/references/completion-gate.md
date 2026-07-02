# 完成门禁（Completion Gate）

统一 OpenSpec verify、Harness `make verify`、追溯、UI-Craft、Code Review、Superpowers 完成前验证。

配置：`.aetherstack/context/completion-gate.yaml`

## 推荐流程

```text
/opsx-apply（全部 tasks [x]）
  → Superpowers verification-before-completion
  → record-completion-step.ps1 -Change <id> -Step superpowersVerification -Status done
/opsx-verify → 保存 openspec/changes/<id>/verification-report.md
  → record-completion-step.ps1 -Change <id> -Step openspecVerify -Status pass
cr backend | cr frontend
  → record-code-review.ps1 -Change <id> -Scope backend -Status approved [-PrUrl ...]
make completion-gate CHANGE=<id>
/opsx-archive
```

## 命令

```powershell
# 全量检查（含 make verify）并写入 .completion-gate.json
make completion-gate CHANGE=my-change

# 跳过关联仓构建（仅本地调试，不可用于归档）
powershell -File .aetherstack/scripts/completion-gate.ps1 -Change my-change -SkipVerify

# 仅读取已有 gate 文件（shell hook 用）
powershell -File .aetherstack/scripts/completion-gate.ps1 -Change my-change -CheckOnly

# 有 WARNING 时强制归档
powershell -File .aetherstack/scripts/completion-gate.ps1 -Change my-change -AllowWarnings
```

## 记录脚本

```powershell
.aetherstack/scripts/record-code-review.ps1 -Change my-change -Scope backend -Status approved -PrUrl "https://..."
.aetherstack/scripts/record-completion-step.ps1 -Change my-change -Step superpowersVerification -Status done
.aetherstack/scripts/record-completion-step.ps1 -Change my-change -Step openspecVerify -Status pass -ReportPath verification-report.md
```

`check-superpowers-steps.ps1` 会在 `make completion-gate` 时校验：已记录 superpowersVerification、`verification-report.md` 含 Final Assessment；AI-TDD 变更另检查报告是否提及 TDD 覆盖。

## verification-report.md

`/opsx-verify` 产出须落在变更目录，且 **Final Assessment** 含：

- `All checks passed. Ready for archive.` 或
- `Ready for archive (with noted improvements).`

## 与 Cursor Hooks

- `beforeSubmitPrompt`：归档/设计审查提醒
- `beforeShellExecution`：无 gate 时阻断 `mv` 到 `changes/archive`

## CI

治理仓 PR 可触发 `.github/workflows/completion-gate.yml`（默认 `-SkipVerify`；自托管 runner 检出 ai/ai_react 后可跑全量 verify）。开关：`COMPLETION_GATE_ENABLED=false`。
