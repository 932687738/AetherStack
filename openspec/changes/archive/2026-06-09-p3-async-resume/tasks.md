> **uiCraftMode: disabled** | **aiTddMode: disabled** | **design-review**: Reviewed（2026-06-09）

## 0. Repository 查询（collaboration REQ-3 前置）

- [x] 0.1 后端：`WorkflowSuspendRepository.findActiveSuspendedBySession` + Mapper/SQL — **可验证**：编译通过
- [x] 0.2 测试：**AUTO-UT** `MyBatisWorkflowSuspendRepositorySessionTest` — trace: TC-REQ3-02 → MyBatisWorkflowSuspendRepositorySessionTest

## 1. 挂起验收（REQ-1）

- [x] 1.1 测试：**AUTO-UT** `WorkflowSuspendServiceTest` — trace: TC-REQ1-01
- [x] 1.2 测试：**AUTO-UT** `HumanApprovalSkillGraphNodeTest` — trace: TC-REQ1-02

## 2. 唤醒验收（REQ-2）

- [x] 2.1 测试：**AUTO-UT** 补强 `WorkflowResumeServiceTest` DisplayName — trace: TC-REQ2-01
- [x] 2.2 测试：**AUTO-UT** 补强 `SuperAgentWebhookControllerTest` resume 用例 — trace: TC-REQ2-02

## 3. 查询验收（REQ-3）

- [x] 3.1 测试：**AUTO-UT** 补强 `WorkflowSuspendQueryServiceTest` — trace: TC-REQ3-01

## 4. Chat 继续桥接（collaboration REQ-3）

- [x] 4.1 后端：`SuspendedSessionResumeBridge` + `SuperAgentChatApplicationService` 挂起分支 — trace: TC-REQ3-03
- [x] 4.2 测试：**AUTO-UT** `SuperAgentChatSuspendedResumeTest` — trace: TC-REQ3-03 → SuperAgentChatSuspendedResumeTest

## 5. 治理与验证

- [x] 5.1 治理：更新 `docs/ROADMAP.md` — **可验证**：async-resume / collaboration REQ-3 已消化
- [x] 5.2 验证：`mvn -pl aether-platform test`（scoped *Test）— **可验证**：BUILD SUCCESS
