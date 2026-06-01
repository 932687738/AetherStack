# Spring AI ReactAgent 与 CompiledGraph 规范（AetherStack）

> **适用范围**：关联仓库 **ai** 中 ReactAgent、CompiledGraph、StateGraph、检查点/HIL 及 `resources/graphs/**` 配置。  
> **配套**：`engineering-standards.md` §4.5、`.aetherstack/rules/spring-ai-react-graph.md`、`.aetherstack/rules/backend-ai.md`、`spring-ai-core-standards.md`、`spring-ai-multi-agent-standards.md`、`spring-ai-rag-standards.md`

---

## 1. 选型原则

| 能力 | 典型场景 | 生产参考 | 教程（Demo） |
|------|----------|----------|--------------|
| **ReactAgent** | ReAct 多轮、动态工具、灵活推理 | `projectpractice/recommendedpackaging/` | `springai/agent/` |
| **CompiledGraph** | 固定流水线、分支、循环、HIL、检查点 | `knowledgehub/graph/` | `springai/graph/` |
| **ChatClient** | 单轮、无状态 | `AgentChatService` | `springai/chat/` |
| **Graph 内嵌 ReactAgent** | 图中需 LLM 决策的单一节点 | design 中显式 `DelegatingAgentNode` | — |

**禁止复制**：`RequirementDevelopmentOrchestrator` 式 Flux 手写编排；`OrchestratorAgent` 扩大范围（仅维护存量）。

与 `backend-design-guide.md` 目标态一致：Agent Hub / 需求开发逐步 Graph/ReactAgent 化。

---

## 2. ReactAgent 规范

### 2.1 必选配置项

| 配置项 | 要求 |
|--------|------|
| System Prompt | 角色、工具摘要、推理步骤、终止条件；放 `resources/prompts/` |
| `maxIterations` | 显式设置（默认建议 10），防止死循环 |
| 工具列表 | Function Calling 注入；单次暴露 ≤5（见 multi-agent 规范） |
| 终止信号 | 如 `FINAL ANSWER:` 前缀后停止工具调用 |

API 名称以 Spring AI Alibaba 为准（`ReactAgent`、`ToolCallingAgent` 等）；勿与教程类名混用而不加 `@Profile("demo")`。

### 2.2 System Prompt 模板（结构强制）

design.md 须粘贴或引用下列结构的实例化版本：

```text
你是 {角色}，负责 {任务范围}。
你可以使用以下工具：
{tool_descriptions}

推理流程：
1. 分析用户问题，判断可直接回答或需调用工具。
2. 若需调用工具，只调用一个最相关工具，并等待结果。
3. 观察工具返回，判断是否足以回答。
4. 如不足，继续调用其他相关工具，避免重复无谓调用。
5. 信息足够时直接给出最终答案，以 “FINAL ANSWER: ” 开头。

注意：一次只能调用一个工具，调用后必须等待结果才能进行下一次思考。
```

### 2.3 工具与对话历史

- `@Tool` 四段式描述（multi-agent 规范）。
- **禁止**仅 Prompt 描述工具而不注册 Function Calling。
- 工具返回值 → `ToolResponseMessage`，完整进入 history（可日志截断，不可改语义）。

### 2.4 安全与可观测

- 达 `maxIterations`：强制收尾回答 + WARN 日志。
- `onIteration`（或项目等价 Hook）：Thought / Action / Observation。
- 同参重复调用：Prompt 禁止 + 代码去重。

**指标（Micrometer）**：`agent_iterations_total`、`agent_tool_calls_total`、`agent_timeouts_total`，标签 `agent_name`。

---

## 3. CompiledGraph 规范

### 3.1 图生命周期

1. `StateGraph` 定义节点与边（入口 / 业务 / 出口）。
2. 应用启动时 `compile()` → **单例** `CompiledGraph` Bean。
3. **禁止**请求级 `buildLinearGraph` / 重复 compile（Knowledge Hub post Graph 存量问题勿复制）。

### 3.2 节点与分层

| 规则 | 说明 |
|------|------|
| 节点职责 | 编排步骤 only；业务规则 → DomainService |
| 命名 | `动词_领域` |
| 工具 | 复用 `@Tool`，禁止节点内重复实现 |
| 禁令 | 禁止 import `web.dto`；禁止节点内 `newFixedThreadPool` |

### 3.3 条件边

