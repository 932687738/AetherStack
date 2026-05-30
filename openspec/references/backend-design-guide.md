# 后端设计指南（ai 关联仓库）

> **目的**：梳理当前实现中的不合理之处，定义目标架构与演进规则。  
> **真源代码**：`D:\cache\workspace\ai`（见 `LOCALPATH.md`）  
> **配套**：`engineering-standards.md`、`architecture.md`、`backend-ai.md`（`.aetherstack/rules/`）

---

## 1. 现状总览

### 1.1 三个后端包与职责

| 包 | 定位 | 生产 API 前缀 | AI 编排方式 |
|----|------|---------------|-------------|
| `agents` | Agent Hub：多智能体、工具、MCP、需求开发 | `/api/agent-hub` | **手写** `OrchestratorAgent` + `ChatClient`（无 CompiledGraph/ReactAgent） |
| `knowledgehub` | 业务知识库：CRUD、上传、RAG 问答 | `/api/agent-hub`（同 BASE） | **CompiledGraph**（upload 全 Graph；query prep/post Graph + 中间 ChatClient 流式） |
| `springai` | 教程、对照实验、Spring 官方 API 镜像 | `/springai/demo/*` 等 | CompiledGraph + ReactAgent + ChatClient **仅 Demo** |

### 1.2 生产调用链（As-Is）

```text
智能体对话     AgentHubController → OrchestratorAgent → SubAgent / 直答 → AgentChatService(ChatClient)
需求开发       AgentHubController → RequirementDevelopmentOrchestrator → SubAgent 串并行
知识库问答     KnowledgeHubController → QueryKnowledgeService → CompiledGraph(prep) → ChatClient.stream → CompiledGraph(post)
文档上传       KnowledgeHubController → DocumentUploadService → CompiledGraph(upload)
知识库 CRUD    KnowledgeBaseController → KnowledgeBaseService → Repository
会话向量捕获   AgentHubController → ConversationKnowledgeService → VectorStore（agents.knowledge）
```

---

## 2. 主要问题（不合理之处）

### 2.1 编排模式分裂

| 问题 | 影响 | 证据 |
|------|------|------|
| Agent Hub 仍用手写 Orchestrator，Knowledge Hub 已用 CompiledGraph | 同一产品两套编排范式，难以统一观测、检查点、HIL | `OrchestratorAgent.java` vs `QueryKnowledgeService.java` |
| 需求开发工作流用 Java Flux 串并行，未用 Graph | 阶段状态难持久化、难可视化、难插人工节点 | `RequirementDevelopmentOrchestrator.java` |
| springai 有完整 Graph/ReactAgent 样板，生产 agents 未迁移 | 规范与实现脱节 | `springai/graph/`、`springai/agent/` 无 agents 引用 |

### 2.2 三套 RAG / 向量路径并存

| 路径 | 用途 | 问题 |
|------|------|------|
| `agents.knowledge` + Spring AI `VectorStore` | 旧版单路 RAG、会话捕获 | 与 knowledgehub 多 KB / 多路召回 **语义重复** |
| `knowledgehub` 表 + `knowledge_chunks.embedding` | 生产知识库 | **目标主路径** |
| `springai.rag.PgVectorRagDemo` | Demo | 第三套元数据约定，与生产 **不互通** |

**遗留死路径**：`OrchestratorAgent.processKnowledgeMode()` 仍存在，但 HTTP 知识问答已迁至 `KnowledgeHubController`；`AgentHubApiPaths.CHAT` 已 `@Deprecated`。

### 2.3 分层与依赖违规

