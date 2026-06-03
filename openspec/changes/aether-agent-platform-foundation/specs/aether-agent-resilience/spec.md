# 弹性与兜底

## Agent Hub / 错误回退与 HA 需求说明（前提/操作/结果）
> Tool 重试降级、Graph Saga 补偿、DB Skill 状态机回退、LastResort FAQ 兜底、限流 429、无状态实例 + 会话 DB 恢复。
> 交付阶段：**P3**（LastResort/限流部分 **P4**）。详见 proposal `aether-agent/resilience`。

---

## ADDED Requirements
（新增用户故事）

<a name="req-1"></a>
### Requirement: 1. Tool 失败重试与降级 [P3]

<a name="openspec-req-1"></a>系统 shall 对 Tool 调用失败实施指数退避重试（可配置次数）；耗尽后返回清晰 ToolResult 错误并触发子 Agent 降级逻辑（友好提示或备选 Tool）。

#### 场景: 外部 API 瞬时 503
- **前提**：Tool 依赖 HTTP 服务返回 503。
- **操作**：子 Agent 调用该 Tool。
- **结果**：重试后仍失败则 ToolResult 含 errorCode；用户看到「系统繁忙」类提示，非堆栈。

---

<a name="req-2"></a>
### Requirement: 2. CompileGraph Saga 补偿 [P3]

<a name="openspec-req-2"></a>系统 shall 使 CompileGraph 多步流程支持节点级补偿回滚；失败时自动执行已定义补偿节点。

#### 场景: 第三步失败触发补偿
- **前提**：Graph 含 step1→step2→step3 及 step2 补偿节点。
- **操作**：step3 执行失败。
- **结果**：自动执行 step2 补偿；状态一致；审计记录。

---

<a name="req-3"></a>
### Requirement: 3. 限流与 429 [P3]

<a name="openspec-req-3"></a>系统 shall 内置多维度限流（tenantId、userId、IP、API/Tool）；超阈值返回 HTTP 429 或等价错误码，Agent 生成频率友好提示。

#### 场景: 租户 QPS 超限
- **前提**：租户 A 配置 max_requests=100/window。
- **操作**：第 101 次请求同一窗口。
- **结果**：429；响应含 retry-after 或友好文案。

---

<a name="req-4"></a>
### Requirement: 4. LastResort 兜底 [P4]

<a name="openspec-req-4"></a>系统 shall 在意图识别与 Skill 全部失败时，通过 FAQ 向量检索或热门问题推荐给出保底回复，避免死循环或空白响应。

#### 场景: 完全未识别意图
- **前提**：用户输入无法路由且无 Skill 匹配。
- **操作**：LastResortHandler 介入。
- **结果**：返回 FAQ 相关推荐或引导改写；记录未覆盖意图供运营分析。

---

<a name="req-5"></a>
### Requirement: 5. 无状态实例与会话恢复 [P3]

<a name="openspec-req-5"></a>系统 shall 将会话与工作记忆持久化至 PostgreSQL；任意实例故障后，新实例可通过 sessionId 重建上下文继续服务。

#### 场景: 实例重启后会话继续
- **前提**：用户 session 有未结束对话，实例 A 宕机。
- **操作**：负载均衡将请求转至实例 B。
- **结果**：B 从 DB 加载 session 上下文；对话连贯。

---
