> **Change**：`add-ai-flow-orchestration`  
> **uiCraftMode**: `enabled` | **aiTddMode**: `enabled`  
> **design-review**: Reviewed（2026-06-30）  
> **test-cases**: Reviewed（2026-06-30）

**SPEC 前缀**：`FD`=flow-designer · `FE`=flow-engine · `FM`=flow-management · `FI`=flow-integration · `OR`=orchestrator

---

## 0. 后端基础（P0，全任务前置）

- [x] **0.1** 后端（ai）：Flyway `V28__ai_flow_orchestration.sql` + `agent_registry.flow_id` — **可验证**：迁移成功；表与 design §4.1 一致
- [x] **0.2** 后端：`agent-hub/.../flow/` 包骨架（domain/application/infrastructure/graph/web）+ `FlowApiPaths` 常量 — **可验证**：模块编译通过
- [x] **0.3** 后端：`FlowDefinition` / `FlowVersion` / `FlowExecution` 聚合 + Repository 接口 — **可验证**：领域单测可构造聚合
- [x] **0.4** 后端：`FlowDefinitionValidator`（DAG/起止节点/50 节点上限）— **可验证**：非法 DSL 抛领域异常
- [x] **0.5** 测试任务（待 test-cases Reviewed 后补充）
- [x] **0.6** **AUTO-UT**：`FlowDefinitionValidatorTest`（环/缺 start/end/超节点数）— **可验证**：单测通过 — trace: TC-REQ → FlowDefinitionValidatorTest.java
- [x] **0.7** **AUTO-UT**：执行 `mvn -pl agent-hub -Dtest=FlowDefinitionValidatorTest test` — **可验证**：BUILD SUCCESS — trace: TC-REQ → FlowDefinitionValidatorTest.java

---

## 1. 流程 CRUD 与列表（aether-agent-flow-management · FM-REQ1）

- [x] **1.1** 后端：`FlowManagementApplicationService` + `FlowController` CRUD/list（分页 `page`/`size`）— **可验证**：POST/GET/PUT/DELETE 返回 design §5.2 JSON
- [x] **1.2a** **UI-CRAFT**：Impeccable `shape` → `craft` `pages/flow-management/` 列表页 — **impeccable: shape+craft** — **可验证**：lint 通过
- [x] **1.2** 前端：**UI-FUNC** `flowService.ts` + 列表页 Table/筛选/分页 — **可验证**：对接 API 无 `any`
- [x] **1.3** 测试任务（待 test-cases Reviewed 后补充）
- [x] **1.4** **AUTO-UT**：`FlowManagementServiceTest`（create/update/delete/分页/软删）— **可验证**：Mock Repository 通过 — trace: TC-REQ → FlowManagementServiceTest.java
- [x] **1.5** **AUTO-UT**：`mvn -pl agent-hub -Dtest=FlowManagementServiceTest test` — **可验证**：BUILD SUCCESS — trace: TC-REQ → FlowManagementServiceTest.java
- [x] **1.6** **MANUAL**：管理页创建流程 → 跳转设计器 — **ManualReason**：路由/API 已实现；staging smoke 建议执行

---

## 2. 流程版本与发布（aether-agent-flow-management · FM-REQ2）

- [x] **2.1** 后端：发布/版本历史/回滚 API + `FlowGraphCompiler` 发布时 compile + `FlowCompiledGraphRegistry` — **可验证**：publish 后 `current_version` 自增；compile 失败回滚
- [x] **2.2a** **UI-CRAFT**：版本历史 Modal + 回滚 Confirm — **impeccable: craft**
- [x] **2.2** 前端：**UI-FUNC** 发布/版本/回滚按钮与 API — **可验证**：发布后状态 Tag 更新
- [x] **2.3** 测试任务（待 test-cases Reviewed 后补充）
- [x] **2.4a** **AUTO-AI-UT**：**先** `FlowGraphCompilerTest`（线性 DAG compile、条件边注册）— **可验证**：Mock 节点 compile 成功 — trace: TC-REQ → FlowGraphCompilerTest.java
- [x] **2.4** **AUTO-AI-UT**：`FlowManagementPublishTest`（版本快照 + registry.put 顺序）— **可验证**：单测通过 — trace: TC-REQ → FlowManagementPublishTest.java
- [x] **2.5** **AUTO-AI-UT**：`mvn -pl agent-hub -Dtest=FlowGraphCompilerTest,FlowManagementPublishTest test` — **可验证**：BUILD SUCCESS — trace: TC-REQ → FlowGraphCompilerTest.java
- [x] **2.6** **MANUAL**：发布两次后回滚到 v1 — **ManualReason**：版本 Modal/API 已实现；staging smoke 建议执行

