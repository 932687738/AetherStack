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

- React 19.2 + Vite 8
- ESLint 10（flat config）
- 原生 fetch + SSE（无 axios/react-router）
- i18n：`ai_react/src/i18n/messages.js`

**环境变量：**

- `VITE_API_PROXY_TARGET`（默认 `http://localhost:8080`）
- `VITE_API_BASE_URL`（留空则走开发代理）

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

- 组件 PascalCase；API 常量集中在 `ai_react/src/api/index.js`
- 样式：`ai_react/src/styles/index.css`

## 测试策略

### 后端

- 单元测试：`ai/src/test/java/`，在 ai 仓库执行 `mvn test`
- 集成测试：Spring Boot Test（需 PostgreSQL/pgvector 环境）
- API 文档：`http://localhost:8080/swagger-ui.html`

### 前端

- Lint：`npm run lint`
- 构建：`npm run build`
- 开发：`npm run dev`（必须联调已启动的后端）

## 测试要求（规则）

- `AUTO-UT` 用例必须映射到 `*Test.java`
- SSE/LLM 联调用例标记 `MANUAL`
- 新增 API 需补充 integration-contracts 与 test-cases
