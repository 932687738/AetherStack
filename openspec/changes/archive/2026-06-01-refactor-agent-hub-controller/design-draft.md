# Agent Hub 智能体对话规范重构 - 整体方案

## 一、核心问题

**要解决什么问题**：`POST /api/agent-hub/chat/agent` 虽已接入 CompiledGraph prep + `AgentChatApplicationService`，但 prep 仍依赖关键词 `IntentRouter` / `SubAgent.matchScore`，正文流仍经 `AgentChatService` + 自研 `ToolRegistry` + `Skill` 聚合工具，与 AetherStack 目标架构（RouterAgent、`@Tool` 四段式、ReactAgent 工具链、CompiledGraph 节点适配器）不一致；Controller 仍注入 `OrchestratorAgent` / `List<Skill>` 供 `/status` 等旁路使用，增加维护与认知成本。

**技术挑战**：
- **双轨编排**：prep 已 Graph 化，但路由与工具仍沿用 Orchestrator 时代组件（`OrchestrationPlan`、`ToolRegistry.toolObjectsForNames`），需在不破坏 SSE 契约前提下分阶段替换
- **SubAgent 存量**：`CustomerServiceAgent`、`DataAnalysisAgent`、`CodeGenerationAgent` 等实现 `SubAgent` 接口并共用 `AgentChatService`；需求开发类 SubAgent（`ProjectManagerAgent` 等）须保留在 `/requirement-dev` scope，chat 重构不得误伤
- **工具规模**：本地 `@Tool`（`DateTimeTools`、`WeatherTools`、`FileTools`、`ExternalAiCliTools`）+ MCP 外部回调合计可能超过单次 LLM ≤5 约束，需引入动态注入
- **L1 测试**：prep 节点、`AgentChatApplicationService` 流式分支、`AgentChatDomainService` 路由决策属 L1（`aiTddMode: auto` 将命中）

---

## 二、整体思路

### 现状调用链（As-Is，已代码追踪）

```text
AgentHubController.chatAgent (L62)
  → AgentChatApplicationService.streamAgentChat
      → agentChatPrepCompiledGraph.invoke  (单例 Bean)
          normalize_input → prepare_agent_chat → emit_before_hook
      → resolveBodyStream by STREAM_ROUTE:
          DIRECT_WEATHER/DATETIME → Flux.just(directAnswer)
          SUB_AGENT → SubAgent.process → AgentChatService
          ORCHESTRATOR → AgentChatService.stream + ToolRegistry
  → metrics doOnComplete/doOnError

PrepareAgentChatNode
  → AgentChatDomainService.resolveAgentPlan
      → ChatModePlanResolver → IntentRouter.routeAgentPlan (关键词 + 内置能力得分)
  → resolveStreamRoute / buildAgentContext / buildRoutingSummaryPrefix

OrchestratorAgent：chat 路径 **已无调用**；仅 AgentHubController.status → AgentHubDocumentationService
Skill：ProductivitySkill → ToolRegistry 启动扫描注入 DateTimeTools
ToolRegistry：包扫描 agents.tool.functions + Skill 工具 + MCP ToolCallbackProvider
```

### 目标调用链（To-Be）

```text
AgentHubController.chatAgent
  → AgentChatApplicationService.streamAgentChat   (不变入口)
      → CompiledGraph prep (保留线性拓扑，替换 prepare 节点内部路由源)
          RouterDecisionNode 或 PrepareAgentChatNode 内调用 AgentHubRouter
      → resolveBodyStream:
          DIRECT_* 保留确定性直答（不经 LLM）
          SUB_AGENT → 对应 ReactAgent.stream / invoke（替代 SubAgent.process + ChatClient 手写）
          ORCHESTRATOR → OrchestratorReactAgent 或 ChatClient + ToolCallbackProvider（不经 ToolRegistry 白名单拼装）
  → Hook / 前缀 / metrics 不变

AgentHubRouter (新)
  → transferToAgent 语义路由至 vertical Agent
  → 结构化日志：conversationId + selectedAgent（脱敏）

/status 旁路
  → AgentHubDocumentationService 改依赖 AgentRegistry / ToolCatalog（只读），去除 OrchestratorAgent + Skill 列表硬依赖
```

**业务场景 → 处理方式**：

| 场景 | 处理方式 |
|------|----------|
| 用户问天气/时间 | 保留 `WeatherDirectAnswerService` / `DatetimeDirectAnswerService` 确定性直答（REQ-3） |
| 用户意图命中垂直域（客服/数据/代码） | RouterAgent 选子 Agent → 对应 ReactAgent 流式输出 |
| 通用问答 / 多工具 | Orchestrator ReactAgent 或 ChatClient + 动态 Top-K 工具 |
| 工具数 >5 | prep 或 stream 前按 prompt 向量检索注入 3~5 个 `@Tool` |
| `/status` 诊断 | 从 AgentRegistry / ToolCatalog 读取，不经过 OrchestratorAgent |

