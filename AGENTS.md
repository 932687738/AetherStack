# AetherStack AI 入口（OpenSpec 1.x）

## 配置源

**单一配置源**：`.aetherstack/`。修改规则后运行 `make sync-config`。

## 规范层次（落地顺序）

| 层级 | 路径 | 职责 |
|------|------|------|
| Cursor 规则（AI 编码） | `.aetherstack/rules/` → sync 至 `.cursor/rules/` | 精简约束；铁三角（multi-agent + rag + react-graph）与 core/backend-ai 同时生效 |
| OpenSpec 参考（design/tasks） | `openspec/references/*-standards.md` | 完整细则、design 必填项、验收口径 |
| 工程基线 | `engineering-standards.md`、`backend-design-guide.md` | 分层矩阵、存量债务、演进路线 |
| 冲突解决 | — | 同题多规范冲突时取**更严格、更安全**条款；以 `aether-rules.md` §5.11 铁三角清单为 design 自检 |

## AI 工作流（obra Superpowers）

通用工作流（TDD、代码审查、brainstorming、调试等）由 **obra Superpowers** Cursor 插件提供：

```text
/add-plugin superpowers
```

项目约束（多仓库、DDD、Harness）见 `.aetherstack/rules/superpowers.md`（随 sync-config 加载）。

## 需求交付规范（默认强制）

**所有功能/缺陷类需求**默认走完整交付链，见 `.aetherstack/rules/delivery-workflow.md`：

1. **OpenSpec**（0.1 → artifacts → `openspec/changes/`）
2. **Superpowers**（计划、TDD、验证、CR）
3. **UI-Craft / Impeccable**（`uiCraftMode` 命中时的 U1 界面）

口头需求也先建 OpenSpec 变更目录；仅探索讨论可跳过。

## 强制入口校验（仅 OpenSpec 流程必做）

当且仅当用户明确要走 **OpenSpec 流程**（创建/继续变更、生成 proposal/spec/design/tasks、调用 opsx-* 或 OpenSpec 技能）时，才需要按 `openspec/references/aether-rules.md` **0.1 前置检查** 逐项执行：

1. 工单链接（**可选**，允许「无工单」）
2. 选择 schema（standard / simple / bugfix）
3. 需求材料（**必填**）
4. **AI-TDD 模式**（AI 相关变更必选其一；非 AI 可答 `disabled`）：`enabled` / `disabled` / `auto`（默认），写入变更 `.openspec.yaml` 的 `aiTddMode`
5. **UI-Craft 模式**（前端可见 UI 变更必选其一；纯 API 可答 `disabled`）：`enabled` / `disabled` / `auto`（默认），写入 `.openspec.yaml` 的 `uiCraftMode`

未完成第 2、3 步，**不得**进入 OpenSpec artifact、不得创建变更目录。

若用户请求为普通问答/方案讨论/非 OpenSpec 文档编辑，则无需触发 0.1。**探索阶段不触发 0.1，且禁止调用 OpenSpec 相关技能**。

## OpenSpec 核心路径

- 工作流 schema：
  - `openspec/schemas/standard-spec-driven/schema.yaml`（复杂需求）
  - `openspec/schemas/simple-spec-driven/schema.yaml`（小需求）
  - `openspec/schemas/bugfix-spec-driven/schema.yaml`（缺陷修复）
- 项目配置：`openspec/config.yaml`
- 项目规则：`openspec/references/aether-rules.md`
- 目录示例：`openspec/references/directory-examples.md`
- 接口契约：`openspec/references/integration-contracts.md`
- **必须先读**：`LOCALPATH.md`（关联仓库与治理层路径）

变更生命周期：`openspec/changes/` → 归档 → `openspec/specs/`

Cursor 命令：`.cursor/commands/opsx-*.md`  
Cursor Skills：`.cursor/skills/openspec-*/SKILL.md`

## 关键词速查

| 关键词 | obra 插件 skill | AetherStack 规则 |
|--------|-----------------|------------------|
| cr / code review / 代码审查 | `requesting-code-review` | `rules/superpowers.md` |
| `cr backend` / `cr frontend` | 同上 | `LOCALPATH.md` |
| 单测 / unit test / AUTO-UT | `test-driven-development` | `rules/superpowers.md` |
| AI-TDD / `/tdd` / AI 核心模块 | `test-driven-development` | `rules/ai-tdd.md`、`openspec/references/ai-tdd-standards.md` |
| Spring AI / ChatClient / Prompt / 模型配置 | — | `rules/spring-ai-core.md`、`openspec/references/spring-ai-core-standards.md` |
| 多 Agent / `@Tool` / RouterAgent | — | `rules/spring-ai-multi-agent.md`、`openspec/references/spring-ai-multi-agent-standards.md` |
| 知识库 / RAG / 向量检索 / 文档入库 | — | `rules/spring-ai-rag.md`、`openspec/references/spring-ai-rag-standards.md` |
| ReactAgent / CompiledGraph / StateGraph | — | `rules/spring-ai-react-graph.md`、`openspec/references/spring-ai-react-graph-standards.md` |
| UI-Craft / `/impeccable` / 前端 UI 改版 | Impeccable skill | `rules/ui-craft.md`、`openspec/references/ui-craft-standards.md` |
| design-review / 设计审查（standard 模式） | `brainstorming` | `rules/openspec.md`、`aether-rules.md` §5.12 |
| `/opsx-apply` / OpenSpec 实现 | **harness-apply** + hev-* | `.cursor/skills/harness-apply/SKILL.md` |
| 归档前门禁 | `make completion-gate` + `/opsx-verify` | `openspec/references/completion-gate.md` |
| 计划 skill 路由 | 有 tasks 用 `/opsx-apply` | `workflow-planning-routing.md` |
| 提交型 DDD 设计 | — | `rules/ddd-commit-design.md` |
| 更新文档 / 同步 changelog | — | `rules/documentation.md` |

## Harness

- 配置：`harness/harness.config.yaml`（项目内 vendoring）
- Agent：`harness/agents/hev-analyzer.md`、`hev-coder.md`、`hev-verifier.md`
- 本地验证：`make verify`

## 启动边界

- **治理层**（openspec、.aetherstack、harness/docs、根文档）：**离线可用**
- **关联仓库 ai / ai_react**：开发时**必须**在各自仓库路径启动（见 `LOCALPATH.md`）

## 工程参考

- 架构：`ARCHITECTURE.md`、`openspec/references/architecture.md`
- **后端设计指南（现状/目标/演进）**：`openspec/references/backend-design-guide.md`
- 工程规范：`openspec/references/engineering-standards.md`
- 技术栈：`openspec/references/tech-stack.md`
- 领域模型：`openspec/references/domain-models.md`
- **AI 阶段化 TDD**：`openspec/references/ai-tdd-standards.md`、`.aetherstack/rules/ai-tdd.md`
- **Spring AI 核心**：`openspec/references/spring-ai-core-standards.md`、`.aetherstack/rules/spring-ai-core.md`
- **多 Agent / Tool**：`openspec/references/spring-ai-multi-agent-standards.md`、`.aetherstack/rules/spring-ai-multi-agent.md`
- **知识库 RAG**：`openspec/references/spring-ai-rag-standards.md`、`.aetherstack/rules/spring-ai-rag.md`
- **ReactAgent / CompiledGraph**：`openspec/references/spring-ai-react-graph-standards.md`、`.aetherstack/rules/spring-ai-react-graph.md`
- **前端 UI Craft**：`openspec/references/ui-craft-standards.md`、`.aetherstack/rules/ui-craft.md`、`.cursor/skills/impeccable/`