- `EdgeCondition` 返回下一节点**名字符串常量**。
- 条件仅读 State；DB/HTTP 调用放在前置节点。
- 编译期注册全部边目标。

### 3.4 状态

- 不可变 State（Record 推荐）；状态键常量化。
- 暂停/恢复：`StateRepository` + Redis/DB；失败保存快照。

### 3.5 HIL

- `Interrupt` 暂停；外部 API 恢复并写入审核结果到 State。
- 审计日志：介入点 ID、时间、决定。

### 3.6 错误与补偿

- 每节点 `onError`：重试 / 补偿 / 终止。
- 补偿须可回滚（释放库存、取消订单等）。

### 3.7 测试要求

| 类型 | 覆盖 |
|------|------|
| 单测 | 各节点正常路径、条件分支、异常、中断恢复 |
| 集成 | 端到端图执行（`TestCompiledGraph` 或项目测试基座） |
| OpenSpec | `AUTO-UT` / `AUTO-AI-UT`（L1 prep/路由节点） |

**指标**：`graph_execution_duration_seconds`、`graph_node_errors_total`、`graph_interruptions_total`，标签 `graph_name`。

---

## 4. Graph 内嵌 ReactAgent

- 输入：State 子集映射为 task description。
- 输出：Agent 最终文本写入指定 State 键。
- 工具列表由 State 驱动（动态检索仍 ≤5）。
- 节点级超时与迭代监控；超时熔断。

---

## 5. 与铁三角规范衔接

| 规范 | 衔接点 |
|------|--------|
| `spring-ai-multi-agent-standards.md` | Tool 描述、≤5 注入、Router、日志脱敏 |
| `spring-ai-rag-standards.md` | 图/RAG 节点：阈值、Top-K、rerank、`[来源]` 格式 |
| `ai-tdd-standards.md` | L1：Graph prep、流式 ApplicationService、路由 |

---

## 6. 代码组织

```
ai/src/main/java/
  com.yxy.deepseek.knowledgehub.graph/   # 生产 Graph
  com.yxy.deepseek.agents/.../graph/     # Agent Hub Graph（目标态）
  com.yxy.deepseek.agents/.../agent/     # ReactAgent 配置
ai/src/main/resources/
  prompts/          # System Prompt 模板
  graphs/           # 可选 JSON/.graph（须有 Java DSL 双写）
```

`@ConfigurationProperties` 前缀建议：`aether.agent.*`、`aether.graph.*`。

---

## 7. OpenSpec design 必填（触及 React/Graph 时）

1. 选型表：ReactAgent vs CompiledGraph vs ChatClient vs 组合
2. `maxIterations`、超时、终止策略
3. State 键列表与持久化策略（含 HIL）
4. 节点清单与条件边表（Mermaid 推荐）
5. 错误/补偿策略
6. 指标与告警阈值
7. 与 multi-agent / RAG 的 Tool 与检索参数交叉引用

---

## 8. Harness 与本地验证

```powershell
.aetherstack/scripts/check-spring-ai-react-graph.ps1
.aetherstack/scripts/check-spring-ai-react-graph.ps1 -Strict
```

检查项（静态，非 Strict 仅警告）：

- `knowledgehub/graph`、`agents` 下 Graph 节点 **import `web.dto`**
- `agents` 包内手写 `while` + tool 调用反模式
- 含 `ReactAgent` 的 Java 文件附近未出现 `maxIterations` / `max-iterations` 配置

`make verify` 在后端测试后可执行（见 `verify-all.ps1`）。

---

## 9. 监控告警

| 条件 | 动作 |
|------|------|
| 单次执行 >30s | 告警 |
| `graph_node_errors_total` 突增 | 告警 |
| Agent 达 maxIterations | WARN + 指标计数 |

---

## 10. 铁三角衔接

本规范与 **`spring-ai-multi-agent-standards.md`**（Tool/Router）、**`spring-ai-rag-standards.md`**（检索节点）共同构成 Spring AI 智能体开发铁三角；design 须交叉引用。

---

## 11. 参考索引

| 文档 | 用途 |
|------|------|
| `.aetherstack/rules/spring-ai-react-graph.md` | Cursor 规则源 |
| `.aetherstack/rules/backend-ai.md` | 选型与分层禁令 |
| `openspec/references/backend-design-guide.md` | 现状与演进 |
| `harness/adapters/java-maven/verify-commands.md` | 验证步骤 |
