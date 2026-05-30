# 历史会话持久化 - 整体方案

## 一、核心问题

**要解决什么问题**：Nebula Desk 历史会话与消息正文仅存于浏览器 `localStorage`，无法跨端恢复，且重命名/删除仅改本地；需改为 **PostgreSQL 永久存储 + 热缓存加速读取**，后端为唯一数据源。

**技术挑战**：

- 与存量 `chat_history`（Knowledge Hub Graph 写入、无会话元数据）**职责分离**，避免混用同表导致边界模糊。
- 相同 `conversationId` 再次访问需 **L1 缓存 → L2 PG** 两级读取，且写入时双写保持一致。
- 不改造 Graph 检索/生成/SSE 协议；**Knowledge Hub** `MemoryUpdateNode` 的 `chat_history` UI 落库须改为统一历史服务；`HomePage` 各模式挂钩同一历史 API。
- 本期无登录，需 `ownerId` 默认账号 + 后续可演进。

---

## 二、整体思路

**业务场景**：

| 场景 | 处理方式 |
|------|----------|
| 进入工作台 | 前端 `GET` 会话列表（按 `ownerId` + `chatMode`） |
| 选中历史会话 | 前端 `GET` 消息列表；后端 **先 L1 后 L2**，可选回填 L1 |
| 发送用户消息 / 流式结束 | 前端调用 **追加消息** + **更新会话元数据**；知识库模式由 Graph **MemoryUpdateNode** 同步落库（与前端双写去重见 design） |
| 知识库 SSE 完成 | `MemoryUpdateNode` 调用 `ConversationHistoryApplicationService` 追加本轮 user/assistant，不再写 `chat_history` |
| 重命名 / 删除 | 前端 `PATCH` / `DELETE`；删除时清 L1 + L2 级联消息 |
| 新会话首条消息 | `upsert` 会话元数据并追加消息 |

**技术实现思路**（仅历史子域）：

```text
ai_react (conversationHistory API client)
  → ConversationHistoryController (/api/agent-hub/conversations/*)
  → ConversationHistoryApplicationService
       → ConversationMessageCache (L1, Caffeine by conversationId)
       → ConversationRepository (L2, JDBC → PostgreSQL)
  ↔ 不经过 OrchestratorAgent / ChatMemory 写入路径
```

发消息时：

- **智能体/需求开发**：`HomePage.submitMessage` 在 `onComplete` 调用历史 API；**不修改** `AgentHubController` SSE 签名。
- **知识库**：`QueryKnowledgeService` / Graph 主路径不变；`MemoryUpdateNode` 将原 `ChatHistoryRepository.append`（`chat_history` 表）替换为 `ConversationHistoryApplicationService.recordTurn(sessionId, mode=KNOWLEDGE, ...)`。`session_memory` 短期记忆 **保留**（`ContextPrepareNode` 仍用 `ShortTermMemoryService`）。

**会话 ID 对齐**：`KnowledgeHubChatRequest.effectiveSessionId()` 优先使用前端传入的 `conversationId`/`sessionId`，避免 meta 回写另一 ID 导致历史分裂；前端移除 `localStorage` 的 `knowledge_session_${conversationId}` 映射。

---

## 三、技术选型

| 功能场景 | 技术组件 | 使用理由 |
|---------|---------|---------|
| 永久存储（L2） | PostgreSQL + Flyway `V3__...` | 与项目栈一致；权威数据源 |
| 热缓存（L1） | Caffeine（`conversationId` → 消息列表） | 满足「先缓存后表」；与 `InMemoryChatMemoryRepository` **解耦**（ChatMemory 为 LLM 窗口，格式/容量/UI 需求不一致） |
| 持久化访问 | `JdbcTemplate` / Spring JDBC Repository | 对齐 `knowledgehub.repository.ChatHistoryRepository` 存量风格，agents 子域新建 Repository |
| 分层 | DDD 四层 under `agents.conversationhistory` | 对齐 `engineering-standards.md` 与 `recommendedpackaging` 样板 |
| 前端 | `ai_react/src/api/conversationHistory.js` + 改造 `services/conversationHistory.js` | 统一走 `request.js`；移除 `localStorage` |
| Knowledge Hub 历史落库 | `MemoryUpdateNode` → `ConversationHistoryApplicationService` | 替换 `chat_history` UI 写入；Graph 其余节点不变 |
| Agent/需求开发编排 | 不变 | spec REQ-8：不改造 SSE 主路径 |

**不选用**：

- 复用 `chat_history` 表承载 UI 侧边栏（缺 `title`/`mode`/`preview`/级联删除会话实体；已被 `MemoryUpdateNode` 使用）。
- 以 `ChatMemory` 作为 L1（窗口 40 条、Message 类型、与编排耦合）。
- Redis（本期无必要；进程内 Caffeine 即可）。

---

## 四、影响范围

### 系统间影响

- 仅 **ai** + **ai_react**；治理层更新 `integration-contracts.md`、`api-contracts.yaml`。
- Knowledge Hub：**仅** `MemoryUpdateNode` 历史落库改统一服务；检索/上传/向量记忆无变更。需求开发、Agent Orchestrator 编排无变更。

### 模块改动

