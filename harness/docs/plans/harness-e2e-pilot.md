# Harness E2E 试跑：OpenSpec × Apply × Verify × Archive

> **试点变更**：`add-app-variables`（`simple-spec-driven`，`uiCraftMode: enabled`）  
> **目的**：证明 Cursor `/opsx-apply` + hev-* 三阶段 + `make verify` + completion-gate 可闭环。

## 前置条件

- [ ] obra Superpowers 已安装（`/add-plugin superpowers`）
- [ ] 关联仓路径正确：`LOCALPATH.md` / `make sync-config`
- [ ] ai 可 `mvn test`；ai_react 可 `node scripts/harness.mjs lint` 与 `build`
- [ ] 治理仓 `make verify` 通过（本文件创建后执行一次并记录下方表格）

## 阶段 A：OpenSpec 制品（变更目录就绪）

路径：`openspec/changes/add-app-variables/`

| 制品 | 状态 | 说明 |
|------|------|------|
| `.openspec.yaml` | ✅ | simple-spec-driven |
| `proposal.md` | ✅ | |
| `specs/aether-agent/app-variables/spec.md` | ✅ | 4 Requirements |
| `design-lite.md` | ✅ | 含 U1 界面清单 |
| `tasks.md` | ✅ | 5 组任务 + UI-CRAFT |
| `test-cases.md` | ⬜ 可选 | 测试同学提供；apply 不阻塞 |
| `verification-report.md` | ⬜ apply 后 | `/opsx-verify` |

**阶段 A 结论**：apply 准入已满足（`tasks` 就绪）。

## 阶段 B：Harness Apply（每 task 微循环）

对每个 `- [ ]` 实现类 task：

```text
### Harness Analyze（hev-analyzer）
### Harness Code（hev-coder）
### Harness Verify（hev-verifier）
```

| 变更范围 | Scoped Verify（最低） |
|----------|----------------------|
| 后端 Java | ai：`mvn -Dtest=XxxTest test` 或 `-pl <module>` |
| 前端 U1 | ai_react：`node scripts/harness.mjs lint` + `build`；Impeccable 标记 |
| 仅治理文档 | 跳过 mvn/npm；自检链接 |

参考：`.cursor/skills/harness-apply/SKILL.md`

## 阶段 C：会话完成门禁

按序执行并记录：

```powershell
# 1. Superpowers verification-before-completion
.aetherstack/scripts/record-completion-step.ps1 -Change add-app-variables -Step superpowersVerification -Status done

# 2. OpenSpec verify
# /opsx-verify → 保存 openspec/changes/add-app-variables/verification-report.md
.aetherstack/scripts/record-completion-step.ps1 -Change add-app-variables -Step openspecVerify -Status pass

# 3. Code review
.aetherstack/scripts/record-code-review.ps1 -Change add-app-variables -Scope backend -Status approved
.aetherstack/scripts/record-code-review.ps1 -Change add-app-variables -Scope frontend -Status approved

# 4. 统一门禁（含 make verify）
make completion-gate CHANGE=add-app-variables

# 5. 归档
# /opsx-archive
```

## 阶段 D：Harness 进度追踪

| Task | Analyze | Code | Verify | 备注 |
|------|---------|------|--------|------|
| （apply 开始后按 tasks.md 填写） | | | | |

## 验证记录

| 时间 | 命令 | 结果 | 执行人/会话 |
|------|------|------|-------------|
| 2026-06-29 | `verify-all.ps1` | ✅ 通过 | mvn test + harness lint + E2E 3/3；约 90s |
| | `make completion-gate CHANGE=add-app-variables` | | |

## 完成标准（勾选 PLANS.md）

- [ ] 全部 tasks `[x]`
- [ ] `make verify` 通过（含 frontend harness build E2E）
- [ ] `.completion-gate.json` overall = `ready` 或 `ready_with_warnings`
- [ ] 变更已移入 `openspec/changes/archive/`

## 备选试点

若 `add-app-variables` 范围过大，可改用更小 `bugfix-spec-driven` 变更，复制本文件并替换变更 ID。
