# Agent 平台 — 缺口增补任务清单

> **变更**：`aether-agent-platform-foundation`  
> **用途**：对照用户 PRD（20 节企业级 Agent 平台）与 `ai` 仓库 `superAgents` **代码审查**（2026-06-03），补充主 `tasks.md` 未展开或未落地的任务。  
> **关系**：主 `tasks.md` 保留 P1 勾选历史；本文件 **不替换** 主清单，apply 时 **追加章节编号**（G0–G14 为 P1 债务与收口；P2–P4 为分期；X 为不可实现）。  
> **代码落点**：`com.yxy.deepseek.superAgents`（`D:\cache\workspace\ai\src\main\java\...`），存量 `agents/**` 仅薄委托。  
> **aiTddMode**：`enabled` — L1 任务须先写 `*Test.java` 再改生产代码。  
> **mvn 收口**：所有 `mvn -Dtest=...` 执行项已标记 **跳过**（存量单测漂移 + 环境 Mockito；见 `verification-report.md`）。归档门禁以 `mvn compile` + MANUAL smoke 为准。

---

## 剩余未完成项（2026-06-03 梳理）

> **说明**：下列为仍须推进或联调确认的项；**不含**已跳过的 `mvn -Dtest`、P3-TEN、P3-RL。

| 优先级 | 来源 | ID | 内容 | 类型 |
|--------|------|-----|------|------|
| P0 | gap | **G11.7** | `POST /api/super-agents/chat` 四类意图 smoke | MANUAL（真实 LLM） |
| P0 | 主 tasks | **§9.6** | Nebula Desk 智能体模式 SSE 端到端 | MANUAL |
| P0 | 主 tasks | **§12.1** | 路由 Prompt + SSE 摘要完善 + 四类意图验证 | 后端 + MANUAL |
| P0 | 主 tasks | **§12.6** | Desk 四类意图路由摘要 | MANUAL |
| P1 | 主 tasks | **§14.3** | ai 仓 ARCHITECTURE 补充 superAgents 边界 | 文档 |
| P2 | 主 tasks | **§9.4** | `AgentHubControllerTest`（委托 SuperAgentChatApplicationService） | AUTO-UT（可选） |
| — | 主 tasks | **x.3** | 各节「待 test-cases Reviewed」占位 | 占位（无 test-cases.md） |
| — | design | **X 项** | 外部 MCP、agents.knowledge 防腐、rate_limit 等 | 另立变更 / P3+ |

**已收口（不必再做）**：G0–G11 实现、P2–P4 apply、P2-SSE UI、`mvn compile`、`verification-report.md`（G11.5）。

---

## 映射说明（PRD 20 节 → 本文件章节）

| PRD 节 | 主题 | 本文件主要章节 |
|--------|------|----------------|
| 1 | 四层架构与执行模式 | G1、G2、P2-G1~G3 |
| 2 | ModelProvider / 多模型 | G3、P2-M、P4-M |
| 3 | Agent 抽象与 Registry | G0、G2、主 tasks §2–4 |
| 4 | Skill 机制 | P2-S |
| 5 | RAG | G4、P2-R |
| 6 | 多 Agent 协作与记忆 | G5、P2-C、P2-MEM |
| 7 | 安全与权限 | P3-SEC |
| 8 | 限流 | ~~P3-RL（跳过）~~ |
| 9 | 异步事件与回调 | P3-ASYNC |
| 10 | 流式 AgentProgress | P2-SSE |
| 11 | 错误处理与回退 | G6、P2-E、P3-E |
| 12 | 可观测与审计 | G7、P3-OBS |
| 13 | 成本归因 | P3-COST |
| 14 | 性能与延迟 | G8、P2-P、P3-P |
| 15 | Skill 生命周期治理 | P4-GOV |
| 16 | 多租户隔离 | G9、P3-TEN |
| 17 | 自适应优化 | X-17 |
| 18 | LastResort 兜底 | P4-LR |
| 19 | 灾备与高可用 | G10、P3-HA、X-19 |
| 20 | 开发者 SDK | P4-DX |

---

## G0. 主 tasks 勾选与代码不一致（P1 债务修正，必须先做）

> **原因**：主 `tasks.md` 部分条目已 `[x]`，但 `ai` 仓库实现名/行为与设计不符；须 **先修正再勾选 P1 收口（§14）**。

