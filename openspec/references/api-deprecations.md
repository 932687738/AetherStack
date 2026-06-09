# API 废弃登记（Active Deprecations）

本文件维护**当前仍可用但计划下线**的 HTTP 接口与相关约定。真源流程见 [`api-conventions.md`](api-conventions.md) §8。

> 状态：`deprecated` = 仍可用并记录 WARN；`sunset` = 只读或 410；`removed` = 已删除（移至 Changelog Removed 段）。

---

## 登记表

| 状态 | 方法 | 路径 | 替代路径 | 废弃日期 | Sunset 目标 | 关联变更 | 备注 |
|------|------|------|----------|----------|-------------|----------|------|
| deprecated | POST | `/api/agent-hub/chat/agent` | `POST /api/super-agents/chat` | 2026-06-07 | 2026-12-31 | `aether-agent-platform-foundation` | 前端已切 `sendAgentChat`；保留兼容总路由内核 |
| deprecated | — | `VITE_*` 环境变量（`legacy-vite/`） | Umi `API_PROXY_TARGET`、`MOCK_CHAT` | 2026-06-03 | 2026-09-30 | `frontend-umi-refactor` | 仅 legacy-vite 模块 |
| deprecated | — | 手写 Orchestrator 直答路径 `DIRECT_WEATHER` / `DIRECT_DATETIME` | 平台 Router + Skill | 2026-06-07 | 2027-03-31 | `aether-agent-platform-foundation` | 内部路由非 REST；P2 移除 |

---

## 待登记（规划中的废弃，尚未 deprecated）

| 路径/能力 | 计划 | 说明 |
|-----------|------|------|
| `agents.knowledge` 向量路径 | P2 deprecated | 收敛至 knowledgehub 主路径 |
| Skill `active → deprecated` 全自动化 | P4 | 见 `aether-agent-governance` |

---

## 维护流程

1. OpenSpec proposal 声明废弃 → design 写迁移与 Sunset 日
2. 本表新增一行，`状态=deprecated`
3. 更新 `integration-contracts.md`、`api-contracts.yaml`、`api-changelog.md`
4. 后端 springdoc 标记 `deprecated: true`（**ai** 仓）
5. Sunset 到期前创建变更：410 或 removed，并改本表状态

---

## 自检（本地）

```powershell
# 检查 Sunset 已过期但仍为 deprecated 的条目（需人工处理）
Select-String -Path openspec/references/api-deprecations.md -Pattern 'deprecated' 
# 结合当前日期核对 Sunset 目标列
```

自动化脚本 `check-api-deprecations.ps1` 待后续补充。