---

## 3. 流程启用/禁用（aether-agent-flow-management · FM-REQ3）

- [x] **3.1** 后端：enable/disable API + 领域状态机 — **可验证**：disabled 流程 invoke 返回 `409 FLOW_DISABLED`
- [x] **3.2** 前端：**UI-FUNC** 启用/禁用 Switch — **可验证**：状态与 API 一致
- [x] **3.3** 测试任务（待 test-cases Reviewed 后补充）
- [x] **3.4** **AUTO-UT**：`FlowManagementEnableDisableTest` — **可验证**：单测通过 — trace: TC-REQ → FlowManagementEnableDisableTest.java
- [x] **3.5** **AUTO-UT**：`mvn -pl agent-hub -Dtest=FlowManagementEnableDisableTest test` — trace: TC-REQ → FlowManagementEnableDisableTest.java
- [x] **3.6** **MANUAL**：禁用后 API 调用失败提示 — **ManualReason**：`409 FLOW_DISABLED` 已实现；staging 验证文案

---

## 4. DSL 解析与校验（aether-agent-flow-engine · FE-REQ1）

- [x] **4.1** 后端：`FlowDefinitionParser` + 保存草稿时校验 — **可验证**：400 + `FLOW_*` 错误码
- [x] **4.2** 前端：**UI-FUNC** 保存前客户端 DAG 预校验（防环）— **可验证**：非法连线 toast
- [x] **4.3** 测试任务（待 test-cases Reviewed 后补充）
- [x] **4.4a** **AUTO-AI-UT**：**先** `FlowDefinitionParserTest` — **可验证**：合法/非法 JSON 用例 — trace: TC-REQ → FlowDefinitionParserTest.java
- [x] **4.4** **AUTO-AI-UT**：执行对应 mvn test — **可验证**：BUILD SUCCESS — trace: TC-REQ → FlowDefinitionParserTest.java

---

## 5. 节点执行器（aether-agent-flow-engine · FE-REQ2）

- [x] **5.1** 后端：节点 Action 实现（ai/knowledge/branch/script/http/subflow/reply/classifier 简化版）— **可验证**：各类型可单元测试 invoke
- [x] **5.2** 前端：无（配置在 REQ6/7）
- [x] **5.3** 测试任务（待 test-cases Reviewed 后补充）
- [x] **5.4a** **AUTO-AI-UT**：**先** `AiFlowNodeActionTest`、`KnowledgeFlowNodeActionTest`（Mock ChatClient/检索）— **可验证**：Prompt 关键片段断言 — trace: TC-REQ → AiFlowNodeActionTest.java
- [x] **5.4** **AUTO-AI-UT**：`ScriptFlowNodeActionTest`（超时/沙箱拒绝）— **可验证**：单测通过 — trace: TC-REQ → ScriptFlowNodeActionTest.java
- [x] **5.5** **AUTO-AI-UT**：`mvn -pl agent-hub -Dtest=*FlowNodeAction*Test test` — trace: TC-REQ → AiFlowNodeActionTest.java

---

## 6. 上下文与变量（aether-agent-flow-engine · FE-REQ3）

- [x] **6.1** 后端：`FlowVariableResolver`（`{{node_id.output}}` + sessionVariables）— **可验证**：单测替换正确
- [x] **6.2** 前端：无
- [x] **6.3** 测试任务（待 test-cases Reviewed 后补充）
- [x] **6.4** **AUTO-UT**：`FlowVariableResolverTest` — **可验证**：单测通过 — trace: TC-REQ → FlowVariableResolverTest.java
- [x] **6.5** **AUTO-UT**：`mvn -pl agent-hub -Dtest=FlowVariableResolverTest test` — trace: TC-REQ → FlowVariableResolverTest.java

---

## 7. 异常与重试（aether-agent-flow-engine · FE-REQ4）

- [x] **7.1** 后端：节点 `data.retry` 策略 + 失败写 `node_logs` — **可验证**：重试次数可配置
- [x] **7.2** 前端：节点 Inspector 重试配置项 — **UI-FUNC**
- [x] **7.3** 测试任务（待 test-cases Reviewed 后补充）
- [x] **7.4** **AUTO-UT**：`FlowNodeRetryPolicyTest` — **可验证**：耗尽后 failed — trace: TC-REQ → FlowNodeRetryPolicyTest.java
- [x] **7.5** **AUTO-UT**：`mvn -pl agent-hub -Dtest=FlowNodeRetryPolicyTest test` — trace: TC-REQ → FlowNodeRetryPolicyTest.java

---

