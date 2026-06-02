---
name: harness-apply
description: OpenSpec apply 阶段的 Harness 三 Agent 接线。/opsx-apply 或 openspec-apply-change 执行实现任务时 MUST 读取并遵循。
---

# Harness Apply 接线（OpenSpec × Harness）

将 Harness **分析 → 编码 → 验证** 小循环嵌入 OpenSpec `tasks.md` 的逐项 apply，使每次实现任务可感知 hev-* 阶段。

## 何时触发

- 用户 `/opsx-apply`、`/opsx:apply` 或 openspec-apply-change skill
- 任何「按 OpenSpec tasks 实现代码」的会话

## 前置（会话级，一次）

1. 读 `LOCALPATH.md` → 解析 **ai**（backend）、**ai_react**（frontend）路径
2. 读 `harness/harness.config.yaml` → `verify.loop_max`（默认 3）、`adapter`
3. 读 OpenSpec apply 上下文（proposal / spec / design / tasks；standard 模式含 design-review）
4. 读 `.openspec.yaml` → `aiTddMode`、`uiCraftMode`

## 单任务微循环（每个 `- [ ]` 实现类任务）

对 **涉及代码/配置/单测** 的任务，**必须**按序执行并 **在回复中显式输出** 三阶段标题（用户应能「看到 Harness」）：

### 1. Harness Analyze（hev-analyzer）

- **必读** `harness/agents/hev-analyzer.md`（接口验证与依赖链路章节）
- 从当前 task + 对应 spec Requirement + design 章节提取：
  - 影响仓库（ai / ai_react / 治理仓）
  - 待改文件/类/接口清单
  - **Grep/Read 验证** design 中引用的类、方法、路径是否存在
- 输出块（固定格式）：

```markdown
### Harness Analyze（hev-analyzer）
- Task：…
- Requirement：REQ-x / TC-REQx-yy（如有）
- 影响范围：backend | frontend | governance
- 验证过的入口：…
- 风险/阻塞：无 | …
```

**可跳过深度 Analyze**：纯文档勾选、仅改 AetherStack 治理层 markdown 且无代码影响。

### 2. Harness Code（hev-coder）

- **必读** `harness/agents/hev-coder.md`（分层与变更范围）
- 在 **正确仓库** 实现；变更范围对齐 Analyze 清单
- OpenSpec 约束仍优先：AI-TDD 先测后码、UI-Craft 走 Impeccable、禁止扩大 scope
- `AUTO-UT` / `AUTO-AI-UT`：invoke Superpowers `test-driven-development` + 对应 harness 测试模板

### 3. Harness Verify（hev-verifier）

- **必读** `harness/agents/hev-verifier.md` + 对应 adapter：
  - 后端：`harness/adapters/java-maven/verify-commands.md`
  - 前端：`harness/adapters/frontend-npm/verify-commands.md`（若存在）
- **按变更范围执行 scoped 验证**（前一步失败不继续）：

| 变更 | 最低验证 |
|------|----------|
| 后端 Java / 单测 | 在 **ai** 仓库：`mvn -Dtest=XxxTest test`（有 AUTO-UT/AUTO-AI-UT 时）或 `mvn -B -q test -pl <module>` |
| 前端 UI/逻辑 | 在 **ai_react**：`npm run lint`；涉及构建时加 `npm run build` |
| 仅治理仓文档 | 跳过 mvn/npm；自检链接与路径 |

- 失败时按 `hev-verifier` 修复，重试 ≤ `verify.loop_max`（默认 3）
- 输出块：

```markdown
### Harness Verify（hev-verifier）
- 命令：…
- 结果：通过 | 失败（第 n/3 轮）
```

**仅在三步 Verify 通过（或该任务类型允许跳过）后**，将 tasks.md 中 `- [ ]` 改为 `- [x]`。

## 会话完成门禁（全部任务或用户暂停前）

1. 在 AetherStack 治理仓运行 **`make verify`**（或 `.aetherstack/scripts/verify-all.ps1`）
2. invoke Superpowers **`verification-before-completion`**
3. 可选：在 `harness/docs/PLANS.md` 或 `harness/docs/plans/<change-id>.md` 记录本次 apply 进度

**不得**在未跑 `make verify` 的情况下声称「Implementation Complete」。

## 与 OpenSpec apply 输出格式

每个任务会话内嵌 Harness 阶段：

```text
## Implementing: <change> — Task 3/7: <描述>

### Harness Analyze（hev-analyzer）
…

### Harness Code（hev-coder）
…

### Harness Verify（hev-verifier）
…

✓ Task 3 complete
```

全部完成后：

```text
## Implementation Complete
…
### Harness Session Verify
- make verify：通过 | 失败
```

## 禁止

- 跳过 Analyze 直接改代码（实现类任务）
- 未 scoped verify 就勾选 task
- 在 **ai** 仓库改代码却只在治理仓跑验证
- 用「应该能通过」代替实际命令输出
