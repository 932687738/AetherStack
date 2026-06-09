# 测试用例（standard-spec-driven）

## 0. 测试基线来源

- Source：`OpenSpec 派生（依据 specs/design，design-review Reviewed）`
- OpenSpec 基线：`specs/**/spec.md` + `design.md` v0.2
- 外部测试基线：无
- 采用方式：仅 OpenSpec
- Status：`Reviewed`（与 design-review 同步确认，2026-06-09）

---

## 1. 用例主体

# [S] Schema Catalog（aether-agent-schema-catalog）

## [S] Requirement 1：识别历史 Flyway DDL

### [C] TC-SC-REQ1-01 启动全量同步写入 Catalog
[Automation] `AUTO-UT`
[前置条件]
- aether-platform Flyway 已执行；V21 表已存在
#### 步骤1
调用 `SchemaCatalogSyncApplicationService.syncFull()`
##### 预期结果
- `text2sql_schema_table` 含 `skills`、`agent_registry` 等迁移表
- `source_migration` 非空
#### 可观测性断言
- 数据库断言：`text2sql_schema_table` 行数 ≥ 平台核心表数量

## [S] Requirement 2：增量同步新迁移

### [C] TC-SC-REQ2-01 未处理 migration 增量解析
[Automation] `AUTO-UT`
#### 步骤1
向 `flyway_schema_history` mock 新 script；调用 `syncIncremental()`
##### 预期结果
- `text2sql_schema_migration_index` 新增记录
- Catalog upsert 对应表/列变更

## [S] Requirement 3：运行时元数据校验

### [C] TC-SC-REQ3-01 解析与 pg_catalog 不一致时以 DB 为准
[Automation] `AUTO-UT`
#### 步骤1
Flyway 解析含列 A；mock `PgCatalogValidator` 返回列 B
##### 预期结果
- Catalog 持久化列 B；差异日志/表有记录

## [S] Requirement 4：可查询表白名单

### [C] TC-SC-REQ4-01 敏感表默认不可查
[Automation] `AUTO-UT`
#### 步骤1
查询 `queryable=false` 的 `audit_log`
##### 预期结果
- text2sql schema lookup 不返回该表

## [S] Requirement 5：租户可见性

### [C] TC-SC-REQ5-01 租户 A 不可见租户 B 表
[Automation] `AUTO-UT`
#### 步骤1
tenantId=A 调用 `SchemaCatalogRepository.search(tenantId=A, query)`
##### 预期结果
- 结果集不含 tenant B 专属标记表

## [S] Requirement 6：语义检索 MVP（ILIKE）

### [C] TC-SC-REQ6-01 关键词命中 trace 相关表
[Automation] `AUTO-UT`
#### 步骤1
query=`trace 调用` tenant=default
##### 预期结果
- Top-K 含 `trace_spans` 及字段摘要

---

# [S] Text2SQL（aether-agent-text2sql）

## [S] Requirement 1：生成只读 SQL 草案

### [C] TC-T2S-REQ1-01 Prompt 渲染含 Catalog 片段
[Automation] `AUTO-AI-UT`
#### 步骤1
Mock ChatClient；调用 `Text2SqlSqlGenerator.generate(question, catalogContext)`
##### 预期结果
- Prompt 含 `trace_spans` 或 Catalog 注入片段
- 输出 SQL 为 SELECT 形态（Mock 固定响应断言）

## [S] Requirement 2：执行前确认

### [C] TC-T2S-REQ2-01 未确认不执行
[Automation] `AUTO-UT`
#### 步骤1
session.status=AWAITING_CONFIRM；调用 `executeWithoutConfirm()`
##### 预期结果
- 抛出/返回 `TEXT2SQL_NOT_CONFIRMED`；无 JDBC 调用

### [C] TC-T2S-REQ2-02 推送 sql-review artifact
[Automation] `AUTO-AI-UT`
#### 步骤1
Graph 节点 `publishSqlReviewArtifact` 执行
##### 预期结果
- `PlatformSseFormatter.formatArtifact` 被调用；kind=sql-review

## [S] Requirement 3：多轮会话上下文

### [C] TC-T2S-REQ3-01 修改条件后仍关联同 session
[Automation] `AUTO-UT`
#### 步骤1
session AWAITING_CONFIRM；用户 decision=REVISE「加 limit 50」
##### 预期结果
- 同 `conversation_id` session 更新 sql_draft；status 仍为 AWAITING_CONFIRM

## [S] Requirement 4：SqlGuard 安全校验

### [C] TC-T2S-REQ4-01 拒绝 DELETE
[Automation] `AUTO-AI-UT`
#### 步骤1
`SqlGuardDomainService.validate("DELETE FROM skills")`
##### 预期结果
- success=false；errorCode=SQL_NOT_READONLY

### [C] TC-T2S-REQ4-02 缺少 tenant 条件拒绝
[Automation] `AUTO-AI-UT`
#### 步骤1
validate SELECT 无 tenant_id WHERE
##### 预期结果
- errorCode=TENANT_FILTER_MISSING

### [C] TC-T2S-REQ4-03 非白名单表拒绝
[Automation] `AUTO-AI-UT`
#### 步骤1
validate SELECT from 未登记表
##### 预期结果
- errorCode=TABLE_NOT_ALLOWED

