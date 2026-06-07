# SuperAgents 平台运维界面

## Nebula Desk / Agent Hub 需求说明（前提/操作/结果）
> 运维人员在 Nebula Desk 中管理 ModelProvider 开关、触发 MCP 工具缓存刷新、复盘未覆盖用户意图；与既有 MCP 只读展示页并存。
> 详见 proposal `aether-agent/superagents-platform-ops-ui`。

---

## ADDED Requirements
（新增用户故事）

### 功能组 1：ModelProvider 管理

<a name="req-1"></a>
### Requirement: 1. 查看模型厂商开关列表

<a name="openspec-req-1"></a>系统应当（SHALL）提供 ModelProvider 管理页面，展示各 LLM 厂商（如 DashScope、OpenAI、Azure 等）的启用状态及可读说明，数据来源于 SuperAgents 平台只读接口。

#### 场景: 进入 ModelProvider 页面
- **前提**：SuperAgents 后端可用。
- **操作**：从 Agent Hub 导航进入「模型厂商」或等价入口。
- **结果**：展示厂商列表及各自开关状态；加载失败时可重试。

---

<a name="req-2"></a>
### Requirement: 2. 切换单个厂商开关

<a name="openspec-req-2"></a>系统应当（SHALL）允许具备管理权限的用户切换单个 ModelProvider 的启用/禁用状态，并即时反映切换后的列表状态。

#### 场景: 启用厂商
- **前提**：某厂商当前为禁用；用户已配置有效管理密钥（若后端启用）。
- **操作**：将该厂商开关切换为启用。
- **结果**：请求成功后列表更新为启用；给出成功反馈；失败时展示错误且不改变 UI 为成功态。

#### 场景: 禁用厂商
- **前提**：某厂商当前为启用。
- **操作**：将该厂商开关切换为禁用。
- **结果**：列表更新为禁用；后续聊天路由不再使用该厂商（行为由后端保证，前端仅展示结果）。

---

<a name="req-3"></a>
### Requirement: 3. 重建 ModelProvider 绑定

<a name="openspec-req-3"></a>系统应当（SHALL）提供「全量刷新」操作，触发平台按当前配置重建 ModelProvider 端口绑定，并在界面上展示刷新结果摘要。

#### 场景: 手动全量刷新
- **前提**：用户已配置有效管理密钥（若后端启用）。
- **操作**：点击「重建绑定」或等价按钮并确认。
- **结果**：操作完成后展示 refreshed 成功态及最新厂商列表；进行中显示 loading，防止重复提交。

---

### 功能组 2：MCP 运维

<a name="req-4"></a>
### Requirement: 4. MCP 外部工具刷新

<a name="openspec-req-4"></a>系统应当（SHALL）在 MCP 相关界面提供「刷新外部工具」写操作，调用 SuperAgents MCP 刷新接口，并展示刷新前后工具数量或 callback 摘要。

#### 场景: 刷新 MCP 工具缓存
- **前提**：用户已配置有效管理密钥（若后端启用）；MCP 配置已变更或需手动同步。
- **操作**：在 MCP 运维区点击刷新并确认。
- **结果**：展示后端返回的刷新摘要（如工具数量变化）；成功后可选提示用户回到只读 MCP 页查看。

#### 场景: 保留原 MCP 只读页
- **前提**：用户仅需查看 MCP Provider 与 Callback 列表。
- **操作**：打开既有 `/agent-hub/mcp` 页面。
- **结果**：仍仅展示 agent-hub 状态只读数据；默认布局与交互不变；刷新操作为增量能力（新 Tab、抽屉或子路由，design 定稿）。

---

### 功能组 3：未覆盖意图复盘

<a name="req-5"></a>
### Requirement: 5. 未覆盖意图列表

<a name="openspec-req-5"></a>系统应当（SHALL）提供运营复盘页面，按租户展示最近未被任何子 Agent 覆盖的用户 query 记录，包含会话标识、用户原问与发生时间；支持限制条数（默认 20，上限 100）。

#### 场景: 查看最近未覆盖意图
- **前提**：平台已将无法路由的 query 异步落库。
- **操作**：打开「未覆盖意图」页面。
- **结果**：按时间倒序展示列表；支持调整展示条数；无数据时展示空状态说明。

#### 场景: 切换租户查看
- **前提**：用户配置了非默认租户标识。
- **操作**：修改租户并刷新列表。
- **结果**：列表按所选租户重新加载。

---

### 功能组 4：安全与一致性

<a name="req-6"></a>
### Requirement: 6. 写操作鉴权与错误处理

<a name="openspec-req-6"></a>系统应当（SHALL）对所有 ModelProvider 写操作与 MCP 刷新统一复用管理 API 密钥配置；未授权时给出明确提示，不暴露后端堆栈信息。

#### 场景: 密钥缺失时尝试写操作
- **前提**：后端启用了管理 API 密钥校验，用户未配置密钥。
- **操作**：尝试切换厂商开关或刷新 MCP。
- **结果**：阻止误操作或展示 401 等价友好提示；引导配置密钥。

---

<a name="req-7"></a>
### Requirement: 7. 增量挂载与 Impeccable 验收

<a name="openspec-req-7"></a>系统应当（SHALL）以新增路由/菜单项方式交付上述运维界面，不修改对话、知识库、Skill 管理台及 BasicLayout 主体结构；U1 界面须通过 Impeccable shape → craft 验收。

#### 场景: 运维页面上线后回归
- **前提**：本能力已交付。
- **操作**：访问既有 MCP 只读页、ModelProvider 新页、未覆盖意图新页。
- **结果**：既有只读页无行为回归；新页信息架构清晰、与 Agent Hub 视觉一致。

---
