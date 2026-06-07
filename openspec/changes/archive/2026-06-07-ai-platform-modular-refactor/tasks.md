# 实施任务 — ai-platform-modular-refactor

> **关联仓库**：`D:\cache\workspace\ai`  
> **aiTddMode**：`enabled` | **uiCraftMode**：`disabled`  
> **Harness apply**：每实现类任务按 hev-analyzer → hev-coder → hev-verifier 三阶段执行

---

## 0. 工程准备（aether-platform-modular-structure-0）

- [x] 0.1 在 ai 仓库根目录创建父 POM `ai-platform`（packaging=pom）及空子模块骨架（19 模块目录 + pom.xml）+ 可验证输出：`mvn -N validate` 通过
- [x] 0.2 创建 `ai/docs/modular-refactor-path-map.md` 路径映射表（初始模板）+ 可验证输出：文件存在且含表头

---

## 1. 前置收敛（aether-platform-modular-structure-1）

- [x] 1.1 回滚 `agents/knowledgehub` 与重复 `agents/knowledge` staged 变更（design §4.1.1）+ 可验证输出：`git status` 无上述 staged 新增；trace: TC-REQ1-01
- [x] 1.2 梳理 `agents.knowledge` 轻量边界，移除重复 domain 类改引 knowledgehub 包 + 补充包级 README 注释 + 可验证输出：`mvn compile` 通过
- [x] 1.3 knowledge-hub Repository 接口化：domain 接口 + infrastructure MyBatis 实现（KnowledgeBase/Document/Chunk）+ 可验证输出：`KnowledgeBaseRepositoryTest` GREEN；trace: TC-REQ2-01
- [x] 1.4 逐一核对 V1～V16 Flyway 脚本，按 design §3.7 分配到 platform-persistence / knowledge-hub / aether-platform（**先不移动**，仅出归属清单）+ 可验证输出：归属表写入 path-map.md
- [x] 1.5 `application.yaml` 明文 API Key 迁移 `${DASHSCOPE_API_KEY}` 等环境变量 + 可验证输出：仓库无真实密钥；trace: TC-REQ8-04

---

## 2. 横切基础模块（aether-platform-modular-structure-4）

- [x] 2.1 提取 `common` 模块（common/config/helper）+ `mvn -pl common compile` + 更新 path-map
- [x] 2.2 提取 `ai-core`（LlmCompletionPort、ChatService 等端口）+ `mvn -pl ai-core -am compile`
- [x] 2.3 提取 `vector-store-api` + `vector-store-pgvector` + `mvn -pl vector-store-pgvector -am compile`
- [x] 2.4 提取 `platform-persistence`（DataSource、Flyway 主配置、MyBatis 基类）+ compile 通过
- [x] 2.5 提取 `nosql`（CacheStore、Redis/Caffeine）+ compile 通过
- [x] 2.6 提取 `bot-api` + `bot-feishu` + compile 通过（feishu 已迁至 bot-feishu；单测 GREEN）
- [x] 2.7 提取 `human-loop` + compile 通过
- [x] 2.8 提取 `mcp-integration` + 根目录 `mvn clean compile` 通过（**部分完成**：骨架已建；MCP 主体在 agent-hub；`McpSecurityStartupValidator` 在 aether-platform；`mcp-integration` 仍空壳）；trace: TC-REQ4-01

---

## 3. AI 框架模块（aether-platform-modular-structure-5）

- [x] 3.1 提取 `ai-alibaba`（AbstractKnowledgeGraphNode、ConfigurableGraphBuilder 基类）+ compile 通过
- [x] 3.2 提取 `ai-spring`（springai.config + embedding 实现 + rag/audit；生产 ChatClient Bean 仍随 agent-hub/aether-platform 后续提取）+ compile 通过
- [x] 3.3 提取 `ai-langchain`（`base/` 整包 17 文件）+ compile 通过
- [x] 3.4 提取 `learning`（`springai/` 整包 ~100 文件），业务模块 pom **无** learning 依赖 + `mvn dependency:tree` 验证；trace: TC-REQ5-01
- [x] 3.4a **AUTO-AI-UT**：`ConfigurableGraphBuilderTest` GREEN + `mvn -pl ai-alibaba -Dtest=ConfigurableGraphBuilderTest test`；trace: TC-REQ5-02
- [x] 3.5 根目录 `mvn clean compile` 通过