## [S] Requirement 5：结构化结果与摘要

### [C] TC-T2S-REQ5-01 执行成功返回 table artifact
[Automation] `AUTO-UT`
#### 步骤1
Mock ReadOnlyQueryExecutor 返回 2 行；调用 executeConfirmed
##### 预期结果
- table artifact columns/rows 正确；token 摘要含行数

## [S] Requirement 6：审计

### [C] TC-T2S-REQ6-01 审计记录 TEXT2SQL_EXECUTE
[Automation] `AUTO-UT`
#### 步骤1
完成一次 confirm+execute
##### 预期结果
- `AuditLogService.record*` 或等价调用含 sql 摘要、tenantId

---

# [S] Chat Artifacts 契约（aether-integration-chat-artifacts）

## [S] Requirement 1~3：SSE artifact 基础与兼容

### [C] TC-ART-REQ1-01 structured 模式 artifact JSON
[Automation] `AUTO-UT`
#### 步骤1
`formatArtifact(sqlReviewArtifact)` structuredEvents=true
##### 预期结果
- JSON type=artifact；含 id/kind/title

### [C] TC-ART-REQ3-01 非 structured 降级 plain text
[Automation] `AUTO-UT`
#### 步骤1
structuredEvents=false
##### 预期结果
- 返回可读 plain text，非空

---

# [S] SSE 契约增量（aether-integration-chat-sse-contract）

### [C] TC-SSE-REQ5-01 token/progress/artifact 同流
[Automation] `AUTO-UT`
#### 步骤1
Mock SSE 流含三种 type
##### 预期结果
- `SuperAgentSse.ts` 分别触发 onChunk/onProgress/onArtifact

---

# [S] 前端 Artifact 渲染（aether-frontend-artifact-rendering）

### [C] TC-FE-REQ3-01 SQL MySQL 高亮渲染
[Automation] `MANUAL`
[ManualReason]
- 需浏览器验证语法高亮与 dialect 标注
#### 步骤1
加载含 sql-review artifact 的 assistant 消息
##### 预期结果
- SQL 块 MySQL 风格高亮；显示 executionDialect=postgresql 提示

### [C] TC-FE-REQ4-01 表格分页展示
[Automation] `MANUAL`
[ManualReason]
- Ant Design Table 交互与截断提示需 UI 验证
#### 步骤1
table artifact 100 行 truncated=true
##### 预期结果
- 表格可横向滚动；截断提示可见

### [C] TC-FE-REQ6-01 确认按钮发送用户消息
[Automation] `MANUAL`
[ManualReason]
- 聊天 composer 集成 E2E
#### 步骤1
点击「确认执行」
##### 预期结果
- 发送含确认语义的用户消息；触发新一轮 SSE

### [C] TC-FE-REQ1-01 ArtifactRenderer 分发
[Automation] `AUTO-UT`
#### 步骤1
Jest/RTL 渲染 artifacts=[sql-review, table]
##### 预期结果
- 两种视图均挂载

---

# [S] Orchestrator（aether-agent-orchestrator REQ-5~6）

### [C] TC-ORCH-REQ5-01 数据分析路由 data-analysis
[Automation] `AUTO-AI-UT`
#### 步骤1
Mock prep 图；输入「本月 API 调用量统计」
##### 预期结果
- streamRoute=SUB_AGENT；registryEntry.name=data-analysis

### [C] TC-ORCH-REQ6-01 AWAITING_CONFIRM 时走 resume 非新路由
[Automation] `AUTO-UT`
#### 步骤1
存在 text2sql AWAITING_CONFIRM session；用户输入「确认」
##### 预期结果
- 不触发全新 prep 子 Agent 切换；进入 Text2SqlSessionResumeBridge

---

## 2. AUTO-AI-UT / AUTO-UT 标记汇总

| TC | REQ | Automation | 目标测试类 |
|----|-----|------------|------------|
| TC-T2S-REQ1-01 | text2sql-1 | AUTO-AI-UT | `Text2SqlSqlGeneratorTest` |
| TC-T2S-REQ2-02 | text2sql-2 | AUTO-AI-UT | `Text2SqlArtifactPublisherTest` |
| TC-T2S-REQ4-01~03 | text2sql-4 | AUTO-AI-UT | `SqlGuardDomainServiceTest` |
| TC-ORCH-REQ5-01 | orchestrator-5 | AUTO-AI-UT | `Text2SqlRoutingPrepTest` |
| TC-SC-REQ1-01 | schema-catalog-1 | AUTO-UT | `SchemaCatalogSyncApplicationServiceTest` |
| TC-T2S-REQ2-01 | text2sql-2 | AUTO-UT | `Text2SqlApplicationServiceTest` |
| TC-ART-REQ1-01 | chat-artifacts-1 | AUTO-UT | `PlatformSseFormatterArtifactTest` |
| TC-SSE-REQ5-01 | chat-sse-5 | AUTO-UT | `SuperAgentSseTest` |
| TC-FE-REQ1-01 | artifact-rendering-1 | AUTO-UT | `ArtifactRenderer.test.tsx` |
| TC-FE-REQ3-01 等 | frontend | MANUAL | Playwright / 手工 |

## 3. 口径冲突清单

无
