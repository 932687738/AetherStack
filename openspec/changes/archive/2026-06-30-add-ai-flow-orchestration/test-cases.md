# 测试用例（standard-spec-driven）

## 0. 测试基线来源

- **Source**：`AI 生成`（依据 `specs/**/spec.md` + `design.md` v1.1；无外部测试稿）
- **OpenSpec 基线**：`add-ai-flow-orchestration` delta specs + design §4~§6
- **外部测试基线**：无
- **采用方式**：仅 OpenSpec
- **Status**：`Reviewed`（2026-06-30 用户确认）
- **aiTddMode**：`enabled`（L1 用例须 `AUTO-AI-UT`）

---

## 1. 用例主体

# [S] 流程管理（aether-agent-flow-management）

## [S] Requirement 1：流程 CRUD

### [C] TC-FM-REQ1-01 创建新流程
[用例描述]
管理员创建流程草稿并返回空 DSL 骨架
[Automation]
`AUTO-UT`

[前置条件]
- 租户 `default` active；携带有效 `X-Admin-Api-Key`

#### 步骤1
`POST /api/agent-hub/flows` body `{name, description}`

##### 预期结果
- HTTP 200/201；`status=draft`，`currentVersion=0`
- `definition.schemaVersion=1`，`nodes`/`edges` 为空数组

#### 可观测性断言
- 数据库断言：`ai_flow` 新增一行，`deleted=false`

### [C] TC-FM-REQ1-02 流程列表分页与筛选
[用例描述]
按名称/状态分页查询流程列表
[Automation]
`AUTO-UT`

[前置条件]
- 存在 ≥3 条不同 status 的流程

#### 步骤1
`GET /api/agent-hub/flows?page=1&size=20&status=published`

##### 预期结果
- 返回 `items`/`page`/`size`/`total`；仅含 published 记录

#### 可观测性断言
- 接口断言：分页字段符合 `api-conventions.md`

### [C] TC-FM-REQ1-03 删除被 Agent 引用的流程
[用例描述]
流程被 `agent_registry.flow_id` 引用时拒绝删除
[Automation]
`AUTO-UT`

[前置条件]
- 某 Agent 已绑定 flowId

#### 步骤1
`DELETE /api/agent-hub/flows/{id}`

##### 预期结果
- HTTP 409 `CONFLICT`；提示先解除关联

### [C] TC-FM-REQ1-04 管理页创建并跳转设计器
[用例描述]
前端创建流程后进入设计器
[Automation]
`MANUAL`
[ManualReason]
页面路由跳转与 Impeccable 布局需浏览器验收

[前置条件]
- 已登录管理端；`flow-management` 路由可达

#### 步骤1
填写名称 → 创建 → 自动跳转设计器

##### 预期结果
- URL 含 flowId；画布为空图

---

## [S] Requirement 2：流程版本管理

### [C] TC-FM-REQ2-01 发布生成新版本并 compile
[用例描述]
发布时写入版本快照并 compile 注册 CompiledGraph
[Automation]
`AUTO-AI-UT`

[前置条件]
- 草稿含合法 start→ai→end DSL

#### 步骤1
`FlowManagementApplicationService.publish(flowId)`

##### 预期结果
- `current_version` 自增；`ai_flow_version` 新增一行
- `FlowCompiledGraphRegistry.put` 被调用；失败则事务回滚

#### 可观测性断言
- 数据库断言：`ai_flow.status=published`，`enabled=true`

### [C] TC-FM-REQ2-02 发布 compile 失败回滚
[用例描述]
非法条件边目标导致 compile 失败
[Automation]
`AUTO-AI-UT`

[前置条件]
- DSL 通过校验但 compile 阶段抛 `GraphStateException`（Mock）

#### 步骤1
调用 publish

##### 预期结果
- HTTP 400 `FLOW_COMPILE_ERROR`；`current_version` 不变

