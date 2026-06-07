# ai-platform Maven 多模块工程结构

## aether-platform / modular-structure 需求说明（前提/操作/结果）

> 将关联仓库 **ai** 从单模块 Maven 项目重构为按业务域与技术横切面划分的多模块工程。  
> 本能力聚焦**工程结构、依赖治理与迁移验收**；不改变任何对外 REST/SSE 业务行为。  
> 需求真源：`docs/重构方案-合并版.md`。

---

## Requirements

### 功能组 A：前置收敛

<a name="req-1"></a>
### Requirement: 1. 消灭知识库代码重复与 Bean 冲突风险

<a name="openspec-req-1"></a>系统应当（SHALL）在模块化迁移开始前，消除 `agents.knowledgehub` staged 全量副本及 `agents.knowledge` 中与 `knowledgehub` 重复的 domain 类，确保运行时仅存在一条知识库生产路径。

#### 场景: 回滚 staged 副本
- **前提**：Git 存在 `agents/knowledgehub` staged 变更且与 `knowledgehub` 包内容重复
- **操作**：执行 staged 回滚，放弃将 knowledge-hub 整体复制进 agent-hub 的迁移路径
- **结果**：磁盘与索引中不再存在 `agents.knowledgehub` 全量副本；Agent Hub 对知识库的访问仅通过防腐接口

#### 场景: 明确 agents.knowledge 轻量边界
- **前提**：`agents.knowledge` 保留检索适配与记忆压缩等轻量类
- **操作**：移除或合并与 `knowledgehub` 重复的 `KnowledgeBase`、`KnowledgeChunk` 等 domain 类，改为引用 `knowledgehub` 包
- **结果**：`agents.knowledge` 仅含 Retriever、StoreService、Memory 压缩等适配层；无重复聚合根定义

---

<a name="req-2"></a>
### Requirement: 2. knowledge-hub Repository 依赖倒置

<a name="openspec-req-2"></a>系统应当（SHALL）将 `knowledgehub` 的 Repository 从具体 MyBatis 类提升为领域层接口，基础设施层提供 MyBatis 实现，符合四层架构与依赖倒置原则。

#### 场景: 接口与实现分离
- **前提**：当前 `KnowledgeBaseRepository` 等为具体类，直接包含持久化操作
- **操作**：在 `domain` 定义 `KnowledgeBaseRepository` 等接口；在 `infrastructure/repository` 实现 `MyBatisKnowledgeBaseRepository`
- **结果**：应用层与领域服务仅依赖接口；编译通过且现有知识库 CRUD 行为不变

---

<a name="req-3"></a>
### Requirement: 3. Flyway 脚本按业务域归属

<a name="openspec-req-3"></a>系统应当（SHALL）将 V1～V16 Flyway 迁移脚本按表所属业务域分配到对应模块的 `resources/db/migration/`，并由 `platform-persistence` 聚合扫描，不改变 SQL 语义与执行顺序。

#### 场景: 脚本物理迁移
- **前提**：当前所有 Flyway 脚本位于单模块 `resources/db/migration/`
- **操作**：V1～V2 归入 `platform-persistence`；知识库相关（约 V3～V7）归入 `knowledge-hub`；平台治理相关（约 V8～V16）归入 `aether-platform`；配置 `spring.flyway.locations` 聚合
- **结果**：全新环境 `flyway migrate` 与存量库升级结果一致；无重复执行或遗漏脚本

---

### 功能组 B：模块提取与依赖治理

<a name="req-4"></a>
### Requirement: 4. 横切基础模块独立编译

<a name="openspec-req-4"></a>系统应当（SHALL）提取 `common`、`ai-core`、`vector-store-api`、`vector-store-pgvector`、`platform-persistence`、`nosql`、`bot-api`、`bot-feishu`、`human-loop`、`mcp-integration` 为独立 Maven 子模块，每步提取后根目录 `mvn clean compile` 通过。

#### 场景: common 与 ai-core 提取
- **前提**：横切工具、全局配置、`LlmCompletionPort` 等接口散落在单模块
- **操作**：创建子模块 POM；`git mv` 对应源码；`ai-core` 仅依赖 `common`，不含 Spring AI 具体实现
- **结果**：子模块独立编译；`ai-core` 提供框架无关 `ChatService`、`EmbeddingService`、`VectorStore` 等端口定义

#### 场景: 向量库与持久化基础设施
- **前提**：pgvector 与 DataSource/Flyway 配置在单模块
- **操作**：`vector-store-api` 定义接口；`vector-store-pgvector` 实现；`platform-persistence` 承载 DataSource、Flyway 主配置、MyBatis 基类
- **结果**：业务模块通过接口依赖向量库，不直接依赖 pgvector 实现细节

---

<a name="req-5"></a>
### Requirement: 5. AI 框架模块与 learning 隔离

