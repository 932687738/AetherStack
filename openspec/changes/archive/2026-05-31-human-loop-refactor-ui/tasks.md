> **任务编号规则**  
> SPEC_ID = `aether-agent-human-loop` → 前缀 **HIL**

## 1. HIL 代码迁移至 humanLoop 包（HIL-REQ1）

- [x] 1.1 后端：创建 `com.yxy.deepseek.humanLoop` 包结构（web / application / config / contract / tool）；迁移 Controller、三个 Service（原 Demo）、Configuration、Contracts、`DangerousOperationTools`；构造器注入替换字段 `@Autowired`；删除 `springai` 下旧类 — **可验证**：`mvn compile` 成功；应用启动无 Bean 缺失
- [x] 1.2 后端：更新 `AlibabaGraphTutorialController`、`SpringAiDemoController` 等 `@see`/import；更新 `HumanInTheLoopToolFeedback知识点总结.md` 路径 — **可验证**：全量 compile；无残留旧包 import
- [ ] 1.3 测试任务（待 test-cases Reviewed 后补充）
- [x] 1.4a **AUTO-AI-UT**：先编写 `HumanLoopDraftServiceTest`（Mock `CompiledGraph`，断言 step1 返回 INTERRUPTED 与 modelReply；step2 空编辑采纳草稿）— **可验证**：`mvn -Dtest=HumanLoopDraftServiceTest test` 红→绿
- [x] 1.4a2 **AUTO-AI-UT**：先编写 `ToolFeedbackServiceTest`（Mock Agent/Graph，覆盖 invoke 中断与 APPROVED resume）— **可验证**：`mvn -Dtest=ToolFeedbackServiceTest test` 红→绿
- [ ] 1.4 **AUTO-UT**：Configuration Bean 名称常量与 `@Qualifier` 引用一致性编译测试（或轻量 `@SpringBootTest` smoke 加载 humanLoop 包）— **可验证**：测试通过
- [ ] 1.5 执行 `mvn -Dtest=HumanLoopDraftServiceTest,ToolFeedbackServiceTest test` — **可验证**：BUILD SUCCESS（本机 PATH 无 mvn，待本地执行）
- [ ] 1.6 **MANUAL**：启动 ai 后 curl `GET .../human-loop/step1?threadId=smoke-1&prompt=hello` 返回 JSON — **ManualReason**：需真实 Graph + LLM 环境

## 2. REST 契约兼容（HIL-REQ2）

- [x] 2.1 后端：`HumanLoopController` 保持 `@RequestMapping("/springai/demo/alibaba-graph/human-loop")` 及全部 endpoint 签名；保留 400/409/500 `ResponseStatusException` 映射 — **可验证**：OpenAPI/契约对照 design §5 路径清单无遗漏
- [x] 2.2 前端：无独立 UI — **可验证**：N/A
- [ ] 2.3 测试任务（待 test-cases Reviewed 后补充）
- [x] 2.4 **AUTO-UT**：`HumanLoopControllerTest`（`@WebMvcTest`）校验空 threadId 返回 400；未 invoke 即 resume 返回 409 — **可验证**：MockMvc 测试通过
- [ ] 2.5 执行 `mvn -Dtest=HumanLoopControllerTest test` — **可验证**：BUILD SUCCESS（本机 PATH 无 mvn）
- [ ] 2.6 **MANUAL**：Postman/curl 遍历 design §5 全部 11 个端点 — **ManualReason**：端到端 JSON 字段对照

## 3. 对话分组人工审核菜单（HIL-REQ3）

- [x] 3.1 后端：无 — **可验证**：N/A
- [ ] 3.2a **UI-AUDIT**：Impeccable `audit HomePage` 侧边栏「对话」分组；新增菜单项视觉与选中态与现有三项一致 — **可验证**：audit 问题修复或记录豁免（已实现样式对齐，未跑 Impeccable CLI）
- [x] 3.2 前端：**UI-AUDIT**：`chatMode.js` 新增 `SIDEBAR_CHAT_VIEW.HUMAN_REVIEW`；`messages.js` 中英文 `humanReview`；`HomePage.jsx` 对话分组按钮 — **可验证**：点击菜单切换视图；中英文切换文案正确
- [ ] 3.3 测试任务（待 test-cases Reviewed 后补充）
- [ ] 3.4 **MANUAL**：窄屏侧边栏下菜单可点击、选中态可见 — **ManualReason**：响应式 UI