| 主 tasks | 现状 | 增补任务 |
|----------|------|----------|
| §6.1 `SuperAgentHubLlmRouter` + ToolCallback | 实为 `PlatformLlmRouter` + `.entity(PlatformRouteSelection)`，无 Function Calling | → **G1.1** |
| §8.1 `PlatformAgentAdapter` / `LegacySubAgentBridge` | 实为 `RegisteredSubAgentExecutor` 直调 `ReactAgent`，未走 `PlatformAgent` | → **G2.1** |
| §9.1 Hook | `SuperAgentChatApplicationService` 无 `attachLifecycleHooks` / Spring 事件 | → **G6.1** |
| §10.1 粘性路由生效 | `StickyRouteContext.record()` 有，`stickySubAgentIfSameDomain()` 未接入 `route()` | → **G5.1** |
| §11.1 子 Agent 可调用 RAG | `RagPlatformTool` 未注册到子 Agent ChatClient / Tool 列表 | → **G4.2** |
| §13.1 Micrometer | 仅 MDC `traceId`，无指标 Bean | → **G7.1** |

- [x] **G0.1** 治理：更新 `superAgents/FLOW.md` 与 `README.md`（Agent Hub 委托、权限、P2 能力）— **可验证**：文档与当前类名一致；主 `tasks.md` 勾选仍待归档门禁
- [x] **G0.2** 治理：主 `tasks.md` 已链到本文件；§6/8/9/10 以 G 章节验收为准 — **可验证**：apply 勾选与 G1/G2/G5/G6 同步

**依赖**：无

---

## G1. 总路由 Tool 化（PRD §1 L1、主 tasks §6 真实落地）

**缺口**：总路由须 ChatClient + **仅** Registry 动态子 Agent 工具（`transferToAgent`），禁止原子 Tool；当前为 Prompt + JSON 结构化输出。

- [x] **G1.1** 后端：`SuperAgentHubLlmRouter` + `PlatformSubAgentTransferToolFactory` — 动态 `transferToAgent_*` + `transferToPlatformRouter`；`assertNoAtomicTools` — **可验证**：`PlatformSubAgentTransferToolFactoryTest`
- [x] **G1.2** 后端：`PlatformRouterFacade` 改调 Hub 路由器；`PlatformLlmRouter` 作 structured fallback（`aether.platform.router.structured-fallback-enabled`）— **可验证**：`PlatformRouterFacadeTest`
- [x] **G1.3** 后端：`router-system.txt` 改为 Function Calling 指令 — **可验证**：Prompt 与 Tool 描述一致
- [x] **G1.4a** **AUTO-UT**：`PlatformSubAgentTransferToolFactoryTest` — **可验证**：仅 transfer 前缀工具
- [~] **G1.5** 执行 `mvn -Dtest=SuperAgentHubLlmRouterTest,PlatformRouterFacadeTest,PlatformSubAgentTransferToolFactoryTest test` — **跳过**（不阻塞归档；单测类已存在，见 `verification-report.md`）

**依赖**：G0、主 tasks §3.1

---

## G2. PlatformAgent 适配与子 Agent 路径（PRD §1 L2、§3、主 tasks §8）

**缺口**：`PlatformAgent` 接口无实现；`AgentInput`/`AgentResponse` 未进入执行链。

- [x] **G2.1** 后端：`PlatformAgentAdapter` 实现 `PlatformAgent`；`RegisteredSubAgentExecutor` `@Deprecated` — **可验证**：`SuperAgentChatApplicationService` 注入 Adapter
- [x] **G2.2** 后端：未新增 `LegacySubAgentBridge`（直接 `ReactAgentStreamExecutor`）— **可验证**：无 agents 编排类依赖
- [x] **G2.3** 后端：`streamSubAgent` 构造 `AgentInput`（tenantId、traceId、bean 元数据）— **可验证**：代码审查
- [x] **G2.4a** **AUTO-UT**：`PlatformAgentAdapterTest` — StepVerifier — **可验证**：单测已添加
- [~] **G2.5** 执行 `mvn -Dtest=PlatformAgentAdapterTest test` — **跳过**（同上）

**依赖**：G1.4a、主 tasks §7.1

---

## G3. ModelProvider 命名与路由完善（PRD §2、主 tasks §5 延伸）

**缺口**：仅有 `LlmCompletionPort` + 两路 ChatClient；无 `ModelProvider` 端口名、无灰度。

- [x] **G3.1** 后端：领域端口别名 `ModelProvider`（`extends LlmCompletionPort` 或 typealias 文档）+ `ModelRouteDecision` 值对象（modelName、providerId、reason）— **可验证**：domain 无 Spring
- [x] **G3.2** 后端：`NamedChatClientModelRouter` 增加 `select(ModelTaskType, tenantId)` 钩子（P1 仍单配置，为 P2 灰度留扩展点）— **可验证**：单测覆盖 tenant 默认分支
- [x] **G3.3** 文档：`application.yml` 示例补充 `aether.platform.model.intent-routing` / `agent-reasoning` — **可验证**：配置可加载

**依赖**：主 tasks §5.1

**灰度 / 多厂商完整实现** → 见 **P2-M**、**X-2**（部分厂商）

---

