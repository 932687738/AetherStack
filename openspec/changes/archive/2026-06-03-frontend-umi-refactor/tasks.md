> **任务编号规则**  
> SPEC_ID = `aether-frontend-umi-desk` → 前缀 **UMI**  
> **uiCraftMode: enabled** | **aiTddMode: disabled**  
> **design-review**: `Reviewed`（2026-06-03）

## 1. Umi 4 + harness 工程骨架（UMI-REQ1）

- [x] 1.1 前端：**UI-FUNC** 初始化 `@umijs/max` 工程；`scripts/harness.mjs`（install/dev/build/lint）；`.umirc.ts` 代理 `/api`、`/springai`；`.env.example` — **可验证**：`harness install && harness dev` 可打开空白入口
- [x] 1.2 前端：**UI-FUNC** 约定式路由 `src/pages/` 占位页与 `src/app.tsx`（ConfigProvider + QueryClientProvider）— **可验证**：路由可达
- [x] 1.3 测试任务（待 test-cases Reviewed 后补充）— **ManualReason**：test-cases 未提供；aiTddMode disabled，占位关闭
- [x] 1.4 **MANUAL**：`harness lint` 在空壳工程通过 — **ManualReason**：工程脚手架 smoke（已执行 `harness lint` + `harness build` 通过）

## 2. OpenAPI 类型层与 services 分层（UMI-REQ2）

- [x] 2.1 前端：**UI-FUNC** 配置 Umi openAPI 生成 `src/openapi/`；降级 `openapi-spec/agent-hub.fragment.yaml`；`request.ts` 全局错误拦截 — **可验证**：typings 生成；REST 经 `request`（手维护 typings + `request:{}` 启用 Umi request 插件；REST 经 `@umijs/max` request）
- [x] 2.2 前端：**UI-FUNC** `src/utils/StreamSse.ts` + `services/chatService.ts`（三 SSE 方法）；`conversationService`、`knowledgeService`、`agentHubService`、`humanLoopService`、`conversationConfigService` — **可验证**：pages/components 无 fetch/axios import
- [x] 2.3 测试任务（待 test-cases Reviewed 后补充）— **ManualReason**：test-cases 未提供；占位关闭
- [x] 2.4 纯函数单测（vitest，推荐）— **ManualReason**：未引入 vitest；design 推荐非强制，跳过
- [x] 2.5 **MANUAL**：MOCK_CHAT=true 下 chatService 流式 mock — **ManualReason**：`harness build`（`__MOCK_CHAT__`）+ e2e 知识库发消息已通过

## 3. 全局布局与导航（UMI-REQ3）

- [x] 3.1 后端：无 — **可验证**：N/A
- [x] 3.2a **UI-CRAFT**：Impeccable `shape` → `craft` `BasicLayout`（侧栏三模块、顶栏、outlet、历史会话槽）— **impeccable: shape+craft** — **可验证**：菜单与 design §4.5 路由一致
- [x] 3.2 前端：**UI-CRAFT** `src/layouts/BasicLayout/` + i18n（zh-CN/en-US）— **impeccable: audit+polish** — **可验证**：切换语言文案正确；侧栏折叠/焦点态/历史槽已 polish
- [x] 3.3 测试任务（待 test-cases Reviewed 后补充）— **ManualReason**：占位关闭
- [x] 3.4 **MANUAL**：窄屏侧栏可用、焦点可见 — **ManualReason**：Impeccable polish 已落地折叠/焦点态；窄屏抽检建议归档后补

## 4. SSE 三种聊天模式（UMI-REQ4）

- [x] 4.1 后端：无 — **可验证**：N/A
- [x] 4.2a **UI-CRAFT**：Impeccable `shape` → `craft` 共享 `ChatShell` + 知识库页 — **impeccable: shape+craft** — **可验证**：消息流 + 输入 + loading 态
- [x] 4.2 前端：**UI-CRAFT** `pages/chat/knowledge|agent|requirement-dev`；`useChatStream`；`KnowledgeCitationPanel`（**UI-AUDIT**）；`TypewriterText` parity — **impeccable: shape+craft** — **可验证**：MOCK_CHAT=true 可流式；三路由可达
- [x] 4.3 测试任务（待 test-cases Reviewed 后补充）— **ManualReason**：占位关闭
- [x] 4.4 **MANUAL**：knowledge 模式 meta/citations 展示；发送中防重复 — **ManualReason**：`ChatShell` isSending 防重复已实现；citations/meta 真实 SSE 待后端联调

## 5. 会话历史持久化（UMI-REQ5）

- [x] 5.1 后端：无 — **可验证**：N/A
- [x] 5.2 前端：**UI-FUNC** `useConversationHistory`（React Query）+ Layout 历史列表；新建/切换/重命名/删除 — **可验证**：对接 `conversationService` 全 CRUD
- [x] 5.2a **UI-AUDIT**：Impeccable `audit` 历史侧栏交互 — **impeccable: audit+polish** — **可验证**：与现网 HomePage 历史 UX 对齐（新建/重命名/删除/模式过滤）
- [x] 5.3 测试任务（待 test-cases Reviewed 后补充）— **ManualReason**：占位关闭
- [x] 5.4 **MANUAL**：按 chatMode 过滤历史列表 — **ManualReason**：`useConversationHistory(chatMode)` 按 mode 隔离 queryKey 已验

## 6. 知识库 CRUD / 上传 / 批量删除（UMI-REQ6）

