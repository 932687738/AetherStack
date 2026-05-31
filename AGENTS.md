# AetherStack AI 入口（OpenSpec 1.x）

## 配置源

**单一配置源**：`.aetherstack/`。修改规则后运行 `make sync-config`。

## AI 工作流（obra Superpowers）

通用工作流（TDD、代码审查、brainstorming、调试等）由 **obra Superpowers** Cursor 插件提供：

```text
/add-plugin superpowers
```

项目约束（多仓库、DDD、Harness）见 `.aetherstack/rules/superpowers.md`（随 sync-config 加载）。

## 强制入口校验（仅 OpenSpec 流程必做）

当且仅当用户明确要走 **OpenSpec 流程**（创建/继续变更、生成 proposal/spec/design/tasks、调用 opsx-* 或 OpenSpec 技能）时，才需要按 `openspec/references/aether-rules.md` **0.1 前置检查** 逐项执行：

1. 工单链接（**可选**，允许「无工单」）
2. 选择 schema（standard / simple / bugfix）
3. 需求材料（**必填**）

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