**分阶段实施建议（本变更内）**：

1. **P2a 路由与注册表**：新增 `agents.agent.router` 包（Router 配置 + AgentRegistry）；prep 节点改调 Router；关键词得分降级为 Router 输入特征之一（非唯一决策）
2. **P2b 子 Agent ReactAgent 化（chat 三剑客）**：`CustomerServiceAgent`、`DataAnalysisAgent`、`CodeGenerationAgent` 各配 ReactAgent Bean；`SubAgent.process` chat 路径委托 ReactAgent
3. **P2c 工具链收敛**：`AgentChatService` 去除 `ToolRegistry` 依赖，改用 `MethodToolCallback` / `ToolCallbackProvider`；移除 chat 对 `Skill` 的依赖；补齐 `@Tool` 四段式
4. **P2d 遗留清理**：删除/废弃 `OrchestratorAgent` chat 相关死代码（含 `processKnowledgeMode`）；Controller 去 `OrchestratorAgent`/`List<Skill>` 注入；更新 ModuleGuide / domain-models
5. **P2e L1 单测**：prep 路由、ApplicationService 流式组装、Router 决策 Mock 测试

---

## 三、技术选型

| 功能场景 | 技术组件 | 使用理由 |
|---------|---------|---------|
| Prep 流水线（上下文、压缩、Hook） | **CompiledGraph** 单例 Bean（现有 `AgentGraphConfiguration`） | 已有实现；节点仅适配器，规则在 `AgentChatDomainService` |
| 意图路由 / 子 Agent 选择 | **RouterAgent** + `transferToAgent` | 对齐 `spring-ai-multi-agent-standards.md`；替代纯关键词 `IntentRouter` 作为唯一决策 |
| 垂直子能力（客服/数据/代码） | **ReactAgent** Bean（每域一个） | 工具密集、ReAct 循环；参考 `RecommendedPackagingAlibabaAgentConfig`、`humanLoop` ReactAgent 配置 |
| 编排器兜底 + 轻量工具 | **ChatClient** + `ToolCallback` | 工具少、无多轮 ReAct 时保持现有流式体验；与 ReactAgent 并存 |
| 确定性天气/时间 | 保留 **DirectAnswerService** | 无 LLM 成本；已在 `AgentChatDomainService.resolveStreamRoute` 优先 |
| 工具发现（chat 主路径） | Spring AI **ToolCallbackProvider** / `methodTools` | 替代 `ToolRegistry.toolObjectsForNames` 手写过滤 |
| 工具发现（/status 只读） | **ToolCatalog** 只读组件 | 从 `@Tool` Bean + MCP 汇总，供文档 API；Skill 不再参与 |
| 工具 >5 动态注入 | 向量 Top-K（复用 embedding 基础设施或轻量内存索引） | 规范强制；design 细化存储与刷新 |
| 会话记忆 | 现有 **MessageChatMemoryAdvisor** | 不变 |
| MCP 外部工具 | 现有 **McpManager** + ToolCallback | 保留；按 plan 白名单过滤 |

不涉及：MQ、Redis 新依赖（除非工具向量索引选用 Redis）、新建 DB 表。

---

## 四、影响范围

### 系统间影响

- **ai ↔ ai_react**：HTTP/SSE 契约不变；前端无代码变更（`uiCraftMode: disabled`）
- **无** GOMS/外部 RPC/MQ 变更

### 模块改动（ai 仓库）

| 模块/包 | 改动点 |
|---------|--------|
| `agents/web/AgentHubController` | chat 路径依赖瘦身；status 改注入 AgentRegistry |
| `agents/application/AgentChatApplicationService` | SUB_AGENT/ORCHESTRATOR 分支改调 ReactAgent / 新 Tool 集成 |
| `agents/graph/**` | `PrepareAgentChatNode` 或新增 Router 节点；state keys 可能增 `ROUTER_DECISION` |
| `agents/domain/agentchat/AgentChatDomainService` | 路由委托 Router；保留直答与 context 装配 |
| `agents/agent/router/**`（新） | RouterAgent Configuration、transferToAgent、子 Agent 描述 |
| `agents/agent/react/**`（新） | Customer/Data/Code ReactAgent Bean |
| `agents/agent/subagent/**` | chat 三 Agent 改为委托层或标记 `@Deprecated` 的 process |
| `agents/agent/orchestrator/` | `OrchestratorAgent` chat/knowledge 死代码清理；`IntentRouter` 收窄或内联到 Router |
| `agents/agent/orchestrator/AgentChatService` | 去除 ToolRegistry；ToolCallback 注入 |
| `agents/skill/**` | chat 路径移除依赖；`ProductivitySkill` 废弃或仅 status 兼容 |
| `agents/tool/ToolRegistry` | 职责收窄为 status/MCP 注册或拆 ToolCatalog |
| `agents/tool/functions/**` | `@Tool` description 四段式补齐 |
| `agents/web/AgentHubDocumentationService` | 数据源改 AgentRegistry + ToolCatalog |
| `docs/flowcharts/AgentHubController.md` | 流程图更新 |