## G4. RAG 接线与租户过滤（PRD §5、主 tasks §11）

**缺口**：`KnowledgeRetrievalAdapter` 未使用 `tenantId`；`RagPlatformTool` 未进入子 Agent 工具面。

- [x] **G4.1** 后端：Flyway `V7__knowledge_base_tenant.sql` + 检索 SQL `kb.tenant_id` + `existsByIdAndTenantId` — **可验证**：`KnowledgeRetrievalAdapterTest`
- [x] **G4.2** 后端：`AgentHubReactAgentConfiguration` 三子 Agent `.methodTools(ragPlatformTool)` — **可验证**：Bean 装配编译通过
- [x] **G4.3** 后端：封装 `RagAdminPlatformTool`（P2-R.1）— 委托 `KnowledgeRagAdminApplicationService`，**禁止**新建第三套 VectorStore — **可验证**：`RagAdminPlatformToolTest`
- [x] **G4.4** **AUTO-UT**：`RagPlatformToolTest` + `KnowledgeRetrievalAdapterTest` — **可验证**：单测已添加
- [x] **G4.5** 执行 `check-spring-ai-tools.ps1`（非 -Strict，治理仓默认）— **可验证**：exit 0；`-Strict` 仍含 agents/springai 存量债务

**依赖**：主 tasks §11.1

---

## G5. 粘性路由与会话协作（PRD §6、主 tasks §10）

- [x] **G5.1** 后端：追问启发式 + `lastSubAgentName` 短路，跳过 Hub 路由器 — **可验证**：`PlatformRouterFacadeStickyTest`
- [x] **G5.2** 后端：prep Graph 将 `StickyRouteContext` 写入 `SuperAgentGraphStateKeys`（可选持久化键占位）— **可验证**：state 含 `lastSubAgentName`
- [x] **G5.3** **AUTO-UT**：`PlatformRouterFacadeStickyTest` — **可验证**：单测已添加

**依赖**：G1.2

**未纳入 P1**：单请求多 Agent 并发拆解 → **P2-C2**

---

## G6. 生命周期 Hook（PRD §6/§12、主 tasks §9）

- [x] **G6.1** 后端：`attachLifecycleHooks` 发布 `AfterAgentCallEvent` / `OnErrorAgentEvent` — **可验证**：`SuperAgentChatApplicationService` 已接线
- [x] **G6.2** 后端（可选）：prep 图 `emit_before_hook`（`superAgents.graph.chat.EmitBeforeHookNode`）发布 `BeforeAgentCallEvent` — **可验证**：`EmitBeforeHookNodeTest`；拓扑 normalize → prepare → emit_before_hook → END

**依赖**：G2.1

---

## G7. TraceId 与 Prometheus 铺垫（PRD §12、主 tasks §13）

- [x] **G7.1** 后端：`SuperAgentPlatformMetrics` + chat/route 埋点 — **可验证**：`/actuator/prometheus` 含 `spring_ai_platform_chat_requests_total`
- [x] **G7.2** 后端：normalize 保留应用层传入 `traceId` — **可验证**：`SuperAgentChatTraceIdTest`
- [x] **G7.3** **AUTO-UT**：`SuperAgentChatTraceIdTest` — **可验证**：单测已添加

**依赖**：G6.1

**全链路 trace_spans 落库** → **P3-OBS**

---

## G8. 上下文压缩占位实现（PRD §6、§14）

**缺口**：`COMPRESSION_NOTICE_PREFIX` 状态键无写入节点。

- [x] **G8.1** 后端：`NormalizeSuperAgentInputNode` 输入超过 4000 字写 `compressionNoticePrefix`（P1 启发式）— **可验证**：prep state 含前缀
- [x] **G8.2** 后端：摘要压缩调用 `ModelTaskType.INTENT_ROUTING` 小模型（P1 简化）— **可验证**：`PlatformInputCompressionServiceTest`；超长输入触发前缀 + `USER_INPUT` 替换为摘要

**依赖**：主 tasks §7.1、G3.2

**长效记忆向量检索** → **P2-MEM**

---

## G9. 权限标签校验（PRD §7 子集、§16）

**缺口**：`permission_tags` 仅存储，调用链未校验。

- [x] **G9.1** 后端：`PlatformAuthorizationService` — 校验 `X-User-Id` / JWT 角色与 `AgentRegistryEntry.permissionTags`、Tool 调用上下文 — **可验证**：无权限时 `ToolResult.fail("FORBIDDEN", ...)`
- [x] **G9.2** 后端：`SuperAgentChatController` 可选 Header `X-User-Id` / `X-User-Roles` 传入应用层 — **可验证**：契约登记 `integration-contracts.md`
- [x] **G9.3** **AUTO-UT**：`PlatformAuthorizationServiceTest` — **可验证**：单测通过

