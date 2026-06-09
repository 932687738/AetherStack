# 设计审查（design-review）

> **Schema**：`standard-spec-driven`  
> **审查方式**：Superpowers `brainstorming`（设计审查模式）  
> **输入**：`proposal.md`、`specs/**/spec.md`、`design.md` v1.0  
Status: Reviewed

## 审查基线

| 项 | 值 |
|---|---|
| Change | `p3-observability-resilience-foundation` |
| design.md 版本 | v1.0（2026-06-09，审查后修订 traceId / ToolRetry / 限流范围） |
| 审查执行 | AI + brainstorming 设计审查 |
| 审查人确认 | **已确认**（2026-06-09） |

## 审查结论摘要

- **总体结论**：**通过**（阻塞已修订，用户已确认）
- **阻塞项数量**：2（均已修订）
- **建议项数量**：5

## 模式评估（design-review 联动）

| 开关 | 结论 |
|------|------|
| `aiTddMode: disabled` | 维持 **disabled**；无新增 L1（ChatClient/Prompt/SSE 组装） |
| `uiCraftMode: disabled` | 维持 **disabled**；无 U1 界面 |

---

## 审查维度与发现

### 1. 需求与 spec 对齐

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-01 | 建议 | 主 spec REQ-5 示例指标名 `agent_tool_calls_total` 与存量 `platform_skill_executions_total` 不一致 | design §6.1 已声明映射关系，验收以存量指标名为准 | 已对齐 |
| DR-02 | 建议 | resilience delta REQ-3 写「多维度」，design 仅 tenant | 与 proposal 子集范围一致；userId/IP 留后续波次 | 豁免 |
| DR-03 | 建议 | observability REQ-1 要求 parent-child | design §6.2 增补断言口径 | 已对齐 |

**spec 覆盖核对**：

| Capability | Delta REQ | design 覆盖 |
|------------|-----------|-------------|
| observability | REQ-1、REQ-5 | §6.1、§6.2、可观测性清单 |
| resilience | REQ-1、REQ-3 | §6.3、§6.4、§5.2 |

### 2. 架构与分层（DDD / 四层）

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-04 | 建议 | Filter 放 `infrastructure.web` 合理 | 不写业务规则，仅计数短路 | 已对齐 |
| DR-05 | 建议 | Controller 不改动业务分支 | 限流在 Filter 前置 | 已对齐 |
| DR-06 | 建议 | TraceSpanRecorder 属 application 层，符合分层 | 无变更 | 已对齐 |

### 3. 接口与契约

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-07 | **阻塞** | 429 JSON 写 `traceId: uuid-or-empty` 含糊；Filter 前无 Trace 上下文 | 明确允许空 `traceId` 或仅日志 UUID | **已修订** §5.2 |
| DR-08 | 建议 | 429 行为须同步 `api-changelog.md` | tasks 治理任务 | 待 tasks |
| DR-09 | 建议 | 限流路径未说明 agent-hub | 本期仅 super-agents | **已修订** §4.3 |

### 4. 非功能与可观测性

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-10 | 建议 | 开发环境误触发 429 | `enabled=false` 或高配额 profile | 已对齐 §4.3 |
| DR-11 | 建议 | 固定窗口边界 burst | design §7 已注明 | 已对齐 |
| DR-12 | 建议 | 单 JVM 限流不跨实例 | 记录为假设；与 P3 范围一致 | 豁免 |

### 5. Spring AI / 铁三角

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| — | — | 无 LLM/Agent/RAG/Graph 变更 | **不适用**（design §八） | — |

### 6. 风险、假设与备选方案

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-13 | **阻塞** | `PlatformToolRetryExecutorTest` 断言 `TOOL_RETRY_EXHAUSTED`，实现默认返回 `DEGRADED`；且测试未 mock `PlatformDegradationService` | apply 修订单测 + mock 注入 | **已修订** §6.3 |
| DR-14 | 建议 | REQ-5 集成验证可用 MockMvc `/actuator/prometheus` | tasks 标 MANUAL 或 AUTO-UT 二选一 | 待 test-cases |
| DR-15 | 建议 | ROADMAP 闭环更新 | tasks 末项治理 | 待 tasks |

---

## 阻塞项清单（须清零后方可 Status → Reviewed）

- [x] **DR-07**：429 `traceId` 口径 — design §5.2 已修订
- [x] **DR-13**：ToolRetry 单测与 `DEGRADED` 实现对齐 — design §6.3 已修订

---

## design.md 修订记录

| 章节 | 修订摘要 | 对应 DR |
|------|----------|---------|
| §4.3 | 明确本期不纳入 `/api/agent-hub/**` | DR-09 |
| §5.2 | 429 `traceId` 允许空；Filter 无 Trace 上下文 | DR-07 |
| §6.3 | ToolRetry 单测须 mock DegradationService；断言 `DEGRADED` | DR-13 |

---

## 用户确认

- [x] 审查结论已阅读，同意进入 test-cases / tasks 阶段

---

确认无误请回复 **「确认 design-review」**，我将把 `Status` 改为 `Reviewed` 并继续生成 `test-cases.md` / `tasks.md`。