### 治理仓（AetherStack）

| 文件 | 改动 |
|------|------|
| `openspec/references/domain-models.md` | §智能体对话流程更新 |
| `.aetherstack/context/api-contracts.yaml` | 增量注释（内部重构，paths 不变） |

### 接口变更

- **新增**：无对外 REST 路径
- **修改**：无（`POST /api/agent-hub/chat/agent` 请求/响应/SSE 语义不变）
- **内部**：Spring Bean 名称新增 Router/ReactAgent Configuration

### SubAgent → 规范 Agent 映射（草案）

| 存量 SubAgent | chat 路径 | 目标 |
|---------------|-----------|------|
| `CustomerServiceAgent` | 是 | `customerServiceReactAgent` |
| `DataAnalysisAgent` | 是 | `dataAnalysisReactAgent` |
| `CodeGenerationAgent` | 是 | `codeGenerationReactAgent` |
| `ProjectManagerAgent` 等 requirement 包 | 否（仅 requirement-dev） | **不改动** |

---

## 五、数据设计

**无数据库变更**。

会话状态仍由 `ChatMemory` + `ConversationContext` 属性承载；Graph prep state 键沿用 `AgentGraphStateKeys` 并可能扩展 Router 决策字段。

工具动态注入若需向量索引：首期可用内存 Map（工具 description embedding 启动时计算），不新增表；超规模再评估 knowledgehub embedding 复用。

---

## 六、约束与风险

### 技术约束

- **性能**：prep Graph 同步 invoke 须保持毫秒~百毫秒级（无 LLM）；RouterAgent 若含 LLM 调用需评估是否改为「规则 + 可选 LLM 路由」混合——**建议 prep 阶段 Router 先用规则/得分 + 结构化 Agent 描述，LLM Router 放 ORCHESTRATOR 分支内**，避免 prep 阻塞
- **业务**：SSE 路由摘要前缀、`AfterAgentCallEvent` 字段语义不变
- **技术**：禁止 Graph 节点 import `web.dto`；禁止 `@Transactional` 内 LLM；agents 禁止 import springai Demo

### 风险点

| 风险 | 应对措施 |
|------|----------|
| RouterAgent 引入 LLM 导致 prep 延迟 | prep 保留规则路由为主；RouterAgent LLM 仅作 tie-breaker 或移至 stream 阶段 |
| ReactAgent 与现有 ChatClient 流式语义差异 | SUB_AGENT 路径统一 `ReactAgent.stream` 适配为 `Flux<String>`；单测 StepVerifier 对比 |
| 工具四段式改造工作量大 | 按 chat 可见工具优先；`check-spring-ai-tools.ps1` 增量通过 |
| `/status` 移除 Skill 破坏诊断 UI | ToolCatalog 仍列出全部 `@Tool`；Skill 段改为空列表或 deprecated 提示 |
| 需求开发 SubAgent 误重构 | 包路径 `subagent.requirement` 排除在 chat ReactAgent 迁移外；grep 门禁 |
| L1 单测不足 | `aiTddMode: auto` 命中；tasks 含 AUTO-AI-UT 先行 |

---

## 七、待 AI 细化

- [ ] 完整 `design.md` 章节（概述/业务分析/系统设计/详细设计/接口/代码改造/非功能）
- [ ] RouterAgent Configuration 伪代码与 Bean 清单
- [ ] 各 `@Tool` 四段式 description 对照表
- [ ] 工具 >5 动态注入时序与 Top-K 算法
- [ ] prep / stream 时序图（Mermaid）
- [ ] OrchestratorAgent 删除/保留方法清单
- [ ] `AgentHubController` / `AgentChatApplicationService` 改造前后代码 diff 分析
- [ ] AUTO-AI-UT 测试类清单与 Mock 策略
- [ ] test-cases.md（测试同学提供）

---

## 八、复杂度判定

| 维度 | 结论 |
|------|------|
| Requirement 数量 | 10（≥8）→ **复杂** |
| Scenario 数量 | ≥12 → **复杂** |
| 跨模块 | agents web/application/graph/domain/agent/tool → **复杂** |
| 新外部依赖 | 无 mandatory |
| DB/MQ | 无 |

**结论**：须先确认本 draft，再生成完整 `design.md`。