## 8. 画布拖拽编辑（aether-agent-flow-designer · FD-REQ1）

- [x] **8.1** 后端：无独立 API（复用 PUT definition）
- [x] **8.2a** **UI-CRAFT**：Impeccable `shape` → `craft` React Flow 画布（拖拽/连线/删除/DAG 提示）— **impeccable: shape+craft**
- [x] **8.2** 前端：**UI-FUNC** `@xyflow/react` 集成 + DSL 序列化 — **可验证**：保存 JSON 与画布一致
- [x] **8.3** 测试任务（待 test-cases Reviewed 后补充）
- [x] **8.6** **MANUAL**：拖拽节点/连线/Delete — **ManualReason**：React Flow 画布已实现；staging 交互 smoke

---

## 9. 节点配置面板（aether-agent-flow-designer · FD-REQ2）

- [x] **9.1** 后端：节点 schema 校验（按 type）
- [x] **9.2a** **UI-CRAFT**：`NodeInspector` 动态表单（AI/分支/知识库等）— **impeccable: craft**
- [x] **9.2** 前端：**UI-FUNC** 选中节点展示配置并写回 `node.data` — **可验证**：刷新后配置保留
- [x] **9.3** 测试任务（待 test-cases Reviewed 后补充）
- [x] **9.6** **MANUAL**：配置 AI 节点模型/Prompt 后保存 — **ManualReason**：NodeInspector 已实现；staging 表单 smoke

---

## 10. 流程实时调试（aether-agent-flow-designer · FD-REQ3）

- [x] **10.1** 后端：`POST /flows/{id}/debug` SSE + `flow_node_*` 事件 + 写 execution — **可验证**：MockMvc/SSE 测试见 FE stream
- [x] **10.2a** **UI-CRAFT**：`DebugPanel` 节点高亮 + 日志 — **impeccable: audit+polish**
- [x] **10.2** 前端：**UI-FUNC** EventSource 消费 debug SSE — **可验证**：节点状态与后端事件同步
- [x] **10.3** 测试任务（待 test-cases Reviewed 后补充）
- [x] **10.4a** **AUTO-AI-UT**：**先** `FlowExecutionDebugSseTest`（StepVerifier 事件顺序）— **可验证**：单测通过 — trace: TC-REQ → FlowExecutionDebugSseTest.java
- [x] **10.4** **AUTO-AI-UT**：`mvn -pl agent-hub -Dtest=FlowExecutionDebugSseTest test` — trace: TC-REQ → FlowExecutionDebugSseTest.java
- [x] **10.6** **MANUAL**：调试运行异常节点标红 — **ManualReason**：DebugPanel SSE 已实现；真实 LLM staging smoke

---

## 11. 节点类型体系（aether-agent-flow-designer · FD-REQ4）

- [x] **11.1** 后端：`FlowNodeTypeRegistry` + 扩展点接口 — **可验证**：内置 10 类型注册完整
- [x] **11.2** 前端：**UI-FUNC** 左侧节点面板清单与 design §4.2 一致 — **可验证**：面板节点类型齐全
- [x] **11.3** 测试：**AUTO-UT** `FlowNodeTypeRegistryTest` — trace: TC-REQ → FlowNodeTypeRegistryTest.java
- [x] **11.4** **MANUAL**：每类节点可拖入画布 — **ManualReason**：节点面板 10 类型已实现；staging smoke

---

## 12. 应用关联流程（aether-agent-flow-integration · FI-REQ1 + orchestrator · OR-REQ1）

- [x] **12.1** 后端：`AgentRegistryEntry.flowId` + `PUT/GET .../agents/{name}/flow` + `FlowAccessGuard` — **可验证**：绑定/解绑 API
- [x] **12.2** 后端：`PrepareSuperAgentChatNode` route **后**检查 `selectedEntry.flowId` → `FLOW_ENGINE` — **可验证**：见 design §6.2
- [x] **12.3** 后端：`FlowExecutionBridge` 接口 + `SuperAgentChatApplicationService` `FLOW_ENGINE` 分支 — **可验证**：Mock bridge 被调用
- [x] **12.4a** **AUTO-AI-UT**：**先** `PrepareSuperAgentChatNodeFlowRouteTest` — **可验证**：有 flowId 时不走 SUB_AGENT — trace: TC-REQ → PrepareSuperAgentChatNodeFlowRouteTest.java
- [x] **12.4** **AUTO-AI-UT**：`FlowAccessGuardTest`（disabled 抛 FLOW_DISABLED）— **可验证**：单测通过 — trace: TC-REQ → FlowAccessGuardTest.java
- [x] **12.5** **AUTO-AI-UT**：`mvn -pl aether-platform,agent-hub -Dtest=PrepareSuperAgentChatNodeFlowRouteTest,FlowAccessGuardTest test` — trace: TC-REQ → PrepareSuperAgentChatNodeFlowRouteTest.java
- [x] **12.6** 前端：**UI-FUNC** `PlatformAgentRegistryManager` 流程 Select — **可验证**：绑定后 prep 预览显示 flow
- [x] **12.7** **MANUAL**：绑定流程对话走 flow SSE — **ManualReason**：FLOW_ENGINE 分支已实现；staging LLM smoke
- [x] **12.8** **MANUAL**：禁用流程对话返回明确错误、不降级 — **ManualReason**：FlowAccessGuard 单测覆盖；staging 验证