| 违规 | 严重度 | 说明 |
|------|--------|------|
| Graph 节点直连 Repository | 中 | 如 `MultiRetrievalNode`、`StoreDocumentNode` 跳过 Application/Domain |
| Graph 节点依赖 `web.dto` | 中 | 编排层反向依赖接口层 DTO |
| 业务规则落在 Graph 节点 | 中 | 去重、选库、分段策略应在领域服务 |
| 生产依赖 springai Demo | **高** | `ConversationKnowledgeService` → `springai.rag.audit.RagContentAuditor` |
| domain 贫血 | 中 | `KnowledgeBase` 等 record 无行为，校验散落在 Service |
| Demo 与生产同进程 | 中 | 无 `@Profile("demo")` 隔离，`/springai/demo/*` 与生产一并暴露 |

### 2.4 其他工程问题

- `QueryKnowledgeService` 每次问答 **重新 compile** post Graph，应复用单例 Bean
- `MultiRetrievalNode` 内 `newFixedThreadPool(4)` 无生命周期管理
- 按 **技术分包**（web/service/repository）为主，仅 `springai/projectpractice/recommendedpackaging` 具备完整 DDD 四层

---

## 3. 目标架构（To-Be）

### 3.1 原则

1. **限界上下文清晰**：Agent Hub、Knowledge Hub、springai（仅教程）互不 import 违规依赖
2. **编排统一走 Spring AI Alibaba**：多步有状态 → **CompiledGraph**；ReAct+工具 → **ReactAgent**；单次问答 → **ChatClient**
3. **四层 + 编排配置分离**：Configuration 装配 Graph/Agent；ApplicationService 编排；Domain 承载规则；Infrastructure 实现持久化
4. **单一 RAG 平台**：生产检索与入库以 **knowledgehub 表结构** 为准；agents 会话捕获改为写入同一契约或明确防腐层
5. **Demo 隔离**：`springai/**` 使用 `@Profile("demo")` 或条件装配；**禁止** agents/knowledgehub 依赖 springai

### 3.2 目标分层

```text
┌─────────────────────────────────────────┐
│ web / controller     HTTP、SSE、DTO 转换  │
└──────────────────┬──────────────────────┘
                   │ 仅调用
┌──────────────────▼──────────────────────┐
│ application          *ApplicationService   │
│                      invoke / stream 编排  │
└──────────────────┬──────────────────────┘
        ┌──────────┼──────────┐
        ▼          ▼          ▼
┌───────────┐ ┌─────────┐ ┌──────────────┐
│ domain    │ │ graph/  │ │ infrastructure│
│ 聚合/规则  │ │ agent   │ │ repository   │
│ 领域服务   │ │ config  │ │ 外部 API     │
└───────────┘ └─────────┘ └──────────────┘
```

**Graph 节点职责（强制）**：

- 节点 = **适配器**：读写在 `OverAllState` 与 Port 之间转换
- **禁止**：节点 import `web.dto`；节点内写复杂业务规则；节点内 `new` 线程池
- **允许**：节点调用 **DomainService** 或 **Repository 接口**（接口定义在 domain，实现在 infrastructure）

### 3.3 各上下文目标编排

| 上下文 | 现状 | 目标 | 优先级 |
|--------|------|------|--------|
| **Knowledge Hub 上传** | CompiledGraph 线性链 | 保持 Graph；业务规则迁入 Document 聚合 + DomainService | P1 |
| **Knowledge Hub 问答** | Graph prep + ChatClient + Graph post | **CompiledGraph 端到端**（LLM 流式纳入 Graph 或官方 stream 节点）；post Graph **单例 Bean** | P1 |
| **Agent Hub 对话** | OrchestratorAgent + ChatClient | **中期**：CompiledGraph（路由→子图→工具）或工具密集场景 **ReactAgent** | P2 |
| **需求开发** | Java 工作流 Orchestrator | **CompiledGraph**（phase 条件边 + checkpoint/threadId） | P2 |
| **单次工具调用** | ChatClient | 保持 ChatClient（豁免 Graph） | — |
| **知识库 CRUD** | Service + Repository | 保持；补齐 Domain 行为 | P3 |
| **springai** | 教程 | 保持 Demo profile；作为新技术验证场，验证后迁入生产包 | — |