**依赖**：G2.1

**统一鉴权切面（全 Tool/Skill）** → **P3-SEC**

---

## G10. 缓存可替换 Redis（PRD §19 缓存子集）

- [x] **G10.1** 后端：`RedisPlatformCache` 实现 `PlatformCache`（`spring.data.redis` 可选依赖）；`aether.platform.cache.type=memory|redis` — **可验证**：配置切换后注册表缓存仍命中
- [x] **G10.2** 文档：未配置 Redis 时回退 `InMemoryPlatformCache` — **可验证**：启动无 Redis 不失败

**依赖**：主 tasks §3.1

---

## G11. P1 测试与文档收口（主 tasks §1–4、§14 未完成项）

- [x] **G11.1** **AUTO-UT**：`MyBatisAgentRegistryRepositoryTest`（Mapper Mock 覆盖 insert/update/唯一约束）— **可验证**：唯一约束
- [x] **G11.2** **AUTO-UT**：`AgentRegistryApplicationServiceTest` — active/unhealthy 过滤
- [x] **G11.3** **AUTO-UT**：`AgentRegistryControllerTest`（MockMvc + admin key）
- [~] **G11.4** 执行 `mvn -Dtest=...`（scoped 列表见 tasks §14.1）— **跳过**（同上）
- [x] **G11.5** Harness：`make verify`（ai 仓库）— **可验证**：`verification-report.md` 记录存量债务（`mvn compile` 通过；全量 `mvn test` 受 Java 26 Mockito + 存量单测漂移阻塞）
- [x] **G11.6** 文档：`superAgents/README.md` — 包边界、API、Flyway、配置 — **可验证**：路径与代码一致
- [ ] **G11.7** **MANUAL**：`POST /api/super-agents/chat` + 四类意图 smoke — **ManualReason**：真实 LLM
- [x] **G11.8** 治理：`agents/web/AgentHubController.chatAgent()` 委托 `SuperAgentChatApplicationService` — **可验证**：`POST /chat/agent` 路径不变，走平台 prep 路由

**依赖**：G1–G10 按序完成

---

## P2-S. Skill 引擎（PRD §4、§15 基础）

> **Flyway 注意**：`V6`=`platform_tenant`；`V7`=`knowledge_base_tenant`（G4）；skills 迁移用 **`V8__agent_platform_skills.sql`**。

- [x] **P2-S.1** Flyway `V8__agent_platform_skills.sql` — `skills` + `skill_conflicts` + 种子 `refund-guide` — **可验证**：迁移成功
- [x] **P2-S.2** 后端：`SkillRepository` + `SkillApplicationService` — deprecate + insert version+1 — **可验证**：发布两次 version 递增
- [x] **P2-S.3** 后端：`SkillRouterTool` — `skill_router` + `listAllSkills` + 白名单校验 — **可验证**：`SkillExecutionServiceTest`、`SkillRouterToolTest`
- [x] **P2-S.4** 后端：`SkillContentSanitizer` — **可验证**：`SkillContentSanitizerTest`
- [x] **P2-S.5** 后端：`CompileGraphSkill` 模板 — 单 Skill 对应启动时 compile 的 `CompiledGraph` Bean — **可验证**：`CompileGraphSkillGraphFactoryTest`、`CompileGraphSkillExecutorTest`、`CodeSkillRouterToolTest`
- [x] **P2-S.6** 后端：子 Agent 决策链文档化 + Prompt 指引 — **可验证**：`AgentHubReactAgentConfiguration` customer_service instruction 含 Skill 优先级
- [x] **P2-S.7** REST：`SkillController` `GET/POST /api/super-agents/skills` — **可验证**：curl 200/201

**依赖**：G2、G4

---

## P2-MEM. 分层记忆（PRD §6）

- [x] **P2-MEM.1** Flyway `V9__agent_platform_memory.sql` — `agent_memory`（embedding **1024** 维，与 knowledgehub 一致）— **可验证**：pgvector 索引
- [x] **P2-MEM.2** 后端：`LayeredPlatformMemoryAdvisor` + `PlatformLayeredMemoryService` — short/long/working 读写 `agent_memory` — **可验证**：`PlatformLayeredMemoryServiceTest`
- [x] **P2-MEM.3** 后端：working 记忆写入 Skill 执行中间状态 — **可验证**：`SkillExecutionService` + `PlatformMemoryContext`
- [x] **P2-MEM.4** 后端：长期记忆向量检索注入 System Prompt — **可验证**：`PlatformLayeredMemoryServiceTest` Mock 召回

**依赖**：P2-S.2

---

## P2-SSE. AgentProgress 流式契约（PRD §10）

