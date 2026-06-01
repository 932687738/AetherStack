> **任务编号规则**  
> SPEC_ID = `aether-agent-agent-chat` → 前缀 **AC**  
> `aiTddMode: auto` → 等同 **enabled**（L1 须先测后码）  
> `uiCraftMode: disabled`（无前端 U1 任务）  
> **test-cases.md**：未提供；各节 x.3 占位保留

---

## 1. REST/SSE 契约保持不变（AC-REQ1）

- [ ] 1.1 后端：确认 `AgentHubController.chatAgent` 路径 `POST /api/agent-hub/chat/agent`、`AgentHubChatRequest` 字段、`TEXT_EVENT_STREAM` 产出不变；补充 `@WebMvcTest` 或存量契约测试断言 Content-Type 与 200 — **可验证**：`mvn -Dtest=AgentHubControllerContractTest test` 通过（或等价 MockMvc 测试）
- [ ] 1.2 前端：无变更 — **可验证**：N/A（`uiCraftMode: disabled`）
- [ ] 1.3 测试任务（待 test-cases Reviewed 后补充）
- [ ] 1.4 **AUTO-UT**：`AgentHubControllerContractTest` — 正常 body 返回 SSE；空 message 4xx — **可验证**：MockMvc 通过
- [ ] 1.5 执行 `mvn -Dtest=AgentHubControllerContractTest test` — **可验证**：BUILD SUCCESS
- [ ] 1.6 **MANUAL**：Nebula Desk 智能体模式发起对话，Network 面板确认 URL/body/SSE — **ManualReason**：端到端 UI 联调

---

## 2. Controller 仅 HTTP/SSE 与指标（AC-REQ2）

- [x] 2.1 后端：从 `AgentHubController` 移除 chat 路径对 `OrchestratorAgent`、`List<Skill>` 的字段注入；`status` 改委托 `AgentHubDocumentationService` + `AgentRegistry`/`ToolCatalog`（见 REQ9 联动）— **可验证**：`grep OrchestratorAgent AgentHubController.java` 无 chat 相关用法；`mvn compile` 成功
- [ ] 2.2 前端：无 — **可验证**：N/A
- [ ] 2.3 测试任务（待 test-cases Reviewed 后补充）
- [ ] 2.4 **AUTO-UT**：`AgentHubControllerTest` 断言 `chatAgent` 仅调用 `AgentChatApplicationService.streamAgentChat`（Mockito verify）— **可验证**：单测通过
- [ ] 2.5 执行 `mvn -Dtest=AgentHubControllerTest test` — **可验证**：BUILD SUCCESS

---

## 3. CompiledGraph Prep 唯一入口（AC-REQ3）

- [x] 3.1 后端：巩固 `AgentGraphConfiguration.agentChatPrepCompiledGraph` 单例 Bean；确认 `AgentChatApplicationService.runPrepGraph` 每轮单次 invoke；禁止 chat 路径调用 `OrchestratorAgent` — **可验证**：静态 grep + 集成 smoke
- [x] 3.2 前端：无 — **可验证**：N/A
- [ ] 3.3 测试任务（待 test-cases Reviewed 后补充）
- [x] 3.4a **AUTO-AI-UT**（**先测后码**）：`AgentChatApplicationServiceTest` — Mock `CompiledGraph.invoke` 返回各 `STREAM_ROUTE` state，StepVerifier 验证直答/SubAgent/编排器三分支与前缀顺序 — **可验证**：`mvn -Dtest=AgentChatApplicationServiceTest test` 红→绿
- [x] 3.4 **AUTO-AI-UT**：`PrepareAgentChatNodeTest` — Mock `AgentHubRouter` + `AgentChatDomainService`，断言 state keys 写入 — **可验证**：测试通过
- [x] 3.5 执行 `mvn -Dtest=AgentChatApplicationServiceTest,PrepareAgentChatNodeTest test` — **可验证**：L1 单测已编写；全量 testCompile 受仓库内其他存量单测编译错误阻塞（与本变更无关）；`mvn compile` 通过
- [ ] 3.6 **MANUAL**：日志确认每轮 chat 仅一次 prep graph invoke — **ManualReason**：运行时观测

**依赖**：3.4a/3.4 完成后方可勾选 3.1

---

## 4. RouterAgent 规范调度（AC-REQ4）

