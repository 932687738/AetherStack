# Engineering Standards（AetherStack 工程级技术规范）

本文件用于约束 **AI coding 的工程实践**，避免实现偏离现有代码风格与运行约束。  
适用范围：关联仓库 **ai**（Spring Boot）为主，**ai_react**（React）为辅。路径见 `LOCALPATH.md`。

> 若与真实代码冲突，以真实代码为准；需同步更新本规范与设计文档。

## 1. 分层与依赖方向（强制）

**目标**：保证职责清晰、依赖单向，避免跨层直连。

**推荐四层结构：**

| 层 | 职责 | backend 包/目录示例 |
|----|------|---------------------|
| 接口层 | HTTP、SSE、DTO 转换、参数校验 | `*.web`、`*.dto` |
| 应用层 | 用例编排、事务边界、Graph/Agent invoke/stream | `*.application.*ApplicationService` |
| 领域层 | 业务规则、聚合、领域服务、Repository 接口 | `*.domain.*` |
| 基础设施层 | Repository 实现、DB、向量、LLM/MCP 适配 | `*.infrastructure.*`、`*.repository.*` |
| 编排配置 | CompiledGraph / ReactAgent Bean 装配（非业务编排） | `*.graph.*`、`*AgentConfiguration` |

**模块映射（关联仓库）：**

