# Integration Contracts (AetherStack)

本文件作为 AetherStack **前后端接口契约**的事实基线，面向 OpenSpec 方案设计、联调与验收。

> 详细路径见 `.aetherstack/context/api-contracts.yaml`。

## 1. 目标与边界

- 目标：统一 REST/SSE 接口的路径、语义、错误口径。
- 范围：Agent Hub + Knowledge Hub 生产接口；Demo HIL 见 `springai/demo/.../human-loop/*`（非生产）。
- 边界：前端通过 Umi 代理 `/api`、`/springai` → `API_PROXY_TARGET`（默认 `http://localhost:8080`，开发环境）。

## 2. 标准链路

```text
ai_react (Nebula Desk, Umi 4)
  → services/* + utils/StreamSse.ts
  → REST/SSE /api/agent-hub/* 、/api/super-agents/*
  → ai AgentHubController / KnowledgeHubController
  → Orchestrator / Graph Pipeline
  → PostgreSQL + pgvector
```

## 3. 关键接口白名单

| 方法 | 路径 | 说明 | 前端引用（Umi） |
|------|------|------|-----------------|
| POST | `/api/agent-hub/chat/knowledge` | 知识库模式 SSE 对话 | `ai_react/src/services/chatService.ts` → `sendKnowledgeChat` |
| POST | `/api/super-agents/chat` | SuperAgents 平台智能体 SSE | `ai_react/src/services/chatService.ts` → `sendAgentChat` |
| POST | `/api/agent-hub/chat/agent` | 存量 Agent Hub 智能体 SSE（legacy） | 已弃用；现网走 super-agents |
| POST | `/api/agent-hub/requirement-dev` | 需求开发模式 SSE | `ai_react/src/services/chatService.ts` → `sendRequirementDevChat` |
| GET | `/api/agent-hub/status` | 运行时状态 | `ai_react/src/services/agentHubService.ts` |
| POST | `/api/agent-hub/knowledge/upload` | 文档上传 | `ai_react/src/services/knowledgeService.ts` |
| GET | `/api/agent-hub/knowledge-bases/{knowledgeBaseId}/documents` | 知识库文档列表 | `ai_react/src/services/knowledgeService.ts` |
| POST | `/api/agent-hub/knowledge/documents/batch-delete` | 批量删除文档 | `ai_react/src/services/knowledgeService.ts` |
| GET/POST/PUT/DELETE | `/api/agent-hub/knowledge-bases` | 知识库 CRUD | `ai_react/src/services/knowledgeService.ts` |
| GET/PUT | `/api/agent-hub/conversation-config/knowledge-retrieval-threshold` | 检索阈值 | `ai_react/src/services/conversationConfigService.ts` |
| GET | `/api/agent-hub/conversations` | 历史会话列表 | `ai_react/src/services/conversationService.ts` |
| POST | `/api/agent-hub/conversations` | 创建/更新会话元数据 | `ai_react/src/services/conversationService.ts` |
| GET | `/api/agent-hub/conversations/{conversationId}/messages` | 历史消息列表 | `ai_react/src/services/conversationService.ts` |
| POST | `/api/agent-hub/conversations/{conversationId}/messages` | 追加历史消息 | `ai_react/src/services/conversationService.ts` |
| PATCH | `/api/agent-hub/conversations/{conversationId}` | 重命名会话 | `ai_react/src/services/conversationService.ts` |
| DELETE | `/api/agent-hub/conversations/{conversationId}` | 删除会话及消息 | `ai_react/src/services/conversationService.ts` |
| GET | `/api/super-agents/agents` | SuperAgents 注册表列表 | 待 UI（design DR-11 可选） |
| POST | `/api/super-agents/agents` | 注册子 Agent | P1 管理/运维 |
| POST | `/api/super-agents/agents/{name}/health` | 主动探测 Agent 健康 | P1 管理/运维 |
| GET/POST | `/springai/demo/alibaba-graph/human-loop/*` | Graph HIL Demo | `ai_react/src/services/humanLoopService.ts` |

路径常量真源：`ai_react/src/constants/ApiPaths.ts`。

## 4. SSE 契约要点

- Content-Type: `text/event-stream`
- 前端解析：`ai_react/src/utils/StreamSse.ts` 中 `postStream`（chat 专用；其余 REST 走 `src/openapi/request.ts`）
- 知识库模式在 token 流结束后由服务端再发送一条 **JSON meta**（`event: "meta"`）；Spring 将其封装为 SSE `data:` 帧（勿手写 `event: meta`，避免双重编码）：
  - `event`: `"meta"`
  - `sessionId`, `knowledgeBaseNames`, `knowledgeBaseCount`
  - `citations[]`: `chunkId`, `documentId`, `knowledgeBaseId`, `knowledgeBaseName`, `documentName`, `preview`, `vectorScore`, `score`（重排相关度）

## 5. 环境变量

| 变量 | 用途 |
|------|------|
| `API_PROXY_TARGET` | Umi 开发代理目标（默认 `http://localhost:8080`） |
| `MOCK_CHAT` | `true` 时 chat SSE 使用前端 mock（E2E / 无后端 smoke） |
| `SUPER_AGENTS_TENANT_ID` | 智能体模式 Header `X-Tenant-Id`（默认 `default`） |
| `POSTGRES_JDBC_URL` | 后端数据库连接 |
| `DASHSCOPE_API_KEY` | LLM API 密钥 |

> Legacy Vite 变量 `VITE_*` 仅适用于 `legacy-vite/`，新工程勿用。

## 6. 设计要求（OpenSpec design 引用）

- 新增/修改 API 时必须同步更新本文件与 `api-contracts.yaml`
- SSE 接口需说明事件类型、结束条件、错误传播方式
- 破坏性变更需在 proposal 中标注并给出前端兼容策略
