# Harness 使用指南

Harness 是 **AI 驱动开发操作系统**（项目内 vendoring），与 GitHub Actions CI 互补。

## 1. 核心文件

| 路径 | 说明 |
|------|------|
| `harness/harness.config.yaml` | 验证命令、Agent、文档路径 |
| `harness/agents/hev-analyzer.md` | 技术分析 |
| `harness/agents/hev-coder.md` | 编码实现 |
| `harness/agents/hev-verifier.md` | 验证修复 |
| `harness/adapters/java-maven/verify-commands.md` | 后端 scoped 验证 |
| `harness/adapters/frontend-npm/verify-commands.md` | 前端 scoped 验证 |
| `harness/references/phases/` | 六阶段细则 |
| `harness/docs/PLANS.md` | 当前计划 |
| `harness/docs/plans/` | 变更级子计划（含 E2E 试跑） |
| `.cursor/skills/harness-apply/SKILL.md` | `/opsx-apply` 三 Agent 接线 |

## 2. 六阶段

```mermaid
flowchart LR
    P1[1 索引] --> P2[2 计划]
    P2 --> P3[3 执行]
    P3 --> P4[4 验证]
    P4 --> P5[5 完成]
    P5 --> P6[6 归档]
```

| 阶段 | 读什么 | 产出 |
|------|--------|------|
| 索引 | CLAUDE.md、AGENTS.md、harness.config | 上下文就绪 |
| 计划 | openspec tasks、PLANS.md、`plans/<change-id>.md` | 子计划 |
| 执行 | hev-coder | 代码变更 |
| 验证 | hev-verifier、make verify | 测试通过 |
| 完成 | 文档更新 | 摘要 |
| 归档 | docs/archive/ | 历史留存 |

## 3. 验证命令（与 CI 一致）

关联仓库路径由 `.aetherstack/context/repos.yaml` 解析（见 `LOCALPATH.md`）。

```yaml
# harness/harness.config.yaml（逻辑步骤；本地一键仍走 verify-all）
verify:
  loop_max: 3
  adapters:
    backend: java-maven
    frontend: frontend-npm
  steps:
    - name: full-verify
      command: "powershell -ExecutionPolicy Bypass -File .aetherstack/scripts/verify-all.ps1"
    - name: backend-test
      repo: backend
      command: "mvn -B -q test"
    - name: frontend-lint
      repo: frontend
      command: "node scripts/harness.mjs lint"
    - name: frontend-build-e2e
      repo: frontend
      command: "node scripts/harness.mjs build"
```

**本地一键**（治理仓根目录）：

```powershell
make verify
```

等价于在 **ai** 跑 `mvn test` + Spring AI 检查，在 **ai_react** 跑 `harness lint` + `harness build`（含 Playwright E2E）。

**Apply 内 scoped 验证**：见 `harness-apply/SKILL.md` 与双适配器 `verify-commands.md`；单 task 可只跑相关模块测试，会话结束前仍须 `make verify`。

## 4. Claude Code / Cursor 示例

```
1. 读 CLAUDE.md → AGENTS.md → harness/harness.config.yaml
2. 读 openspec/changes/xxx/tasks.md
3. /opsx-apply → 读 harness-apply/SKILL.md
4. 每 task：hev-analyzer → hev-coder → hev-verifier（显式输出三阶段）
5. 全部完成：make verify + verification-before-completion
6. 更新 harness/docs/plans/<change-id>.md
```

**首个 E2E 试跑清单**：`harness/docs/plans/harness-e2e-pilot.md`（试点变更 `add-app-variables`）。

## 5. 与 OpenSpec 协作

- OpenSpec 提供 **tasks.md**（做什么）
- Harness 提供 **怎么做 + 怎么验**
- apply 阶段：**必读** `.cursor/skills/harness-apply/SKILL.md`；每 task 走 hev-analyzer → hev-coder → hev-verifier；结束前 `make verify`

### Apply 时你会看到的输出

```text
### Harness Analyze（hev-analyzer）
### Harness Code（hev-coder）
### Harness Verify（hev-verifier）
```

## 6. 适配器

| 适配器 | 路径 | verify 文档 |
|--------|------|-------------|
| Java/Maven | `harness/adapters/java-maven/` | `verify-commands.md` |
| Frontend/npm | `harness/adapters/frontend-npm/` | `verify-commands.md` |

前端 Harness CLI 实现在关联仓 **ai_react**：`scripts/harness.mjs`（`install` / `dev` / `lint` / `build`）。
