# OpenSpec 使用指南

## 1. 前置检查（AetherStack 适配）

进入 OpenSpec 流程时按 [aether-rules.md](../openspec/references/aether-rules.md) 0.1：

1. 工单链接（**可选**，允许无工单）
2. 选择 schema
3. 需求材料（**必填**）
4. **AI-TDD 模式** → `aiTddMode`
5. **UI-Craft 模式** → `uiCraftMode`

详见 [ai-tdd-standards.md](../openspec/references/ai-tdd-standards.md)、[ui-craft-standards.md](../openspec/references/ui-craft-standards.md)。

## 2. 目录约定

- 能力命名：`aether-{domain}/{capability}`
- 变更期：`openspec/changes/<id>/specs/aether-xxx-yyy/spec.md`（一层）
- 归档后：`openspec/specs/aether-xxx/yyy/spec.md`（两层）

示例见 [directory-examples.md](../openspec/references/directory-examples.md)。

## 3. Cursor 命令

| 命令 | 作用 |
|------|------|
| `/opsx-new` | 新建变更 |
| `/opsx-continue` | 继续变更 |
| `/opsx-apply` | 按 tasks 实现 |
| `/opsx-archive` | 归档到 specs |
| `/opsx-verify` | 校验变更 |
| `/opsx-sync` | 同步 spec |

## 4. 工件链（standard）

```
proposal.md → spec.md → design-draft.md → design.md → test-cases.md → tasks.md → apply
```

`aiTddMode: enabled` → L1 模块 + TDD；`uiCraftMode: enabled` → U1 界面 + Impeccable + tasks `1.2a`。

## 5. AI-TDD 与 Superpowers

OpenSpec **不自动**走 Superpowers；仅当 `aiTddMode: enabled`（或 auto 命中 L1）、tasks 含 `AUTO-AI-UT`、或用户说 `/tdd` 时 invoke `test-driven-development`。

| 文档 | 说明 |
|------|------|
| [ai-tdd-standards.md](../openspec/references/ai-tdd-standards.md) | 分层、标记、范式 |
| [SUPERpower.md](../SUPERpower.md) | 插件 + AI-TDD 手册 |
| [ai-test-templates.md](../harness/adapters/java-maven/ai-test-templates.md) | 测试代码模板 |

## 6. UI-Craft 与 Impeccable

OpenSpec **不自动** invoke Impeccable；仅当 `uiCraftMode: enabled`（或 auto 命中 U1）、tasks 为 `UI-CRAFT`/`UI-AUDIT`、或用户说 `/impeccable` 时读取 `.cursor/skills/impeccable/SKILL.md`。

| 任务标记 | Impeccable 命令链 |
|----------|-------------------|
| UI-CRAFT | `shape` → `craft` → （可选）`polish` |
| UI-AUDIT | `audit` / `critique` → `polish` |
| UI-FUNC | 跳过（仅 API/SSE 逻辑） |

| 文档 | 说明 |
|------|------|
| [ui-craft-standards.md](../openspec/references/ui-craft-standards.md) | U1/U3 分层、开关、阻断规则 |
| [Impeccable SKILL](../.cursor/skills/impeccable/SKILL.md) | 执行入口 |

## 7. OpenSpec CLI

```bash
npm install -g @fission-ai/openspec
openspec validate
openspec show <change-id>
```

CI 可选工作流：`.github/workflows/openspec-validate.yml`（需 `OPENSPEC_VALIDATE_ENABLED=true`）。

## 8. 与代码仓关系

AetherStack 为 **治理层仓库**：规范在本仓，实现改关联仓库 **ai** / **ai_react**（见 `LOCALPATH.md`），追溯读 `openspec/changes/`。
