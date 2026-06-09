# 全链路可观测与审计

## Agent Hub / Trace 审计与成本 需求说明（前提/操作/结果）
> 每次请求唯一 trace_id；路由→子Agent→Skill→Tool 全链路 span；决策日志；不可篡改审计；token 与费用归因。
> 交付阶段：**P3**。详见 proposal `aether-agent/observability`。

---

## Requirements

<a name="req-1"></a>
### Requirement: 1. 全链路 Trace [P3]

<a name="openspec-req-1"></a>系统应当（SHALL）为每次用户请求生成唯一 trace_id，并记录路由、子 Agent、Skill、Tool 各层 span（含耗时、错误、token）；验收须包含 `TraceSpanRecorder` 落库 parent-child 关系，且具备 AUTO-UT。

#### 场景: Span 父子关系落库
- **前提**：一次对话产生 ROUTER 与 SUB_AGENT 两层 span。
- **操作**：按 trace_id 查询 trace_spans（或 mock 捕获 `TraceSpanRecord`）。
- **结果**：SUB_AGENT span 的 parent 指向 ROUTER span；字段含耗时与 token 摘要。

#### 场景: 单次对话 Trace
- **前提**：用户发起一轮含 Tool 调用的对话。
- **操作**：查询 trace_spans 按 trace_id。
- **结果**：span 树完整覆盖各层；parent-child 关系正确。

---

<a name="req-2"></a>
### Requirement: 2. 决策日志 [P3]

<a name="openspec-req-2"></a>系统应当（SHALL）记录模型工具选择依据、调用参数（脱敏）与返回值摘要，供排障与合规审计。

#### 场景: 路由决策审计
- **前提**：总路由选择数据分析 Agent。
- **操作**：查看决策日志。
- **结果**：含选中 Agent 名称、置信依据；无 API Key 明文。

---

<a name="req-3"></a>
### Requirement: 3. 审计日志不可篡改 [P3]

<a name="openspec-req-3"></a>系统 shall 将关键操作写入 audit_log，含用户、时间、操作类型、请求/响应摘要及数据变更前后快照（JSONB）。

#### 场景: Skill 发布审计
- **前提**：管理员发布 Skill 新版本。
- **操作**：审计查询。
- **结果**：audit_log 含变更前后 steps 快照。

---

<a name="req-4"></a>
### Requirement: 4. 成本归因 [P3]

<a name="openspec-req-4"></a>系统 shall 在 Trace 中记录 token 消耗与估算费用，并按 tenant、agent、skill 日聚合至 cost_records；超预算可告警。

#### 场景: 租户日成本统计
- **前提**：租户 A 当日多轮对话。
- **操作**：查询 cost_records 日报。
- **结果**：按 agent/skill 维度聚合 token 与费用。

---

<a name="req-5"></a>
### Requirement: 5. Prometheus 指标 [P3]

<a name="openspec-req-5"></a>系统 SHALL 暴露 Prometheus 指标（如请求量、延迟、Tool 调用次数、Agent 迭代次数、RAG 命中率）；验收须包含 `spring_ai_platform_chat_requests_total` 与 `spring_ai_platform_chat_duration_seconds` 可通过 `/actuator/prometheus` 抓取，且具备 AUTO-UT 覆盖 MeterRegistry 注册。

#### 场景: Actuator 指标可抓取
- **前提**：应用启动且 SuperAgents 对话路径已执行至少一次。
- **操作**：`GET /actuator/prometheus` 过滤 `spring_ai_platform_chat_requests_total`。
- **结果**：指标存在且 `tenant` 或等价标签可过滤。

#### 场景: 监控大盘
- **前提**：Prometheus 抓取应用 metrics 端点。
- **操作**：查看 agent_tool_calls_total。
- **结果**：指标可按 agent_name 标签过滤。

---

