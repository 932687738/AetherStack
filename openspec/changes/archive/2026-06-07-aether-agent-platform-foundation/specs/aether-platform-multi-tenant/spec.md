# 多租户隔离

## Platform / 多租户 需求说明（前提/操作/结果）
> 核心表 tenant_id；数据访问强制过滤；缓存 Key 租户前缀；pgvector 检索租户隔离。
> 交付阶段：**P3**。详见 proposal `aether-platform/multi-tenant`。

---

## ADDED Requirements
（新增用户故事）

<a name="req-1"></a>
### Requirement: 1. 表级租户字段 [P3]

<a name="openspec-req-1"></a>系统 shall 使平台核心表（agent_registry、skills、agent_memory、documents、audit_log 等）均含 tenant_id；写入时必填。

#### 场景: 无 tenant 写入拒绝
- **前提**：调用方 omit tenant_id。
- **操作**：注册 Agent 或写入 Skill。
- **结果**：校验失败；不写入脏数据。

---

<a name="req-2"></a>
### Requirement: 2. 数据访问层强制过滤 [P3]

<a name="openspec-req-2"></a>系统 shall 在 Repository/查询层自动附加 tenant_id 条件，防止开发者遗漏导致跨租户泄露。

#### 场景: 列表查询
- **前提**：租户 A、B 各有 Skill。
- **操作**：租户 A 上下文调用 listSkills。
- **结果**：仅返回 A 的记录。

---

<a name="req-3"></a>
### Requirement: 3. 缓存 Key 租户前缀 [P3]

<a name="openspec-req-3"></a>系统 shall 使所有平台缓存 Key 含 tenant 前缀；内存缓存实现须遵守，便于后续切换 Redis 不改语义。

#### 场景: 同 Key 不同租户
- **前提**：两租户 Skill 菜单均缓存 key=skill-menu。
- **操作**：分别读取缓存。
- **结果**：实际 Key 为 tenant:A:skill-menu 与 tenant:B:skill-menu；互不覆盖。

---

<a name="req-4"></a>
### Requirement: 4. 向量检索租户过滤 [P3]

<a name="openspec-req-4"></a>系统 shall 使 pgvector 检索（RAG、记忆、Skill 描述）强制带 tenant 元数据过滤或分区索引。

#### 场景: RAG 跨租户隔离
- **前提**：两租户各有同名标题文档。
- **操作**：租户 A 发起 RAG 检索。
- **结果**：仅命中 A 的向量；不返回 B 文档。

---
