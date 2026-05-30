# Capability Directory Examples (AetherStack)

本文件仅提供目录结构**示例**，用于辅助选址与对照。规则与判定标准请以 `openspec/references/aether-rules.md` 为准。

## 快速索引

- [目录层级速览](#目录层级速览)
- [默认两层与子域例外](#默认两层与子域例外)
- [AetherStack 目录案例](#aetherstack-目录案例)
- [复杂场景示例](#复杂场景示例)
- [常见错误与修正](#常见错误与修正)

## 目录层级速览

```
openspec/specs/
└── aether-{domain}/              # 一级：领域，如 aether-agent
    └── {capability}/             # 二级：能力（默认）
        └── spec.md
```

> 子域为例外模式，仅复杂领域在审批后使用：
> `openspec/specs/aether-{domain}/{sub-domain}/{capability}/spec.md`

**变更目录不镜像归档层级，统一为单层能力名：**
`openspec/changes/{change-id}/specs/aether-{domain}-{capability}/spec.md`
或（子域例外）`openspec/changes/{change-id}/specs/aether-{domain}-{sub-domain}-{capability}/spec.md`

## 默认两层与子域例外

- 默认规则：新能力优先使用两层路径（`aether-{domain}/{capability}`）。
- 子域例外：仅复杂领域且存在稳定复用边界时，允许三层路径。
- 存量兼容：已存在子域结构可继续使用，不强制迁移。

## AetherStack 目录案例

```
aether-agent/
├── orchestrator/         # 编排路由
├── subagent/             # 子智能体
└── requirement-dev/      # 需求开发工作流

aether-knowledge/
├── upload/               # 文档上传入库
├── query/                # RAG 问答
└── memory/               # 会话/长期记忆

aether-hub/
└── status/               # Agent Hub 运行时状态
```

## 复杂场景示例

### 示例 1：新增 RAG 重排序能力

- 领域：knowledge
- 决策：独立能力，无需子域
- **目录：** `openspec/specs/aether-knowledge/rerank/spec.md`
- **变更期：** `openspec/changes/add-rerank/specs/aether-knowledge-rerank/spec.md`

### 示例 2：Knowledge Graph 流水线节点

- 需求：upload/query 各有多个 graph node
- 决策：子域例外，按 upload/query 分子域
- **目录：**
  - `openspec/specs/aether-knowledge/upload/parse-document/spec.md`
  - `openspec/specs/aether-knowledge/query/multi-retrieval/spec.md`

### 示例 3：前后端共享契约

- 需求：新增 SSE 聊天协议字段
- 决策：放入 integration 相关能力
- **目录：** `openspec/specs/aether-integration/chat-sse-contract/spec.md`

## 常见错误与修正

| 错误场景 | 错误示例 | 正确做法 |
|----------|---------|----------|
| 缺少领域层 | `openspec/specs/orchestrator/` | `openspec/specs/aether-agent/orchestrator/` |
| 变更目录不匹配 | `changes/add-chat/specs/chat/spec.md` | `changes/add-chat/specs/aether-agent-chat/spec.md` |
| 默认场景滥用子域 | `aether-knowledge/upload/parse/split/` | 能力保持单层或经评审的子域结构 |
| 前缀拼写错误 | `aether/agent/orchestrator/` | 使用连字符：`aether-agent/orchestrator/` |

## 变更期与归档期映射

- 默认：`aether-{domain}-{capability}` → `aether-{domain}/{capability}`
  - 示例：`aether-agent-orchestrator` → `aether-agent/orchestrator`
- 子域例外：`aether-knowledge-upload-parse` → `aether-knowledge/upload/parse`
