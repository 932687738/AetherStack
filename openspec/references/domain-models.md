# Domain Context & Models (AetherStack)

本文件汇总 AetherStack 的业务领域知识、核心流程与限界上下文。涉及领域建模、聚合或 DDD 任务前请先阅读。

## 快速索引

- [限界上下文](#限界上下文)
- [Agent Hub 领域](#agent-hub-领域)
- [Knowledge Hub 领域](#knowledge-hub-领域)
- [核心流程](#核心流程)
- [聚合与实体](#聚合与实体)

## 限界上下文

| 上下文 | 路径（相对 ai / ai_react 仓库根） | 说明 |
|--------|------|------|
| Agent Hub | `ai/.../agents` | 多智能体编排、路由、工具调用 |
| Knowledge Hub | `ai/.../knowledgehub` | 知识库、文档、RAG、记忆 |
| Spring AI Demo | `ai/.../springai` | 教程与实验（独立上下文） |
| Nebula Desk | `ai_react/` | 对话 UI、本地历史、设置 |

## Agent Hub 领域

- **Orchestrator**：统一入口，意图识别与路由
- **SubAgent**：垂直能力（客服、分析、代码、需求开发）
- **Tool**：本地工具与 MCP 暴露
- **Hook**：生命周期事件与知识捕获
- **Skill/Plugin**：可插拔能力扩展

## Knowledge Hub 领域

- **KnowledgeBase**（聚合根）：知识库元数据；**目标** 校验与不变式迁入 domain
- **KnowledgeDocument**：上传文档生命周期；去重/替换规则 **目标** 在聚合内
- **KnowledgeChunk**：分段与 embedding
- **SessionMemory / LongTermMemory**：会话与长期记忆
- **Graph Pipeline**：upload/query CompiledGraph 编排（节点 **目标** 仅做适配，规则在 DomainService）

**与 agents.knowledge 边界**：agents 侧 VectorStore 会话捕获为存量路径；新 RAG 能力只扩展 knowledgehub，不新增第三套存储。

## 核心流程

### 1. 知识库对话（SSE）— 生产唯一入口

```text
用户 -> ai_react -> POST /api/agent-hub/chat/knowledge
  -> QueryKnowledgeService (CompiledGraph prep -> ChatClient -> Graph post)
  -> knowledgehub 多路召回 + LLM -> SSE
```

> 勿使用 OrchestratorAgent KNOWLEDGE 模式（遗留无 HTTP 入口）。

### 2. 智能体对话

```text
用户 -> ai_react -> POST /api/agent-hub/chat/agent
  -> AgentChatApplicationService (CompiledGraph prep + 流式分支)
  -> AgentHubRouter (transferToAgent 语义) -> ReactAgent 子能力 / 编排器 ChatClient
  -> ToolCatalog Top-K @Tool -> SSE
```

### 3. 文档上传入库

```text
用户 -> ai_react -> POST /api/agent-hub/knowledge/upload
  -> Upload Graph: parse -> split -> embed -> store
  -> knowledge_chunks + vector_store
```

### 4. 需求开发模式

```text
用户 -> POST /api/agent-hub/requirement-dev
  -> RequirementDevelopmentOrchestrator
  -> SSE 多阶段输出
```

## 聚合与实体

### KnowledgeBase 聚合

- 根：KnowledgeBase
- 实体：KnowledgeDocument
- 值对象/Chunk：KnowledgeChunk（含 vector）
- 不变式：文档归属唯一知识库；chunk 维度与 embedding 模型一致

### Agent 会话（逻辑聚合）

- 会话上下文、路由决策、工具调用记录
- 长期价值片段可经 Hook 写入向量存储

## OpenSpec 能力命名对照

| 业务能力 | 建议 spec 路径 |
|----------|----------------|
| 编排路由 | `aether-agent/orchestrator` |
| 知识库上传 | `aether-knowledge/upload` |
| RAG 问答 | `aether-knowledge/query` |
| Hub 状态 | `aether-hub/status` |
| SSE 契约 | `aether-integration/chat-sse-contract` |

详见 `directory-examples.md`。
