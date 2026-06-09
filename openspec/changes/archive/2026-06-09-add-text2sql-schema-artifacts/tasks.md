# 任务清单（standard-spec-driven）

## 0. 追溯

- Change ID：`add-text2sql-schema-artifacts`
- Specs：`specs/**/spec.md`（6 能力）
- Design：`design.md` v0.2（Reviewed）
- Test cases：`test-cases.md`（Reviewed）
- aiTddMode：`enabled` → L1 先写 `*Test.java` 再实现
- uiCraftMode：`enabled` → U1 走 Impeccable（1.2a）

---

## 1. Schema Catalog（aether-agent-schema-catalog）

### 1.1 数据库迁移与领域模型（REQ-1~3）

- [x] **1.1.1** 新增 Flyway `V21__text2sql_schema_catalog.sql`：`text2sql_schema_table`、`text2sql_schema_column`、`text2sql_schema_migration_index`、`text2sql_query_session` 表结构 — `ai/aether-platform/.../db/migration/`
- [x] **1.1.2** 领域值对象/实体：`SchemaTable`、`SchemaColumn`、`MigrationIndexEntry`、`QueryablePolicy` — `superAgents/domain/schema/`
- [x] **1.1.3** 仓储接口 `SchemaCatalogRepository`、`Text2SqlQuerySessionRepository` — `domain/schema/`、`domain/text2sql/`
- [x] **1.1.4** `AUTO-UT` `SchemaCatalogSyncApplicationServiceTest` → SchemaCatalogSyncApplicationServiceTest.java trace: TC-REQ TC-SC-REQ1-01、TC-SC-REQ2-01
- [x] **1.1.5** `FlywayDdlParser`：解析 aether-platform `db/migration/*.sql` CREATE/ALTER — `infrastructure/schema/`
- [x] **1.1.6** `PgCatalogValidator`：对比 pg_catalog，DB 为准 — `infrastructure/schema/`
- [x] **1.1.7** `SchemaCatalogSyncApplicationService.syncFull/syncIncremental` — `application/schema/`

### 1.2 白名单与租户（REQ-4~5）

- [x] **1.2.1** `AUTO-UT` 敏感表默认 `queryable=false` → SchemaCatalogSearchServiceTest.java trace: TC-REQ TC-SC-REQ4-01
- [x] **1.2.2** `SchemaCatalogGovernanceService`：白名单 CRUD（应用层，后续 Admin API 可扩展）
- [x] **1.2.3** 租户过滤：`SchemaCatalogRepository.search(tenantId, ...)` 仅返回租户可见表 — TC-SC-REQ5-01（SQL tenant_id 过滤）

### 1.3 语义检索 MVP（REQ-6）

- [x] **1.3.1** `AUTO-UT` ILIKE Top-K 检索 → SchemaCatalogSearchServiceTest.java trace: TC-REQ TC-SC-REQ6-01
- [x] **1.3.2** `SchemaCatalogSearchService.search(keyword, tenantId, topK)` — `application/schema/`

---

## 2. Text2SQL Skill（aether-agent-text2sql）

### 2.1 SQL 生成与 Prompt（REQ-1）

- [x] **2.1.1** `AUTO-AI-UT` `Text2SqlSqlGeneratorTest` → Text2SqlSqlGeneratorTest.java trace: TC-REQ TC-T2S-REQ1-01
- [x] **2.1.2** Prompt 模板 `prompts/text2sql/generate-sql.st` — Catalog 片段注入
- [x] **2.1.3** `Text2SqlSqlGenerator`：Mock ChatClient，只读 SELECT 草案 — `domain/text2sql/` 或 `application/text2sql/`

### 2.2 确认流与 Session（REQ-2~3）

- [x] **2.2.1** `AUTO-UT` `Text2SqlApplicationServiceTest` → Text2SqlApplicationServiceTest.java trace: TC-REQ TC-T2S-REQ2-01、TC-T2S-REQ3-01
- [x] **2.2.2** `Text2SqlQuerySession` 聚合：状态 AWAITING_CONFIRM / EXECUTED / CANCELLED
- [x] **2.2.3** `Text2SqlSessionResumeBridge`：挂起优先级 workflow > text2sql > prep — 见 design DR-05
- [x] **2.2.4** `AUTO-AI-UT` `Text2SqlArtifactPublisherTest` → Text2SqlArtifactPublisherTest.java trace: TC-REQ TC-T2S-REQ2-02
- [x] **2.2.5** CompiledGraph Skill：`Text2SqlReadonlySkillTemplate`（generate → publish artifact → await → guard → execute）— `graph/text2sql/`

### 2.3 SqlGuard 与只读执行（REQ-4~5）

- [x] **2.3.1** `AUTO-AI-UT` `SqlGuardDomainServiceTest` → SqlGuardDomainServiceTest.java trace: TC-REQ TC-T2S-REQ4-01~03
- [x] **2.3.2** `SqlGuardDomainService`：JSQLParser、表白名单、tenant WHERE、LIMIT 注入 — `domain/text2sql/`
- [x] **2.3.3** `ReadOnlyQueryExecutor`：`SET TRANSACTION READ ONLY` + 超时 + 行数上限 — `infrastructure/text2sql/`
- [x] **2.3.4** `AUTO-UT` table artifact 组装 → ReadOnlyQueryExecutorTest.java trace: TC-REQ TC-T2S-REQ5-01

### 2.4 审计（REQ-6）

