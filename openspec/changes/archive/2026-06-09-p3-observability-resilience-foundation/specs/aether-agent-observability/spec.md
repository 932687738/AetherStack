# 全链路可观测与审计（P3 验收闭环）

> 本 delta 仅强化 REQ-1、REQ-5 的可验证验收口径；其余 REQ 保持主 spec 不变。

---

## MODIFIED Requirements

<a name="req-5"></a>
### Requirement: 5. Prometheus 指标 [P3]

<a name="openspec-req-5"></a>系统 SHALL 暴露 Prometheus 指标（如请求量、延迟、Tool 调用次数、Agent 迭代次数、RAG 命中率）；本变更验收须包含 `spring_ai_platform_chat_requests_total` 与 `spring_ai_platform_chat_duration_seconds` 可通过 `/actuator/prometheus` 抓取，且具备 AUTO-UT 覆盖 MeterRegistry 注册。

#### 场景: Actuator 指标可抓取
- **前提**：应用启动且 SuperAgents 对话路径已执行至少一次。
- **操作**：`GET /actuator/prometheus` 过滤 `spring_ai_platform_chat_requests_total`。
- **结果**：指标存在且 `agent_name` 或等价标签可过滤。

---

<a name="req-1"></a>
### Requirement: 1. 全链路 Trace [P3]

<a name="openspec-req-1"></a>系统应当（SHALL）为每次用户请求生成唯一 trace_id，并记录路由、子 Agent、Skill、Tool 各层 span（含耗时、错误、token）；本变更验收须包含 `TraceSpanRecorder` 落库 parent-child 关系，且具备 AUTO-UT。

#### 场景: Span 父子关系落库
- **前提**：一次对话产生 ROUTER 与 TOOL 两层 span。
- **操作**：按 trace_id 查询 trace_spans。
- **结果**：TOOL span 的 parent 指向 ROUTER span；字段含耗时与 token 摘要。
