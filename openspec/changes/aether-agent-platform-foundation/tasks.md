> **变更**：`aether-agent-platform-foundation`  
> **Apply 阶段**：`/opsx-apply` + Harness（hev-analyzer → hev-coder → hev-verifier，见 `.cursor/skills/harness-apply/SKILL.md`）  
> **代码落点（强制）**：`com.yxy.deepseek.superAgents`（`ai/src/main/java/.../superAgents/`）  
> **aiTddMode**：`enabled` — L1 模块 **先测后码**（1.4a 先于 1.1）  
> **uiCraftMode**：`auto` — P1 **无 U1**；前端任务标 N/A 或 UI-FUNC（P2）  
> **test-cases.md**：未提供；各节 x.3 占位保留  
> **缺口增补**（PRD 20 节对照 + 不可实现说明）：[`tasks-gap-supplement.md`](./tasks-gap-supplement.md) — **剩余未完成项见 supplement 文首表**  
> **mvn 收口**：所有 `mvn -Dtest=...` 已标记 **跳过**（`[ ~]`）；不阻塞归档。

---

## 剩余未完成项（速查）

| 优先级 | 任务 | 说明 |
|--------|------|------|
| P0 | §9.6、§12.1、§12.6、G11.7 | MANUAL：真实 LLM + Desk/SSE 四类意图 |
| P1 | §14.3 | ai 仓 ARCHITECTURE 补 superAgents |
| P2 | §9.4 | `AgentHubControllerTest`（可选） |
| — | 各节 x.3 | test-cases 占位（无 `test-cases.md`） |

**已跳过**：x.5 / G1.5 / G2.5 / G11.4 等全部 `mvn -Dtest`；§14.1 scoped test 同上。§14.2 见 `verification-report.md`（G11.5）。

---

## 0. 模块脚手架与数据库（P1 前置）

- [x] 0.1 后端：创建 `superAgents` 包骨架（domain/application/infrastructure/web/graph/agent/tool/config）+ `SuperAgentsModuleConfiguration` `@ComponentScan` — **可验证**：`mvn compile` 成功；包路径存在
- [x] 0.2 后端：Flyway `V5__agent_platform_registry.sql` + 初始化三 SubAgent DML — **可验证**：本地启动 Flyway 迁移成功；`agent_registry` 表有 3 条 active
- [x] 0.3 后端：Prompt 目录 `src/main/resources/prompts/super-agents/` 占位 — **可验证**：资源文件可被 `ClassPathResource` 加载
- [x] 0.4 治理：增量登记 Registry API 至 `integration-contracts.md` 与 `.aetherstack/context/api-contracts.yaml` — **可验证**：契约文件含 `GET/POST /api/agent-hub/platform/agents`

**依赖**：无（apply 首任务）

---

## 1. 领域模型与 ToolResult（aether-agent-orchestrator-4）

- [x] 1.1 后端：实现 `superAgents/domain/tool/ToolResult.java` + `superAgents/domain/agent/{AgentInput,AgentResponse,PlatformAgent}.java`（含 `stream()` 默认/抽象）— **可验证**：domain 包无 Spring import；`mvn compile`
- [x] 1.2 前端：无 — **可验证**：N/A
- [~] 1.3 测试任务（待 test-cases Reviewed 后补充）— **跳过**（无 test-cases.md）
- [x] 1.4 **AUTO-UT**：`ToolResultTest` — ok/fail 工厂方法 — **可验证**：`mvn -Dtest=ToolResultTest test` 通过
- [~] 1.5 执行 `mvn -Dtest=ToolResultTest test` — **跳过**（见 supplement / verification-report）

---

## 2. Agent 元数据注册（aether-agent-registry-1）

