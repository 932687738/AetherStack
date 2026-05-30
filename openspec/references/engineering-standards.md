# Engineering Standards（AetherStack 工程级技术规范）

本文件用于约束 **AI coding 的工程实践**，避免实现偏离现有代码风格与运行约束。  
适用范围：关联仓库 **ai**（Spring Boot）为主，**ai_react**（React）为辅。路径见 `LOCALPATH.md`。

> 若与真实代码冲突，以真实代码为准；需同步更新本规范与设计文档。

## 1. 分层与依赖方向（强制）

**目标**：保证职责清晰、依赖单向，避免跨层直连。

**推荐四层结构：**

| 层 | 职责 | backend 包/目录示例 |
|----|------|---------------------|
| 接口层 | HTTP、SSE、DTO 转换、参数校验 | `*.web`、`*.dto`、`agents.constants.web` |
| 应用层 | 用例编排、事务边界、调用领域与基础设施 | `*.service`（编排）、`agents.agent.orchestrator`、`knowledgehub.graph.*` |
| 领域层 | 业务规则、实体、值对象、领域服务 | `knowledgehub.domain`（record）、领域算法 |
| 基础设施层 | DB、向量存储、MyBatis、外部 LLM/MCP | `*.repository`、`*.config`、`agents.mcp` |

**模块映射（关联仓库）：**

- **ai/.../agents**：Agent Hub 编排、SubAgent、Tool、Hook、MCP
- **ai/.../knowledgehub**：知识库 RAG、Graph 流水线、记忆
- **ai/.../springai**：Spring AI 教程与 Demo（非生产默认路径）
- **ai_react/**：Nebula Desk UI，通过 `/api/agent-hub/*` 调用后端

**允许/禁止调用矩阵（强制）：**

- Controller → **只允许** 调用 ApplicationService / Orchestrator；**禁止** 直连 Repository
- 应用层 → **允许** 调用 Repository、VectorStore、外部 API；**禁止** 反向依赖 Controller
- 领域层 → **允许** 纯业务计算；**禁止** 依赖 Spring Web、具体 DAO 实现（目标态）
- 基础设施层 → 实现 Repository 接口；**禁止** 包含业务编排

**参考分层实现：**

- `ai/.../springai/projectpractice/recommendedpackaging/`（较完整 DDD 分包示例）
- `ai/.../knowledgehub/`（Graph + Repository 生产路径）

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

- 模型调用通过 Spring AI `ChatClient` / `VectorStore` 抽象
- API Key 通过环境变量注入（`DASHSCOPE_API_KEY`），禁止硬编码
- Prompt 模板放在 `ai/src/main/resources/prompts/`
- RAG 检索需说明 topK、相似度阈值、rerank 策略（design 文档必填）
- 事务内 **禁止** 调用外部 LLM HTTP 接口

## 5. 前端规范

- React 19 + Vite 8；JavaScript（JSX），后续可升级 TypeScript
- API 调用统一走 `ai_react/src/api/` + `ai_react/src/utils/request.js`
- 流式对话使用 SSE（`postStream`）；不得在各组件重复解析协议
- 环境变量：`.env.example` 为模板；`.env` 不入库

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

- 存量包名 `com.yxy.deepseek` 保留，新模块可对齐 `recommendedpackaging` 分层
- `springai/` Demo 代码与生产 Agent Hub 路径分离；生产变更优先改 `agents/`、`knowledgehub/`