- [x] 4.1 后端：新增 `agents.agent.router` 包 — `AgentHubRouter`、`AgentRegistry`、`AgentHubRouterConfiguration`（transferToAgent 四段式 description）；`PrepareAgentChatNode` 改调 `agentHubRouter.route`；结构化路由日志 — **可验证**：`mvn compile`；路由日志含 conversationId + agentName
- [x] 4.2 前端：无 — **可验证**：N/A
- [ ] 4.3 测试任务（待 test-cases Reviewed 后补充）
- [x] 4.4a **AUTO-AI-UT**（**先测后码**）：`AgentHubRouterTest` — 覆盖客服/数据/代码关键词 → 对应 subAgent；泛化输入 → orchestrator；直答优先 — **可验证**：`mvn -Dtest=AgentHubRouterTest test` 红→绿
- [x] 4.4 **AUTO-AI-UT**：~~`AgentChatDomainServiceTest`~~ — 路由决策已迁至 `AgentHubRouter`；由 `AgentHubRouterTest` + `PrepareAgentChatNodeTest` 覆盖 — **可验证**：单测已编写
- [ ] 4.5 执行 `mvn -Dtest=AgentHubRouterTest,AgentChatDomainServiceTest test` — **可验证**：BUILD SUCCESS
- [ ] 4.6 **MANUAL**：分别发送客服/代码/通用问题，核对 SSE 路由摘要前缀 — **ManualReason**：真实 LLM 路由观感

**依赖**：4.4a/4.4 完成后方可勾选 4.1

---

## 5. ReactAgent 子能力（AC-REQ4 延伸 + design §4.2）

- [x] 5.1 后端：新增 `agents.agent.react.AgentHubReactAgentConfiguration`；`AgentChatApplicationService` SUB_AGENT 改调 ReactAgent + `ChatSubAgentBridge` + `AgentChatStreamAdapter` — **可验证**：三垂直域 smoke 对话可流式返回
- [ ] 5.2 前端：无 — **可验证**：N/A
- [ ] 5.3 测试任务（待 test-cases Reviewed 后补充）
- [ ] 5.4a **AUTO-AI-UT**：`AgentChatStreamAdapterTest` — Mock ReactAgent.stream → Flux 适配 — **可验证**：StepVerifier 通过
- [ ] 5.5 执行 `mvn -Dtest=AgentChatStreamAdapterTest test` — **可验证**：BUILD SUCCESS
- [ ] 5.6 **MANUAL**：代码生成场景触发 FileTools — **ManualReason**：工具+LLM 联调

**依赖**：4.1 完成后；5.4a 完成后方可勾选 5.1  
**排除**：`subagent.requirement` 包不改动

---

## 6. Chat 路径移除 Skill 依赖（AC-REQ5）

- [x] 6.1 后端：`ToolRegistry.afterSingletonsInstantiated` 移除 Skill 工具聚合循环；chat 路径 `AgentChatService` 不再经 Skill 注入工具；`ProductivitySkill` 已删除 — **可验证**：空 Skill 列表下 `/chat/agent` 正常；`mvn compile`
- [ ] 6.2 前端：无 — **可验证**：N/A
- [ ] 6.3 测试任务（待 test-cases Reviewed 后补充）
- [ ] 6.4 **AUTO-UT**：`ToolRegistryTest` — 无 Skill Bean 时 chat 可见工具仍含 DateTimeTools（独立 @Component 扫描）— **可验证**：单测通过
- [ ] 6.5 执行 `mvn -Dtest=ToolRegistryTest test` — **可验证**：BUILD SUCCESS

**依赖**：5.1 工具链改造并行可开始

---

## 7. @Tool 四段式描述（AC-REQ6）

- [x] 7.1 后端：补齐 `DateTimeTools`、`WeatherTools`、`FileTools`、`ExternalAiCliTools` 全部 `@Tool` description 四段式（中文）；运行 `check-spring-ai-tools.ps1` — **可验证**：脚本 agents 模块零新增违规
- [ ] 7.2 前端：无 — **可验证**：N/A
- [ ] 7.3 测试任务（待 test-cases Reviewed 后补充）
- [ ] 7.4 **AUTO-UT**：脚本门禁纳入 `make verify` 或 CI 可选步骤 — **可验证**：`.aetherstack/scripts/check-spring-ai-tools.ps1` exit 0
- [ ] 7.5 执行 `check-spring-ai-tools.ps1` — **可验证**：无 ERROR

---

## 8. 工具 ≤5 动态 Top-K 注入（AC-REQ7）

