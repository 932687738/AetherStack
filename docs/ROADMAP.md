# AetherStack 能力成熟度 Roadmap

跟踪 **OpenSpec 主 spec** 从「愿望清单」到「已闭环验收」的状态。  
**闭环定义**：存在已 **archive** 的变更目录 + `verification-report.md` 含 *Ready for archive* + 对应 REQ 在 tasks 中有 `trace:` 或明确 MANUAL 验收记录。

> 主 spec 文件头 `交付阶段：P3/P4` **不等于已交付**；以本表 `闭环` 列为准。  
> API 横切约定见 [`openspec/references/api-conventions.md`](../openspec/references/api-conventions.md)。

**最后更新**：2026-06-30（+ knowledge-arch-debt 归档）

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
| RAG 主路径 | `aether-knowledge-rag` | ✅ done | 多变更累积 + `refactor-knowledge-arch-debt`（2026-06-30） | knowledgehub；Agent Hub 写入经 Port 收口 |
| 编排抽象 | `aether-agent-orchestrator` | ✅ done | `aether-agent-platform-foundation` | |

---

## P2 — 已闭环（2026-06-30）

| Capability | Spec | 闭环 | 归档变更 | 备注 |
|------------|------|------|----------|------|
| SSE AgentProgress | `aether-integration-chat-sse-contract` | ✅ done | `aether-agent-platform-foundation` + P2-SSE 闭环（2026-06-30） | structured progress + plain 回退 + Tool failed |
| Skill 引擎 | `aether-agent-skill-engine` | ✅ done | `aether-agent-platform-foundation` + P2-S 闭环（2026-06-30） | DB Skill 管理 + 代码 Skill 目录 + Prompt 菜单 |
| 多 Agent 协作 | `aether-agent-collaboration` | ✅ done | `aether-agent-platform-foundation` + P2-C 闭环（2026-06-30） | 粘性短前缀 + 串行协作 UI + prep 预览 |
| 分层记忆 | `aether-knowledge-memory` | ✅ done | `aether-agent-platform-foundation` + P2-MEM 闭环（2026-06-30） | SHORT/LONG/WORKING + SSE meta + 聊天召回提示 |
| MCP 安全 | `aether-integration-mcp-security` | ✅ done | `aether-agent-platform-foundation` + P2-MCP + P3-TLS 闭环（2026-06-30） | REQ-1/2/4 + REQ-3 传输加密 |
| 前端 Umi Desk | `aether-frontend-umi-desk` | ✅ done | `frontend-umi-refactor` | |
| SuperAgents 管理 UI | `aether-agent-superagents-*-ui` | ✅ done | `superagents-frontend-page-completion` | |
| 应用变量 | `aether-agent/app-variables` | ✅ done | `2026-06-29-add-app-variables` | 管理端配置 + 会话填写 + Prompt 注入 |
| AI 流程编排 | `aether-agent-flow-*` | ✅ done | `add-ai-flow-orchestration` ✅ archived（2026-06-30） | 流程 CRUD/发布/调试 + FLOW_ENGINE 路由 + 前端三页 + 56 AUTO-UT |

---

## P3 — 已闭环（2026-06-30）

| Capability | Spec | 闭环 | 目标变更 ID | 备注 |
|------------|------|------|-------------|------|
| **可观测性** | `aether-agent-observability` | ✅ done | `p3-observability-resilience-foundation` + P3-OBS | REQ-1~5 + 决策审计 + Skill 发布快照 + 成本聚合 AUTO-UT |
| **弹性** | `aether-agent-resilience` | ✅ done | `p3-observability-resilience-foundation` + P3-SAGA + P3-HA + P4-LR | REQ-1~5 + Saga 补偿审计 + 会话 hydrate + LastResort AUTO-UT |
| **多租户** | `aether-platform-multi-tenant` | ✅ done | `p3-multi-tenant-enforcement` + P4-MT-PLUGIN | REQ-1~4 + 全量 MyBatis 租户 SQL 插件 |
| **异步恢复** | `aether-agent-async-resume` | ✅ done | `p3-async-resume` ✅ archived | REQ-1~3；挂起/唤醒/查询 + 7 AUTO-UT |
| 协作挂起恢复 | `aether-agent-collaboration` REQ-3 | ✅ done | 合入 `p3-async-resume` | chat「继续」桥接 |
| 记忆租户隔离 | `aether-knowledge-memory` REQ-4 | ✅ done | `p3-multi-tenant-enforcement` + P3-MEM-TEN | TenantGuard + 分层记忆全路径 |
| MCP 传输加密 | `aether-integration-mcp-security` REQ-3 | ✅ done | P2-MCP + P3-TLS | 远程明文 HTTP 拒绝 + localhost 例外 |

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
| Skill 治理 | `aether-agent-governance` | ⬜ not started | 灰度、冲突、废弃、效果评估（代码已有 P4-GOV，待 OpenSpec 闭环） |
| 开发者 SDK | `aether-platform-dev-sdk` | ⬜ not started | CLI/Maven 脚手架、OpenAPI 导出 |
| Trace 本地回放 | `aether-platform-dev-sdk` REQ-3 | ⬜ not started | TraceReplayRoutingSimulatorTest 已有 fixture |

---

## 横切治理（非单一 spec）

| 项 | 闭环 | 文档/脚本 | 下一步 |
|----|------|-----------|--------|
| API 通用约定 | ✅ done | `api-conventions.md` | apply 时强制更新 changelog |
| API 废弃登记 | ✅ done | `api-deprecations.md` | springdoc deprecated 标记 |
| API Changelog | ✅ done | `api-changelog.md` | 每 API 变更追加 |
| OpenAPI 治理仓真源 | ⬜ not started | — | 导出 `openspec/contracts/openapi.yaml` + diff 脚本 |
| 关联仓 CI | ⬜ not started | — | ai / ai_react GitHub Actions |
| completion-gate + P3 | ✅ done | `completion-gate.yaml` | P3 能力面已闭环（2026-06-30） |

---

## 变更闭环检查表（归档前自检）

对每个 P3/P4 波次变更：

- [ ] `tasks.md` 全部 `[x]`
- [ ] P3 REQ 在 `test-cases.md` 有 `[C]` + `AUTO-UT`/`MANUAL`
- [ ] AUTO-UT 行含 `trace: TC-REQx-yy → XxxTest#method`
- [ ] `verification-report.md` → *Ready for archive*
- [ ] 本 ROADMAP 对应行更新为 ✅ 或 🟡 partial（注明剩余 REQ）
- [ ] 触及 API 时更新 `api-changelog.md`
