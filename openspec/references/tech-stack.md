# Tech Stack Reference (AetherStack)

本文件提供 AetherStack 的技术栈、项目约定以及测试策略。所有实现和规范编写都应与此保持一致。

## 快速索引

- [后端技术栈](#后端技术栈)
- [前端技术栈](#前端技术栈)
- [基础设施](#基础设施)
- [构建工具](#构建工具)
- [接口契约](#接口契约)
- [项目代码规范](#项目代码规范)
- [测试策略](#测试策略)

## 后端技术栈

- Java 17 + Spring Boot 3.4.3
- Spring AI 1.1.2 + Spring AI Alibaba 1.1.2.2
- MyBatis + Flyway
- PostgreSQL 16 + pgvector（HNSW 向量索引）
- springdoc-openapi（Swagger UI）
- Actuator + Micrometer Prometheus
- JUnit 5 + Mockito（测试）

**核心模块（ai 仓库分包，路径相对 ai 根目录）：**

| 模块 | 路径 | 职责 |
|------|------|------|
| Agent Hub | `src/main/java/.../agents` | 多智能体编排、Tool、Hook、MCP |
| Knowledge Hub | `src/main/java/.../knowledgehub` | 知识库 CRUD、RAG Graph、记忆 |
| Spring AI Demo | `src/main/java/.../springai` | 教程与实验（非默认生产路径） |

**环境变量（常用）：**

- `DASHSCOPE_API_KEY`、`DASHSCOPE_BASE_URL`、`DASHSCOPE_CHAT_MODEL`
- `POSTGRES_JDBC_URL`、`POSTGRES_USERNAME`、`POSTGRES_PASSWORD`
- `PGVECTOR_DIMENSIONS`、`PGVECTOR_HNSW_*`

## 前端技术栈

**目标栈（新开发与迁移对齐）**：

- React 18 + Umi 4 + TypeScript
- Ant Design 5 + Zustand
- OpenAPI 自动生成类型（`src/openapi/`）
- TanStack Query（服务端数据缓存）
- ESLint + Stylelint + Prettier；工程入口 **`harness` CLI**

**存量（迁移中）**：部分模块仍为 React 19 + Vite 8 + JavaScript，见 `frontend-umi-standards.md` §8。

**规范文档**：`openspec/references/frontend-umi-standards.md`

**环境变量（Umi）**：

- 统一 `.env`；经 `process.env` 或 Umi `define` 注入
- 禁止硬编码 API 基址；开发代理在 `.umirc.ts` 配置

## 基础设施

- Docker Compose：`pgvector/pgvector:pg16`（`ai/docker-compose.yml`）
- 默认库名：`agenthub`，端口 `5432`

## 构建工具

- 后端：Maven（`ai/pom.xml`）
- 前端：npm（`ai_react/package.json`）

## 接口契约

- 前后端 REST/SSE 契约：`openspec/references/integration-contracts.md`
- 机器可读摘要：`.aetherstack/context/api-contracts.yaml`

## 项目代码规范

### 后端

- 编码 UTF-8；四层架构见 `engineering-standards.md`
- 包名保留 `com.yxy.deepseek`（存量）；新代码对齐 DDD 分层
- Flyway 迁移脚本命名 `V{n}__description.sql`

### 前端

- 组件 PascalCase；API 经 `src/services/` + OpenAPI 类型
- Zustand Store：`src/models/useXxxStore.ts`
- 样式：Ant Design 主题 + CSS Modules（`*.less`）
- 细则：`frontend-umi-standards.md`

## 测试策略

### 后端

- 单元测试：`ai/src/test/java/`，在 ai 仓库执行 `mvn test`
- 集成测试：Spring Boot Test（需 PostgreSQL/pgvector 环境）
- API 文档：`http://localhost:8080/swagger-ui.html`

### 前端

- Lint：`harness lint`（或存量 `npm run lint` 至迁移完成）
- 构建：`harness build`
- 开发：`harness dev`（须联调已启动的后端）

## 测试要求（规则）

- `AUTO-UT` 用例必须映射到 `*Test.java`
- `AUTO-AI-UT`（AI-TDD 开启时）：L1 AI 核心模块单测，Mock LLM，见 `ai-tdd-standards.md`
- `AUTO-AI-IT`：复杂 RAG 集成测试（推荐）
- SSE/LLM 联调用例标记 `MANUAL`
- 新增 API 需补充 integration-contracts 与 test-cases

## AI 应用测试（阶段化）

OpenSpec 变更通过 `.openspec.yaml` 的 `aiTddMode` 开关控制：

| 层级 | 范围 | 要求 |
|------|------|------|
| L1 | ChatClient 封装、Prompt、路由、Graph prep、流式 ApplicationService | AI-TDD 开启时 **强制 TDD** |
| L2 | 复杂 RAG / 多步 Graph | 推荐 `AUTO-AI-IT` |
| L3 | CRUD、DTO 映射 | 常规 `AUTO-UT`，可放宽 |

范式要点：Mockito 模拟 DashScope/ChatClient；Prompt 断言关键片段；Flux 用 StepVerifier。

详见 `openspec/references/ai-tdd-standards.md`、`harness/adapters/java-maven/ai-test-templates.md`。

## 前端 UI Craft（Impeccable）

OpenSpec `uiCraftMode` 控制是否在 **U1 可见 UI** 任务中强制 Impeccable：

| 层级 | 范围 | uiCraft enabled |
|------|------|-----------------|
| U1 | 页面/组件/布局改版 | 必须 Impeccable |
| U3 | api/*、SSE 逻辑 | 不要求 |

详见 `openspec/references/ui-craft-standards.md`、`.cursor/skills/impeccable/SKILL.md`。
