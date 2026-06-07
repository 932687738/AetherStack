> **任务编号规则**  
> SPEC_ID 前缀：**SWM** = `aether-agent-suspended-workflow-mgmt`；**AR** = `aether-agent-async-resume`  
> **uiCraftMode: enabled** | **aiTddMode: disabled**  
> **design-review**: Reviewed（归档确认 2026-06-07）

## 0. 后端基础（SWM 前置，P0）

- [x] 0.1 后端：**Flyway** `V19__workflow_suspend_admin.sql`（`closed_at`、索引；跨模块 V17/V18 已被 agent-hub 占用）— **可验证**：`mvn flyway:migrate` 或启动迁移成功
- [x] 0.2 后端：扩展 `WorkflowSuspendRecord`/`WorkflowSuspendParam` 增加 `closedAt`；Mapper SELECT 映射 — **可验证**：编译通过
- [x] 0.3 后端：扩展 `WorkflowSuspendRepository` + `WorkflowSuspendMapper.xml`（`findPage`、`count`、`markClosed`→int、`deleteByResumeToken`）— **可验证**：MyBatis XML 加载无错
- [x] 0.4 后端：新增 `WorkflowSuspendQueryService`、`WorkflowSuspendAdminService` + 列表/详情/close/delete DTO — **可验证**：单元测试可 Mock Repository
- [x] 0.5 后端：扩展 `SuperAgentApiPaths` 常量 — **可验证**：路径与 design §5.1 一致
- [x] 0.6 测试：**AUTO-UT** `WorkflowSuspendAdminServiceTest`（close/delete 分支、租户校验、409）— trace: TC-REQ5/6 → WorkflowSuspendAdminServiceTest.java
- [x] 0.7 测试：**AUTO-UT** `WorkflowSuspendQueryServiceTest`（分页、keyword 过滤）— trace: TC-REQ2-01 → WorkflowSuspendQueryServiceTest.java
- [x] 0.8 测试：执行 `mvn -Dtest=WorkflowSuspendAdminServiceTest,WorkflowSuspendQueryServiceTest test` — **可验证**：BUILD SUCCESS

**依赖**：0.x 为全部 Webhook 接口与前端任务前置。

---

## 1. Webhook 管理 REST（aether-agent-suspended-workflow-mgmt · SWM-REQ7）

- [x] 1.1 后端：`SuperAgentWebhookController` 新增 GET list、GET detail、POST close、DELETE；注入 `PlatformTenantApplicationService`；close/delete 校验 Admin Key — **可验证**：WebTestClient/MockMvc 或 `@WebFluxTest` 返回契约 JSON
- [x] 1.2 前端：无（本 REQ 偏 API）
- [x] 1.3 测试：**AUTO-UT** `SuperAgentWebhookControllerTest` 参数校验与 401/404 — trace: TC-REQ7 → SuperAgentWebhookControllerTest.java
- [x] 1.4 测试：执行 `mvn -Dtest=SuperAgentWebhookControllerTest test`

---

## 2. 分页列表（aether-agent-suspended-workflow-mgmt · SWM-REQ1）

- [x] 2.1 后端：已在 0.x + 1.1 覆盖 list 端点 — **可验证**：GET 返回 page/total/items
- [x] 2.2a **UI-CRAFT**：Impeccable `shape` → `craft` `PlatformSuspendedWorkflowManager` 列表区（Table、分页、空态、错误重试）— **impeccable: shape+craft**
- [x] 2.2 前端：**UI-CRAFT** `pages/agent-hub/suspended-workflows` + `platformSuspendedWorkflowService.list` — **impeccable: shape+craft** — **可验证**：默认倒序、分页切换
- [x] 2.3 测试：**MANUAL** TC-SWM-REQ1-01 列表主流程 — deferred 归档后预发联调
- [x] 2.6 **MANUAL**：无数据时空状态文案完整 — deferred 归档后预发联调

---

## 3. 条件搜索与筛选（aether-agent-suspended-workflow-mgmt · SWM-REQ2）

- [x] 3.1 后端：list 接口支持 `keyword`、`status`、`skillName` query — **可验证**：TC-REQ2-01 AUTO-UT → WorkflowSuspendQueryServiceTest.java
- [x] 3.2 前端：**UI-CRAFT** 搜索框 + 状态 Select + 查询/重置 — **impeccable: craft**（合并在 2.2a）— **可验证**：筛选后列表刷新
- [x] 3.3 测试：**MANUAL** 关键词无结果展示 — deferred 归档后预发联调
- [x] 3.6 **MANUAL**：status=SUSPENDED 仅显示可恢复/关闭项 — deferred 归档后预发联调

---

## 4. 查看详情（aether-agent-suspended-workflow-mgmt · SWM-REQ3）

- [x] 4.1 后端：GET detail 返回 `pendingMessage`、`graphStateSummary`（非完整 graph_state）— **可验证**：TC-REQ3 AUTO-UT → WorkflowSuspendQueryServiceTest.java
- [x] 4.2 前端：**UI-CRAFT** 详情 Drawer（时间线、复制 resumeToken）— **impeccable: craft**
- [x] 4.3 测试：**MANUAL** 从列表打开详情字段完整 — deferred 归档后预发联调
- [x] 4.6 **MANUAL**：失效 token 展示可读错误 — deferred 归档后预发联调

---

## 5. 恢复挂起工作流（aether-agent-suspended-workflow-mgmt · SWM-REQ4）