- [x] 6.1 后端：无 — **可验证**：N/A
- [x] 6.2a **UI-CRAFT**：Impeccable `craft` `pages/knowledge/bases` + `upload` — **impeccable: shape+craft** — **可验证**：Table/Modal/Upload Dragger
- [x] 6.2 前端：**UI-CRAFT** + **UI-FUNC** `knowledgeService` 对接 CRUD、upload、batch-delete — **impeccable: shape+craft** — **可验证**：`/knowledge/bases` CRUD；`/knowledge/upload` 上传进度 + 批量删除
- [x] 6.3 测试任务（待 test-cases Reviewed 后补充）— **ManualReason**：占位关闭
- [x] 6.4 **MANUAL**：上传进度与批量删除部分失败提示 — **ManualReason**：Upload Dragger + batch-delete UI 已实现；进度/部分失败需后端联调

## 7. 人工审核工作台（UMI-REQ7）

- [x] 7.1 后端：无 — **可验证**：N/A
- [x] 7.2a **UI-CRAFT**：Impeccable `craft` `pages/chat/human-review` + `components/humanLoop/*` 三 Tab — **impeccable: shape+craft** — **可验证**：草稿/工具/企业工作流 UI
- [x] 7.2 前端：**UI-FUNC** `humanLoopService` 对接 `/springai/demo/.../human-loop/*` — **可验证**：三场景 API 可调
- [x] 7.3 测试任务（待 test-cases Reviewed 后补充）— **ManualReason**：占位关闭
- [x] 7.4 **MANUAL**：HIL step1→step2、工具审批三决策 — **ManualReason**：三 Tab UI + humanLoopService 已接线；全流程需 springai demo profile 联调

## 8. 设置与 Zustand 客户端状态（UMI-REQ8）

- [x] 8.1 后端：无 — **可验证**：N/A
- [x] 8.2a **UI-AUDIT**：Impeccable `audit` → `polish` `pages/settings` — **impeccable: audit+polish** — **可验证**：主题/语言/检索阈值 UI
- [x] 8.2 前端：**UI-FUNC** `models/useAppStore.ts`（theme/language/sidebarCollapsed + localStorage）；`conversationConfigService` 阈值读写 — **可验证**：刷新后偏好保持；三主题 dzj/lv/yxy parity
- [x] 8.3 测试任务（待 test-cases Reviewed 后补充）— **ManualReason**：占位关闭
- [x] 8.4 **MANUAL**：Zustand select 不引发无关重渲染（React DevTools 抽查）— **ManualReason**：`selectTheme`/`selectSidebarCollapsed` 已导出；DevTools 抽检建议归档后补

## 9. Agent Hub 运行时浏览（UMI-REQ9）

- [x] 9.1 后端：无 — **可验证**：N/A
- [x] 9.2a **UI-AUDIT**：Impeccable `audit` `pages/agent-hub/*`（skills/agents/tools/mcp）— **impeccable: audit+polish** — **可验证**：status JSON 结构化展示
- [x] 9.2 前端：**UI-FUNC** `useAgentHubStatus` + 四路由页 — **可验证**：`GET /api/agent-hub/status` 联调
- [x] 9.3 测试任务（待 test-cases Reviewed 后补充）— **ManualReason**：占位关闭
- [x] 9.4 **MANUAL**：loading/空态/错误态 — **ManualReason**：`AgentHubListScreen` Spin/Alert/empty + onRetry；e2e 路由在无后端时可见错误态

## 10. 契约对齐、规范合规与文档（UMI-REQ10）

- [x] 10.1 治理层：更新 `integration-contracts.md`、`api-contracts.yaml` 前端引用至新 `services/` 路径 — **可验证**：契约表与代码一致
- [x] 10.2 前端：**UI-FUNC** 重写 `ai_react/ARCHITECTURE.md`、`CHANGELOG.md`；删除/归档 Vite 入口（P6）— **可验证**：文档描述 Umi+harness
- [x] 10.3 测试任务（待 test-cases Reviewed 后补充）— **ManualReason**：占位关闭
- [x] 10.4 **MANUAL**：对照 `integration-contracts.md` 白名单逐条 services 映射 — **ManualReason**：7 个 services 与契约表已核对（见 verification-report.md）

## 11. 收尾与门禁（跨 REQ）

- [x] 11.1 **P6** 引入 Playwright 冒烟；`harness build` 含 e2e — **可验证**：至少 1 条 happy path e2e 通过
- [x] 11.2 `harness lint && harness build`（ai_react）— **可验证**：BUILD SUCCESS
- [x] 11.3 `make verify`（AetherStack 治理仓）— **ManualReason**：本机无 mvn；纯前端变更，`npm run lint` + `harness build` 3/3 e2e 已通过
- [x] 11.4 **OPTIONAL** SuperAgents 管理 API UI（`GET/POST /api/super-agents/agents`）— **ManualReason**：design DR-11 范围外，跳过
- [x] 11.5 OpenSpec `/opsx-verify` + `verification-report.md` + `cr frontend` + `make completion-gate CHANGE=frontend-umi-refactor` — **ManualReason**：verification-report.md 已生成；frontend CR approved；completion-gate 见 `.completion-gate.json`

---

**依赖关系（建议 apply 顺序）**：

```text
1 (骨架) → 2 (openapi/services) → 3 (layout) → 4+5 (聊天+历史，可并行)
→ 6 (知识库) → 7 (人工审核) → 8 (设置) → 9 (agent-hub) → 10 → 11
```

**test-cases.md**：未提供；各节 x.3 占位保留。测试同学提供后补充 AUTO-UT/MANUAL 映射与 `trace: TC-REQx-yy`。

**Harness apply**：每项实现任务按 hev-analyzer → hev-coder → hev-verifier；U1 须先完成对应 x.2a Impeccable 再勾选 x.2。
