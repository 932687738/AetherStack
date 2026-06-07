# 挂起工作流管理 - 整体方案（Draft）

## 一、核心问题

**要解决什么问题**：SuperAgents 已有挂起（`WorkflowSuspendService`）与 Webhook 恢复（`POST /hooks/resume`），但缺少挂起记录的查询、搜索与管理入口，运维无法在控制台审阅并执行关闭/清理。

**技术挑战**：
- 在**不破坏**既有 resumeToken + SSE 恢复语义的前提下扩展 REST 管理面
- `agent_workflow_suspend` 当前仅支持 `SUSPENDED` / `RESUMED`，需引入 `CLOSED` 及删除策略
- 前端恢复操作需对接 SSE 流，与列表/详情 CRUD 模式不同
- 租户隔离须贯穿查询与写操作

---

## 二、整体思路

**业务场景**：
- 运维查看挂起列表 → 分页 GET + 筛选
- 定位单条记录 → GET detail by resumeToken
- 决定恢复 → 复用 `POST /hooks/resume`（SSE）
- 决定放弃 → POST close → 状态 CLOSED + 解除会话 suspended
- 清理历史 → DELETE（仅 RESUMED/CLOSED）

**技术实现思路**：
- **后端**：在 `SuperAgentWebhookController` 新增管理端点；抽取 `WorkflowSuspendQueryService` / `WorkflowSuspendAdminService` 应用层用例；扩展 `WorkflowSuspendRepository` + Mapper（分页查询、markClosed、delete）；`WorkflowResumeService` 保持不变
- **前端**：新增 `/agent-hub/suspended-workflows` 页面 + `platformSuspendedWorkflowService`；列表 ProTable + 详情 Drawer；恢复用 `fetch` SSE 或复用 `SuperAgentSse` 工具
- **数据**：不新建表；`status` 枚举扩展 `CLOSED`；可选新增 `closed_at` 列（Flyway V*）；补充 `(tenant_id, status, created_at)` 索引

---

## 三、技术选型

| 功能场景 | 技术组件 | 使用理由 |
|---------|---------|---------|
| 列表/详情/关闭/删除 | Spring WebFlux REST + 应用服务 | 与现有 superAgents web 层一致；恢复保持 SSE |
| 分页查询 | MyBatis + LIMIT/OFFSET | 沿用 WorkflowSuspendMapper 模式 |
| 会话挂起标记 | `ConversationSessionSnapshotService.markSuspended` | 与 resume/close 对称 |
| 前端列表 | Ant Design Table + TanStack Query | 对齐 platform-agents 等运维页 |
| 前端恢复 SSE | `SuperAgentSse` / `fetch` stream | 对齐既有 chat resume 消费方式 |
| UI 视觉 | Impeccable shape+craft | `uiCraftMode: auto` 命中 U1 |

不涉及 CompiledGraph / ReactAgent / RAG 变更（`aiTddMode: disabled`）。

---

## 四、影响范围

### 系统间影响
- 无跨系统 MQ；外部 Webhook 恢复调用**不变**

### 模块改动
- **ai** `superAgents/web/SuperAgentWebhookController` — 新增 4~5 个端点
- **ai** `application/async` — 新增 Query/Admin 服务
- **ai** `domain/async/WorkflowSuspendRepository` — 扩展接口
- **ai** `infrastructure/async` — Mapper XML + 实现
- **ai** `db/migration` — 可选 closed_at + 索引
- **ai_react** — 新页面、service、ApiPaths、menu、i18n
- **AetherStack** — api-contracts.yaml

### 接口变更
- 新增：`GET /api/super-agents/hooks/suspended`（分页列表）
- 新增：`GET /api/super-agents/hooks/suspended/{resumeToken}`（详情）
- 新增：`POST /api/super-agents/hooks/suspended/{resumeToken}/close`
- 新增：`DELETE /api/super-agents/hooks/suspended/{resumeToken}`
- 保持：`POST /api/super-agents/hooks/resume`（SSE，不变）

---

## 五、数据设计

### 数据模型关系
- `agent_workflow_suspend` 1:1 `resume_token`（唯一）
- 逻辑关联 `conversation_session_snapshot` via `(tenant_id, session_id)`

### 表结构要点
```sql
-- 修改表：agent_workflow_suspend（V14 已存在）
-- status 枚举扩展：SUSPENDED | RESUMED | CLOSED
-- 可选新增：closed_at TIMESTAMPTZ
-- 新增索引：idx_workflow_suspend_tenant_status (tenant_id, status, created_at DESC)
```

---

## 六、约束与风险

### 技术约束
- 恢复须先 DB 状态校验再清 suspended，顺序与 `WorkflowResumeService` 一致
- 关闭须拒绝已 RESUMED 记录
- 删除默认拒绝 SUSPENDED（须先 close）

### 风险点
| 风险 | 应对措施 |
|------|---------|
| 重复 resume | 保持 status 校验 + markResumed 原子 update |
| close 后会话仍 suspended | close 用例内调用 markSuspended(false) |
| graph_state 过大撑爆详情 API | 详情 DTO 只暴露 pendingMessage 等摘要字段 |
| resumeToken 泄露 | 列表可脱敏展示；详情需租户校验 |

---

## 七、待 AI 细化
- [ ] 完整 DDL（closed_at、索引）
- [ ] 接口 JSON、分页参数、错误码
- [ ] 时序图（列表/恢复/关闭/删除）
- [ ] 代码改造分析（Controller → Service → Repository）
- [ ] 前端 UI 界面清单（Impeccable）
- [ ] test-cases / tasks
