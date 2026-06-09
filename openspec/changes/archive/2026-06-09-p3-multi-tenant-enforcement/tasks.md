> **uiCraftMode: disabled** | **aiTddMode: disabled** | **design-review**: Reviewed（2026-06-09）

## 0. Flyway（REQ-1 前置）

- [x] 0.1 后端：`knowledge-hub` 新增 `V20__session_memory_tenant.sql` — **可验证**：迁移脚本含 backfill
- [x] 0.2 验证：`mvn -pl knowledge-hub compile` — **可验证**：BUILD SUCCESS

## 1. 租户上下文与 Filter（REQ-2）

- [x] 1.1 后端：`PlatformTenantContext`、`TenantGuard`、`PlatformTenantFilter`、`PlatformApiErrorWriter.write400` — trace: TC-REQ2-01
- [x] 1.2 测试：**AUTO-UT** `PlatformTenantFilterTest` — trace: TC-REQ2-01 → PlatformTenantFilterTest
- [x] 1.3 测试：**AUTO-UT** `TenantGuardTest` — trace: TC-REQ1-01 → TenantGuardTest

## 2. Repository 守卫（REQ-1/2）

- [x] 2.1 后端：`MyBatisSkillRepository`、`MyBatisAgentRegistryRepository`、`MyBatisWorkflowSuspendRepository` 接入 `TenantGuard` — **可验证**：编译通过
- [x] 2.2 测试：**AUTO-UT** `MyBatisSkillRepositoryTenantTest` — trace: TC-REQ2-02

## 3. 缓存租户前缀（REQ-3）

- [x] 3.1 后端：`TenantScopedPlatformCache` + `SkillMenuCacheKeys` 逻辑 Key + 调用方迁移 — trace: TC-REQ3-01
- [x] 3.2 测试：**AUTO-UT** `TenantScopedPlatformCacheTest` — trace: TC-REQ3-01

## 4. RAG / 记忆隔离（REQ-4）

- [x] 4.1 测试：**AUTO-UT** `KnowledgeRetrievalPortServiceTest`（knowledge-hub）— trace: TC-REQ4-01
- [x] 4.2 测试：**AUTO-UT** `PlatformLayeredMemoryServiceTenantTest` — trace: TC-REQ4-02

## 5. 治理与验证

- [x] 5.1 治理：更新 `docs/ROADMAP.md` — **可验证**：multi-tenant / memory REQ-4 已消化
- [x] 5.2 验证：`mvn -pl aether-platform,knowledge-hub test`（scoped *Test）— **可验证**：BUILD SUCCESS