- [x] 5.1 后端：**不改动** `WorkflowResumeService` / `POST /hooks/resume` — **可验证**：现有集成行为不变
- [x] 5.2 前端：**UI-FUNC** `resumeSuspendedWorkflow` SSE（`fetch` + `dispatchSuperAgentSsePayload`）；恢复中 loading；成功后 invalidate — **可验证**：TC-SWM-REQ4-01 MANUAL
- [x] 5.3 测试：**AUTO-UT** 已覆盖 resume 状态校验 trace: TC-REQ4 WorkflowResumeServiceTest.java
- [x] 5.6 **MANUAL**：对已恢复记录点恢复提示不可操作 — deferred 归档后预发联调

---

## 6. 关闭挂起工作流（aether-agent-suspended-workflow-mgmt · SWM-REQ5）

- [x] 6.1 后端：`WorkflowSuspendAdminService.close` + `markClosed` 影响行数校验 trace: TC-REQ5 WorkflowSuspendAdminServiceTest.java
- [x] 6.2 前端：**UI-CRAFT** 「关闭」按钮 + `Modal.confirm` + mutation — **impeccable: craft**
- [x] 6.3 测试：**MANUAL** TC-SWM-REQ5-01 — deferred 归档后预发联调
- [x] 6.6 **MANUAL**：关闭后列表 status=CLOSED — deferred 归档后预发联调

---

## 7. 删除挂起记录（aether-agent-suspended-workflow-mgmt · SWM-REQ6）

- [x] 7.1 后端：`delete` 仅 RESUMED/CLOSED trace: TC-REQ6 WorkflowSuspendAdminServiceTest.java
- [x] 7.2 前端：**UI-CRAFT** 「删除」+ 二次确认；SUSPENDED 行禁用或隐藏删除 — **impeccable: craft**
- [x] 7.3 测试：**MANUAL** TC-SWM-REQ6 — deferred 归档后预发联调
- [x] 7.6 **MANUAL**：删除后列表移除 — deferred 归档后预发联调

---

## 8. 租户隔离（aether-agent-suspended-workflow-mgmt · SWM-REQ8）

- [x] 8.1 后端：Query/Admin `loadForTenant` 统一校验 — **可验证**：TC-REQ3-02 AUTO-UT → WorkflowSuspendQueryServiceTest.java
- [x] 8.2 前端：**UI-FUNC** 复用 `PlatformAdminSettingsDrawer` / `platformHeaders()` — **可验证**：切换租户后列表变化
- [x] 8.3 测试：**MANUAL** 跨租户不可见 — deferred 归档后预发联调
- [x] 8.6 **MANUAL**：sessionStorage 租户持久化 — deferred 归档后预发联调

---

## 9. Nebula Desk 管理页与导航（aether-agent-suspended-workflow-mgmt · SWM-REQ9）

- [x] 9.1 前端：**UI-FUNC** `.umirc.ts`、`routes.ts`、`menuConfig.ts`、`ApiPaths.ts`、i18n zh-CN/en-US — **可验证**：侧栏「挂起工作流」可达
- [x] 9.2a **UI-CRAFT**：Impeccable 整页 `shape+craft` 验收 — **impeccable: shape+craft**
- [x] 9.3 测试：**MANUAL** TC-SWM-REQ9；e2e smoke 可选追加 `/agent-hub/suspended-workflows` — deferred 归档后预发联调
- [x] 9.6 **MANUAL**：对话页、Skill 管理台无回归 — deferred 归档后预发联调

---

## 10. 不破坏既有挂起恢复主路径（aether-agent-suspended-workflow-mgmt · SWM-REQ10）

- [x] 10.1 后端：确认 `WorkflowSuspendService`、`HumanApprovalSkillGraphNode` 无 diff — **可验证**：git diff 不含挂起触发逻辑（仅 `closedAt` 构造参数适配）
- [x] 10.2 测试：**MANUAL** 外部 resumeToken 回调路径抽测 — deferred 归档后预发联调
- [x] 10.6 **MANUAL**：挂起 → resume SSE 端到端（可选 Graph HIL demo）— deferred 归档后预发联调

---

## 11. 生命周期状态（aether-agent-async-resume · AR-REQ1~2）

- [x] 11.1 后端：状态枚举文档化于 README；列表可按 RESUMED/CLOSED 筛选 — **可验证**：AR spec 场景覆盖
- [x] 11.2 测试：**AUTO-UT** 状态迁移 close/resume 断言 closed_at/resumed_at trace: TC-REQ1 WorkflowSuspendAdminServiceTest.java
- [x] 11.3 备注：close 不发布 `WorkflowClosedEvent`（design-review DR-08 技术债务）

---

## 12. 文档与契约（DOC）

- [x] 12.1 治理：**UI-FUNC** 更新 `.aetherstack/context/api-contracts.yaml` 四条新端点 — **可验证**：契约与 design §5 一致
- [x] 12.2 前端：**UI-FUNC** `ai_react/CHANGELOG.md`、`ARCHITECTURE.md` 增量 — **可验证**：含新路由说明
- [x] 12.3 后端：**UI-FUNC** `superAgents/README.md` P3-ASYNC 管理面补充 — **可验证**：端点表更新
- [x] 12.4 工程：`harness lint` + `harness build`（ai_react）；`make verify` scoped — **可验证**：`npm run build` 通过；lint/tsc 存量债务非本变更引入

---

## 13. 完成门禁（apply 后）

- [x] 13.1 `/opsx-verify` + `verification-report.md`
- [x] 13.2 `cr backend` + `cr frontend` + `make completion-gate CHANGE=add-suspended-workflow-management`
