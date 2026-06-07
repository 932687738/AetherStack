# 测试用例（standard-spec-driven）

## 0. 测试基线来源

- Source：`OpenSpec 派生（待测试同学 Reviewed）`
- OpenSpec 基线：`specs/aether-agent-suspended-workflow-mgmt/spec.md` + `design.md`
- 外部测试基线：无
- 采用方式：仅 OpenSpec（测试同学未单独提供稿）
- Status：`Draft`

> 说明：正式测试稿可由测试同学覆写本节；当前用例由 spec/design 派生，用于 tasks 占位与开发自测。

---

## 1. 用例主体

# [S] 挂起工作流管理 API

## [S] Requirement 1–2：列表与搜索

### [C] TC-SWM-REQ1-01 分页列表主流程
查询当前租户挂起记录分页列表，默认按创建时间倒序。
[Automation]
`MANUAL`
[ManualReason]
需 PostgreSQL 测试数据 + 后端联调

[前置条件]
- 租户 default 存在 ≥1 条 SUSPENDED 记录

#### 步骤1
GET `/api/super-agents/hooks/suspended?page=1&pageSize=20`，Header `X-Tenant-Id: default`

##### 预期结果
- HTTP 200
- `items` 非空；含 sessionId、skillName、status、createdAt、resumeTokenMasked

#### 可观测性断言
- 数据库断言：`agent_workflow_suspend.tenant_id = default`

### [C] TC-SWM-REQ2-01 关键词搜索
[Automation]
`AUTO-UT`
[ManualReason]
N/A

[前置条件]
- 存在 skillName 含 `refund` 的记录

#### 步骤1
调用 `WorkflowSuspendQueryService.list(..., keyword="refund", ...)`

##### 预期结果
- 返回项 skillName 匹配关键词

#### 可观测性断言
- 接口断言：total ≥ 1

---

## [S] Requirement 3：详情

### [C] TC-SWM-REQ3-01 详情存在
[Automation]
`AUTO-UT`

[前置条件]
- 已知有效 resumeToken

#### 步骤1
GET `/api/super-agents/hooks/suspended/{resumeToken}`

##### 预期结果
- HTTP 200；含 pendingMessage、status、时间字段

### [C] TC-SWM-REQ3-02 跨租户 404
[Automation]
`AUTO-UT`

#### 步骤1
租户 A 的 token，用租户 B 请求详情

##### 预期结果
- HTTP 404

---

## [S] Requirement 4：恢复

### [C] TC-SWM-REQ4-01 恢复挂起中记录
[Automation]
`MANUAL`
[ManualReason]
SSE 流式响应需端到端验证

#### 步骤1
POST `/api/super-agents/hooks/resume` body `{ "resumeToken": "..." }`

##### 预期结果
- SSE 含 progress `workflow/resumed` 与 token 正文
- DB status=RESUMED；conversation_session_snapshot.suspended=false

### [C] TC-SWM-REQ4-02 恢复非 SUSPENDED 拒绝
[Automation]
`AUTO-UT`

#### 步骤1
对已 RESUMED 记录再次 resume

##### 预期结果
- Flux 错误 / HTTP 4xx/5xx；状态不变

---

## [S] Requirement 5：关闭

### [C] TC-SWM-REQ5-01 关闭挂起中
[Automation]
`AUTO-UT`

#### 步骤1
POST `/api/super-agents/hooks/suspended/{token}/close`，Admin Key 有效

##### 预期结果
- HTTP 204；status=CLOSED；closed_at 非空；suspended=false

### [C] TC-SWM-REQ5-02 关闭已恢复拒绝
[Automation]
`AUTO-UT`

##### 预期结果
- HTTP 409

---

## [S] Requirement 6：删除

### [C] TC-SWM-REQ6-01 删除 CLOSED 记录
[Automation]
`AUTO-UT`

##### 预期结果
- HTTP 204；记录物理删除

### [C] TC-SWM-REQ6-02 删除 SUSPENDED 拒绝
[Automation]
`AUTO-UT`

##### 预期结果
- HTTP 409

---

## [S] Requirement 9：前端管理页

### [C] TC-SWM-REQ9-01 页面可达与列表展示
[Automation]
`MANUAL`
[ManualReason]
UI 交互 + Impeccable 验收

#### 步骤1
打开 `/agent-hub/suspended-workflows`

##### 预期结果
- 列表加载；搜索/筛选/详情 Drawer 可用

### [C] TC-SWM-REQ9-02 关闭二次确认
[Automation]
`MANUAL`

##### 预期结果
- Modal.confirm 后出现；确认后 Toast 成功

---

## 2. 口径冲突清单

无
