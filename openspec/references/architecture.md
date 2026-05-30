# Architecture & Integration Reference (AetherStack)

本文件提供 AetherStack 系统架构、模块关系与约束。执行架构或跨模块任务前请先阅读。

## 快速索引

- [系统整体架构](#系统整体架构)
- [后端模块](#后端模块)
- [前端模块](#前端模块)
- [数据与 AI 层](#数据与-ai-层)
- [治理与工程层](#治理与工程层)
- [重要约束](#重要约束)

## 系统整体架构

AetherStack 采用 **治理层 + 关联仓库 + 四层后端 + SPA 前端** 架构：

```text
ai_react (Nebula Desk)          # 关联仓库，见 LOCALPATH.md
    |  REST / SSE
    v
ai (Spring Boot)                # 关联仓库
    |-- agents/        Agent Hub 编排
    |-- knowledgehub/  RAG 知识库
    |-- springai/      教程 Demo
    v
PostgreSQL + pgvector
    ^
    |  LLM API (DashScope 等)
```

## 后端模块

### Agent Hub (`ai/.../agents`)

- **OrchestratorAgent**：统一接收输入，意图路由
- **SubAgent**：客服、数据分析、代码生成、需求开发等
- **Tool / Skill / Plugin**：可扩展工具与技能包
- **Hook**：Spring Events（Before/After/Error/KnowledgeCapture）
- **MCP**：Model Context Protocol Client/Server

典型链路：`AgentHubController` → `OrchestratorAgent` → `SubAgent` / 直答 → `ChatClient` + Tools → `Flux<String>` (SSE)

### Knowledge Hub (`ai/.../knowledgehub`)

- **上传流水线**：parse → split → embed → store
- **问答流水线**：retrieval → rerank → prompt → memory update
- **聚合**：KnowledgeBase、KnowledgeDocument、KnowledgeChunk（含 embedding）

### Spring AI Demo (`ai/.../springai`)

- 教程、Graph Human-in-the-loop、RAG 实验
- 路由前缀多为 `/springai/demo/...`，与生产 `/api/agent-hub/...` 分离

## 前端模块

- **Nebula Desk**（关联仓库 `ai_react`）：单页工作台，视图内切换（无 react-router）
- 聊天模式：knowledge / agent / requirementDev
- API 层：`ai_react/src/api/` + SSE 封装 `request.js`

## 数据与 AI 层

- **PostgreSQL 16 + pgvector**：业务表 + 向量检索（HNSW）
- **Flyway**：`V1__knowledge_schema.sql` 等
- **双向量路径**：
  - Spring AI `vector_store` 表
  - 业务表 `knowledge_chunks.embedding`
- **LLM**：默认 DashScope OpenAI 兼容 API

## 治理与工程层

| 目录 | 职责 | 启动要求 |
|------|------|----------|
| `openspec/` | OpenSpec 规范与变更 | 离线可用 |
| `.aetherstack/` | AI 单一配置源 | 离线可用 |
| `aether-skills/` | Superpower 技能 | 离线可用 |
| `harness/` | AI 六阶段工程实践 | 离线可用（文档） |

## 重要约束

### 技术约束

- 领域层目标态不依赖 Spring（存量逐步对齐）
- 应用层禁止事务内调用外部 HTTP/LLM
- 前后端契约以 `integration-contracts.md` 为准

### 启动边界

- **治理层**：无需启动 ai / ai_react
- **应用开发**：在各自关联仓库启动；数据库 `docker compose up -d`（在 `ai` 仓库根目录）

### 性能约束

- 向量检索需关注 HNSW 参数（m、ef_search）
- SSE 流式响应需控制首 token 延迟与超时

## 外部依赖

- DashScope / OpenAI 兼容 API
- Docker（pgvector 本地开发）
- OpenSpec CLI（可选，规范校验）

详细 API 列表见 `integration-contracts.md`。