| 模块 | 改动点 |
|------|--------|
| `ai` / `agents.conversationhistory`（新建） | 领域模型、应用服务、JDBC Repository、Caffeine 缓存、Controller；对外暴露 `recordTurn` 供 Knowledge Hub 调用 |
| `ai` / `knowledgehub.graph.query.MemoryUpdateNode` | 移除 `ChatHistoryRepository` 注入与 `chat_history` 写入；改为调用历史应用服务 |
| `ai` / `knowledgehub.repository.ChatHistoryRepository` | 标记废弃或删除（若无其他引用） |
| `ai` / `db/migration` | 新增 `agent_hub_conversation`、`agent_hub_conversation_message`（命名 design 定稿） |
| `ai` / `AgentHubApiPaths` | 新增 conversations 路径常量 |
| `ai_react` / `conversationHistory.js`、`HomePage.jsx` | API 化；删除 localStorage 与 `saveConversationHistory` 副作用 |
| `ai_react` / `messages.js` | 调整「本地保存历史」文案或移除无效开关 |

### 接口变更（草案）

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/agent-hub/conversations` | 列表（`mode` 可选，`ownerId` 默认系统账号） |
| POST | `/api/agent-hub/conversations` | 创建/更新会话元数据 |
| GET | `/api/agent-hub/conversations/{conversationId}/messages` | 加载消息（L1→L2） |
| POST | `/api/agent-hub/conversations/{conversationId}/messages` | 追加一条消息（user/assistant） |
| PATCH | `/api/agent-hub/conversations/{conversationId}` | 重命名标题 |
| DELETE | `/api/agent-hub/conversations/{conversationId}` | 删除会话及消息 |

> 详细 JSON / 错误码在 `design.md` 细化。

---

## 五、数据设计

### 数据模型关系

```text
Owner (本期常量 SYSTEM_DEFAULT)
  1 : N  Conversation（conversationId 业务主键）
            1 : N  ConversationMessage（有序 seq 或 created_at）
```

- `conversationId`：与前端 `createConversationId()` / `AgentHubChatRequest.conversationId` **同值**。
- `chatMode`：`knowledge` | `agent` | `requirement-dev`（与前端 `CHAT_MODE` 对齐，VARCHAR）。
- 消息字段：`role`、`content`（正文）、`kind`（text 等）、`client_message_id`（前端 `user-xxx`/`assistant-xxx` 幂等）、`pending`/`error` 状态（可选 JSON metadata）。

### 表结构要点

```sql
-- 新增表：agent_hub_conversation（会话元数据）
-- 核心字段：conversation_id (UK), owner_id, title, preview, chat_mode, updated_at, created_at
-- 索引：(owner_id, chat_mode, updated_at DESC)

-- 新增表：agent_hub_conversation_message（消息正文）
-- 核心字段：id, conversation_id (FK), role, content, kind, client_message_id, metadata JSONB, seq, created_at
-- 索引：(conversation_id, seq) 或 (conversation_id, created_at)

-- 不修改：chat_history / session_memory（Knowledge Hub 专用）
```

**与存量 `chat_history` 关系**：本期 **停止** 向 `chat_history` 写入 `knowledge_chat` 类型 UI 历史；统一写 `agent_hub_conversation_message`。表可保留供存量数据/后续清理，**不再**作为侧边栏数据源。`session_memory` 继续服务 Graph 短期上下文，与 UI 历史表职责分离。

**双写去重（知识库模式）**：design 阶段二选一——（1）仅 `MemoryUpdateNode` 落库，前端知识库模式不再 POST 追加；或（2）前端落库 + 节点幂等 `client_message_id`。推荐 **（1）** 减少重复与竞态。

---

## 六、约束与风险

### 技术约束

- **性能**：列表分页可首期 `LIMIT 50`（对齐前端 `slice(0, 10)` 展示逻辑可改为服务端排序）；单会话消息全量加载，大会话需 design 评估上限。
- **业务**：默认系统账号下多用户共享同一历史视图（无登录）；上线认证前需产品知悉。
- **技术**：历史 API 调用在 **事务外**；禁止在 `@Transactional` 内调 LLM；追加消息与 SSE 解耦。
- **缓存**：服务重启 L1 失效，依赖 L2 恢复；删除/重命名须 **失效** 对应 L1 条目。

### 风险点

| 风险 | 应对措施 |
|------|---------|
| 与 `chat_history` 概念混淆 | 新表命名带 `agent_hub_` 前缀；MemoryUpdateNode 切断旧写入 |
| 知识库前端/后端双写重复 | 知识库模式落库以 MemoryUpdateNode 为准，前端只读历史 API |
| `sessionId` 与 `conversationId` 不一致 | 请求统一传 `conversationId`；废弃 meta 触发的 localStorage 映射 |
| 流式过程中频繁写库 | 用户消息立即 append；助手消息在 `onComplete` 一次 append 完整正文 |
| 前端仍写 localStorage | 删除 STORAGE_KEY；Code review 检查 |
| `knowledge_session_*` localStorage | 本期历史范围外；保留或另开变更，不在本方案改动 SSE meta |

---

## 七、待 AI 细化（→ design.md）

- [ ] 完整 DDL（Flyway `V3`）、字段长度与 FK 级联
- [ ] REST 请求/响应 JSON、错误码（404 会话不存在等）
- [ ] Caffeine 容量、TTL、失效策略与时序图（打开会话 / 发消息 / 删除）
- [ ] `agents.conversationhistory` 包结构与类清单
- [ ] 前端 API 模块与 `HomePage` 挂钩点对照表
- [ ] 复杂度对齐 spec 8 条 Requirement 的实现映射
- [ ] 是否同步更新 `api-contracts.yaml` 条目

---

## 复杂度判定

| 条件 | 是否命中 |
|------|----------|
| 新增表 + 缓存 | ✅ |
| Requirement ≥ 8 | ✅ |
| Scenario ≥ 12 | ✅ |

**结论**：属 **复杂需求**，须先确认本 draft，再生成完整 `design.md`。