### [C] TC-FM-REQ2-03 版本回滚
[用例描述]
回滚到历史版本并生成新版本记录
[Automation]
`AUTO-UT`

[前置条件]
- 存在 v1/v2/v3

#### 步骤1
`POST /flows/{id}/rollback` body `{versionNo: 1}`

##### 预期结果
- 生成 v4，内容与 v1 definition 一致；registry 刷新 compile

### [C] TC-FM-REQ2-04 版本历史 UI
[用例描述]
管理页查看版本列表
[Automation]
`MANUAL`
[ManualReason]
Modal 交互与 Impeccable 验收

#### 步骤1
点击「版本历史」

##### 预期结果
- 展示 versionNo、发布时间、发布人

---

## [S] Requirement 3：流程启用与禁用

### [C] TC-FM-REQ3-01 禁用后 API 拒绝
[用例描述]
已发布流程 disable 后 invoke 返回 FLOW_DISABLED
[Automation]
`AUTO-UT`

#### 步骤1
disable → `POST /flows/{id}/invoke`

##### 预期结果
- HTTP 409 `FLOW_DISABLED`

### [C] TC-FM-REQ3-02 重新启用后可调用
[用例描述]
enable 后 invoke 恢复成功
[Automation]
`AUTO-UT`

#### 步骤1
enable → invoke 合法 params

##### 预期结果
- HTTP 200；`status=success`

---

# [S] 流程引擎（aether-agent-flow-engine）

## [S] Requirement 1：流程定义解析与校验

### [C] TC-FE-REQ1-01 合法 DSL 解析通过
[用例描述]
含 start/end 的有效 DAG 通过校验
[Automation]
`AUTO-UT`

#### 步骤1
`FlowDefinitionValidator.validate(dsl)`

##### 预期结果
- 无异常；拓扑排序非空

### [C] TC-FE-REQ1-02 缺少开始或结束节点
[用例描述]
缺 start 或 end 拒绝
[Automation]
`AUTO-UT`

#### 步骤1
提交缺 end 的 DSL

##### 预期结果
- 抛领域异常 → 400 `FLOW_MISSING_START_END`

### [C] TC-FE-REQ1-03 存在环路
[用例描述]
DAG 校验检出环路
[Automation]
`AUTO-UT`

#### 步骤1
提交 A→B→C→A 连线

##### 预期结果
- 400 `FLOW_CYCLE_DETECTED`；错误含环路 hint

### [C] TC-FE-REQ1-04 节点数超过 50
[用例描述]
超限拒绝保存
[Automation]
`AUTO-UT`

#### 步骤1
DSL 含 51 个节点

##### 预期结果
- 400 `FLOW_NODE_LIMIT_EXCEEDED`

---

## [S] Requirement 2：节点执行器调度

### [C] TC-FE-REQ2-01 AI 节点调用 ChatClient 并写上下文
[用例描述]
AI 节点组装 Prompt 流式输出
[Automation]
`AUTO-AI-UT`

[前置条件]
- Mock `AgentChatService.stream` 返回 Flux

#### 步骤1
`AiFlowNodeAction.execute(state)` 含 ai 节点配置

##### 预期结果
- `NODE_OUTPUTS[ai_1]` 含 LLM 文本；Prompt 渲染含 `userPromptTemplate` 关键片段

#### 可观测性断言
- 日志断言：无真实 DashScope 调用

### [C] TC-FE-REQ2-02 知识库节点 RAG 检索
[用例描述]
knowledge 节点按 kbId/Top-K/阈值检索
[Automation]
`AUTO-AI-IT`

[前置条件]
- Mock 检索 Port 或 Testcontainers pgvector（推荐 Mock）

#### 步骤1
执行 knowledge 节点

##### 预期结果
- 上下文注入 `[来源: xxx] content` 格式片段

### [C] TC-FE-REQ2-03 分支节点条件路由
[用例描述]
branch 命中条件走对应边
[Automation]
`AUTO-AI-UT`

