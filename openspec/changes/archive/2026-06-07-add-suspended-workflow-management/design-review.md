# 设计审查（design-review）

> **Schema**：`standard-spec-driven`  
> **审查方式**：Superpowers `brainstorming`（设计审查模式）  
> **输入**：`proposal.md`、`specs/**/spec.md`、`design.md` v0.2  
> **Status**: Reviewed

Status: Reviewed

## 审查基线

| 项 | 值 |
|---|---|
| Change | `add-suspended-workflow-management` |
| design.md 版本 | v0.2（2026-06-07） |
| 审查执行 | AI + brainstorming 设计审查 |
| 审查人确认 | **待用户确认** |

## 审查结论摘要

- **总体结论**：**有条件通过**（阻塞项已在 design v0.2 修订，待用户确认后 → `Reviewed`）
- **阻塞项数量**：2（均已修订）
- **建议项数量**：6

## 模式评估（design-review 联动）

| 开关 | 结论 |
|------|------|
| `aiTddMode: disabled` | 维持 **disabled**；无 L1 AI 模块 |
| `uiCraftMode: auto` → | 命中 U1 界面，已更新 `.openspec.yaml` 为 **`enabled`**；design §8.1 已列 UI-CRAFT 清单 |

---

## 审查维度与发现

### 1. 需求与 spec 对齐

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-01 | 建议 | spec REQ-6 允许 design 定稿删除策略 | design §4.4 已明确仅 RESUMED/CLOSED 可删 | 已对齐 |
| DR-02 | 建议 | spec REQ-4 恢复须 SSE | design §8.2 复用 `dispatchSuperAgentSsePayload` | 已对齐 |
| DR-03 | 建议 | async-resume spec 要求 CLOSED 状态可查询 | design 状态机 + 列表 status 筛选覆盖 | 已对齐 |
| DR-04 | 建议 | 用户明确要求接口在 WebhookController | design §5.1 / §6.1 集中实现 | 已对齐 |

**spec 覆盖核对**：

| Capability | Requirements | design 覆盖 |
|------------|--------------|-------------|
| suspended-workflow-mgmt | REQ 1–10 | §5 接口、§8 前端、§6 改造 |
| async-resume | REQ 1–2 | §2.2.1 状态机、§4.1 closed_at |

### 2. 架构与分层（DDD / 四层）

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-05 | **阻塞** | `WorkflowSuspendRecord` 仅有 `resumedAt`，无 `closedAt`，与 DDL/API 不一致 | Record + Param + toRecord 映射增补 `closedAt` | **已修订** v0.2 §6.2/§6.3 |
| DR-06 | 建议 | Query/Admin 拆分为两个 ApplicationService，符合用例边界 | design §3.2 / §4.2 已明确 | 已对齐 |
| DR-07 | 建议 | Controller 不直连 Repository | 经 Query/Admin 服务 | 已对齐 |
| DR-08 | 建议 | close 未发布 PlatformEventBus 事件 | 当前 EventBus 为占位；Graph 中断态靠会话 suspended 解除。记录为**技术债务**，后续可增 `WorkflowClosedEvent` | 豁免（tasks 备注） |

### 3. 接口与契约

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-09 | **阻塞** | design 写 Flyway `V15`，仓库已有 `V15__skill_gov_lr.sql`、`V16__platform_model_provider_state.sql`；跨模块 V17/V18 已被 agent-hub 占用 | 改为 **V19__workflow_suspend_admin.sql** | **已修订** v0.2 §4.1 |
| DR-10 | 建议 | close/delete 写操作 Admin Key 策略 | 对齐 `AgentRegistryController` | 已对齐 §7.1 |
| DR-11 | 建议 | resume 不强制 Admin Key（外部 Webhook） | 与既有行为一致 | 已对齐 |
| DR-12 | 建议 | 列表响应 `resumeTokenMasked` 脱敏 | design §5.2 已定义 | 已对齐 |
| DR-13 | 建议 | 新接口须同步 `api-contracts.yaml` | tasks P4 文档任务 | 待 tasks |

### 4. 非功能与可观测性

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-14 | 建议 | close/resume 并发竞态 | `markClosed` 返回影响行数，0 行抛 409 | **已修订** v0.2 §6.2 |
| DR-15 | 建议 | 可观测性无 Micrometer 增量 | 本期管理 CRUD 可接受；可选 log INFO（tenant/token/op） | 待 tasks 可选 |
| DR-16 | 建议 | 租户隔离 | find 后比对 + SQL tenant_id 条件 | 已对齐 |

### 5. Spring AI / 铁三角

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| — | — | 无 LLM/Agent/RAG/Graph 变更 | **不适用** | — |

### 6. 风险、假设与备选方案

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-17 | 建议 | 关闭后 Graph 仍处 Interrupt 检查点 | 假设：清除 session suspended 后用户可新开对话；存量图实例不自动终止 | 豁免，README 备注 |
| DR-18 | 建议 | graph_state 体积 | 详情仅返回摘要 | 已对齐 §5.2 |
| DR-19 | 建议 | e2e smoke | tasks 增加 `/agent-hub/suspended-workflows` 可达 | 待 tasks |

---

## 阻塞项清单（须清零后方可 Status → Reviewed）

- [x] **DR-05**：`WorkflowSuspendRecord.closedAt` — design v0.2 §6.2/§6.3 已增补
- [x] **DR-09**：Flyway V19（跨模块全局唯一）— design v0.2 §4.1 已修正

---

## design.md 修订记录

| 章节 | 修订摘要 | 对应 DR |
|------|----------|---------|
| §4.1 | Flyway V15 → V19 | DR-09 |
| §3.2 / §6.2 / §6.3 | Record/Param `closedAt`；`markClosed` 返回 int | DR-05、DR-14 |
| 文首 | v0.2 修订记录 | — |
| `.openspec.yaml` | `uiCraftMode: enabled` | 模式评估 |

---

## 用户确认

- [ ] 审查结论已阅读，同意进入 test-cases / tasks 阶段
- [ ] 关闭不发布 EventBus、Graph 中断态技术债务 — 可接受
- [ ] 删除策略（仅 RESUMED/CLOSED）— 可接受