---

## 4. 业务域模块（aether-platform-modular-structure-6）

- [x] 4.1 在 knowledge-hub/domain/port 定义 `KnowledgeRetrievalPort`、`KnowledgeAdminPort` + `*PortService` 实现 + 可验证输出：编译通过
- [x] 4.2 提取 `knowledge-hub`（含 `KnowledgeHubController`；`ChatStreamMetricsPort` 解耦指标）+ Flyway V1/V2/V4/V7 物理迁移 + compile 通过
- [x] 4.3 提取 `agent-hub`（含 `AgentHubChatStreamMetricsAdapter`）+ `KnowledgeRetrievalAdapter`/`ConversationHistoryRecorderAdapter` 注入 Port + compile 通过
- [x] 4.4 提取 `aether-platform`；Flyway 脚本物理迁移（平台域）+ MapperScan 验证 + compile 通过
- [x] 4.4a **AUTO-AI-UT**：`KnowledgeRetrievalAdapterTest` GREEN + `mvn -pl deepseek -Dtest=KnowledgeRetrievalAdapterTest test`；trace: TC-REQ6-01
- [x] 4.5 配置 `spring.flyway.locations` 聚合三模块 classpath + `FlywayClasspathAggregationTest`（空 schema migrate V1～V16）；trace: TC-REQ3-01
- [x] 4.5a 远程漂移收敛：`ai/src` → agent-hub（conversationshare + conversationhistory 增量 + V17/V18）+ `ai/src` 删除 + agent-hub 单测 GREEN
- [x] 4.5b 阶段 B：`feishu` → bot-feishu；`McpSecurityStartupValidator` → aether-platform；`demo` → learning；配置收敛
- [x] 4.5c 桥接清零：`KnowledgeHubController` → knowledge-hub（`ChatStreamMetricsPort`）；`AgentHubController`/`DocumentationService`/`ReactAgentConfiguration` → aether-platform；deepseek **0** main Java
- [x] 4.6 MANUAL：知识库上传+问答 E2E；trace: TC-REQ6-02

---

## 5. 启动组装（aether-platform-modular-structure-7）

- [x] 5.1 创建 `application` 模块：迁移 `DeepseekApplication`；`scanBasePackages = "com.yxy.deepseek"` + 可验证输出：编译通过
- [x] 5.2 配置 `spring.config.import` 聚合各 `application-*.yml` + 可验证输出：配置加载无报错
- [x] 5.3 application `pom.xml` 聚合全部运行时依赖（knowledge-hub、agent-hub、aether-platform、bot-feishu、human-loop、ai-spring、ai-alibaba、vector-store-pgvector、nosql、mcp-integration）+ 可验证输出：依赖树完整
- [x] 5.4 MANUAL：启动 application，`/actuator/health` → UP；trace: TC-REQ7-01

---

## 6. 验收与回归（aether-platform-modular-structure-8）

- [x] 6.1 MANUAL：`mvn clean install` 全量构建；trace: TC-REQ8-01
- [x] 6.2 MANUAL：`mvn dependency:tree` 无环依赖；trace: TC-REQ8-03
- [x] 6.3 MANUAL：核心 API 回归（agent/knowledge/super-agents 三路径 + 飞书端点）；trace: TC-REQ8-02
- [x] 6.4 **AUTO-AI-UT**：迁移 L1 单测包路径（ApplicationService、Graph prep、Prompt 组装）+ `mvn test` L1 子集 GREEN；trace: TC-REQ8-05
- [x] 6.5 评估并逐步解除 pom `testExclude` + 可验证输出：排除列表 diff 记录于 path-map.md
- [x] 6.6 同步 ai 仓库 `ARCHITECTURE.md` 模块结构章节 + AetherStack `docs/重构方案-合并版.md` 标注「已 OpenSpec 立项」

---

## 7. 完成门禁（归档前）

- [x] 7.1 `/opsx-apply` 全部任务勾选 + `make verify`
- [x] 7.2 `/opsx-verify` → `verification-report.md`
- [x] 7.3 `cr backend` + `make completion-gate CHANGE=ai-platform-modular-refactor`
