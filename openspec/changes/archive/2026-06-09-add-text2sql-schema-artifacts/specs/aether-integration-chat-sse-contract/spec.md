# SSE 契约（Artifact 事件增量）

> 本 delta 在既有 chat-sse-contract spec 基础上新增 artifact 结构化事件；REQ-1~4 保持主 spec 不变。

---

## ADDED Requirements
（SSE 协议扩展）

<a name="req-5"></a>
### Requirement: 5. Artifact 结构化 SSE 事件 [P4]

<a name="openspec-req-5"></a>系统 shall 在 SuperAgents SSE 流中推送 type=artifact 的结构化事件；payload 须符合 `aether-integration/chat-artifacts` 定义的 artifact 契约，至少含 id、kind、title、content 或 typed payload。

#### 场景: text2sql 推送 SQL 与表格 artifact
- **前提**：text2sql 完成草案生成与查询执行。
- **操作**：监听 `POST /api/super-agents/chat` SSE。
- **结果**：流中除 token/progress 外，出现 artifact 事件；客户端可据此渲染 SQL 卡片与结果表格。

---

<a name="req-6"></a>
### Requirement: 6. Artifact 与 token/progress 非 BREAKING 共存 [P4]

<a name="openspec-req-6"></a>系统 shall 使 artifact 事件与存量 token、progress 事件在同一条 SSE 连接上共存；未订阅 artifact 的调用方仍须获得等价可读 token 正文，HTTP 路径与成功语义不变。

#### 场景: 仅解析 token 的客户端
- **前提**：客户端未实现 artifact 解析。
- **操作**：完成含 artifact 的 SuperAgents 对话。
- **结果**：仍收到完整 token 正文；忽略 artifact 事件不崩溃；与 REQ-4 非 BREAKING 原则一致。

---
