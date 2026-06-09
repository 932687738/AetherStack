# 测试用例（standard-spec-driven）

## 0. 测试基线来源

- Source：`OpenSpec 派生（依据 spec/design，design-review Reviewed）`
- Status：`Reviewed`

---

## 1. 用例主体

# [S] 异步挂起与唤醒（async-resume）

## [S] Requirement 1：长时间 Skill 挂起

### [C] TC-REQ1-01 WorkflowSuspendService 写库与事件
[Automation] `AUTO-UT`
#### 步骤1
调用 `suspend(tenant, session, skill, graphState, message)`
##### 预期结果
- `workflowSuspendRepository.insert` 被调用；status=SUSPENDED
- `markSuspended(true)`；`publishSuspended`

### [C] TC-REQ1-02 审批节点未批准时挂起
[Automation] `AUTO-UT`
#### 步骤1
`HumanApprovalSkillGraphNode.execute` 且 `HUMAN_APPROVAL_GRANTED=false`
##### 预期结果
- 调用 `WorkflowSuspendService.suspend`；state 含 resumeToken

## [S] Requirement 2：Webhook 唤醒

### [C] TC-REQ2-01 resumeByToken 状态迁移
[Automation] `AUTO-UT`
#### 步骤1
`WorkflowResumeService.resumeByToken(validToken)` mock SUSPENDED 记录
##### 预期结果
- `markResumed`；`markSuspended(false)`；`publishResume`；SSE 2 段

### [C] TC-REQ2-02 Controller resume 入口
[Automation] `AUTO-UT`
#### 步骤1
`SuperAgentWebhookController.resume` body 含 resumeToken
##### 预期结果
- 委托 `WorkflowResumeService.resumeByToken`

## [S] Requirement 3：挂起状态可查询

### [C] TC-REQ3-01 列表与详情
[Automation] `AUTO-UT`
#### 步骤1
`WorkflowSuspendQueryService.list` / `getDetail`
##### 预期结果
- 租户参数传入 repository；详情含 skillName / pending 摘要

# [S] 协作跨会话恢复（collaboration REQ-3）

## [S] Requirement 3：跨会话恢复挂起流程

### [C] TC-REQ3-03 chat 继续桥接
[Automation] `AUTO-UT`
#### 步骤1
`streamAgentChat` 且 session 挂起、userInput=`继续`
##### 预期结果
- `findActiveSuspendedBySession` → `resumeByToken`；非静态 block 文案

---

## 3. AUTO-UT 标记汇总

| TC | REQ | 目标测试类 |
|----|-----|------------|
| TC-REQ1-01 | async-resume-1 | `WorkflowSuspendServiceTest` |
| TC-REQ1-02 | async-resume-1 | `HumanApprovalSkillGraphNodeTest` |
| TC-REQ2-01 | async-resume-2 | `WorkflowResumeServiceTest` |
| TC-REQ2-02 | async-resume-2 | `SuperAgentWebhookControllerTest` |
| TC-REQ3-01 | async-resume-3 | `WorkflowSuspendQueryServiceTest` |
| TC-REQ3-02 | async-resume-3 | `MyBatisWorkflowSuspendRepositorySessionTest` |
| TC-REQ3-03 | collaboration-3 | `SuperAgentChatSuspendedResumeTest` |
