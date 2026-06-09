# 异步挂起与唤醒

## Agent Hub / EventBus 与 Webhook 需求说明（前提/操作/结果）
> 长时间 Skill 挂起写库；外部 Webhook/消息到达后通过 sessionId 唤醒 Agent 继续执行。
> 交付阶段：**P3**。详见 proposal `aether-agent/async-resume`。

---

## Requirements

<a name="req-1"></a>
### Requirement: 1. 长时间 Skill 挂起 [P3]

<a name="openspec-req-1"></a>系统 SHALL 支持长时间运行 Skill 在安全点挂起，将执行状态写入 PostgreSQL，释放计算资源；本变更验收须包含 `WorkflowSuspendService` / `HumanApprovalSkillGraphNode` 路径 AUTO-UT，断言 DB 写入与 session 挂起标记。

#### 场景: 等待外部审批
- **前提**：CompileGraph 到达审批节点且未批准。
- **操作**：流程挂起。
- **结果**：DB 存 checkpoint 与 `resumeToken`；会话标记 SUSPENDED；HTTP/SSE 告知用户等待审批；无 busy-wait。

---

<a name="req-2"></a>
### Requirement: 2. Webhook 唤醒 [P3]

<a name="openspec-req-2"></a>系统 SHALL 提供 Webhook 或内部 EventBus 入口，外部系统审批完成后携带 resumeToken 唤醒对应 Agent 从挂起点继续；本变更验收须包含 `POST /api/super-agents/hooks/resume` AUTO-UT，断言状态迁移与 EventBus 发布。

#### 场景: 审批通过回调
- **前提**：流程在审批节点挂起。
- **操作**：外部系统 POST 审批结果（resumeToken）。
- **结果**：记录状态 RESUMED；清除 session 挂起标记；发布恢复事件；SSE 推送恢复进度。

---

<a name="req-3"></a>
### Requirement: 3. 挂起状态可查询 [P3]

<a name="openspec-req-3"></a>系统 SHALL 允许授权用户按 sessionId / resumeToken 查询当前挂起状态与等待原因；本变更验收须包含 `GET /hooks/suspended` 列表与详情 AUTO-UT。

#### 场景: 用户查询进度
- **前提**：用户流程挂起在「人工审核」。
- **操作**：查询挂起列表或详情 API。
- **结果**：返回 pending、当前步骤名（skillName）、等待说明（pendingMessage 摘要）。

---

