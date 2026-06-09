# 分层记忆（P3 租户隔离验收）

> 本 delta 仅强化 REQ-4 的可验证验收口径；REQ-1~3 保持主 spec 不变。

---

## MODIFIED Requirements

<a name="req-4"></a>
### Requirement: 4. 租户隔离记忆 [P3]

<a name="openspec-req-4"></a>系统 SHALL 使长期/工作记忆读写与向量检索按 tenant_id 隔离；本变更验收须与 `aether-platform-multi-tenant` REQ-4 合并，包含 `PlatformLayeredMemoryService` 或等价路径的 AUTO-UT。

#### 场景: 工作记忆租户隔离
- **前提**：租户 A、B 同 conversationId 写入 working 记忆。
- **操作**：租户 A 读取 working 记忆。
- **结果**：仅返回 A 写入内容；不含 B 数据。

---
