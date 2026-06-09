# 子 Agent 编排（Text2SQL 路由增量）

> 本 delta 在既有 orchestrator spec 基础上新增数据分析类意图路由与 text2sql 多轮确认上下文要求；REQ-1~4 保持主 spec 不变。

---

## ADDED Requirements
（新增用户故事）

<a name="req-5"></a>
### Requirement: 5. 数据分析意图路由至 text2sql 能力 [P4]

<a name="openspec-req-5"></a>系统应当（SHALL）使总路由或数据分析子 Agent 能识别统计、报表、SQL 查询类意图，并路由至 text2sql Skill 或等价子 Agent；不得将 text2sql 所需底层 schema/执行工具直接暴露给总路由。

#### 场景: 用户询问业务统计
- **前提**：用户提问「本月各租户 API 调用次数排行」。
- **操作**：发起 SuperAgents 智能体对话。
- **结果**：路由至数据分析/text2sql 路径；总路由仅暴露子 Agent transfer，不直接调用 schema 或 execute 类底层工具。

---

<a name="req-6"></a>
### Requirement: 6. text2sql 多轮确认会话上下文 [P4]

<a name="openspec-req-6"></a>系统应当（SHALL）在 text2sql 待确认、修改或挂起阶段保持会话级编排上下文，使后续用户消息能继续同一 SQL 流程而不被误判为全新无关意图。

#### 场景: 确认阶段用户补充条件
- **前提**：当前会话处于 text2sql SQL 草案待确认状态。
- **操作**：用户发送「加上按日期分组」。
- **结果**：编排层识别为同一 text2sql 流程的修改请求；不会重新走无关子 Agent 路由。

---