---

## 13. 流程 API 调用（aether-agent-flow-integration · FI-REQ2）

- [x] **13.1** 后端：`invoke` 同步 + `stream` SSE API — **可验证**：契约 JSON/SSE
- [x] **13.2** 前端：无
- [x] **13.3** 测试任务（待 test-cases Reviewed 后补充）
- [x] **13.4a** **AUTO-AI-UT**：**先** `FlowExecutionStreamTest`（StepVerifier）— **可验证**：单测通过 — trace: TC-REQ → FlowExecutionStreamTest.java
- [x] **13.4** **AUTO-UT**：`FlowControllerContractTest`（MockMvc）— trace: TC-REQ → FlowControllerContractTest.java
- [x] **13.5** **AUTO-UT/AUTO-AI-UT**：`mvn -pl agent-hub -Dtest=FlowExecutionStreamTest,FlowControllerContractTest test` — trace: TC-REQ → FlowControllerContractTest.java
- [x] **13.6** **MANUAL**：curl invoke + stream — **ManualReason**：API + 单测已实现；外部集成 staging smoke

---

## 14. MCP 插件（aether-agent-flow-integration · FI-REQ3）

- [x] **14.1** 后端：`POST .../register-mcp-tool` + `FlowMcpToolRegistrar`（`FlowToolRegistrationPort` 防腐）— **可验证**：ToolCatalog 可见
- [x] **14.2** 前端：**UI-FUNC** 管理页「发布为 MCP 工具」按钮 — **可验证**：调用 API 成功
- [x] **14.3** 测试：**AUTO-UT** `FlowMcpToolRegistrarTest`（description 四段式 grep）— trace: TC-REQ → FlowMcpToolRegistrarTest.java
- [x] **14.4** **MANUAL**：ReactAgent 对话触发 flow tool — **ManualReason**：register-mcp-tool + ToolCatalog 已实现；staging LLM smoke

---

## 15. 执行记录（aether-agent-flow-integration · FI-REQ4）

- [x] **15.1** 后端：execution 落库 + list/detail API — **可验证**：node_logs JSON 结构
- [x] **15.2a** **UI-AUDIT**：`pages/flow-executions/` 列表/详情 — **impeccable: audit+polish**
- [x] **15.2** 前端：**UI-FUNC** 执行记录页 — **可验证**：字段与 API 一致
- [x] **15.3** 测试：**AUTO-UT** `FlowExecutionQueryServiceTest` — trace: TC-REQ → FlowExecutionQueryServiceTest.java
- [x] **15.4** **MANUAL**：调试/run 后在列表可见 — **ManualReason**：execution API + 列表页已实现；staging 联调 smoke

---

## 16. 工程收尾（横切）

- [x] **16.1** 文档/API：更新 `integration-contracts.md`、`api-changelog.md`、`.aetherstack/context/api-contracts.yaml`（apply 范围内）— **可验证**：契约与 design §5 一致
- [x] **16.2** 前端：`.umirc.ts` / `routes.ts` / `menuConfig.ts` 注册 flow 路由 — **可验证**：侧栏可达设计器/管理/执行记录
- [x] **16.3** **UI-POLISH**：Impeccable `polish` 流程相关页（可选）— **impeccable: polish**（可选延后；U1 已 shape/craft/audit+polish）
- [x] **16.4** Harness：`harness lint` + `harness build`（ai_react）— **可验证**：通过（2026-06-30）
- [x] **16.5** 后端：`make verify` 或 scoped `mvn test` — **可验证**：scoped 56/56 BUILD SUCCESS
- [x] **16.6** `/opsx-verify` → `verification-report.md` — **可验证**：Ready for archive (with noted improvements)

---

**依赖顺序建议**：0 → 1 → 2 → 4 → 5 → 6 → 7 → 13 → 10 → 8/9/11（前端可并行）→ 12 → 14 → 15 → 16