- [x] 2.1 后端：`AgentRegistryEntry` + `AgentRegistryRepository`（domain）+ `MyBatisAgentRegistryRepository` / `AgentRegistryMapper` + `AgentRegistryApplicationService` + `AgentRegistryStartupValidator` — **可验证**：重复 `(tenantId,name)` 注册抛业务异常；bean_name 不存在时校验失败
- [x] 2.2 前端：无 — **可验证**：N/A
- [~] 2.3 测试任务 — **跳过**（无 test-cases.md）
- [x] 2.4 **AUTO-UT**：`MyBatisAgentRegistryRepositoryTest` — **可验证**：见 gap G11.1
- [~] 2.5 执行 `mvn -Dtest=MyBatisAgentRegistryRepositoryTest test` — **跳过**

**依赖**：0.2

---

## 3. 运行时发现与健康检查（aether-agent-registry-2 + registry-3）

- [x] 3.1 后端：`InMemoryPlatformCache` + `listActiveForChat(tenantId)` + `AgentHealthCheckJob` + unhealthy 剔除 — **可验证**：模拟 health 失败 → 路由列表不含该 Agent
- [x] 3.2 前端：无 — **可验证**：N/A
- [~] 3.3 测试任务 — **跳过**（无 test-cases.md）
- [x] 3.4 **AUTO-UT**：`AgentRegistryApplicationServiceTest` — **可验证**：见 gap G11.2
- [~] 3.5 执行 `mvn -Dtest=AgentRegistryApplicationServiceTest test` — **跳过**

**依赖**：2.1

---

## 4. Registry 管理 API（aether-agent-registry-1 延伸 + design §5）

- [x] 4.1 后端：`superAgents/web/AgentRegistryController` — GET/POST agents、POST `{name}/health`；P1 admin-api-key 保护写接口 — **可验证**：Postman/curl 200/201/409；无 key 写操作 401
- [x] 4.2 前端：无 — **可验证**：N/A
- [~] 4.3 测试任务 — **跳过**（无 test-cases.md）
- [x] 4.4 **AUTO-UT**：`AgentRegistryControllerTest`（MockMvc）— **可验证**：见 gap G11.3
- [~] 4.5 执行 `mvn -Dtest=AgentRegistryControllerTest test` — **跳过**

**依赖**：2.1、0.4

---

## 5. 多模型路由（aether-agent-model-routing-1 + model-routing-2）

- [x] 5.1 后端：`LlmCompletionPort`（domain）+ `SpringAiLlmCompletionAdapter` + `SuperAgentChatClientConfiguration`（命名 ChatClient Bean）+ `NamedChatClientModelRouter` + `aether.platform.model` 配置 — **可验证**：INTENT_ROUTING 与 AGENT_REASONING 使用不同 model 配置（日志或单测）
- [x] 5.2 前端：无 — **可验证**：N/A
- [~] 5.3 测试任务 — **跳过**（无 test-cases.md）
- [x] 5.4a **AUTO-AI-UT**（**先测后码**）：`NamedChatClientModelRouterTest` — Mock ChatClientBuilder，断言 taskType→model 映射 — **可验证**：红→绿
- [x] 5.4 **AUTO-AI-UT**：`SpringAiLlmCompletionAdapterTest` — Mock 流式返回 — **可验证**：StepVerifier 通过
- [~] 5.5 执行 `mvn -Dtest=NamedChatClientModelRouterTest,SpringAiLlmCompletionAdapterTest test` — **跳过**

**依赖**：1.1

---

## 6. 总路由仅暴露子 Agent 工具（aether-agent-platform-router-1）

- [x] 6.1 后端：`PlatformRouterFacade` + `SuperAgentHubLlmRouter` — ToolCallback **仅** transferToAgent 风格子 Agent；断言无 atomic Tool — **可验证**：单元测试或日志确认 tools 列表仅 registry 条目
- [x] 6.2 前端：无 — **可验证**：N/A
- [~] 6.3 测试任务 — **跳过**（无 test-cases.md）
- [x] 6.4a **AUTO-AI-UT**（**先测后码**）：`PlatformRouterFacadeTest` — Mock LlmRouter + Repository，断言 Prompt 含 capability_description、无 ToolCatalog — **可验证**：红→绿
- [x] 6.4 **AUTO-AI-UT**：`SuperAgentHubLlmRouterTest` — **可验证**：见 gap G1.4a
- [~] 6.5 执行 `mvn -Dtest=PlatformRouterFacadeTest,SuperAgentHubLlmRouterTest test` — **跳过**