#### 步骤1
compile 含条件边的图；VARIABLES 满足 branch-A

##### 预期结果
- 仅执行 branch-A 下游节点

### [C] TC-FE-REQ2-04 脚本节点 Groovy 沙箱超时
[用例描述]
脚本超时 30s 终止
[Automation]
`AUTO-UT`

#### 步骤1
脚本含 infinite loop；`maxAttempts=1`

##### 预期结果
- 节点 failed；`node_logs` 含 timeout

### [C] TC-FE-REQ2-05 HTTP 节点 SSRF 拒绝
[用例描述]
内网 URL 被白名单拦截
[Automation]
`AUTO-UT`

#### 步骤1
http 节点 url=`http://127.0.0.1/`

##### 预期结果
- 400/节点错误；不发起请求

---

## [S] Requirement 3：执行上下文与数据流

### [C] TC-FE-REQ3-01 变量引用替换
[用例描述]
`{{node_1.output}}` 替换为前序输出
[Automation]
`AUTO-UT`

#### 步骤1
`FlowVariableResolver.resolve(template, context)`

##### 预期结果
- 输出字符串含实际值；未知占位符抛校验异常

### [C] TC-FE-REQ3-02 开始节点输入参数注入
[用例描述]
invoke 传入 params 写入 INPUT_PARAMS
[Automation]
`AUTO-UT`

#### 步骤1
invoke params `{question: "hi"}`

##### 预期结果
- start 节点输出可被子节点引用

### [C] TC-FE-REQ3-03 对话 sessionVariables 合并
[用例描述]
SuperAgents chat 的 sessionVariables 进入 flow INPUT_PARAMS
[Automation]
`AUTO-AI-UT`

#### 步骤1
`FlowExecutionBridge.stream` 传入 sessionVariables

##### 预期结果
- Prompt 渲染含变量值；经 sanitizer 过滤注入片段

---

## [S] Requirement 4：异常处理与重试

### [C] TC-FE-REQ4-01 节点失败写 node_logs 并停止
[用例描述]
未配置重试时失败即终止流程
[Automation]
`AUTO-UT`

#### 步骤1
Mock LLM 抛异常；retry.maxAttempts=1

##### 预期结果
- execution `status=failed`；`node_logs` 含 error

### [C] TC-FE-REQ4-02 重试策略耗尽
[用例描述]
maxAttempts=3 仍失败
[Automation]
`AUTO-UT`

#### 步骤1
Mock 连续失败 3 次

##### 预期结果
- 调用 3 次；最终 failed；间隔符合 backoff

---

# [S] 流程设计器（aether-agent-flow-designer）

## [S] Requirement 1：画布拖拽编辑

### [C] TC-FD-REQ1-01 拖拽节点到画布
[Automation]
`MANUAL`
[ManualReason]
React Flow 拖拽交互

#### 步骤1
从面板拖 AI 节点到画布

##### 预期结果
- 节点出现且 id 唯一

### [C] TC-FD-REQ1-02 连线建立有向边
[Automation]
`MANUAL`
[ManualReason]
端口连线 UI

#### 步骤1
连接 start → ai

##### 预期结果
- edges 增加；箭头方向正确

### [C] TC-FD-REQ1-03 前端防环预校验
[用例描述]
连线形成环时前端阻止或警告
[Automation]
`AUTO-UT`

#### 步骤1
单元测试 `validateDagClient(edges)` 含环

##### 预期结果
- 返回 false/错误消息

### [C] TC-FD-REQ1-04 删除节点清除关联边
[Automation]
`MANUAL`
[ManualReason]
Delete 键交互

#### 步骤1
选中中间节点 Delete

##### 预期结果
- 节点及相关 edges 移除

---

## [S] Requirement 2：节点配置面板

