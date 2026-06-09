## Why
（为什么要做）

### 背景与目标

- **背景**：`aether-platform-multi-tenant`（P3）与 `aether-knowledge-memory` REQ-4 已在主 spec 定义；**ai** 仓平台表（`agent_registry`、`skills`、`agent_memory`、`audit_log` 等）大多已有 `tenant_id` 列，Controller 层也解析 `X-Tenant-Id`，但 **platform foundation 显式跳过** `P3-TEN.*`（无 `TenantContext`、无 DAL 强制过滤、无 spec 级 AUTO-UT）。`session_memory` 等 knowledge-hub 表仍缺租户字段。ROADMAP 标 🟡 partial。
- **目标**：以最小波次完成多租户 **验收闭环**——请求级租户绑定、写入校验、核心 Repository 防遗漏、缓存 Key 规范、RAG/记忆检索租户隔离；不重复平台基础架构设计。本变更消化 multi-tenant REQ-1~4 与 memory REQ-4 子集，其余横切（全库 MyBatis 拦截器覆盖每一张表）留后续波次。

## Jira / 需求链接

- 无工单

## What Changes
（变更内容）

### 本变更消化的 REQ（子集）

| 主 Spec | REQ | 交付内容 |
|---------|-----|----------|
| `aether-platform-multi-tenant` | REQ-1 表级租户字段 | 补缺 Flyway（`session_memory` 等）；写入路径非空校验 |
| `aether-platform-multi-tenant` | REQ-2 DAL 强制过滤 | `PlatformTenantContext` + 请求 Filter；核心 Repository 守卫（skills、agent_registry、workflow_suspend） |
| `aether-platform-multi-tenant` | REQ-3 缓存 Key 前缀 | 审计并统一 `PlatformCache` 调用；`TenantScopedPlatformCache` 装饰器 |
| `aether-platform-multi-tenant` | REQ-4 向量检索租户过滤 | `knowledge-hub` RAG 检索 + `agent_memory` 向量查询强制 tenant 条件 |
| `aether-knowledge-memory` | REQ-4 租户隔离记忆 | 与上列 REQ-4 合并验收；working/long 记忆读写带 tenant |

### 明确不在本变更范围（保留 OPEN）

- 限流 userId/IP 维度 → 后续 resilience 子变更
- 全量 MyBatis 插件覆盖 **所有** Mapper（含 agent-hub 存量）→ 分阶段
- 前端租户切换 UI / 租户管理台 → 非本波次
- observability REQ-2~4、async-resume 闭环 → 各自变更

### API 与文档

- 无新增 REST 路径；非法/未知租户返回 **400**（对齐 `api-conventions.md`）
- 更新 [`docs/ROADMAP.md`](../../../docs/ROADMAP.md) multi-tenant / memory REQ-4 闭环状态

## Capabilities
（能力清单 — 需求层面变化）

- `aether-platform/multi-tenant`（delta：REQ-1~4 验收闭环）
- `aether-knowledge/memory`（delta：REQ-4 租户隔离记忆验收）

## Impact
（影响范围）

| 仓库 | 模块 | 说明 |
|------|------|------|
| **ai** | `aether-platform` | TenantContext、Filter、Cache 装饰、Repository 守卫 |
| **ai** | `knowledge-hub` | `session_memory` 迁移、RAG 检索 tenant 断言 |
| AetherStack | `docs/ROADMAP.md` | 闭环状态更新 |

## Schema

- `standard-spec-driven`
- `aiTddMode: disabled`（租户过滤属常规 AUTO-UT，非 L1 LLM）
- `uiCraftMode: disabled`

## Risks / Notes

- 存量单租户开发环境默认 `default` 须保持可用（`PlatformTenantApplicationService.ensureActiveTenant`）
- Flyway 迁移须 backfill `tenant_id='default'`，避免破坏现有数据
- 测试在 **`aether-platform`** 模块执行（`deepseek` testExcludes 排除 superAgents）