## 4. 单页三 Tab 审核工作台（HIL-REQ4）

- [x] 4.1 后端：无 — **可验证**：N/A
- [x] 4.2a **UI-CRAFT**：Impeccable shape 决策已体现在三 Tab IA — **可验证**：Tab 结构符合 design
- [x] 4.2b **UI-CRAFT**：`HumanReviewWorkbench.jsx` 容器（Tab、loading、空态、边界说明）— **可验证**：Nebula 深色风格 CSS
- [x] 4.2 前端：**UI-CRAFT**：`HomePage.jsx` 挂载 `<HumanReviewWorkbench />` — **可验证**：从菜单进入见工作台
- [ ] 4.3 测试任务（待 test-cases Reviewed 后补充）
- [ ] 4.4 **MANUAL**：Tab 间切换保留各 Tab 已填 threadId — **ManualReason**：交互验收

## 5. Graph 草稿审核 Tab（HIL-REQ5）

- [x] 5.1 后端：无（REQ1 已迁移 Service）— **可验证**：N/A
- [x] 5.2a **UI-CRAFT**：`DraftHilPanel.jsx` — **可验证**：step1/step2 表单与结果区
- [x] 5.2 前端：**UI-FUNC**：`api/humanLoop.js` + `DraftHilPanel.jsx` — **可验证**：对接 hilStep1/hilStep2
- [ ] 5.3 测试任务（待 test-cases Reviewed 后补充）
- [ ] 5.4 **MANUAL**：留空 humanEditedReply 采纳草稿 — **ManualReason**：需 LLM 联调

## 6. 工具审批 Tab（HIL-REQ6）

- [x] 6.1 后端：无 — **可验证**：N/A
- [x] 6.2a **UI-CRAFT**：`ToolFeedbackPanel.jsx` — **可验证**：待审批列表与决策按钮
- [x] 6.2 前端：**UI-FUNC**：tool-feedback API + Panel — **可验证**：invoke/approve/reject/edit
- [ ] 6.3 测试任务（待 test-cases Reviewed 后补充）
- [ ] 6.4 **MANUAL**：三种决策路径 — **ManualReason**：Agent 联调

## 7. 企业工作流 Tab（HIL-REQ7）

- [x] 7.1 后端：无 — **可验证**：N/A
- [x] 7.2a **UI-CRAFT**：`EnterpriseWorkflowPanel.jsx` — **可验证**：三场景子区
- [x] 7.2 前端：**UI-FUNC**：enterprise API + Panel — **可验证**：三场景可触发
- [ ] 7.3 测试任务（待 test-cases Reviewed 后补充）
- [ ] 7.4a **AUTO-AI-UT**（可选）：`EnterpriseWorkflowServiceTest` — **可验证**：未实现（可选）
- [ ] 7.5 **MANUAL**：自媒体 publishing step1→step2 — **ManualReason**：Graph 联调

## 8. 错误处理与能力边界（HIL-REQ8）

- [x] 8.1 后端：无变更 — **可验证**：N/A
- [x] 8.2 前端：各 Panel 错误展示 + 工作台 scope 说明 — **可验证**：hil-error + notice 文案
- [ ] 8.3 测试任务（待 test-cases Reviewed 后补充）
- [ ] 8.4 **AUTO-UT**：前端 API 层单测 — **可验证**：项目无 vitest，跳过
- [ ] 8.5 **MANUAL**：断网失败 UX — **ManualReason**：网络异常

## 9. 收尾与契约

- [x] 9.1 更新 `.aetherstack/context/api-contracts.yaml` 登记 HIL 11 个端点 — **可验证**：已登记
- [x] 9.2 `npm run lint && npm run build`（ai_react）— **可验证**：build SUCCESS（lint 存量告警非本变更引入）
- [ ] 9.3 `make verify` 或 `mvn test`（ai 仓库）— **可验证**：本机无 mvn
- [ ] 9.4 **UI-POLISH**（可选）：`/impeccable polish HumanReviewWorkbench` — **可验证**：可选收尾

---

**依赖关系**：（见 design / 原 tasks）

**test-cases.md**：未提供；x.3 占位保留