### [C] TC-FD-REQ2-01 配置 AI 节点参数持久化
[Automation]
`MANUAL`
[ManualReason]
Inspector 表单 + 保存 API 联调

#### 步骤1
设置 model/temperature/Prompt → 保存 → 刷新

##### 预期结果
- definition 中 node.data 一致

### [C] TC-FD-REQ2-02 分支条件多出口
[Automation]
`MANUAL`
[ManualReason]
多分支 UI 与 edges 绑定

#### 步骤1
配置两条 branch 条件并连不同下游

##### 预期结果
- 每条边对应条件表达式

### [C] TC-FD-REQ2-03 知识库节点 Top-K/阈值
[Automation]
`AUTO-UT`

#### 步骤1
保存 knowledge 节点 data `{kbIds, topK, threshold}`

##### 预期结果
- 后端 schema 校验通过

---

## [S] Requirement 3：流程实时调试

### [C] TC-FD-REQ3-01 调试 SSE 节点事件顺序
[用例描述]
debug 运行按序推送 flow_node_start/complete
[Automation]
`AUTO-AI-UT`

[前置条件]
- Mock CompiledGraph 逐节点返回

#### 步骤1
`FlowExecutionApplicationService.streamDebug`

##### 预期结果
- StepVerifier 验证事件顺序与 nodeId

### [C] TC-FD-REQ3-02 画布节点高亮与日志面板
[Automation]
`MANUAL`
[ManualReason]
SSE + UI 高亮同步

#### 步骤1
点击调试运行

##### 预期结果
- 执行顺序高亮；DebugPanel 展示 input/output

### [C] TC-FD-REQ3-03 调试异常节点标红
[Automation]
`MANUAL`
[ManualReason]
错误态 UI + 真实失败节点

#### 步骤1
配置非法脚本节点并 debug

##### 预期结果
- 失败节点标红；展示 error 详情；已完成节点保持高亮

---

## [S] Requirement 4：节点类型体系

### [C] TC-FD-REQ4-01 内置节点类型注册完整
[Automation]
`AUTO-UT`

#### 步骤1
`FlowNodeTypeRegistry.listBuiltIn()`

##### 预期结果
- 含 design §4.2 所列 10 类（含 classifier 简化版）

### [C] TC-FD-REQ4-02 节点面板展示与 spec 一致
[Automation]
`MANUAL`
[ManualReason]
面板文案与图标 UI

#### 步骤1
打开设计器左侧节点面板

##### 预期结果
- 类型清单与 spec REQ-4 场景一致

---

# [S] 流程集成（aether-agent-flow-integration）

## [S] Requirement 1：应用关联流程

### [C] TC-FI-REQ1-01 绑定 flowId 到 Agent
[Automation]
`AUTO-UT`

#### 步骤1
`PUT /api/super-agents/agents/{name}/flow` `{flowId: 1}`

##### 预期结果
- `agent_registry.flow_id=1`

### [C] TC-FI-REQ1-02 解绑 flowId
[Automation]
`AUTO-UT`

#### 步骤1
PUT `{flowId: null}`

##### 预期结果
- `flow_id` IS NULL

### [C] TC-FI-REQ1-03 关联流程被禁用时对话错误
[Automation]
`AUTO-UT`

[前置条件]
- Agent 绑定 flow；flow disabled

#### 步骤1
`POST /api/super-agents/chat`

##### 预期结果
- 409 `FLOW_DISABLED`；**不**降级到 PlatformRouter

---

## [S] Requirement 2：流程 API 调用

### [C] TC-FI-REQ2-01 同步 invoke 返回完整 JSON
[Automation]
`AUTO-UT`

#### 步骤1
`POST /flows/{id}/invoke` 合法 params

##### 预期结果
- 200；body 含 output/executionId/status

### [C] TC-FI-REQ2-02 SSE stream 推送进度
[Automation]
`AUTO-AI-UT`