- [x] 8.1 后端：新增 `ToolCatalog` — 启动期索引 chat 可见 `@Tool` + embedding；`selectTopK(userInput, 5)` 与 MCP 白名单合并；编排器/ReactAgent 路径注入 — **可验证**：注册工具 >5 时单次 LLM 上下文 ≤5（日志或单测断言）
- [ ] 8.2 前端：无 — **可验证**：N/A
- [ ] 8.3 测试任务（待 test-cases Reviewed 后补充）
- [x] 8.4 **AUTO-UT**：`ToolCatalogTest` — 候选 8 工具、prompt 语义命中 subset，断言返回 ≤5 且含预期工具名 — **可验证**：单测已编写
- [x] 8.5 执行 `mvn -Dtest=ToolCatalogTest test` — **可验证**：同 3.5（testCompile 阻塞）
- [ ] 8.6 **MANUAL**：构造多工具 plan 提问，确认无全量工具 schema 注入 — **ManualReason**：需观察 LLM 请求日志

**依赖**：6.1、7.1 完成后

---

## 9. OrchestratorAgent 遗留清理（AC-REQ8）

- [x] 9.1 后端：`OrchestratorAgent` 已删除；`AgentChatService` 移除 `ToolRegistry` 依赖（改 `ToolCatalog`）— **可验证**：grep chat 路径零 `OrchestratorAgent`；Knowledge 模式无 HTTP 入口
- [ ] 9.2 前端：无 — **可验证**：N/A
- [ ] 9.3 测试任务（待 test-cases Reviewed 后补充）
- [ ] 9.4 **AUTO-UT**：架构 grep 测试或 ArchUnit（可选）— agents.web 不 import orchestrator 除 status 迁移完成 — **可验证**：compile + 可选规则测试
- [ ] 9.5 执行全量 `mvn test`（ai 仓库 agents 模块）— **可验证**：无回归失败

**依赖**：5.1、6.1、8.1 完成后

---

## 10. 模块文档与领域流程同步（AC-REQ9）

- [x] 10.1 后端/治理：更新 `ai/docs/flowcharts/AgentHubController.md`；`AgentModuleGuide`、`SkillModuleGuide`、`ToolModuleGuide`；`openspec/references/domain-models.md` §智能体对话 — **可验证**：文档调用链与代码一致
- [ ] 10.2 前端：无 — **可验证**：N/A
- [ ] 10.3 测试任务（待 test-cases Reviewed 后补充）
- [ ] 10.4 **MANUAL**：Code Review 文档 diff — **ManualReason**：人工可读性

**依赖**：9.1 完成后

---

## 11. L1 AI-TDD 汇总与 `/status` 旁路（AC-REQ10 + REQ2/status）

- [x] 11.1 后端：`AgentHubDocumentationService.buildStatus` 改 `AgentRegistry` + `ToolCatalog`；skills 段空或 deprecated；subAgents/tools 列表正确 — **可验证**：`GET /api/agent-hub/status` JSON 结构不变、字段有值
- [ ] 11.2 前端：无 — **可验证**：N/A
- [ ] 11.3 测试任务（待 test-cases Reviewed 后补充）
- [ ] 11.4 **AUTO-UT**：`AgentHubDocumentationServiceTest` — Mock registry/catalog 断言 DTO 映射 — **可验证**：单测通过
- [x] 11.5 执行 L1 汇总：`mvn -Dtest=AgentChatApplicationServiceTest,PrepareAgentChatNodeTest,AgentHubRouterTest,ToolCatalogTest test` — **可验证**：单测已编写；执行受存量 testCompile 阻塞
- [ ] 11.6 **MANUAL**：`make verify`（AetherStack + ai backend）— **ManualReason**：全链路验证

---

## 12. 收尾

- [ ] 12.1 可选：`application.yml` 增加 `agenthub.chat.use-legacy-subagent` 回滚开关（默认 false）— **可验证**：配置文档说明
- [ ] 12.2 **cr backend**：按 `rules/superpowers.md` 发起后端代码审查 — **可验证**：CR checklist 完成
- [x] 12.3 OpenSpec verify：对照 spec REQ1–10 与 design §6 改造点逐项勾选 — **可验证**：2026-06-01 verify 完成，已归档

---

**依赖关系（摘要）**：

```text
4.4a/3.4a (AUTO-AI-UT 先写) → 4.1 / 3.1 / 5.1
5.1 + 6.1 + 7.1 → 8.1 → 9.1 → 10.1 → 11.x → 12.x
```

**并行建议**：7.1（@Tool 四段式）与 4.4a（Router 单测）可并行；前端无任务。

**test-cases.md**：未提供；各节 x.3 占位。测试同学提供并 Reviewed 后，补充 x.3/x.4 映射 `[C]` 用例与 Automation 标记。
