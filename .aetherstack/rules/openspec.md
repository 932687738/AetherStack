# OpenSpec 流程规则

## 何时触发

仅当用户明确要走 **OpenSpec 流程**（创建/继续变更、生成 proposal/spec/design/tasks、调用 opsx-* 命令）时适用。

普通问答、方案讨论、非 OpenSpec 文档编辑**不触发**前置检查。探索阶段禁止调用 OpenSpec 技能。

## 前置检查（0.1 — 已适配 AetherStack）

按顺序逐项提问并等待回答：

1. **工单链接（可选）**：GitHub Issue / Jira 链接；允许回答「无工单」。
2. **选择 schema**：
   - `standard-spec-driven`（复杂需求）
   - `simple-spec-driven`（小需求）
   - `bugfix-spec-driven`（缺陷修复）
3. **需求材料（必填）**：
   - standard/simple：PRD 或需求描述（背景、目标、功能点）
   - bugfix：缺陷描述（现象/复现/影响）

无工单时，第 3 步的需求描述即为唯一输入，可直接创建变更目录。

## 能力命名

- 格式：`aether-{domain}/{capability}`（kebab-case）
- 示例：`aether-agent/orchestrator`、`aether-knowledge/upload`
- changes 目录一层；specs 目录两层（见 `openspec/references/aether-rules.md`）

## 引用

- 全局规则：`openspec/references/aether-rules.md`
- 目录示例：`openspec/references/directory-examples.md`
- 接口契约：`openspec/references/integration-contracts.md`
- 工程标准：`openspec/references/engineering-standards.md`
- 项目配置：`openspec/config.yaml`
- 框架同步记录：`openspec/OPENSPEC-SYNC.md`