#### 步骤1
`POST /flows/{id}/stream` Accept SSE

##### 预期结果
- 含 `flow_node_*` 与 `flow_complete` 事件

### [C] TC-FI-REQ2-03 curl 外部集成 smoke
[Automation]
`MANUAL`
[ManualReason]
外部 HTTP 客户端 + 真实服务

#### 步骤1
curl invoke + stream

##### 预期结果
- 与契约一致

---

## [S] Requirement 3：流程作为 MCP 插件

### [C] TC-FI-REQ3-01 注册 MCP Tool 描述四段式
[Automation]
`AUTO-UT`

#### 步骤1
`FlowMcpToolRegistrar.register(flow)`

##### 预期结果
- Tool 描述含名称/适用/反例/参数说明；写入 ToolCatalog

### [C] TC-FI-REQ3-02 Agent 对话触发 flow tool
[Automation]
`MANUAL`
[ManualReason]
真实 LLM 选 tool + 流程执行

#### 步骤1
注册 tool 后发对话触发

##### 预期结果
- Agent 回复整合 flow 输出

---

## [S] Requirement 4：流程执行记录与可观测性

### [C] TC-FI-REQ4-01 执行记录列表分页
[Automation]
`AUTO-UT`

#### 步骤1
`GET /api/agent-hub/flow-executions?flowId=&page=`

##### 预期结果
- items 含 triggerType/duration/tokenUsage

### [C] TC-FI-REQ4-02 执行详情 node_logs 完整
[Automation]
`AUTO-UT`

#### 步骤1
`GET /flow-executions/{id}`

##### 预期结果
- 每节点 input/output/duration/error 字段齐全

### [C] TC-FI-REQ4-03 执行记录 UI 审计页
[Automation]
`MANUAL`
[ManualReason]
只读详情页 UI-AUDIT

#### 步骤1
从列表打开详情

##### 预期结果
- 轨迹与后端 JSON 一致

---

# [S] 编排路由扩展（aether-agent-orchestrator）

## [S] Requirement 1：对话路由增加流程引擎路径

### [C] TC-OR-REQ1-01 路由后 selectedEntry 有 flowId 走 FLOW_ENGINE
[用例描述]
prep 图在 PlatformRouterFacade.route 之后检查 flowId
[Automation]
`AUTO-AI-UT`

[前置条件]
- Mock route 返回 selectedEntry.flowId=1

#### 步骤1
`PrepareSuperAgentChatNode.execute(state)`

##### 预期结果
- `STREAM_ROUTE=FLOW_ENGINE`；`FLOW_ID=1`
- **未**调用 SubAgent ReactAgent 流

### [C] TC-OR-REQ1-02 未绑定 flowId 保持原路由
[Automation]
`AUTO-AI-UT`

#### 步骤1
selectedEntry.flowId=null

##### 预期结果
- `SUB_AGENT` 或 `PLATFORM_ROUTER` 与原逻辑一致

### [C] TC-OR-REQ1-03 SuperAgentChatApplicationService FLOW_ENGINE 分支
[Automation]
`AUTO-AI-UT`

#### 步骤1
prep 快照 streamRoute=FLOW_ENGINE

##### 预期结果
- `FlowExecutionBridge.stream` 被调用；SSE 含 flow 事件

### [C] TC-OR-REQ1-04 端到端对话走流程
[Automation]
`MANUAL`
[ManualReason]
真实 LLM + SSE UI

#### 步骤1
绑定 flow 的 Agent 发消息

##### 预期结果
- 不走原路由摘要「转交 xxx」而走 flow 执行

### [C] TC-OR-REQ1-05 MULTI_AGENT_SERIAL 优先于 flow
[Automation]
`AUTO-UT`

[前置条件]
- hybrid 意图命中 MULTI_AGENT_SERIAL

#### 步骤1
prep execute

##### 预期结果
- 仍为 MULTI_AGENT_SERIAL（design-review DR-16 豁免）