### 3.4 目标依赖矩阵

| 从 \ 到 | web.dto | application | domain | graph 节点 | repository impl | springai |
|---------|---------|-------------|--------|------------|-----------------|----------|
| Controller | ✓ 使用 | ✓ 调用 | ✗ | ✗ | ✗ | ✗ |
| ApplicationService | ✓ 组装响应 | — | ✓ | ✓ invoke | ✓ 经接口 | ✗ |
| Domain | ✗ | ✗ | — | ✗ | ✗ | ✗ |
| Graph 节点 | **✗ 禁止** | ✗ | ✓ Port/Service | — | ✗ 直连 impl | ✗ |
| springai | — | — | — | — | — | 仅 Demo 内部 |

### 3.5 共享基础设施

| 组件 | 现状位置 | 目标位置 |
|------|----------|----------|
| `RagContentAuditor` | `springai.rag.audit` | `agents.infrastructure.audit` 或 `common` 包 |
| 向量写入契约 | 三套并存 | 统一 `knowledgehub` 表 + 明确 agents 捕获防腐层 |

---

## 4. 演进路线（建议 OpenSpec 变更拆分）

| 阶段 | 变更主题 | 产出 |
|------|----------|------|
| **P0 规范对齐** | 文档 + 禁止新增违规依赖 | 本指南、lint/评审检查项 |
| **P1 Knowledge Hub 收敛** | Graph 节点瘦身、post Graph Bean 化、domain 补强 | refactor knowledgehub graph/domain |
| **P1 依赖解耦** | 迁移 RagContentAuditor；springai `@Profile("demo")` | 生产零依赖 springai |
| **P2 清理遗留** | 移除/废弃 `processKnowledgeMode`、统一 RAG 入口文档 | 删除死代码 |
| **P2 Agent Hub Graph 化** | Orchestrator → CompiledGraph；或 SubAgent 工具链 → ReactAgent | agents.graph 新包 |
| **P2 需求开发 Graph 化** | RequirementDevelopment → CompiledGraph + checkpoint | agents.graph.workflow |
| **P3 DDD 对齐** | agents/knowledgehub 按 recommendedpackaging 分包 | application/domain/infrastructure |

---

## 5. 新需求设计检查清单

设计与 Code Review 时逐项确认：

- [ ] 限界上下文是否明确（agents / knowledgehub / 非 springai 生产）
- [ ] 编排选型：CompiledGraph / ReactAgent / ChatClient，理由已写
- [ ] Controller 是否仅 HTTP/SSE
- [ ] Graph 节点是否未依赖 `web.dto`
- [ ] 业务规则是否在 domain，而非 Orchestrator/Node
- [ ] 是否未新增 agents/knowledgehub → springai 依赖
- [ ] CompiledGraph 是否单例 compile（非每次请求 build）
- [ ] LLM 调用是否在事务外
- [ ] API 是否已更新 `integration-contracts.md`

---

## 6. 参考实现（按优先级）

| 场景 | 首选参考 | 说明 |
|------|----------|------|
| DDD 四层分包 | `springai/projectpractice/recommendedpackaging/` | 领域服务 + ApplicationService + Infrastructure |
| CompiledGraph 生产 | `knowledgehub/graph/` + `application-knowledge.yml` | YAML 驱动线性/可扩展拓扑 |
| CompiledGraph 进阶 | `springai/graph/` | 条件边、HIL、MemorySaver |
| ReactAgent 生产对照 | `recommendedpackaging/.../RecommendedPackagingAlibabaAgentApplicationService` | Agent 用例编排 |
| ReactAgent 教程 | `springai/agent/` | Bean 装配与 HTTP 专题 |
| **反例（待重构）** | `OrchestratorAgent` 单体编排、`StoreDocumentNode` 内业务规则 | 新代码勿复制 |