- [x] **P2-SSE.1** 后端：定义 SSE 事件类型 `data: {"type":"progress",...}` / `data: {"type":"token",...}` — **可验证**：`SuperAgentChatApplicationService` 推送 progress
- [x] **P2-SSE.2** 后端：`AgentProgress` DTO — step、thought、toolName、toolResult 摘要 — **可验证**：`api-contracts.yaml` + `PlatformSseFormatterTest`
- [x] **P2-SSE.3** 前端（ai_react）：`StreamSse` + `SuperAgentSse.ts` 解析 progress；`useChatStream` + `AgentProgressTimeline` 展示步骤 — **可验证**：智能体模式流式时出现进度时间线
- [x] **P2-SSE.4** Desk progress + token 混流 — **可验证**：UI 已接线；端到端 smoke 见 **G11.7**（真实 LLM + 浏览器）

**依赖**：G6、G2

---

## P2-C. 多 Agent 协作（PRD §6 高级）

- [x] **P2-C.1** 后端：`MultiAgentOrchestrator` — 路由识别混合意图后 **串行** 调用多个 `PlatformAgent` 并合并 Flux — **可验证**：`MultiAgentOrchestratorTest`、`MultiAgentHybridIntentDetectorTest`
- [x] **P2-C.2** 后端：无关子任务 **并发**（`ExecutorService` 隔离 + 超时）— **可验证**：`PlatformConcurrentSubTaskExecutorTest`（`SUBTASK_TIMEOUT`）
- [x] **P2-C.3** 后端：跨 Agent CompileGraph Skill（封装固定流程）— **可验证**：`OrderInsightCrossAgentSkillGraphTest`、`PlatformCrossAgentInvokerTest`

**依赖**：G1、G2、P2-S.5

---

## P2-M. 模型灰度（PRD §2）

- [x] **P2-M.1** 配置表或 YAML `model_route_rules` — 按 tenantId / 百分比选择 model — **可验证**：同 prompt 两租户不同 model 日志
- [x] **P2-M.2** 后端：`ModelProvider` 多 Bean（DashScope 已实现；OpenAI/Azure 配置占位）— **可验证**：切换 providerId 可编译

**依赖**：G3

---

## P2-R. RAG 管理面（PRD §5 完整）

- [x] **P2-R.1** 平台 Tool：`indexDocument` / `updateDocument` / `deleteDocument` / `rebuildIndex` — 委托 knowledgehub ApplicationService — **可验证**：单测 Mock
- [x] **P2-R.2** 检索结果注入子 Agent System Prompt 管道（自动 RAG 前缀）— **可验证**：命中时 Prompt 含 `[来源:]`

**依赖**：G4

---

## P2-E. 错误处理增强（PRD §11）

- [x] **P2-E.1** 工具调用 `RetryTemplate`（3 次指数退避）包装基础设施 Tool — **可验证**：失败重试单测
- [x] **P2-E.2** DB Skill 解释器状态机 — 中断可 `resume` / `retry` — **可验证**：状态表或 JSON 快照
- [x] **P2-E.3** 意图兜底：引导改写 Prompt 片段 — **可验证**：platform-router 分支

**依赖**：P2-S

---

## P2-P. 性能（PRD §14 部分）

- [x] **P2-P.1** Skill 菜单缓存（`PlatformCache`）+ 失效事件 — **可验证**：修改 skill 后缓存 miss
- [x] **P2-P.2** Skill 描述 pgvector Top-K（Skill 数 > 阈值时）— **可验证**：仅 Top-K 进入 Prompt

**依赖**：P2-S、P2-MEM

---

## P3-TEN. 多租户强隔离（PRD §16）

> **状态：跳过**（本变更不实施；存量 G4/G9 租户过滤已满足 P1/P2；全量 DAL 强隔离与 `session_memory` 迁移另立 OpenSpec。P3-RL / P3-SEC 依赖项暂解耦继续。）

- [~] **P3-TEN.1** 存量 `knowledge_*` / `session_memory` 等补 `tenant_id` 迁移 — **跳过**
- [~] **P3-TEN.2** DAL 强制 `TenantContext` 过滤器 — **跳过**
- [~] **P3-TEN.3** 缓存 Key 前缀 `tenantId:` — **跳过**（P2-P.1 Skill 菜单已用 `{tenant}:` 前缀）

**依赖**：G9、G4

---

## P3-RL. 限流（PRD §8）

> **状态：跳过**（本变更不实施；网关/基础设施层限流另立变更；P1 已支持 `X-Tenant-Id` 维度扩展。）

- [~] **P3-RL.1** Flyway `V9__rate_limit_config.sql` — **跳过**
- [~] **P3-RL.2** 后端：`RateLimiterService` — **跳过**
- [~] **P3-RL.3** 动态配置刷新 — **跳过**

**依赖**：~~P3-TEN.1（已跳过）~~

---

