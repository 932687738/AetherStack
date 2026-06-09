# 多 Agent 协作（P3 跨会话恢复验收）

> 本 delta 仅强化 REQ-3 的可验证验收口径；REQ-1/2/4 保持主 spec 不变。

---

## MODIFIED Requirements

<a name="req-3"></a>
### Requirement: 3. 跨会话恢复挂起流程 [P3]

<a name="openspec-req-3"></a>系统 SHALL 支持将未完成的多步流程（含 CompileGraph 检查点）持久化；用户稍后携带同一 sessionId 返回时可恢复执行；本变更验收须包含 chat 入口「继续」意图桥接 AUTO-UT（复用 `WorkflowResumeService`，不重复已完成步骤）。

#### 场景: 审批挂起后恢复
- **前提**：流程在人工审批节点挂起，状态已写库，session 标记 SUSPENDED。
- **操作**：用户同 session 发送「继续」或等价短句。
- **结果**：自动解析活跃 resumeToken 并恢复；SSE 与 Webhook 恢复路径一致；不重复已完成步骤。

---
