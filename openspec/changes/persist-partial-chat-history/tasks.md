> **任务编号规则**  
> `SPEC_ID` = `aether-agent-conversation-history`（对应 `specs/aether-agent/conversation-history/spec.md`）  
> `REQ_NO` = spec 中 `req-X`

## 0. 基础设施与模块脚手架（横切）

- [x] 0.1 后端（ai）：Flyway V3 与 `conversationhistory` 模块骨架  
  - **依赖**：无  
  - **可验证输出**：`V3__agent_hub_conversation_history.sql` 已添加；包 `com.yxy.deepseek.agents.conversationhistory`（domain/application/infrastructure/web）已创建；`AgentHubApiPaths.CONVERSATIONS` 常量已添加；`mvn compile` 通过。
- [x] 0.2 治理层：登记历史会话 API 契约（可与 6.1 合并验收）  
  - **依赖**：0.1  
  - **可验证输出**：`openspec/references/integration-contracts.md` 与 `.aetherstack/context/api-contracts.yaml` 已登记 6 个 conversations 接口。

---

## 1. 展示当前账号下的历史会话列表（aether-agent-conversation-history-1）

- [x] 1.1 后端（ai）：实现会话列表查询  
  - **依赖**：0.1  
  - **可验证输出**：`GET /api/agent-hub/conversations?mode=&ownerId=` 按 `owner_id`+`chat_mode` 过滤、`updated_at DESC` 返回列表 DTO（含 `id/title/preview/mode/updatedAt`）；默认 `ownerId=SYSTEM_DEFAULT`；`limit` 默认 50。
- [x] 1.2 前端（ai_react）：工作台加载历史列表  
  - **依赖**：1.1  
  - **可验证输出**：`src/api/conversationHistory.js` 实现 `listConversations`；`HomePage` 初始化与切换 `chatMode` 时拉取列表；按模式筛选展示；无数据时显示空状态；**不再**从 `localStorage` 读取 `STORAGE_KEY`。
- [ ] 1.3 测试任务（待 test-cases Reviewed 后补充）

---

## 2. 将全部消息正文永久保存于后端（aether-agent-conversation-history-2）

- [x] 2.1 后端（ai）：消息持久化与 `recordTurn`  
  - **依赖**：0.1  
  - **可验证输出**：`JdbcConversationHistoryRepository` 实现 upsert 会话、按 `seq` 追加消息；`recordTurn` 在同一事务内写入 user+assistant 两条；重启后 PG 数据仍在；`POST .../messages` 支持单条追加与 `clientMessageId` 幂等。
- [x] 2.2 前端（ai_react）：智能体/需求开发模式流式结束后落库  
  - **依赖**：2.1、1.2  
  - **可验证输出**：`HomePage.submitMessage` 的 `onComplete` 调用 append 用户/助手完整正文 + upsert 会话元数据；**知识库模式**不在此路径 POST 追加（留给 REQ-8）。
- [ ] 2.3 测试任务（待 test-cases Reviewed 后补充）

---

## 3. 相同会话标识再次打开时缓存优先、永久存储兜底（aether-agent-conversation-history-3）

- [x] 3.1 后端（ai）：Caffeine L1 + `loadMessages`  
  - **依赖**：2.1  
  - **可验证输出**：`ConversationMessageCache` 配置 `maximumSize=500`、`expireAfterAccess=30m`；`GET .../conversations/{id}/messages` 先 L1 后 PG，未命中回填 L1；`delete/rename/recordTurn/append` 触发 `invalidate`。
- [x] 3.2 前端（ai_react）：选中会话时从 API 加载消息  
  - **依赖**：3.1、1.2  
  - **可验证输出**：点击历史条目调用 `loadConversationMessages(conversationId)` 走 GET messages API；主对话区展示返回列表；**不再**使用 `MESSAGE_STORAGE_KEY`。
- [ ] 3.3 测试任务（待 test-cases Reviewed 后补充）

---

## 4. 选中历史会话后回放全部已保存消息（aether-agent-conversation-history-4）

- [x] 4.1 后端（ai）：消息 DTO 与顺序保证  
  - **依赖**：3.1  
  - **可验证输出**：响应字段对齐前端 `normalizeMessage`（`id/role/kind/text/pending/error/meta`）；`seq` 升序；空会话返回 `[]`。
- [x] 4.2 前端（ai_react）：回放交互与活动会话绑定  
  - **依赖**：3.2、4.1  
  - **可验证输出**：选中历史后 `conversationId` 与条目 `id` 一致；切换会话清空错误输入状态；无消息会话显示空对话区。
- [ ] 4.3 测试任务（待 test-cases Reviewed 后补充）

---

## 5. 支持重命名历史会话标题（aether-agent-conversation-history-5）

- [x] 5.1 后端（ai）：PATCH 重命名  
  - **依赖**：0.1  
  - **可验证输出**：`PATCH /api/agent-hub/conversations/{id}` 更新 `title`；空标题 `400`；刷新后标题持久；缓存失效。
- [x] 5.2 前端（ai_react）：侧边栏重命名 UI 接 API  
  - **依赖**：5.1、1.2  
  - **可验证输出**：`handleSaveRename` 调用 PATCH；列表标题即时更新；**不再**调用 `updateConversationHistory` 写 localStorage。
- [ ] 5.3 测试任务（待 test-cases Reviewed 后补充）