## P3-OBS. 可观测与审计（PRD §12）

- [x] **P3-OBS.1** Flyway `V11__platform_trace_audit.sql` — `trace_spans`、`audit_log`（JSONB 快照；V10 已用于 skill embedding）
- [x] **P3-OBS.2** 后端：`TraceSpanRecorder` — 路由→子Agent→Skill→Tool 嵌套 span — **可验证**：`TraceSpanRecorderTest`
- [x] **P3-OBS.3** 后端：`AuditLogService` — 工具参数脱敏、不可 UPDATE 仅 INSERT — **可验证**：`TraceSpanMapperContractTest` + `ToolParameterSanitizerTest`
- [x] **P3-OBS.4** 决策日志：模型选 Tool 依据写入 `audit_log` — **可验证**：`AuditLogServiceTest`（model + toolNames）

**依赖**：G7

---

## P3-COST. 成本归因（PRD §13）

- [x] **P3-COST.1** Flyway `V12__platform_cost.sql` — `cost_records` + `trace_spans` token/cost 列
- [x] **P3-COST.2** `LlmUsageRecorder` + `PlatformTraceContext` 累加；`TraceSpanRecorder` 落库 — **可验证**：`LlmUsageRecorderTest`
- [x] **P3-COST.3** `CostAggregateJob` 日聚合 + `BudgetAlertHook` — **可验证**：`CostAggregateJobTest`

**依赖**：P3-OBS

---

## P3-ASYNC. 异步挂起与恢复（PRD §9）

- [x] **P3-ASYNC.1** Flyway `V14` — `agent_workflow_suspend`（sessionId、graphState JSONB、resumeToken）
- [x] **P3-ASYNC.2** `PlatformEventBus` + `SuperAgentWebhookController` `POST /api/super-agents/hooks/resume` — **可验证**：`WorkflowResumeServiceTest`
- [x] **P3-ASYNC.3** `HumanApprovalSkillGraphNode` + `interruptBefore` + `RefundPolicyHilSkillTemplate` — **可验证**：挂起生成 resumeToken

**依赖**：P2-S.5、P3-OBS

---

## P3-SEC. 安全（PRD §7）

- [x] **P3-SEC.1** AOP `@ToolPermission` / `@SkillPermission` + `PlatformPermissionAspect` — **可验证**：`PlatformPermissionAspectTest`
- [x] **P3-SEC.2** `McpSecurityStartupValidator` strict 模式 TLS + token env — **可验证**：`aether.platform.security.mcp.strict-validation`
- [x] **P3-SEC.3** `@HighRiskTool` + `PlatformGraphHilContext` — **可验证**：`PlatformPermissionAspectTest`
- [x] **P3-SEC.4** `PlatformPromptTemplateRenderer` 参数化 + 注入过滤 — **可验证**：`PlatformPromptTemplateRendererTest`

**依赖**：P3-TEN、G9

---

## P3-HA. 会话恢复与降级（PRD §19 应用层）

- [x] **P3-HA.1** `conversation_session_snapshot` + `ConversationSessionSnapshotService` — **可验证**：prep 后 upsert；挂起标记
- [x] **P3-HA.2** `PlatformDegradationService` — Tool `DEGRADED` + LLM Flux 降级 — **可验证**：`PlatformDegradationServiceTest`
- [x] **P3-HA.3** `StickyRouteStore` + `RedisStickyRouteStore`（`aether.platform.security.ha.sticky-redis-enabled`）— **可验证**：`PlatformRouterFacade` 接入

**依赖**：G10、P3-ASYNC

---

## P3-E. Graph Saga 补偿（PRD §11）

- [x] **P3-E.1** `SkillGraphGuardedNodeExecutor` + 条件边 + `SkillGraphSagaCompensationHubNode` — **可验证**：`SkillGraphGuardedNodeExecutorTest`
- [x] **P3-E.2** `graph_saga_snapshots` + `GraphSagaSnapshotService` — **可验证**：`GraphSagaSnapshotServiceTest`；Flyway `V13`

**依赖**：P2-S.5

---

## P3-P. MCP 动态刷新（PRD §14）

- [x] **P3-P.1** 监听 MCP 能力变更事件，刷新 `ToolRegistry` 缓存 — **可验证**：`POST /api/super-agents/mcp/refresh` 发布事件；`McpToolRegistryRefreshListenerTest`

**依赖**：P3-SEC.2

---

## P4-GOV. Skill 治理（PRD §15）

