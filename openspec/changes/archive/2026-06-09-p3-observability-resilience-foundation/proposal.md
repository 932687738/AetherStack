## Why
（为什么要做）

### 背景与目标

- **背景**：`aether-agent-observability`（P3）与 `aether-agent-resilience`（P3）已在主 spec 与 `aether-agent-platform-foundation` 设计中定义，且 **ai** 仓已有部分实现（`SuperAgentPlatformMetrics`、`TraceSpanRecorder`、`LastResortHandler`），但缺少**独立 OpenSpec 变更闭环**：无专项 test-cases/tasks/trace、无 verification-report，ROADMAP 标为 🟡 partial。限流 429（resilience REQ-3）**尚未实现**。
- **目标**：以最小波次完成 P3 可观测 + 弹性**验收闭环**，不重复平台基础架构设计。本变更仅消化下列 REQ 子集，其余 REQ 保留 OPEN 并回写 [`docs/ROADMAP.md`](../../../docs/ROADMAP.md)。

## Jira / 需求链接

- 无工单

## What Changes
（变更内容）

### 本变更消化的 REQ（子集）

| 主 Spec | REQ | 交付内容 |
|---------|-----|----------|
| `aether-agent-observability` | REQ-5 Prometheus 指标 | 补齐/验收 `spring_ai_platform_*` 指标；`AUTO-UT` 断言 MeterRegistry |
| `aether-agent-observability` | REQ-1 全链路 Trace | 验收 `TraceSpanRecorder` 落库与 parent-child；`AUTO-UT` 覆盖 span 树 |
| `aether-agent-resilience` | REQ-3 限流与 429 | 新增租户维度限流 Filter/Interceptor；429 + `Retry-After`；对齐 [`api-conventions.md`](../../references/api-conventions.md) §5 |
| `aether-agent-resilience` | REQ-1 Tool 失败重试 | 验收可配置退避重试（若存量已部分实现则补单测，不扩大范围） |

### 明确不在本变更范围（保留 OPEN）

- observability REQ-2 决策日志、REQ-3 审计不可篡改、REQ-4 成本归因日聚合 → 后续 `p3-observability-phase-2`
- resilience REQ-2 Graph Saga 补偿、REQ-4 LastResort 完整版、REQ-5 无状态会话恢复 → 后续波次
- 多租户强制过滤 → `p3-multi-tenant-enforcement`

### API 与文档

- 限流 429 行为写入 [`api-conventions.md`](../../references/api-conventions.md)（已建真源，本变更实现与之对齐）
- 若新增 Actuator 端点或响应 Header 约定，更新 [`integration-contracts.md`](../../references/integration-contracts.md) 与 [`api-changelog.md`](../../references/api-changelog.md)

## Capabilities
（能力清单 — 需求层面变化）

- `aether-agent/observability`（delta：REQ-1、REQ-5 验收闭环）
- `aether-agent/resilience`（delta：REQ-1、REQ-3 实现与验收）

## Impact
（影响范围）

| 仓库 | 模块 | 说明 |
|------|------|------|
| **ai** | `aether-platform/.../metrics`、`.../observability` | 指标与 Trace 验收测试 |
| **ai** | `aether-platform/.../web` 或 `common` | 限流 Filter（429） |
| AetherStack | `docs/ROADMAP.md` | 闭环状态更新 |
| AetherStack | `api-changelog.md` | 若 API 行为变更则追加 |

## Schema

- `standard-spec-driven`
- `aiTddMode: disabled`（无 L1 LLM 编排新增；指标与 Filter 属常规 AUTO-UT）
- `uiCraftMode: disabled`

## Risks / Notes

- 限流阈值须可配置（`application.yml`），默认值避免开发环境误伤
- Prometheus 指标命名与存量 `SuperAgentPlatformMetrics` 保持一致，避免双套指标
- 本变更完成后 ROADMAP 将 observability / resilience 标为 **🟡 partial**（非整 spec done）