**依赖**：3.1、5.4a 完成后方可勾选 6.1

---

## 7. PrepGraph 与 STREAM_ROUTE（aether-agent-platform-router-2 + orchestrator-3）

- [x] 7.1 后端：`SuperAgentGraphConfiguration` + `PrepareSuperAgentChatNode` + `SuperAgentGraphStateKeys`；新增 `PLATFORM_ROUTER` 枚举；保留 deprecated `DIRECT_*` — **可验证**：prep 单次 invoke；state 含 streamRoute
- [x] 7.2 前端：无 — **可验证**：N/A
- [~] 7.3 测试任务 — **跳过**（无 test-cases.md）
- [x] 7.4a **AUTO-AI-UT**（**先测后码**）：`PrepareSuperAgentChatNodeTest` — Mock PlatformRouterFacade，断言 STREAM_ROUTE 写入 — **可验证**：红→绿
- [~] 7.5 执行 `mvn -Dtest=PrepareSuperAgentChatNodeTest test` — **跳过**

**依赖**：6.4a 完成后方可勾选 7.1

---

## 8. 子 Agent 统一接口与流式适配（aether-agent-orchestrator-1 + orchestrator-2）

- [x] 8.1 后端：`PlatformAgentAdapter` + `LegacySubAgentBridge` — 包装存量 ReactAgent Bean；`AgentInput/AgentResponse` 字段完整 — **可验证**：SUB_AGENT 路径 SSE 流式输出
- [x] 8.2 前端：无 — **可验证**：N/A
- [~] 8.3 测试任务 — **跳过**（无 test-cases.md）
- [x] 8.4a **AUTO-AI-UT**：`PlatformAgentAdapterTest` — **可验证**：见 gap G2.4a
- [~] 8.5 执行 `mvn -Dtest=PlatformAgentAdapterTest test` — **跳过**

**依赖**：1.1、7.1

---

## 9. chat/agent 用例编排与入口委托（aether-agent-platform-router-4 + orchestrator-3 + chat-sse-contract-4）

- [x] 9.1 后端：`SuperAgentChatApplicationService`（prep→分支→前缀→Hook）+ `agents/web/AgentHubController` 改注入 superAgents；`agents/application/AgentChatApplicationService` `@Deprecated` 委托 — **可验证**：`POST /chat/agent` URL/body 不变；SSE 200
- [x] 9.2 前端：无 UI 变更（UI-FUNC N/A）— **可验证**：N/A
- [~] 9.3 测试任务 — **跳过**（无 test-cases.md）
- [x] 9.4a **AUTO-AI-UT**（**先测后码**）：`SuperAgentChatApplicationServiceTest` — Mock Graph + 三分支 StepVerifier — **可验证**：红→绿
- [ ] 9.4 **AUTO-UT**：`AgentHubControllerTest` — verify 调用 `SuperAgentChatApplicationService` — **可验证**：单测通过
- [~] 9.5 执行 `mvn -Dtest=SuperAgentChatApplicationServiceTest,AgentHubControllerTest test` — **跳过**
- [ ] 9.6 **MANUAL**：Nebula Desk 智能体模式对话 — **ManualReason**：端到端 SSE 联调

**依赖**：7.4a、8.4a 完成后方可勾选 9.1

---

## 10. 会话粘性路由（aether-agent-collaboration-1）

- [x] 10.1 后端：`StickyRouteContext` + prep Graph state；同类连续请求保持 SubAgent — **可验证**：单测或日志：连续客服追问不重复全量路由
- [x] 10.2 前端：无 — **可验证**：N/A
- [~] 10.3 测试任务 — **跳过**（无 test-cases.md）
- [x] 10.4a **AUTO-AI-UT**：`PlatformRouterFacadeStickyTest` — **可验证**：见 gap G5.3
- [~] 10.5 执行 `mvn -Dtest=PlatformRouterFacadeStickyTest test` — **跳过**