---

## 6. 支持删除历史会话及其全部消息（aether-agent-conversation-history-6）

- [x] 6.1 后端（ai）：DELETE 级联删除  
  - **依赖**：0.1  
  - **可验证输出**：`DELETE /api/agent-hub/conversations/{id}` 返回 204；PG 消息级联删除；L1 invalidate；再次 GET 返回 404。
- [x] 6.2 前端（ai_react）：删除历史接 API  
  - **依赖**：6.1、1.2  
  - **可验证输出**：`handleDeleteHistory` 调用 DELETE；删除当前活动会话时触发 `handleStartNewChat`；**不再**调用 `deleteConversationMessages` 写 localStorage。
- [ ] 6.3 测试任务（待 test-cases Reviewed 后补充）

---

## 7. 历史数据以服务端为唯一数据源并挂接默认系统账号（aether-agent-conversation-history-7）

- [x] 7.1 后端（ai）：`ownerId` 默认值与常量  
  - **依赖**：0.1  
  - **可验证输出**：`ConversationHistoryOwner.SYSTEM_DEFAULT`（或等价常量）用于所有读写；API 未传 `ownerId` 时使用默认值；表字段 `owner_id` 非空。
- [x] 7.2 前端（ai_react）：移除浏览器离线历史  
  - **依赖**：1.2、3.2  
  - **可验证输出**：删除 `nebula_desk_conversation_history_v1` / `nebula_desk_conversation_messages_v1` 相关读写；删除 `useEffect` 中 `saveConversationHistory(historyItems)`；设置页「Auto-save local chat history」文案/开关已移除或改为说明服务端存储。
- [ ] 7.3 测试任务（待 test-cases Reviewed 后补充）

---

## 8. 知识库对话 UI 历史落库并入统一存储（aether-agent-conversation-history-8）

- [x] 8.1 后端（ai）：改造 `MemoryUpdateNode`  
  - **依赖**：2.1  
  - **可验证输出**：`MemoryUpdateNode` 调用 `ConversationHistoryApplicationService.recordTurn`（`chat_mode=knowledge`）；**已移除** `ChatHistoryRepository` 与 `chat_history` 写入；`session_memory` 短期记忆逻辑不变；`ChatHistoryRepository.java` 无引用后删除。
- [x] 8.2 前端（ai_react）：知识库会话 ID 对齐  
  - **依赖**：2.2、8.1  
  - **可验证输出**：`buildRequestBody` 保持 `sessionId: conversationId`；**已删除** `knowledge_session_${conversationId}` localStorage 逻辑；知识库一轮对话完成后侧边栏可查到同 `conversationId` 会话与消息。
- [ ] 8.3 测试任务（待 test-cases Reviewed 后补充）

---

## 9. 不改动对话编排主路径与短期/模型记忆（aether-agent-conversation-history-9）

- [x] 9.1 后端（ai）：回归确认 SSE/Graph 主路径无 BREAKING  
  - **依赖**：8.1  
  - **可验证输出**：`POST /chat/knowledge`、`/chat/agent`、`/requirement-dev` 流式行为与变更前一致（手工冒烟：能正常流式回复）；`ContextPrepareNode` 仍读 `session_memory`；`AgentHubController` / `QueryKnowledgeService` 签名未破坏性变更。
- [x] 9.2 前端（ai_react）：SSE 客户端无协议变更  
  - **依赖**：8.2  
  - **可验证输出**：`chat.js` 的 `postStream` 逻辑未改事件解析；三种模式均可发起对话。
- [ ] 9.3 测试任务（待 test-cases Reviewed 后补充）

---

## 10. 单测与本地验证（横切）

- [x] 10.1 后端（ai）：`ConversationHistoryApplicationService` 单测  
  - **依赖**：3.1、6.1  
  - **可验证输出**：`ConversationHistoryApplicationServiceTest` 覆盖 `loadMessages` L1 命中/未命中、`recordTurn`、`delete` 缓存失效；`mvn -Dtest=ConversationHistoryApplicationServiceTest test` 通过。
- [ ] 10.2 全仓验证  
  - **依赖**：9.1、9.2、10.1  
  - **可验证输出**：`ai` 下 `mvn test`（或项目约定命令）通过；`ai_react` 下 `npm run lint` 与 `npm run build` 通过。（注：本机未配置 `mvn` PATH；前端 `npm run build` 已通过，lint 存量问题见会话说明。）

---

**并行建议**

| 可并行 | 任务 |
|--------|------|
| 波次 1 | 0.1 → 1.1、2.1、5.1、6.1、7.1（后端 API 可同人分文件） |
| 波次 2 | 3.1 依赖 2.1；1.2 依赖 1.1 |
| 波次 3 | 8.1 依赖 2.1；前端 2.2～7.2 依赖对应后端 |
| 波次 4 | 9.x 回归 + 10.x + 0.2 契约 |

**建议实施顺序**：`0.1` → `2.1` → `3.1` → `1.1` → `8.1` → 前端 `1.2`～`8.2` → `9.x` → `10.x` → `0.2`

**apply 准入**：0.x～9.x 开发任务勾选完成后可进入 `openspec-apply-change`；`1.3`～`9.3` 测试占位待 `test-cases.md` **Status=Reviewed** 后回填 AUTO-UT / MANUAL 并执行。
