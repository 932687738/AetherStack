# AetherStack 能力成熟度 Roadmap

跟踪 **OpenSpec 主 spec** 从「愿望清单」到「已闭环验收」的状态。  
**闭环定义**：存在已 **archive** 的变更目录 + `verification-report.md` 含 *Ready for archive* + 对应 REQ 在 tasks 中有 `trace:` 或明确 MANUAL 验收记录。

> 主 spec 文件头 `交付阶段：P3/P4` **不等于已交付**；以本表 `闭环` 列为准。  
> API 横切约定见 [`openspec/references/api-conventions.md`](../openspec/references/api-conventions.md)。

**最后更新**：2026-06-09

---

## 图例

| 闭环 | 含义 |
|------|------|
| ✅ done | 已归档变更验收通过 |
| 🟡 partial | 代码有部分实现，缺独立变更闭环或缺测试/trace |
| ⬜ not started | 仅主 spec，无实现变更 |
| 📋 planned | 已建 `openspec/changes/` 目录，待 continue/apply |

---

## P1 — 已交付内核

| Capability | Spec | 闭环 | 归档变更 | 备注 |
|------------|------|------|----------|------|
| 平台路由 | `aether-agent-platform-router` | ✅ done | `aether-agent-platform-foundation` | P1 内核 |
| Agent 注册表 | `aether-agent-registry` | ✅ done | `aether-agent-platform-foundation` | |
| 模型路由 | `aether-agent-model-routing` | ✅ done | `aether-agent-platform-foundation` | |
| RAG 主路径 | `aether-knowledge-rag` | ✅ done | 多变更累积 | knowledgehub |
| 编排抽象 | `aether-agent-orchestrator` | ✅ done | `aether-agent-platform-foundation` | |

---

## P2 — 进行中 / 部分闭环

| Capability | Spec | 闭环 | 归档变更 | 备注 |
|------------|------|------|----------|------|
| SSE AgentProgress | `aether-integration-chat-sse-contract` | 🟡 partial | — | 协议在 spec；前端 UI-FUNC 待对齐 |
| Skill 引擎 | `aether-agent-skill-engine` | 🟡 partial | `aether-agent-platform-foundation` | DB Skill + 代码 Skill |
| 多 Agent 协作 | `aether-agent-collaboration` | 🟡 partial | `aether-agent-platform-foundation` | REQ-3 跨会话恢复属 P3 |
| 分层记忆 | `aether-knowledge-memory` | 🟡 partial | `aether-agent-platform-foundation` | REQ-4 租户隔离 P3 |
| MCP 安全 | `aether-integration-mcp-security` | 🟡 partial | — | P2 基础认证；P3 传输加密 |
| 前端 Umi Desk | `aether-frontend-umi-desk` | ✅ done | `frontend-umi-refactor` | |
| SuperAgents 管理 UI | `aether-agent-superagents-*-ui` | ✅ done | `superagents-frontend-page-completion` | |

---

## P3 — 待闭环（优先波次）

| Capability | Spec | 闭环 | 目标变更 ID | 优先 REQ | 代码现状 |
|------------|------|------|-------------|----------|----------|
| **可观测性** | `aether-agent-observability` | 🟡 partial | `p3-observability-resilience-foundation` ✅ archived | REQ-5 指标、REQ-1 Trace 验收 | **已消化** REQ-5、REQ-1 Trace（2026-06-09 归档）；审计/成本归因仍 P4 |
| **弹性** | `aether-agent-resilience` | 🟡 partial | `p3-observability-resilience-foundation` ✅ archived | REQ-3 限流 429、REQ-1 Tool 重试 | **已消化** REQ-3、REQ-1 Tool 重试（2026-06-09 归档）；Graph Saga / LastResort 完整版仍待 P4 |
| **多租户** | `aether-platform-multi-tenant` | 🟡 partial | `p3-multi-tenant-enforcement` ✅ archived | REQ-1~4 | **已消化** REQ-1~4（2026-06-09 归档）；Filter/Guard/缓存前缀/记忆隔离；全量 MyBatis 插件仍 P4 |
| **异步恢复** | `aether-agent-async-resume` | ✅ done | `p3-async-resume` ✅ archived | REQ-1~3 | **已消化** REQ-1~3（2026-06-09 归档）；挂起/唤醒/查询 + 7 AUTO-UT |
| 协作挂起恢复 | `aether-agent-collaboration` REQ-3 | ✅ done | 合入 `p3-async-resume` ✅ archived | REQ-3 | **已消化** chat「继续」桥接（2026-06-09 归档） |
| 记忆租户隔离 | `aether-knowledge-memory` REQ-4 | 🟡 partial | 合入 `p3-multi-tenant-enforcement` ✅ archived | REQ-4 | **已消化** REQ-4（2026-06-09 归档） |
| MCP 传输加密 | `aether-integration-mcp-security` REQ-3 | ⬜ not started | TBD | REQ-3 | |

### 推荐实施顺序

```text
1. ~~p3-observability-resilience-foundation~~ ✅ 已归档（2026-06-09）
2. ~~p3-multi-tenant-enforcement~~ ✅ 已归档（2026-06-09）
3. ~~p3-async-resume~~ ✅ 已归档（2026-06-09）
```

---

## P4 — 远期

| Capability | Spec | 闭环 | 说明 |
|------------|------|------|------|
| Skill 治理 | `aether-agent-governance` | ⬜ not started | 灰度、冲突、废弃、效果评估 |
| 开发者 SDK | `aether-platform-dev-sdk` | ⬜ not started | CLI/Maven 脚手架、OpenAPI 导出 |
| LastResort 完整版 | `aether-agent-resilience` REQ-4 | 🟡 partial | `LastResortHandler` 已存在，缺 spec 级 AUTO-UT 闭环 |
| Trace 本地回放 | `aether-platform-dev-sdk` REQ-3 | ⬜ not started | |

---

## 横切治理（非单一 spec）

| 项 | 闭环 | 文档/脚本 | 下一步 |
|----|------|-----------|--------|
| API 通用约定 | ✅ done | `api-conventions.md` | apply 时强制更新 changelog |
| API 废弃登记 | ✅ done | `api-deprecations.md` | springdoc deprecated 标记 |
| API Changelog | ✅ done | `api-changelog.md` | 每 API 变更追加 |
| OpenAPI 治理仓真源 | ⬜ not started | — | 导出 `openspec/contracts/openapi.yaml` + diff 脚本 |
| 关联仓 CI | ⬜ not started | — | ai / ai_react GitHub Actions |
| completion-gate + P3 | 🟡 partial | `completion-gate.yaml` | 按变更消化 REQ，不整 spec 一次做完 |

---

## 变更闭环检查表（归档前自检）

对每个 P3/P4 波次变更：

- [ ] `tasks.md` 全部 `[x]`
- [ ] P3 REQ 在 `test-cases.md` 有 `[C]` + `AUTO-UT`/`MANUAL`
- [ ] AUTO-UT 行含 `trace: TC-REQx-yy → XxxTest#method`
- [ ] `verification-report.md` → *Ready for archive*
- [ ] 本 ROADMAP 对应行更新为 ✅ 或 🟡 partial（注明剩余 REQ）
- [ ] 触及 API 时更新 `api-changelog.md`
