# 测试用例（standard-spec-driven）

## 0. 测试基线来源

- Source：`OpenSpec 派生（依据 spec/design，design-review Reviewed）`
- Status：`Reviewed`

---

## 1. 用例主体

# [S] 多租户（multi-tenant）

## [S] Requirement 1：表级租户字段

### [C] TC-REQ1-01 无 tenant 写入拒绝
[Automation] `AUTO-UT`
#### 步骤1
`TenantGuard.requireTenantId("")` 或 `insertVersion` 含 blank tenantId
##### 预期结果
- 抛出 `IllegalArgumentException`

## [S] Requirement 2：DAL 强制过滤

### [C] TC-REQ2-01 未知租户返回 400
[Automation] `AUTO-UT`
#### 步骤1
MockMvc `GET /api/super-agents/skills`，Header `X-Tenant-Id: unknown-tenant`
##### 预期结果
- HTTP 400；body 含 `INVALID_TENANT`

### [C] TC-REQ2-02 Repository 列表带 tenant 参数
[Automation] `AUTO-UT`
#### 步骤1
`MyBatisSkillRepository.listActiveByTenant("tenant-a")` mock 验证 mapper 参数
##### 预期结果
- `skillMapper.listActiveByTenant("tenant-a")` 被调用

## [S] Requirement 3：缓存 Key 租户前缀

### [C] TC-REQ3-01 同逻辑 Key 不同租户隔离
[Automation] `AUTO-UT`
#### 步骤1
`TenantScopedPlatformCache` 对 tenant-a / tenant-b 写入同 logicalKey
##### 预期结果
- 底层 cache 物理 Key 分别为 `tenant-a:skill-menu` 与 `tenant-b:skill-menu`

## [S] Requirement 4：向量检索租户过滤

### [C] TC-REQ4-01 RAG 跨租户拒绝
[Automation] `AUTO-UT`
#### 步骤1
`KnowledgeRetrievalPortService.search(q, kbId, "tenant-b")` 且 kbase 属于 tenant-a
##### 预期结果
- `FORBIDDEN`；不调用 chunk 检索

### [C] TC-REQ4-02 工作记忆按 tenant 读写
[Automation] `AUTO-UT`
#### 步骤1
`PlatformLayeredMemoryService.loadSkillWorking("tenant-a", conv, skill)`
##### 预期结果
- `agentMemoryRepository.findWorkingContent("tenant-a", ...)`

---

## 3. AUTO-UT 标记汇总

| TC | REQ | 目标测试类 |
|----|-----|------------|
| TC-REQ1-01 | multi-tenant-1 | `TenantGuardTest` |
| TC-REQ2-01 | multi-tenant-2 | `PlatformTenantFilterTest` |
| TC-REQ2-02 | multi-tenant-2 | `MyBatisSkillRepositoryTenantTest` |
| TC-REQ3-01 | multi-tenant-3 | `TenantScopedPlatformCacheTest` |
| TC-REQ4-01 | multi-tenant-4 | `KnowledgeRetrievalPortServiceTest` |
| TC-REQ4-02 | memory-4 | `PlatformLayeredMemoryServiceTenantTest` |