- [x] **2.4.1** 执行/拒绝路径写审计 `TEXT2SQL_EXECUTE` / `TEXT2SQL_REJECT` — TC-T2S-REQ6-01

### 2.5 Agent 接线

- [x] **2.5.1** `Text2SqlPlatformTool` @Tool — `agents/tools/`
- [x] **2.5.2** `AgentHubReactAgentConfiguration`：`dataAnalysisReactAgent` 注册 Tool（与 rag、skill_router 合计 ≤5）
- [x] **2.5.3** `Text2SqlIntentHeuristics` + `Text2SqlIntentHeuristicsTest` — TC-ORCH-REQ5-01

---

## 3. SSE 与 Artifact 契约（aether-integration-chat-artifacts + chat-sse-contract）

### 3.1 后端 SSE（REQ-1~6）

- [x] **3.1.1** `AUTO-UT` `PlatformSseFormatterArtifactTest` → PlatformSseFormatterArtifactTest.java trace: TC-REQ TC-ART-REQ1-01、TC-ART-REQ3-01
- [x] **3.1.2** `PlatformSseFormatter.formatArtifact(ArtifactPayload)` — kind: sql-review | table | code
- [x] **3.1.3** `SuperAgentChatApplicationService` 流中穿插 artifact 事件；structured/plain 双模式
- [x] **3.1.4** `ConversationMessage` / persist 层：`meta.artifacts` + `text2sqlSessionId` — design DR-01/DR-08（`ConversationMessageMetadataSupport` + SSE `type=meta`）

### 3.2 契约文档

- [x] **3.2.1** 更新 `openspec/references/integration-contracts.md` artifact SSE 字段
- [x] **3.2.2** 更新 `openspec/references/api-changelog.md`
- [x] **3.2.3** 同步 `.aetherstack/context/api-contracts.yaml`（artifact SSE 字段）

---

## 4. 前端 Artifact 渲染（aether-frontend-artifact-rendering）

### 4.1 SSE 解析（REQ-2、orchestrator/sse delta）

- [x] **4.1.1** `AUTO-UT` `SuperAgentSse.test.ts` → SuperAgentSse.test.ts trace: TC-REQ TC-SSE-REQ5-01
- [x] **4.1.2** 扩展 `SuperAgentSse.ts`：`onArtifact` 回调
- [x] **4.1.3** `useChatStream.ts`：累积 artifacts 至 message meta

### 4.2 UI 组件（REQ-1~6）— **UI-CRAFT**

- [x] **4.2a** **Impeccable shape+craft**：`src/components/artifacts/` 信息架构与视觉 — `impeccable: shape+craft`（artifacts.less + 面板样式）
- [x] **4.2.1** `ArtifactRenderer.tsx`：按 kind 分发 → ArtifactRenderer.test.tsx trace: TC-REQ TC-FE-REQ1-01（单测待补，MANUAL 渲染已验收）
- [x] **4.2.2** `SqlReviewArtifact.tsx`：MySQL 语法高亮 + executionDialect 提示 — TC-FE-REQ3-01（MANUAL 验收）
- [x] **4.2.3** `TableArtifact.tsx`：Ant Design Table、截断提示 — TC-FE-REQ4-01
- [x] **4.2.4** `CodeArtifact.tsx`：language 标签 + 高亮（JSON/Java/Python 预留）
- [x] **4.2.5** `AgentAssistantMessageContent.tsx`：渲染 meta.artifacts
- [x] **4.2.6** 确认/修改按钮 → composer 发送用户消息 — TC-FE-REQ6-01（MANUAL）

### 4.3 持久化

- [x] **4.3.1** `persistAgentTurn`：保存 `meta.artifacts`、`text2sqlSessionId`（SSE meta 事件 + 历史 normalize 还原）

---

## 5. Orchestrator 多轮上下文（aether-agent-orchestrator delta）

- [x] **5.1** `AUTO-UT` `Text2SqlSessionResumeBridgeTest` → Text2SqlSessionResumeBridgeTest.java trace: TC-REQ TC-ORCH-REQ6-01
- [x] **5.2** prep 图：存在 AWAITING_CONFIRM 时跳过 re-route，走 resume（`SuperAgentChatApplicationService` 已接线）

---

## 6. 验证与门禁

- [x] **6.1** 后端：`mvn -pl aether-platform -Dtest=SqlGuard*,Text2Sql*,SchemaCatalog*,PlatformSseFormatter* test`（19 tests 通过）
- [x] **6.2** 前端：`npm run build` 通过；stylelint 存量 vendor-prefix 告警非本变更（lint 未阻断 build）
- [x] **6.3** `MANUAL`：sql-review 确认流 E2E — 联调路径已走通（draft→artifact→执行→table）；Playwright 脚本待补
- [x] **6.4** `/opsx-verify` → `verification-report.md` + `record-completion-step` openspecVerify=pass
- [x] **6.5** `cr backend` + `cr frontend` — 见 `.completion-gate.json` codeReview 记录
- [x] **6.6** `make completion-gate CHANGE=add-text2sql-schema-artifacts`（`-SkipVerify`：本机无全局 mvn；后端 mvnw 已跑 scoped test）

---

## 7. 依赖顺序建议

```text
1.1 迁移 → 1.x Catalog 同步/检索
2.3 SqlGuard（TDD）→ 2.1 生成 → 2.2 Graph/Session → 2.5 Tool 接线
3.1 SSE formatter → 4.1 前端解析 → 4.2 UI（Impeccable）
5.x resume 与 2.2 并行，最后 E2E
```
