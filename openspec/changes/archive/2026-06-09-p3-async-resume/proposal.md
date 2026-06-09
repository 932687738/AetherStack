## Why
（为什么要做）

### 背景与目标

- **背景**：`aether-agent-async-resume`（P3）与 `aether-agent-collaboration` REQ-3 已在主 spec 定义；**ai** 仓 `aether-platform` 已实现 `WorkflowSuspendService`、`WorkflowResumeService`、`SuperAgentWebhookController`（`/api/super-agents/hooks/**`）、`HumanApprovalSkillGraphNode` 挂起点及前端挂起工作流管理页，但 ROADMAP 仍标 🟡 partial——缺 **spec 级 AUTO-UT trace 闭环**，且协作场景「同 session 发送继续」尚未从 chat 入口自动桥接到 resume。
- **目标**：以最小波次完成异步挂起/唤醒 **验收闭环**——补强 session 级继续恢复、补齐测试与 tasks trace；不重复 Graph/HIL 基础设计。本变更消化 async-resume REQ-1~3 与 collaboration REQ-3 子集。

## Jira / 需求链接

- 无工单

## What Changes
（变更内容）

### 本变更消化的 REQ（子集）

| 主 Spec | REQ | 交付内容 |
|---------|-----|----------|
| `aether-agent-async-resume` | REQ-1 长时间 Skill 挂起 | `HumanApprovalSkillGraphNode` + `WorkflowSuspendService` 验收；挂起写库 AUTO-UT |
| `aether-agent-async-resume` | REQ-2 Webhook 唤醒 | `POST /hooks/resume` + `PlatformEventBus` 验收 AUTO-UT |
| `aether-agent-async-resume` | REQ-3 挂起状态可查询 | `GET /hooks/suspended` 列表与详情 AUTO-UT |
| `aether-agent-collaboration` | REQ-3 跨会话恢复 | 同 session「继续」意图 → 查找活跃 resumeToken → 复用 `WorkflowResumeService` |

### 明确不在本变更范围（保留 OPEN）

- MQ/Webhook 出站推送至外部系统 → P4 集成
- Graph Saga 全量补偿 → `aether-agent-resilience` P4
- 前端 UI 改版 → 存量管理页已可用；仅 UI-FUNC 对齐（无 Impeccable）
- human-loop 模块既有编译债务 → 独立修复，不阻塞本变更 scoped 测试

### API 与文档

- 无新增 REST 路径；chat 挂起会话在「继续」意图下行为增强（SSE 恢复流，非静态提示）
- 更新 [`docs/ROADMAP.md`](../../../docs/ROADMAP.md) async-resume / collaboration REQ-3 闭环状态

## Capabilities
（能力清单 — 需求层面变化）

- `aether-agent/async-resume`（delta：REQ-1~3 验收闭环）
- `aether-agent/collaboration`（delta：REQ-3 跨会话恢复验收）

## Impact
（影响范围）

| 仓库 | 模块 | 说明 |
|------|------|------|
| **ai** | `aether-platform` | Repository 查询 by session、Chat 继续桥接、单测补强 |
| **ai_react** | 挂起工作流页 | 无视觉变更；确认 API 契约不变 |
| AetherStack | `docs/ROADMAP.md` | 闭环状态更新 |

## Schema

- `standard-spec-driven`
- `aiTddMode: disabled`（挂起/恢复属常规 AUTO-UT，非 L1 LLM）
- `uiCraftMode: disabled`

## Risks / Notes

- 单 session 多条 SUSPENDED 记录时取 **最新一条**（`created_at DESC`）
- Webhook `POST /hooks/resume` 仍为外部系统主路径；chat 继续为协作 REQ-3 用户友好路径
