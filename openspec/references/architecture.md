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

> **现状梳理与目标设计**：[`backend-design-guide.md`](backend-design-guide.md)

### Agent Hub (`ai/.../agents`) — 存量 Orchestrator 路径

- **OrchestratorAgent**：统一接收输入，意图路由（**待迁移** CompiledGraph/ReactAgent）
- **SubAgent**：客服、数据分析、代码生成、需求开发等
- **RequirementDevelopmentOrchestrator**：Java 工作流（**待迁移** CompiledGraph）
- **Tool / Skill / Hook / MCP**：可扩展能力
- **agents.knowledge**：旧 VectorStore RAG + 会话捕获（与 knowledgehub **重复**，待收敛）

典型链路（As-Is）：`AgentHubController` → `OrchestratorAgent` → `SubAgent` / 直答 → `AgentChatService` (ChatClient)

### Knowledge Hub (`ai/.../knowledgehub`) — 目标生产 RAG 路径

- **上传**：CompiledGraph 线性链（parse → split → embed → store）
- **问答**：CompiledGraph prep → ChatClient 流式 → CompiledGraph post（**目标**：端到端 Graph + post Bean 单例）
- **CRUD**：KnowledgeBase 聚合（**目标**：domain 行为补强，Graph 节点瘦身）

### Spring AI Alibaba 编排（新需求默认）

| 组件 | 用途 | 参考 |
|------|------|------|
| **CompiledGraph** | 多步工作流、条件边、检查点、HIL | `knowledgehub/graph/`、`springai/graph/` |
| **ReactAgent** | ReAct + 工具、MemorySaver | `recommendedpackaging/`、`springai/agent/` |

细则：`.aetherstack/rules/backend-ai.md`

### Spring AI Demo (`ai/.../springai`) — 仅教程

- 路由 `/springai/demo/*`；**目标** `@Profile("demo")` 隔离
- **禁止** agents/knowledgehub 生产代码依赖本包

## 前端模块

- **Nebula Desk**（关联仓库 `ai_react`）：单页工作台，视图内切换（无 react-router）
- 聊天模式：knowledge / agent / requirementDev
- API 层：`ai_react/src/api/` + SSE 封装 `request.js`

## 数据与 AI 层

- **PostgreSQL 16 + pgvector**：业务表 + 向量检索（HNSW）
- **Flyway**：`V1__knowledge_schema.sql` 等
- **向量路径（目标统一）**：
  - **生产主路径**：`knowledgehub` — `knowledge_chunks.embedding` + 多 KB 召回
  - **存量/待收敛**：Spring AI `vector_store`（agents 会话捕获）
  - **Demo 仅**：`springai` PgVectorRagDemo（不与生产互通）
- **LLM**：默认 DashScope OpenAI 兼容 API

详见 `backend-design-guide.md` §2.2 三套 RAG 问题。

## 治理与工程层

| 目录 | 职责 | 启动要求 |
|------|------|----------|
| `openspec/` | OpenSpec 规范与变更 | 离线可用 |
| `.aetherstack/` | AI 单一配置源 | 离线可用 |
| `.aetherstack/` | AI 配置（rules + context + obra 插件约束） | 离线可用 |
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