- **ai/.../agents**：Agent Hub（**存量** Orchestrator + ChatClient；**新 AI 能力**优先 Graph/ReactAgent）
- **ai/.../knowledgehub**：知识库 RAG（**目标** CompiledGraph 生产路径）
- **ai/.../springai**：教程 Demo（`@Profile("demo")` 目标态；**禁止**被 agents/knowledgehub 依赖）
- **ai_react/**：Nebula Desk UI

**详细现状问题与目标架构**：`openspec/references/backend-design-guide.md`

**允许/禁止调用矩阵（强制）：**

- Controller → **只允许** ApplicationService / Orchestrator；**禁止** Repository、CompiledGraph 直连
- ApplicationService → **允许** DomainService、CompiledGraph/ReactAgent、Repository 接口；**禁止** 依赖 `web.dto` 以外的反向 web 层
- Graph 节点 → **允许** 调用 DomainService、Port；**禁止** import `web.dto`、**禁止** 复杂业务规则、**禁止** 直连 Repository 实现（应经 domain 接口）
- Domain → **禁止** Spring Web、具体 DAO、springai
- Infrastructure → 实现 Repository；**禁止** HTTP 编排
- agents/knowledgehub → **禁止** import springai（存量 `RagContentAuditor` 待迁出）

**参考分层实现：**

- **目标样板**：`ai/.../springai/projectpractice/recommendedpackaging/`（DDD 四层 + ReactAgent）
- **Graph 生产参考**：`ai/.../knowledgehub/graph/`（待收敛节点瘦身）
- **反例（勿复制）**：`OrchestratorAgent` 单体编排、Graph 节点内写去重/选库规则

## 2. 接口与 DTO 规范

- REST + SSE 路径统一前缀 `/api/agent-hub/`
- 新增 API 必须同步更新 `integration-contracts.md` 与 `.aetherstack/context/api-contracts.yaml`
- DTO 使用 record 或不可变对象优先；禁止在 DTO 中写业务规则
- SSE 接口需说明事件类型、结束条件、错误传播方式

## 3. 数据与持久化

- 数据库：PostgreSQL 16 + pgvector
- 迁移：Flyway（`ai/src/main/resources/db/migration/`）
- 向量维度默认 1024（DashScope embedding）；变更维度需评估 HNSW 索引重建
- 金额/计量：BigDecimal；禁止 double/float 表示业务数值
- 禁止魔法数字/字符串；业务常量提取到 enum 或 constants 包

## 4. AI / LLM 集成规范

### 4.0 Spring AI 核心（强制基线）

所有 Spring AI / Alibaba 相关实现 **默认须**满足：

1. 细则见 **`openspec/references/spring-ai-core-standards.md`** 与 `.aetherstack/rules/spring-ai-core.md`
2. Spring AI **1.0.0+** 正式版 + BOM；API Key 环境变量注入；禁止硬编码
3. 业务调用统一 **ChatClient**；Prompt 放 `resources/prompts/`；禁止用户输入直接拼接 Prompt
4. `@Tool` 注册为 Bean、幂等、异常友好化；LLM 调用须超时/重试与可观测（traceId、token、Micrometer）
5. 测试禁止真实 API Key；Tool / Prompt 须有单测

### 4.1 Spring AI Alibaba 编排（优先）

本仓库为 **Spring AI Alibaba** 项目。新增 AI 相关后端能力时：

1. **优先**使用 **CompiledGraph**（多步流水线、条件分支、检查点、HIL）或 **ReactAgent**（ReAct + 工具调用）
2. 若场景足够简单（单次 ChatClient、纯 CRUD、纯向量检索等），可选用更轻量方案，并在 design 中说明理由
3. 细则见 `.aetherstack/rules/backend-ai.md`

**参考代码：**

| 能力 | 生产/推荐路径 | 教程路径 |
|------|---------------|----------|
| CompiledGraph | `knowledgehub/graph/` | `springai/graph/` |
| ReactAgent | `springai/projectpractice/recommendedpackaging/` | `springai/agent/` |

### 4.3 多 Agent / Tool（强制）

触及 Agent Hub 多智能体、`@Tool`、`transferToAgent`、工具动态注入时：

1. 细则见 **`openspec/references/spring-ai-multi-agent-standards.md`** 与 `.aetherstack/rules/spring-ai-multi-agent.md`
2. `@Tool` description 须含：功能、典型问法（≥2）、反例、前提（如有）
3. 单次 LLM Function Calling 暴露工具 ≤5；超限须向量检索 Top 3~5 动态注入
4. 记录 Router 选中子 Agent 与 Tool 调用（参数脱敏）
5. REST 契约不变时 OpenSpec `paths` 不修改，仅重构内部实现

本地静态检查：`.aetherstack/scripts/check-spring-ai-tools.ps1`（`make verify` 可选执行）

### 4.4 知识库 RAG（强制）

触及 Knowledge Hub 文档入库、向量检索、rerank、RAG `@Tool` 时：

1. 细则见 **`openspec/references/spring-ai-rag-standards.md`** 与 `.aetherstack/rules/spring-ai-rag.md`
2. 多库分层；元数据最小集（`source`、`updated_at`、`doc_type`、`status`）；禁止日常全量重建
3. 检索须配置相似度阈值与 Top-K（注入 LLM 通常 3~5；Tool 动态注入 ≤3）
4. 重要场景须 rerank；结果注入 LLM 前格式化为 `[来源: {source}] {content}`
5. 生产向量路径以 **knowledgehub** 为准；禁止新增第三套 RAG 存储
6. RAG `@Tool` 须同时满足多 Agent 四段式 + 知识库名称与返回说明

本地静态检查：`.aetherstack/scripts/check-spring-ai-rag.ps1`（`make verify` 可选执行）

### 4.5 ReactAgent / CompiledGraph（强制）

触及 ReactAgent、StateGraph、CompiledGraph、检查点/HIL、图资源配置时：

1. 细则见 **`openspec/references/spring-ai-react-graph-standards.md`** 与 `.aetherstack/rules/spring-ai-react-graph.md`
2. ReactAgent 须显式 `maxIterations`、System Prompt 模板（含 `FINAL ANSWER:` 终止）、工具经 Function Calling 注入
3. CompiledGraph 单例 `compile()`；节点禁止 `web.dto` 与复杂业务逻辑；条件边仅读 State
4. Graph 内嵌 ReactAgent 时工具仍 ≤5，须超时熔断与迭代监控
5. 与 multi-agent、RAG 规范同时满足（铁三角）

本地静态检查：`.aetherstack/scripts/check-spring-ai-react-graph.ps1`（`make verify` 可选执行）

### 4.6 通用约束

- 模型调用通过 Spring AI `ChatClient` / `ChatModel` / `VectorStore` 抽象；Graph/Agent 内部仍走上述抽象（详见 §4.0）
- API Key 通过环境变量注入（`DASHSCOPE_API_KEY`），禁止硬编码
- Prompt 模板放在 `ai/src/main/resources/prompts/`
- RAG 检索需说明 topK、相似度阈值、rerank 策略（design 文档必填；细则见 `spring-ai-rag-standards.md`）
- 事务内 **禁止** 调用外部 LLM HTTP 接口

## 5. 前端规范

> **目标栈（强制）**：React 18 + Umi 4 + TypeScript + Ant Design 5 + Zustand + ES7+。完整细则见 **`openspec/references/frontend-umi-standards.md`**、Cursor 规则 **`.aetherstack/rules/frontend-umi.md`**。

- 目录：`src/pages/`、`components/`、`hooks/`、`models/`（Zustand）、`services/`、`types/`、`utils/`
- API：OpenAPI 生成 `src/openapi/typings.d.ts`；业务调用经 `services/`；禁止 pages/components 直连 API
- 工程命令：`harness install|dev|build|lint`（禁止直接 npm/yarn/pnpm）
- Umi 配置单一来源：`.umirc.ts`；约定式路由
- 流式对话使用 SSE；协议解析集中在请求层，不得在各组件重复实现
- 环境变量：`.env` / `.env.example`；禁止硬编码后端地址；`.env` 含密钥不入库
- **存量**：仍为 Vite + JS 的模块在迁移前可维护，新功能须对齐 Umi 规范（PR 注明范围）

## 6. 测试策略

- 单元测试：JUnit 5 + Mockito；测试类位于 `ai/src/test/java/`
- `AUTO-UT` 用例映射到 Service/Domain 层单测
- 前端：`npm run lint` + `npm run build` 作为 CI 基线
- SSE/LLM 联调类场景标记 `MANUAL`

## 7. 代码质量与验证

- 本地验证：`make verify`（在关联仓库 ai / ai_react 跑 test/lint/build）
- Harness 验证命令见 `harness/harness.config.yaml`
- 新增代码应补充对应 OpenSpec test-cases 与 tasks

## 8. 存量与演进

- 存量包名 `com.yxy.deepseek` 保留，新模块对齐 `recommendedpackaging` 四层分包
- `springai/` 与生产分离；**禁止**新增 agents/knowledgehub → springai 依赖
- 生产变更优先改 `knowledgehub/`（Graph 收敛），Agent Hub 大改走 OpenSpec 专项

## 9. 后端架构债务与演进（强制知晓）

> 完整梳理见 **`openspec/references/backend-design-guide.md`**

### 9.1 已知不合理实现（勿复制）

| 类别 | 说明 |
|------|------|
| 编排分裂 | Agent Hub 手写 Orchestrator；Knowledge Hub 已 CompiledGraph |
| 三套 RAG | agents VectorStore、knowledgehub 表、springai PgVectorRagDemo |
| 遗留死路径 | `OrchestratorAgent.processKnowledgeMode()` 无 HTTP 入口 |
| 分层违规 | Graph 节点直连 Repository、依赖 web.dto、业务规则在 Node |
| 生产依赖 Demo | `ConversationKnowledgeService` → `springai.rag.audit` |
| 性能 | 每次问答重新 compile post Graph |

### 9.2 新代码必须遵循

1. 编排选型按 §4.1 与 `backend-ai.md`
2. Graph 节点禁令、模块依赖禁令见 §1 矩阵
3. CompiledGraph **单例 Bean**，禁止 per-request compile
4. Demo 使用 `@Profile("demo")` 或等价隔离（目标态）
5. 触及架构债务清理时，单独 OpenSpec 变更，避免与功能 PR 混杂

### 9.3 演进优先级

P1 Knowledge Hub Graph/Domain 收敛 → P1 迁出 springai 依赖 → P2 Agent Hub Graph/ReactAgent 化 → P2 需求开发 Graph 化 → P3 全模块 DDD 对齐
