> **任务编号规则**：`aether-agent-app-variables-REQ-x`

## 1. 管理员定义 Agent 变量（REQ-1）

- [ ] 1.1 **后端**：Flyway 增加 `agent_registry.variables`；`AgentAppVariable` 值对象 + `AgentRegistryEntry` 扩展；`AgentRegistryApplicationService.updateVariables` — **可验证**：`mvn test -pl aether-platform -Dtest=AgentAppVariableValidatorTest`
- [ ] 1.2 **后端**：`AgentRegistryController` 增加 variables 更新 API + DTO — **可验证**：MockMvc 或单测返回 200 且 JSON 含 variables
- [ ] 1.2a **UI-CRAFT** Impeccable：`PlatformAgentRegistryManager` 变量 Drawer（shape+craft） — **可验证**：`impeccable: shape+craft`；页面可增删变量行
- [ ] 1.3 **UI-FUNC**：`platformAgentRegistryService` + `platformAgentRegistry.ts` 类型扩展 — **可验证**：lint 通过
- [ ] 1.4 **AUTO-UT**：`AgentAppVariableValidatorTest` 覆盖变量名/长度校验 — **可验证**：`mvn -Dtest=AgentAppVariableValidatorTest test`
- [ ] 1.5 **AUTO-UT**：执行 `mvn -pl aether-platform -Dtest=AgentAppVariableValidatorTest test` — **可验证**：BUILD SUCCESS
- [ ] 1.6 **MANUAL**：管理端保存变量后刷新仍可见 — **ManualReason**：需联调后端

## 2. Prompt 模板引用变量（REQ-2）

- [ ] 2.1 **后端**：Chat 请求 DTO 增加 `sessionVariables`；`PlatformAgentAdapter` 调用 `PlatformPromptTemplateRenderer.render` — **可验证**：单测断言 `{{user_name}}` 被替换
- [ ] 2.2 **后端**：必填变量缺失时应用层返回 400 — **可验证**：`AgentChatVariablesGuardTest`
- [ ] 2.3 测试任务（待 test-cases Reviewed 后补充）
- [ ] 2.4 **AUTO-UT**：`PlatformAgentAdapterVariablesTest` Mock renderer — **可验证**：mvn test 通过
- [ ] 2.5 **AUTO-UT**：执行 scoped mvn test — **可验证**：BUILD SUCCESS

## 3. 对话前变量表单（REQ-3）

- [ ] 3.1 **UI-FUNC**：`ChatVariableFormModal` + 会话 store 缓存变量值 — **可验证**：未填必填变量时 `ChatShell` 阻断 send
- [ ] 3.2a **UI-CRAFT** Impeccable：变量 Modal shape+craft — **可验证**：`impeccable: shape+craft`
- [ ] 3.3 **UI-FUNC**：`chatService` / SSE 请求携带 `sessionVariables` — **可验证**：network 面板可见字段
- [ ] 3.4 测试任务（待 test-cases Reviewed 后补充）
- [ ] 3.5 **MANUAL**：首次进入 Agent 对话弹出表单，同会话不重复 — **ManualReason**：E2E 联调

## 4. 变量安全与大小限制（REQ-4）

- [ ] 4.1 **后端**：变量值 1KB 上限 + 复用 `sanitizeUserInput` — **可验证**：`AgentAppVariableValidatorTest` 超长用例
- [ ] 4.2 **前端**：表单 maxLength + 提交前校验 — **可验证**：超长输入提示错误
- [ ] 4.3 测试任务（待 test-cases Reviewed 后补充）
- [ ] 4.4 **AUTO-UT**：前后端校验单测 — **可验证**：mvn test + harness lint

## 5. 集成与门禁

- [ ] 5.1 **MANUAL**：`harness lint` + `harness build`（ai_react） — **可验证**：E2E 冒烟通过
- [ ] 5.2 **MANUAL**：`make verify`（AetherStack 治理仓） — **可验证**：backend + frontend 全绿
- [ ] 5.3 **MANUAL**：`make completion-gate CHANGE=add-app-variables` — **可验证**：`.completion-gate.json` ready

---

**依赖**：1.x → 2.x → 3.x；4.x 可与 2.x 并行。
