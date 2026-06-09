# 设计审查（design-review）

> **Schema**：`standard-spec-driven`  
> **审查方式**：设计审查（brainstorming 模式要点自检）  
> **输入**：`proposal.md`、`specs/**/spec.md`、`design.md` v1.0  
Status: Reviewed

## 审查基线

| 项 | 值 |
|---|---|
| Change | `p3-multi-tenant-enforcement` |
| design.md 版本 | v1.0（2026-06-09） |
| 审查执行 | AI 设计审查自检 |
| 审查人确认 | **已确认**（2026-06-09，用户回复确认 design-review 并 apply） |

## 审查结论摘要

- **总体结论**：**建议通过**（无阻塞项；2 项须在 apply 前明确）
- **阻塞项数量**：0
- **建议项数量**：3

## 模式评估

| 开关 | 结论 |
|------|------|
| `aiTddMode: disabled` | 维持；租户过滤为常规 AUTO-UT |
| `uiCraftMode: disabled` | 维持；无 U1 界面 |

## 阻塞项清单

无。

## 须在 apply 前明确的决策

| ID | 项 | 建议 |
|----|-----|------|
| DR-01 | 非法租户 HTTP 码 | 采纳 design **400 INVALID_TENANT**（非 403） |
| DR-02 | MyBatis 全局插件 | 本期 **不做**；仅核心 3 个 Repository 守卫 |

## 建议项

| ID | 建议 | 优先级 |
|----|------|--------|
| S-01 | `session_memory` Flyway 放 `knowledge-hub` 模块 | P0 |
| S-02 | `TenantScopedPlatformCache.invalidateAll` 禁止全局 clear，改为按租户失效 | P1 |
| S-03 | apply 后同步 `aether-knowledge-memory` 主 spec REQ-4 验收口径（归档时） | P2 |

## 与 P3 可观测变更的一致性

- Filter 路径范围与 `PlatformRateLimitFilter` 一致（`/api/super-agents/**`）
- 单测执行模块：**aether-platform** / **knowledge-hub**（非 deepseek）

---

确认无误请回复 **「确认 design-review」**，我将生成 `test-cases.md` 与 `tasks.md` 并进入 apply。
