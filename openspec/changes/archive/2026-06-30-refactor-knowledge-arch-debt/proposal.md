## Why

- 背景：[`docs/重构方案-合并版.md`](../../docs/重构方案-合并版.md) 与代码审查确认 knowledge-hub `knowledge_chunks` 与 agent-hub Spring AI `vector_store` 双轨并存，数据不可见风险最高。
- 目标：分阶段收口架构债，优先冻结/迁移 B 路径写入，同步安全与 Flyway 门禁。

## What Changes

- **Phase 1（本期）**：`ConversationKnowledgeService` 改走 `KnowledgeAdminPort`；废弃 `VectorStoreKnowledgeRetriever`；标记 `KnowledgeStoreService`/`KnowledgePersistenceHook` 为遗留；移除 `application.yml` 明文 sk 默认；Flyway 聚合测试对齐 V28。
- **Phase 2（后续）**：`KnowledgePersistenceHook`、`CompressedHistoryVectorIndexer` 迁移至 Port；评估禁用全局 `vector_store` Bean。
- **Phase 3（后续）**：记忆类 `repository/` 具体类提取 domain 接口；Flyway 文档与 path-map 按模块维护。

## Capabilities

### Modified Capabilities

- `aether-knowledge-rag`：Agent Hub 会话入库统一走 knowledge-hub 主路径

## Impact

- 后端：`ai/agent-hub`、`ai/application`、`ai/deepseek`（Flyway 测试）
- 配置：新增 `agenthub.knowledge.default-knowledge-base-id`（必填方可入库）
- 无前端 UI 变更
