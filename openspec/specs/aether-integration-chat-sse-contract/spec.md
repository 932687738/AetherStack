# SSE AgentProgress 契约

## Integration / 聊天 SSE 扩展 需求说明（前提/操作/结果）
> 在存量 SSE 文本流基础上，增加 AgentProgress 中间状态事件（当前步骤、思考链摘要、Tool 调用结果）；与 Nebula Desk 联调。
> 交付阶段：**P2**（协议定义 P2，前端 UI-FUNC 适配 uiCraftMode: auto）。
> 与 `aether-agent/agent-chat` 契约协同：正文流保持兼容，Progress 为增量事件。

```mermaid
mindmap
  root((chat-sse-contract))
    存量
      text chunk 正文
      路由摘要前缀
    新增
      AgentProgress 事件
      步骤名
      Tool 结果摘要
    兼容
      老客户端忽略新事件
```

---

## Requirements
（SSE 协议扩展）

<a name="req-1"></a>
### Requirement: 1. AgentProgress 事件格式 [P2]

<a name="openspec-req-1"></a>系统 shall 在 Agent 执行过程中通过 SSE 推送结构化 AgentProgress 事件，至少含：eventType、stepName、status（running/completed/failed）、可选 thoughtSummary、toolResultSummary。

#### 场景: Tool 调用进度
- **前提**：子 Agent 执行 ReAct 调用查询订单 Tool。
- **操作**：监听 SSE 流。
- **结果**：先收到 Progress running「调用查询订单」；完成后 Progress completed 含结果摘要。

---

<a name="req-2"></a>
### Requirement: 2. 与正文流共存 [P2]

<a name="openspec-req-2"></a>系统 shall 使 AgentProgress 事件与存量文本 chunk 在同一条 SSE 连接上交错推送；最终答案仍以文本 chunk 形式输出。

#### 场景: 老客户端兼容
- **前提**：前端仅解析 text 事件/纯文本 chunk。
- **操作**：后端推送 Progress + 正文。
- **结果**：老客户端仍显示正文；忽略未知事件类型不崩溃。

---

<a name="req-3"></a>
### Requirement: 3. 错误态 Progress [P2]

<a name="openspec-req-3"></a>系统 shall 在步骤失败时推送 status=failed 的 Progress，含可读 errorMessage；随后正文流输出用户友好总结或降级提示。

#### 场景: Tool 超时
- **前提**：Tool 调用超时。
- **操作**：监听 SSE。
- **结果**：Progress failed 含步骤名与超时说明；正文含友好提示。

---

<a name="req-4"></a>
### Requirement: 4. chat/agent 路径保持非 BREAKING [P1]

<a name="openspec-req-4"></a>系统 shall 使未订阅 Progress 的调用方在 `POST /api/agent-hub/chat/agent` 上仍获得与重构前等价的成功路径 SSE 正文行为；Progress 为可选增强。

#### 场景: 仅要最终答案
- **前提**：客户端不解析 Progress。
- **操作**：完整一轮对话。
- **结果**：收到完整流式正文；HTTP 契约不变。

---

