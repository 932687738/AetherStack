# 分层记忆

## Knowledge Hub / 分层 ChatMemory 需求说明（前提/操作/结果）
> 短期对话记忆、长期用户画像、会话级工作记忆（Skill 中间状态）分层管理；agent_memory 表 + pgvector 长效检索；收敛 agents.knowledge 存量路径。
> 交付阶段：**P2**。

---

## Requirements

<a name="req-1"></a>
### Requirement: 1. 三层记忆分类 [P2]

<a name="openspec-req-1"></a>系统应当（SHALL）区分短期对话记忆、长期用户画像与会话级工作记忆，并分别持久化；各层可独立配置保留策略与检索方式。

#### 场景: Skill 执行中间状态
- **前提**：DB Skill 执行到第 2 步中断。
- **操作**：写入工作记忆。
- **结果**：memory_type=working；恢复时可读取；不污染长期画像。

---

<a name="req-2"></a>
### Requirement: 2. 向量长效记忆检索 [P2]

<a name="openspec-req-2"></a>系统应当（SHALL）将需长效保留的记忆内容写入 agent_memory 并生成 embedding；子 Agent 可按语义检索相关历史记忆注入上下文。

#### 场景: 跨会话偏好 recall
- **前提**：用户历史偏好已写入长期记忆。
- **操作**：新 session 用户问「按我习惯推荐」。
- **结果**：检索命中相关长期记忆片段并注入 Prompt。

---

<a name="req-3"></a>
### Requirement: 3. MessageChatMemoryAdvisor 扩展 [P2]

<a name="openspec-req-3"></a>系统应当（SHALL）扩展 MessageChatMemoryAdvisor 为分层记忆管理器，协调各层读写，对 ChatClient/ReAct 透明。

#### 场景: 对话轮次写入
- **前提**：用户完成一轮问答。
- **操作**：Advisor 拦截消息流。
- **结果**：短期层追加；高价值片段异步提炼至长期层（策略可配置）。

---

<a name="req-4"></a>
### Requirement: 4. 租户隔离记忆 [P3]

<a name="openspec-req-4"></a>系统 SHALL 使长期/工作记忆读写与向量检索按 tenant_id 隔离；本变更验收须与 `aether-platform-multi-tenant` REQ-4 合并，包含 `PlatformLayeredMemoryService` 或等价路径的 AUTO-UT。

#### 场景: 工作记忆租户隔离
- **前提**：租户 A、B 同 conversationId 写入 working 记忆。
- **操作**：租户 A 读取 working 记忆。
- **结果**：仅返回 A 写入内容；不含 B 数据。

#### 场景: 跨租户检索
- **前提**：租户 A 与 B 均有记忆数据。
- **操作**：租户 A 会话触发记忆检索。
- **结果**：仅返回 tenant A 记录。

---

