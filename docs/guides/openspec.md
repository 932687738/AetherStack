# OpenSpec 使用指南

## 1. 前置检查（AetherStack 适配）

进入 OpenSpec 流程时按 [aether-rules.md](../openspec/references/aether-rules.md) 0.1：

1. 工单链接（**可选**，允许无工单）
2. 选择 schema
3. 需求材料（**必填**）

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

## 5. OpenSpec CLI

```bash
npm install -g @fission-ai/openspec
openspec validate
openspec show <change-id>
```

CI 可选工作流：`.github/workflows/openspec-validate.yml`（需 `OPENSPEC_VALIDATE_ENABLED=true`）。

## 6. 与代码仓关系

AetherStack 为 **治理层仓库**：规范在本仓，实现改关联仓库 **ai** / **ai_react**（见 `LOCALPATH.md`），追溯读 `openspec/changes/`。