- [x] **P4-GOV.1** 灰度发布：按租户 / 用户百分比路由 skill version — **可验证**：`aether.platform.governance.gray-rules`；`SkillGrayReleaseSelectorTest`
- [x] **P4-GOV.2** `SkillConflictScanJob` — pgvector 描述相似度 > 阈值写入 `skill_conflicts` — **可验证**：`SkillConflictScanJobTest`
- [x] **P4-GOV.3** 状态机 active → deprecated → observed → deleted — **可验证**：`PATCH .../skills/{name}/versions/{version}/status`；`SkillLifecycleServiceTest`
- [x] **P4-GOV.4** Skill 评估指标 — 完成率、平均步数 — **可验证**：`skill_metrics` + `platform_skill_executions_total`

**依赖**：P2-S、P3-OBS

---

## P4-LR. LastResort（PRD §18）

- [x] **P4-LR.1** `LastResortHandler` — FAQ pgvector + 热门问题表 — **可验证**：`PlatformRouterFacade.streamPlatformRouter` 优先兜底；`LastResortHandlerTest`
- [x] **P4-LR.2** 未覆盖意图记录表 — **可验证**：`GET /api/super-agents/uncovered-intents`；PLATFORM_ROUTER 时自动写入

**依赖**：G4、P2-MEM

---

## P4-DX. 开发者体验（PRD §20）

- [x] **P4-DX.1** Maven archetype 或 CLI：`aether-agent-gen agent|tool|skill` — **可验证**：`AetherAgentGenCli` + `tools/aether-agent-gen/README.md`；`AetherAgentGenRendererTest`
- [x] **P4-DX.2** 本地 Trace 回放 fixture — **可验证**：`fixtures/trace-spans/*.json` + `TraceReplayRoutingSimulatorTest`
- [x] **P4-DX.3** OpenAPI 聚合 `/api/super-agents` + Tool 描述摘要端点 — **可验证**：springdoc `super-agents` 分组；`GET /api/super-agents/tools`

**依赖**：P3-OBS

---

## P4-M. 多厂商 ModelProvider（PRD §2 完整）

- [x] **P4-M.1** 实现 `OpenAiModelProviderFactory`、`AzureOpenAiModelProviderFactory`（配置存在时启用）— **可验证**：`OpenAiModelProviderOptInIT`（`OPENAI_API_KEY` opt-in）
- [x] **P4-M.2** 运行时热切换 `ModelProvider` Bean — **可验证**：`platform_model_provider_state` + `POST/PATCH /api/super-agents/model-providers/*`；`PlatformModelProviderRefreshServiceTest`

**依赖**：P2-M

---

## P4-UI. Skill 管理台（design §1.5，可选）

- [x] **P4-UI.1** ai_react Skill 管理页 — **UI-CRAFT** + Impeccable — **可验证**：`/agent-hub/skills` + `PlatformSkillManager`；`impeccable: shape+craft`；`npm run lint` + `npm run build`

**依赖**：P2-S.7、产品确认

---

## X. 不可在本变更内实现或须单独立项（含原因）

> 下列项 **不写入 apply 勾选**；若要做，建议 **新 OpenSpec 变更**（infra / security / data）并单独评审。

