# 知识库架构技术债 — 任务清单

> **aiTddMode**: auto — Phase 1 单测先改后码  
> **关联**: `docs/重构方案-合并版.md` §1.3

---

## Phase 1 — 双轨存储与安全（本期）

- [x] **1.1** 后端：新增 `AgentHubKnowledgeProperties`（`default-knowledge-base-id`、`default-tenant-id`）— **可验证**：配置绑定编译通过
- [x] **1.2** 后端：`ConversationKnowledgeService` 改注入 `KnowledgeAdminPort`，废弃直写 `KnowledgeStoreService` — **可验证**：`ConversationKnowledgeServiceTest` 通过
- [x] **1.3** 后端：`@Deprecated` 标记 `KnowledgeStoreService`、`VectorStoreKnowledgeRetriever`、`KnowledgePersistenceHook`；移除 `VectorStoreKnowledgeRetriever` 的 `@Service` — **可验证**：无 `KnowledgeRetriever` Bean 注入方
- [x] **1.4** 配置：`application.yml` 移除 `sk-*` 硬编码默认，仅保留 `${ENV}` 占位 — **可验证**：grep 无 `sk-` 默认
- [x] **1.5** 测试：`FlywayClasspathAggregationTest.EXPECTED_MIGRATION_COUNT` 更新为 **28** — **可验证**：classpath 聚合测试通过
- [x] **1.6** 文档：更新 `package-info.java`、`agenthub.knowledge` 配置说明 — **可验证**：边界文档与实现对齐

## Phase 2 — 捕获/压缩路径迁移（本期）

- [x] **2.1** `KnowledgePersistenceHook` 改走 `AgentHubKnowledgePortWriter` / `KnowledgeAdminPort`
- [x] **2.2** `CompressedHistoryVectorIndexer` 改走 Port；删除 `KnowledgeStoreService`、`VectorStoreKnowledgeRetriever`
- [x] **2.3** 文档：`index-to-vector-store` 注释说明现写入 knowledge-hub；`spring.ai.vectorstore` 保留供 learning 演示

## Phase 3 — Repository 分层与 Flyway 文档（本期）

- [x] **3.1** `SessionMemoryRepository` / `UserLongTermMemoryRepository` / `ConversationUserConfigRepository` 提取 domain 接口 + `MyBatis*` 实现
- [x] **3.2** 更新 `docs/modular-refactor-path-map.md` Flyway V1–V28 归属表
- [x] **3.3** `ai-core`：`TextEmbeddingPort` + `package-info`；`KnowledgeEmbeddingService` 实现端口
- [x] **3.4** 文档：`knowledgehub/package-info`、`docs/重构方案-合并版.md` §1.3 债务状态、`aether-knowledge-rag` REQ-4 收口说明
