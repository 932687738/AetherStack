# OpenSpec 与 Superpowers 计划类 Skill 路由

> 收敛 `writing-plans` / `executing-plans` 与 OpenSpec `tasks.md`，避免双轨实施。

## 决策表

| 场景 | 使用 | 不用 |
|------|------|------|
| 已走 OpenSpec（有 `tasks.md`） | `/opsx-apply` + Harness | `executing-plans` |
| 口头小改、无变更目录 | `writing-plans` → 直接编码 | OpenSpec 全链 |
| OpenSpec 变更但 tasks 未生成 | `/opsx-continue` 生成 tasks | `writing-plans` 另写平行计划 |
| 探索期、方案未定 | `brainstorming` | `writing-plans`（避免过早拆任务） |
| 超大变更 tasks >30 项 | OpenSpec tasks 分阶段 + `harness/docs/plans/<change-id>.md` 索引 | 第二份 executing-plans |

## 原则

1. **单一实施真源**：有 `openspec/changes/<id>/tasks.md` 时，仅以 tasks 勾选驱动进度。
2. **Harness 只接 OpenSpec**：`harness/docs/PLANS.md` 仅作变更级索引，不替代 tasks。
3. **writing-plans**：仅用于 **尚未创建 OpenSpec 变更** 时的实施草案；草案确认后应 `/opsx-new` 或 `/opsx-continue` 落入 tasks。
4. **executing-plans**：非 OpenSpec 会话的批量执行；OpenSpec 会话内用 `/opsx-apply`。

## 与完成门禁

归档前：`/opsx-verify` → `make completion-gate` → `cr` → `/opsx-archive`（见 `completion-gate.md`）。