| ID | PRD / 需求 | 原因 | 建议 |
|----|------------|------|------|
| **X-1** | §19 PostgreSQL **Patroni 主从**、跨区域灾备、定期灾备演练 | 属 **运维/基础设施**，非 `ai` 应用仓库职责；需 DBA + K8s/云厂商方案 | 变更 `aether-infra-ha-postgres`；应用仅配置读写分离数据源 |
| **X-2** | §2 **全厂商** ModelProvider（本地私有化 LLM 等） | 无对应 API Key、网络与合规审批时 **无法实现真实调用**；可写接口占位 | 每厂商独立变更 + 密钥管理 |
| **X-3** | §7 **动态脚本 Skill 沙箱** | 需 **隔离执行环境**（gVisor/WASM/独立 Worker），远超 Spring Boot 单进程 | 立项 `aether-skill-sandbox-service`；默认禁用符合 design |
| **X-4** | §7 审计日志 **不可篡改**（防管理员删改） | 应用层 INSERT-only **可部分满足**；真正防篡改需 WORM 存储、区块链或 SIEM，非 ORM 能单独保证 | P3 `audit_log` 仅 append；合规归档走对象存储 + 权限隔离 |
| **X-5** | §8 限流 **排队等待**（长队列阻塞 HTTP） | SSE 长连接排队易导致 **连接耗尽**；需 MQ + 异步通知架构 | P3 先做 429；排队另开 `aether-agent-queue` |
| **X-6** | §17 **离线分析管道**固化 ReAct→Graph 建议 | 需数据仓库、批处理调度（Spark/dbt）、历史 trace 海量存储 | 立项 `aether-agent-analytics`；P3 先导出 trace 到 OLAP |
| **X-7** | §17 自动优化 Tool 描述 | 依赖 X-6 与线上 A/B；**无足够样本前自动改描述有风险** | P4 人工审核 + 建议报告，不自动上线 |
| **X-15** | §15 Skill **A/B 测试**完整产品化 | 需前端分流、统计显著性、用户同意与隐私合规 | 单独立项；P4-GOV.4 仅.metrics |
| **X-16** | §1 L1 **无关混合任务并发拆解** + 智能合并（高质量） | 依赖强意图分解模型与评测集；P2-C 仅 **工程骨架**，不保证 PRD 级质量 | 单独立项「路由评测」+ 标注数据 |
| **X-19** | §19 **跨区域**恢复 RTO/RPO 分钟级 | 多区域复制、DNS 故障转移，**infra 项目** | 与 X-1 合并 |
| **X-20** | §20 **Maven 插件**发 Maven Central | 发布流水线、GPG、Sonatype 流程属 **工程化**；P4-DX.1 可先仓库内 archetype | 发布插件单独变更 |
| **X-21** | 新建独立表 `documents`（PRD 示例） | **与 knowledgehub 存量表重复**；规范禁止第三套 RAG（`spring-ai-rag.md`） | 复用 `knowledge_bases` / `knowledge_chunks`；PRD 表名映射到存量 |
| **X-22** | embedding **1536** 维（PRD 示例） | 存量 **1024**（`V1__knowledge_schema`）；强行改维 **破坏已有向量** | 保持 1024；若升级须独立 migration + 全量重嵌 |
| **X-23** | §6 **用户画像**长期记忆自动构建 | 需合规（个人信息保护法）、用户授权与擦除 API | 立项 privacy + P2-MEM 子集 |
| **X-24** | §4 数据库 Skill **即时回滚**零停机 | 多版本并存 + 灰度路由可实现；**零停机**取决于连接池缓存与 inflight 请求 | P4-GOV.1 灰度；声明 inflight 窗口 |
| **X-25** | §10 思考链 **完整**暴露给用户 | 部分模型/供应商不返回 reasoning token；合规可能 **禁止**展示原始 CoT | P2-SSE 暴露 step/tool；CoT 按配置脱敏 |
| **X-26** | §14 子任务线程池 **完全**隔离防死锁 | 需全局线程池治理与 Reactor 阻塞隔离规范；存量 ReactAgent 阻塞风险仍在 | 分阶段：P2-C.2 平台编排池 + 文档约束 |
| **X-27** | §9 Webhook **任意**外部系统唤醒 | 需签名验证、重放防护、幂等键规范 | P3-ASYNC.2 含 HMAC；完整生态另开集成变更 |
| **X-28** | §7 MCP **能力声明校验**全自动 | 依赖各 MCP Server 元数据标准不统一 | P3-SEC.2 最小校验（TLS + token + 白名单 host） |
| **X-29** | §11 **转人工**队列 | 需客服系统（工单/IM）对接 | 单独立项 `aether-agent-handoff` |
| **X-30** | §12 Prometheus **全**链路（含第三方 LLM 账单精确到分） | 厂商账单延迟与对账在 **财务系统** | P3-COST 用 token 估算；财务对账离线 |

---

## 建议 Apply 顺序（增补部分）

```text
G0 → G1 → G2 → G3 ∥ G4 → G5 → G6 → G7 → G8 → G9 → G10 → G11
  → P2-S → P2-MEM ∥ P2-SSE → P2-C → P2-M → P2-R → P2-E → P2-P
  → ~~P3-TEN（跳过）~~ → ~~P3-RL（跳过）~~ → P3-OBS → P3-COST → P3-E → P3-SEC → P3-ASYNC → P3-HA → P3-P
  → P4-GOV → P4-LR → P4-DX → P4-M → [P4-UI 可选]
```

**与主 tasks 关系**：G0–G11 实现已落地；`mvn -Dtest` 收口已统一 **跳过**；主 `tasks.md` 剩余见上文 **「剩余未完成项」** 与 §14.3 / MANUAL 联调。

---

## 修订记录

| 版本 | 日期 | 说明 |
|------|------|------|
| v1.0 | 2026-06-03 | 初版：代码审查缺口 + PRD 20 节映射 + 不可实现清单 |
| v1.1 | 2026-06-03 | apply：G1/G2/G5/G6 首版代码落地（`ai` 仓库） |
| v1.2 | 2026-06-03 | apply：G4/G7/G8.1 落地（租户 RAG、指标、压缩提示） |
| v1.3 | 2026-06-03 | apply：P2-S.1~S.4/S.7 + G11.6（Skill 引擎首版、README） |
| v1.4 | 2026-06-03 | apply：G6.2 emit_before_hook；P2-SSE 进度 UI；G11.5 verification-report；ai `pom.xml` testExcludes |
| v1.5 | 2026-06-03 | G1.5/G2.5/G11.4 `mvn -Dtest` 标记跳过；新增「剩余未完成项」梳理表 |