---

## 2. AUTO-AI-UT 标记清单（L1，须先测后码）

| TC | 目标测试类（建议） |
|----|-------------------|
| TC-FM-REQ2-01 | `FlowManagementPublishTest` |
| TC-FM-REQ2-02 | `FlowManagementPublishTest` |
| TC-FE-REQ2-01 | `AiFlowNodeActionTest` |
| TC-FE-REQ2-03 | `FlowGraphCompilerBranchTest` |
| TC-FE-REQ3-03 | `FlowExecutionBridgeTest` |
| TC-FD-REQ3-01 | `FlowExecutionDebugSseTest` |
| TC-FI-REQ2-02 | `FlowExecutionStreamTest` |
| TC-OR-REQ1-01 | `PrepareSuperAgentChatNodeFlowRouteTest` |
| TC-OR-REQ1-02 | `PrepareSuperAgentChatNodeFlowRouteTest` |
| TC-OR-REQ1-03 | `SuperAgentChatFlowEngineBranchTest` |

## 3. AUTO-UT 标记清单（节选）

| TC | 目标测试类（建议） |
|----|-------------------|
| TC-FM-REQ1-01~03 | `FlowManagementServiceTest` |
| TC-FM-REQ2-03 | `FlowManagementRollbackTest` |
| TC-FM-REQ3-01~02 | `FlowManagementEnableDisableTest` |
| TC-FE-REQ1-01~04 | `FlowDefinitionValidatorTest` |
| TC-FE-REQ2-04~05 | `ScriptFlowNodeActionTest` / `HttpFlowNodeActionTest` |
| TC-FE-REQ3-01~02 | `FlowVariableResolverTest` |
| TC-FE-REQ4-01~02 | `FlowNodeRetryPolicyTest` |
| TC-FD-REQ1-03 | `flowDesignerDagUtils.test.ts` 或 Java 纯函数 |
| TC-FD-REQ4-01 | `FlowNodeTypeRegistryTest` |
| TC-FI-REQ1-01~03 | `AgentRegistryFlowBindingTest` / `FlowAccessGuardTest` |
| TC-FI-REQ2-01 | `FlowControllerContractTest` |
| TC-FI-REQ3-01 | `FlowMcpToolRegistrarTest` |
| TC-FI-REQ4-01~02 | `FlowExecutionQueryServiceTest` |
| TC-OR-REQ1-05 | `PrepareSuperAgentChatNodeFlowRouteTest` |

## 4. MANUAL 标记清单

| TC | 说明 |
|----|------|
| TC-FM-REQ1-04 | 管理页 → 设计器 |
| TC-FM-REQ2-04 | 版本历史 Modal |
| TC-FD-REQ1-01/02/04 | 画布交互 |
| TC-FD-REQ2-01/02 | Inspector 表单 |
| TC-FD-REQ3-02/03 | 调试 UI |
| TC-FD-REQ4-02 | 节点面板 |
| TC-FI-REQ2-03 | curl 集成 |
| TC-FI-REQ3-02 | MCP + LLM |
| TC-FI-REQ4-03 | 执行记录 UI |
| TC-OR-REQ1-04 | 对话 E2E |

---

## 5. 口径冲突清单

无（用例与 spec/design v1.1 一致）。

---

## 6. 确认提示

✅ test-cases.md 格式对齐完成（AI 起草），请确认：

- **AUTO-AI-UT**：共 10 条（L1 模块须先写 `*Test.java` 再改生产代码）
- **AUTO-UT**：约 25 条（Service/Validator/Controller 层）
- **MANUAL**：约 14 条（UI / 真实 LLM / 外部集成）
- **口径冲突**：无

确认无误请回复 **「确认 test-cases」**，将把 Status 改为 `Reviewed`，并可在 `tasks.md` 测试任务行补充 `trace: TC-xxx → XxxTest`。
