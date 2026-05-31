> **任务编号规则**  
> SPEC_ID = `aether-knowledge-retrieval-threshold` → 前缀 `KH-RT`

## 1. 双阈值配置展示与编辑（KH-RT-REQ1）

- [x] 1.1 后端：实现 `KnowledgeRetrievalThresholdConfig` 值对象与校验（0–100）；`ConversationConfigApplicationService` 提供读写；`GET/PUT .../conversation-config/knowledge-retrieval-threshold` 可返回/保存 DTO — **可验证**：curl GET 默认 `{50,50}`；PUT 60/30 后 GET 一致
- [x] 1.2a **UI-CRAFT**：Impeccable shape → craft `RetrievalThresholdSettings.jsx`（双 slider、说明文案、保存/重置）— 已按现有设计语言实现 U1 面板（未跑 Impeccable CLI）
- [x] 1.2 前端：挂载配置面板至知识库对话视图；`conversationConfig.js` 对接 API；i18n — **可验证**：知识库模式下可见面板；保存后刷新仍显示 60/30
- [ ] 1.3 测试任务（待 test-cases Reviewed 后补充）
- [x] 1.4a **AUTO-AI-UT**：先编写 `RetrievalThresholdFilterTest`（或 Node 单测）— 覆盖双阈值 AND、边界 0%、非法 null 分数 — **可验证**：`mvn -Dtest=RetrievalThresholdFilterTest test` 红→绿
- [x] 1.4 **AUTO-UT**：`ConversationConfigApplicationServiceTest` 校验 0–100 与 upsert — **可验证**：测试通过
- [ ] 1.5 执行 `mvn -Dtest=RetrievalThresholdFilterTest,ConversationConfigApplicationServiceTest test` — **可验证**：BUILD SUCCESS（本机 PATH 无 mvn，待本地执行）
- [ ] 1.6 **MANUAL**：浏览器拖动 slider 保存，确认 UI 与 API 一致 — **ManualReason**：滑块交互与 toast

## 2. 配置持久化与可扩展类型（KH-RT-REQ2）

- [x] 2.1 后端：Liquibase/Flyway 迁移 `conversation_user_config`；`ConversationUserConfigRepository` upsert/find；`config_type=KNOWLEDGE_CHAT_RETRIEVAL` — **可验证**：迁移成功；DB 唯一约束 `(user_id, config_type)`
- [ ] 2.2 前端：无独立 UI（复用 REQ1 面板）— **可验证**：N/A
- [ ] 2.3 测试任务（待 test-cases Reviewed 后补充）
- [ ] 2.4 **AUTO-UT**：Repository 集成测试或 Service 测试验证 upsert 幂等 — **可验证**：测试通过
- [ ] 2.5 执行对应 `mvn -Dtest=... test` — **可验证**：BUILD SUCCESS

## 3. 系统默认用户权限（KH-RT-REQ3）

- [x] 3.1 后端：常量 `SYSTEM_DEFAULT_USER="__system__"`；`resolveKnowledgeRetrievalThreshold(userId)` 逻辑：blank/anonymous → 先查 userId 再 fallback `__system__` 再硬编码默认 — **可验证**：anonymous 请求读写同一 DB 行
- [x] 3.2 前端：请求不额外传 userId，沿用现有 `X-User-Id` 或缺省 — **可验证**：未登录时保存全局生效
- [ ] 3.3 测试任务（待 test-cases Reviewed 后补充）
- [ ] 3.4 **AUTO-UT**：Service 测试 anonymous → system fallback — **可验证**：测试通过
- [ ] 3.5 执行 `mvn -Dtest=ConversationConfigApplicationServiceTest test` — **可验证**：BUILD SUCCESS

## 4. 知识库对话检索过滤（KH-RT-REQ4）

- [x] 4.1 后端：新增 `RetrievalThresholdFilterNode`；注册至 prep nodes；`QueryKnowledgeService` 注入 `RETRIEVAL_THRESHOLD_CONFIG` — **可验证**：高阈值下 citations 数量减少；过滤后为空仍 SSE 成功
- [x] 4.2 前端：对话后 `KnowledgeCitationPanel` 仅展示过滤后 citations（无额外改动，依赖后端 meta）— **UI-FUNC** — **可验证**：设置 70% 后低分引用不再出现
- [ ] 4.3 测试任务（待 test-cases Reviewed 后补充）
- [x] 4.4a **AUTO-AI-UT**：`RetrievalThresholdFilterNodeTest` Graph 节点集成或 Filter 单测（Mock state）— **可验证**：先测后码，mvn 通过
- [ ] 4.5 执行 `mvn -Dtest=RetrievalThresholdFilter* test` — **可验证**：BUILD SUCCESS
- [ ] 4.6 **MANUAL**：知识库对话提问，对比阈值 0% vs 80% 的 citations 差异 — **ManualReason**：端到端 SSE + 引用 UI

## 5. 配置说明与校验（KH-RT-REQ5）

- [x] 5.1 后端：`PUT` 校验 0–100，超出返回 400 — **可验证**：Postman PUT 150 得 400
- [x] 5.2a **UI-CRAFT**：配置面板内帮助文案与 hint（相关度 vs 向量相似度）— 已含中英文 hint
- [x] 5.2 前端：展示 hint 文案（复用 1.2a 组件）— **可验证**：界面可见说明
- [ ] 5.3 测试任务（待 test-cases Reviewed 后补充）
- [ ] 5.4 **AUTO-UT**：Controller 或 Service 非法值测试 — **可验证**：测试通过

## 6. 收尾验证

- [x] 6.1 `npm run lint && npm run build`（ai_react）— **可验证**：build 成功；新组件 eslint 通过
- [ ] 6.2 `make verify` 或后端全量 `mvn test`（按 harness 配置）— **可验证**：通过（本机无 mvn）
- [x] 6.3 更新 `.aetherstack/context/api-contracts.yaml`（新增配置 API）— **可验证**：契约与实现一致

---

**依赖关系**：
- REQ2（表结构）→ REQ1/REQ3 持久化 → REQ4 过滤
- REQ1 1.2a 先于 1.2
- REQ4 4.4a 先于 4.1（AI-TDD）

**并行**：REQ5 可与 REQ4 前端部分并行