<a name="openspec-req-5"></a>系统应当（SHALL）将 Spring AI、Alibaba CompiledGraph、LangChain4j 实现分别落入 `ai-spring`、`ai-alibaba`、`ai-langchain`；将 Demo/教程代码落入 `learning` 模块，且**禁止**任何业务模块（`knowledge-hub`、`agent-hub`、`aether-platform`、`bot-feishu`）依赖 `learning`。

#### 场景: CompiledGraph 基础设施独立
- **前提**：`AbstractKnowledgeGraphNode`、`ConfigurableGraphBuilder` 等基类在 knowledgehub 包
- **操作**：提取至 `ai-alibaba`；knowledge-hub 与 agent-hub 依赖 `ai-alibaba` 而非互拷基类
- **结果**：Graph 节点基类单点维护；各业务域 Graph 正常编译

#### 场景: learning 模块不可被生产依赖
- **前提**：`springai`、`base`、`demo` 包含教程与实验代码
- **操作**：合并为 `learning` 子模块；业务模块 POM 无 `learning` 依赖
- **结果**：`mvn dependency:tree` 显示业务域 → learning 无依赖边

---

<a name="req-6"></a>
### Requirement: 6. 三大业务域独立模块

<a name="openspec-req-6"></a>系统应当（SHALL）将 `knowledgehub`、`agents`、`superAgents` 分别提取为 `knowledge-hub`、`agent-hub`、`aether-platform` 三个业务域 Maven 子模块，保留 DDD 四层包结构，跨域调用仅经防腐 Port。

#### 场景: knowledge-hub 模块化
- **前提**：知识库 87 文件含 upload/query Graph 全流水线
- **操作**：提取为 `knowledge-hub` 子模块；Graph 节点 `@Component` 保留；Repository 使用 req-2 接口化结果
- **结果**：知识库上传、问答、CRUD API 行为与模块化前一致

#### 场景: agent-hub 经防腐接口访问知识库
- **前提**：agent-hub 需检索与写入知识库
- **操作**：`KnowledgeRetrievalPort`、`KnowledgeAdminPort` 接口在 knowledge-hub 或共享 domain 定义；agent-hub 通过 Adapter 注入，不 import knowledge-hub infrastructure
- **结果**：agent-hub 对话与 CLI 调用正常；无 Bean 重复定义

#### 场景: aether-platform 模块化
- **前提**：superAgents 273 文件含 11 个 Repository 接口与 Skill/Registry Graph
- **操作**：提取为 `aether-platform`；`LlmCompletionPort` 已提升至 `ai-core`；平台 Flyway 脚本随模块迁移
- **结果**：平台对话、Registry、Skill、MCP 管理 API 行为不变

---

### 功能组 C：组装与验收

<a name="req-7"></a>
### Requirement: 7. application 启动模块组装

<a name="openspec-req-7"></a>系统应当（SHALL）提供 `application` 子模块作为唯一 Spring Boot 启动入口，通过 `scanBasePackages` 与 `spring.config.import` 聚合所有子模块 Bean 与配置，自身不含业务代码。

#### 场景: 全量 Bean 扫描
- **前提**：各子模块 `@Component`、`@Service`、`@Repository` 分布在不同 JAR
- **操作**：`DeepseekApplication` 配置 `scanBasePackages = "com.yxy.deepseek"`；必要时补充 `AutoConfiguration.imports`
- **结果**：应用启动成功；Actuator `/health` 返回 UP；无 Bean 缺失或重复定义

#### 场景: 配置聚合
- **前提**：各模块有 `application-<模块名>.yml`
- **操作**：主 `application.yml` 通过 `spring.config.import` 显式导入子模块配置
- **结果**：DashScope、pgvector、飞书、知识库等配置与模块化前等效加载

---

<a name="req-8"></a>
### Requirement: 8. 无功能回归验收

<a name="openspec-req-8"></a>系统应当（SHALL）在模块化完成后通过全量编译、依赖无环、核心 API E2E 与测试套件验证，确保对外行为零变更。

#### 场景: 构建与依赖检查
- **前提**：全部 19 子模块与父 POM 就位
- **操作**：根目录执行 `mvn clean install`；执行 `mvn dependency:tree` 检查环形依赖
- **结果**：编译与测试通过（既有 `testExclude` 逐步解除）；依赖树无环

#### 场景: 核心 API 端到端
- **前提**：应用由 `application` 模块启动
- **操作**：验证 `POST /api/agent-hub/chat/agent`、`POST /api/agent-hub/chat/knowledge`、`POST /api/super-agents/chat`、知识库上传/问答、飞书回调端点
- **结果**：响应格式、SSE 序列与模块化前一致；无新增 5xx 或契约字段缺失

#### 场景: 密钥不入库
- **前提**：`application.yaml` 曾含明文 API Key
- **操作**：迁移至环境变量（如 `DASHSCOPE_API_KEY`）；占位符提交仓库
- **结果**：仓库无真实密钥；本地/CI 通过环境变量可正常调用 LLM

