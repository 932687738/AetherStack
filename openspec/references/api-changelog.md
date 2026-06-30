# API Changelog

按时间倒序记录 **Agent Hub / SuperAgents** 对外 REST/SSE 变更。格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)。

约定维护见 [`api-conventions.md`](api-conventions.md) §9。

---

## [Unreleased]

### Added
- AI 流程编排（`add-ai-flow-orchestration`）：
  - `GET/POST /api/agent-hub/flows` — 流程分页列表 / 创建草稿（默认 `start→end`）
  - `GET/PUT/DELETE /api/agent-hub/flows/{id}` — 详情 / 更新 definition / 软删
  - `POST /api/agent-hub/flows/{id}/publish|enable|disable|rollback` — 发布、启停、回滚
  - `GET /api/agent-hub/flows/{id}/versions` — 版本历史
  - `POST /api/agent-hub/flows/{id}/invoke|stream|debug` — 同步执行、SSE 执行、设计器调试 SSE
  - `POST /api/agent-hub/flows/{id}/register-mcp-tool` — 注册为 Tool/MCP 描述
  - `GET /api/agent-hub/flow-executions[/{id}]` — 执行记录列表 / 详情
  - `GET/PUT /api/super-agents/agents/{name}/flow` — Agent 绑定/解绑流程；`PrepareSuperAgentChatNode` 路由至 `FLOW_ENGINE`
  - Flyway `V28__ai_flow_orchestration.sql`：`flow_definitions`、`flow_versions`、`flow_executions`；`agent_registry.flow_id`
- Prompt 模板管理（`add-prompt-management`）：
  - `GET/POST /api/super-agents/prompts/templates` — 管理端分页列表 / 创建模板
  - `PUT/DELETE /api/super-agents/prompts/templates/{name}` — 保存新版本 / 软删除（custom only）
  - `GET /api/super-agents/prompts/templates/{name}/versions` — 版本历史
  - `POST /api/super-agents/prompts/templates/{name}/rollback` — 版本回滚
  - `GET/PUT /api/super-agents/prompts/experiments/{sceneKey}` — A/B 实验配置
  - `GET /api/super-agents/prompts/templates/{name}/invokes` — 调用记录分页
  - `POST /api/super-agents/prompts/marketplace/use` 可选 body 字段 `sceneKey` — 实验分流选用
  - Flyway `V27__prompt_management.sql`：`prompt_experiments`、`prompt_invoke_logs`
- Prompt 市场 / 快捷指令（`add-prompt-marketplace`）：
  - `GET /api/super-agents/prompts/marketplace` — 分类/关键词浏览模板
  - `POST/GET /api/super-agents/prompts/marketplace/favorites` — 收藏 toggle / 列表
  - `POST /api/super-agents/prompts/marketplace/use` — 选用模板到 Agent `system_prompt`
  - `POST /api/super-agents/prompts/marketplace/save-generated` — 保存 AI 生成模板
  - `POST /api/super-agents/prompts/generate` — AI 辅助生成 Prompt（SSE）
  - `GET/POST/PUT/DELETE /api/super-agents/agents/{agentName}/quick-commands[/{id}]` — 快捷指令 CRUD
  - Flyway `V25__prompt_marketplace.sql`：`prompt_templates`、`quick_commands`、`prompt_favorites`；`agent_registry.system_prompt`
- `POST /api/super-agents/chat` SSE **`type=artifact`** 事件（非 BREAKING；`sql-review` / `table` / `code`），见 `integration-contracts.md` §4（`add-text2sql-schema-artifacts`）
- Text2SQL：`Text2SqlPlatformTool` + `text2sql-readonly` CompiledGraph Skill；Schema Catalog 表 `text2sql_schema_*`、`text2sql_query_session`
- 会话消息 `meta.artifacts[]`、`meta.text2sqlSessionId`（assistant 持久化扩展字段，可选）

### Changed
- `POST /api/super-agents/chat` 及 `/api/super-agents/**` 管理类 REST：超限时返回 **HTTP 429**，body `code=RATE_LIMIT_EXCEEDED`，Header `Retry-After`；限流维度 **tenantId** / **userId** / **client IP** / **API 路径** / **API Key**（`X-Admin-Api-Key` / `X-Api-Key`），YAML 默认配额可由表 **`rate_limit_config`** 动态覆盖；计数存储支持 **memory**（单实例）与 **redis**（`aether.platform.rate-limit.store-type=redis`）；`@Tool` 方法按工具名独立限流（`p3-observability-resilience-foundation`）

### Deprecated
- （无）

---

## [2026-06-07] — Agent 平台基础（`aether-agent-platform-foundation`）

### Added
- `POST /api/super-agents/chat` — SuperAgents 平台智能体 SSE（Header：`X-Tenant-Id` 等）
- `GET/POST /api/super-agents/agents` — Agent 注册表
- `GET/POST/PATCH /api/super-agents/skills` — Skill 生命周期
- `GET /api/super-agents/tools` — Tool 描述摘要
- `GET/PATCH /api/super-agents/model-providers` — 模型 Provider 开关
- `GET /api/super-agents/hooks/suspended` — 挂起工作流分页列表
- `POST /api/super-agents/hooks/resume` — SSE 恢复挂起流程
- Prometheus 指标：`spring_ai_platform_chat_requests_total` 等（部分 REQ-5）

### Deprecated
- `POST /api/agent-hub/chat/agent` → 使用 `POST /api/super-agents/chat`（Sunset: 2026-12-31）

---

## [2026-06-07] — 挂起工作流管理（`add-suspended-workflow-management`）

### Added
- `GET /api/super-agents/hooks/suspended/{resumeToken}` — 挂起详情
- `POST .../close`、`DELETE ...` — 关闭与删除记录

---

## [2026-05-31] — 会话与配置

### Added
- `GET/POST/PATCH/DELETE /api/agent-hub/conversations*` — 历史会话 CRUD
- `GET/PUT /api/agent-hub/conversation-config/knowledge-retrieval-threshold` — 检索阈值

---

## [2026-05-30] — 知识库

### Added
- `POST /api/agent-hub/knowledge/documents/batch-delete` — 批量删除文档
