# Integration Contracts (AetherStack)

本文件作为 AetherStack **前后端接口契约**的事实基线，面向 OpenSpec 方案设计、联调与验收。

> 详细路径见 `.aetherstack/context/api-contracts.yaml`。

## 1. 目标与边界

- 目标：统一 REST/SSE 接口的路径、语义、错误口径。
- 范围：Agent Hub + Knowledge Hub 生产接口；不含 `springai/` 教程 Demo 路径。
- 边界：前端通过 Vite 代理 `/api` → `http://localhost:8080`（开发环境）。

## 2. 标准链路

```text
ai_react (Nebula Desk)
  → REST/SSE /api/agent-hub/*
  → ai AgentHubController / KnowledgeHubController
  → Orchestrator / Graph Pipeline
  → PostgreSQL + pgvector
```

## 3. 关键接口白名单

| 方法 | 路径 | 说明 | 前端引用 |
|------|------|------|----------|
| POST | `/api/agent-hub/chat/knowledge` | 知识库模式 SSE 对话 | `ai_react/src/api/chat.js` |
| POST | `/api/agent-hub/chat/agent` | 智能体模式 SSE 对话（存量 Agent Hub） | `ai_react/src/api/chat.js` |
| POST | `/api/super-agents/chat` | **SuperAgents 平台** SSE 对话（新接口） | 待 `ai_react` 对接 |
| POST | `/api/agent-hub/requirement-dev` | 需求开发模式 SSE | `ai_react/src/api/chat.js` |
| GET | `/api/agent-hub/status` | 运行时状态 | `ai_react/src/api/agentHub.js` |
| POST | `/api/agent-hub/knowledge/upload` | 文档上传 | `ai_react/src/api/knowledge.js` |
| GET | `/api/agent-hub/knowledge-bases/{knowledgeBaseId}/documents` | 知识库文档列表 | `ai_react/src/api/knowledge.js` |
| POST | `/api/agent-hub/knowledge/documents/batch-delete` | 批量删除文档 | `ai_react/src/api/knowledge.js` |
| GET/POST/PUT/DELETE | `/api/agent-hub/knowledge-bases` | 知识库 CRUD | `ai_react/src/api/knowledge.js` |
| GET | `/api/agent-hub/conversations` | 历史会话列表 | `ai_react/src/api/conversationHistory.js` |
| POST | `/api/agent-hub/conversations` | 创建/更新会话元数据 | `ai_react/src/api/conversationHistory.js` |
| GET | `/api/agent-hub/conversations/{conversationId}/messages` | 历史消息列表 | `ai_react/src/api/conversationHistory.js` |
| POST | `/api/agent-hub/conversations/{conversationId}/messages` | 追加历史消息 | `ai_react/src/api/conversationHistory.js` |
| PATCH | `/api/agent-hub/conversations/{conversationId}` | 重命名会话 | `ai_react/src/api/conversationHistory.js` |
| DELETE | `/api/agent-hub/conversations/{conversationId}` | 删除会话及消息 | `ai_react/src/api/conversationHistory.js` |
| GET | `/api/super-agents/agents` | SuperAgents 注册表列表（可选 `X-Tenant-Id`） | P1 管理/运维 |
| POST | `/api/super-agents/agents` | 注册子 Agent（`X-Admin-Api-Key` + 可选 `X-Tenant-Id`） | P1 管理/运维 |
| POST | `/api/super-agents/agents/{name}/health` | 主动探测 Agent 健康 | P1 管理/运维 |

## 4. SSE 契约要点

- Content-Type: `text/event-stream`
- 前端解析：`ai_react/src/utils/request.js` 中 `postStream`
- 知识库模式在 token 流结束后由服务端再发送一条 **JSON meta**（`event: "meta"`）；Spring 将其封装为 SSE `data:` 帧（勿手写 `event: meta`，避免双重编码）：
  - `event`: `"meta"`
  - `sessionId`, `knowledgeBaseNames`, `knowledgeBaseCount`
  - `citations[]`: `chunkId`, `documentId`, `knowledgeBaseId`, `knowledgeBaseName`, `documentName`, `preview`, `vectorScore`, `score`（重排相关度）

## 5. 环境变量

| 变量 | 用途 |
|------|------|
| `VITE_API_PROXY_TARGET` | 开发代理目标（默认 `http://localhost:8080`） |
| `POSTGRES_JDBC_URL` | 后端数据库连接 |
| `DASHSCOPE_API_KEY` | LLM API 密钥 |

## 6. 设计要求（OpenSpec design 引用）

- 新增/修改 API 时必须同步更新本文件与 `api-contracts.yaml`
- SSE 接口需说明事件类型、结束条件、错误传播方式
- 破坏性变更需在 proposal 中标注并给出前端兼容策略