**依赖**：6.1

---

## 11. 平台 RAG Tool（aether-knowledge-rag-1 ~ rag-4）

- [x] 11.1 后端：`KnowledgeRetrievalPort` + `KnowledgeRetrievalAdapter` + `RagPlatformTool`（四段式 @Tool + ToolResult）— **可验证**：子 Agent 可调用检索；结果含 `[来源:]` 格式；无第三套 VectorStore
- [x] 11.2 前端：无 — **可验证**：N/A
- [~] 11.3 测试任务 — **跳过**（无 test-cases.md）
- [x] 11.4 **AUTO-UT**：`RagPlatformToolTest` — Mock Port 返回片段 — **可验证**：ToolResult.success
- [x] 11.5 执行 `check-spring-ai-tools.ps1`（RagPlatformTool 四段式）— **可验证**：见 gap G4.5
- [~] 11.6 执行 `mvn -Dtest=RagPlatformToolTest test` — **跳过**

**依赖**：1.1

---

## 12. 意图路由与单域路由（aether-agent-platform-router-2）

- [ ] 12.1 后端：完善路由 Prompt（`prompts/super-agents/router-system.txt`）+ SSE 路由摘要前缀 — **可验证**：客服/分析/代码/通用四类输入 smoke（MANUAL 或集成测试）
- [x] 12.2 前端：无 — **可验证**：N/A
- [~] 12.3 测试任务 — **跳过**（无 test-cases.md）
- [ ] 12.6 **MANUAL**：四类意图 Nebula Desk 验证路由摘要 — **ManualReason**：真实 LLM

**依赖**：9.1

---

## 13. TraceId 铺垫（design §7.4）

- [x] 13.1 后端：`SuperAgentChatApplicationService` 生成 traceId 写入 MDC + Micrometer — **可验证**：日志含 traceId；指标 tag 可查
- [x] 13.2 前端：无 — **可验证**：N/A
- [~] 13.3 测试任务 — **跳过**（无 test-cases.md）
- [x] 13.4 **AUTO-UT**：`SuperAgentChatTraceIdTest` — **可验证**：见 gap G7.3

**依赖**：9.1

---

## 14. P1 收口验证

- [x] 14.1a 后端：`mvn compile` — **可验证**：BUILD SUCCESS（见 verification-report）
- [~] 14.1b scoped `mvn -Dtest=...` 全通过 — **跳过**（同 G11.4）
- [x] 14.2 Harness：`make verify` / 存量债务 — **可验证**：`verification-report.md`（G11.5）
- [ ] 14.3 文档：ai 仓库 ARCHITECTURE 或模块说明补充 superAgents 边界 — **可验证**：文档含包路径与 agents 委托关系

**依赖**：9.1、11.1、4.1

---

## P2 占位（不在 P1 apply 勾选）

| 能力 | 概要任务 |
|------|----------|
| skill-engine | V6 skills、SkillRouterTool、CompileGraph Skill |
| knowledge-memory | agent_memory、LayeredChatMemoryAdvisor |
| chat-sse-contract | AgentProgress SSE + ai_react UI-FUNC |
| collaboration-2~4 | 上下文压缩、跨会话恢复、跨 Agent Skill |
| model-routing-3 | 模型灰度 |

## P3 占位

multi-tenant、observability、resilience、async-resume、MCP security TLS

## P4 占位

governance、dev-sdk、LastResort

---

**Apply 顺序建议**：0 → 1 → 2 → 5 ∥ 11 → 3 → 4 → 6 → 7 → 8 → 10 → 9 → 12 → 13 → 14

**测试占位说明**：test-cases.md 就绪后，回填各节 x.3 并映射 `[C]` → AUTO-UT / AUTO-AI-UT / MANUAL；未 Reviewed 前 x.4 可按 spec 场景先行编写 L1 单测（aiTddMode enabled）。
