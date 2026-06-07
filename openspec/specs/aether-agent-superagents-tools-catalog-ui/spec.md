# SuperAgents 平台 Tool 摘要界面

## Nebula Desk / Agent Hub 需求说明（前提/操作/结果）
> 开发者与运维在 Nebula Desk 中查看 SuperAgents 平台聚合的 Tool 描述摘要（Agent Hub Tool + MCP callback），便于对接与调试；与既有本地 Tool Bean 快照页并存。
> 详见 proposal `aether-agent/superagents-tools-catalog-ui`。

---

## Requirements

### 功能组 1：Tool 摘要浏览

<a name="req-1"></a>
### Requirement: 1. 查看平台 Tool 描述摘要

<a name="openspec-req-1"></a>系统应当（SHALL）提供对接 `GET /api/super-agents/tools` 的浏览界面，展示当前可用的 Agent Hub Tool 与 MCP callback 的第一行描述摘要（每条不超过约定长度），并区分来源类型。

#### 场景: 进入平台 Tool 摘要页
- **前提**：SuperAgents 后端可用。
- **操作**：从 Agent Hub 导航进入「平台 Tool 摘要」或等价入口。
- **结果**：展示 Tool 列表，每条含名称、来源类型（本地 Tool / MCP）与描述摘要；加载中显示占位；失败可重试。

#### 场景: 列表为空
- **前提**：当前无可用 Tool 或 MCP callback。
- **操作**：打开摘要页。
- **结果**：展示空状态与说明，而非错误页。

---

<a name="req-2"></a>
### Requirement: 2. 与本地 Tool 快照页并存

<a name="openspec-req-2"></a>系统应当（SHALL）保留既有 `/agent-hub/tools` 本地 Bean 快照只读页不变；平台 Tool 摘要须通过**新增路由或 Tab** 提供，避免用户混淆两种数据来源。

#### 场景: 访问原 Tool 列表页
- **前提**：用户习惯查看本地 Tool Bean 信息。
- **操作**：打开 `/agent-hub/tools`。
- **结果**：仍展示 agent-hub 状态中的 module/bean 信息；页面行为与变更前一致。

#### 场景: 对比两种 Tool 视图
- **前提**：平台摘要页与本地快照页均已上线。
- **操作**：分别在两个入口浏览 Tool 信息。
- **结果**：页面标题或副标题明确标注「平台 API 摘要」与「本地 Bean 快照」；数据互不覆盖。

---

### 功能组 2：检索与可读性

<a name="req-3"></a>
### Requirement: 3. Tool 列表检索与分组

<a name="openspec-req-3"></a>系统应当（SHALL）在 Tool 摘要页支持按名称或描述关键词过滤，并按来源类型（Agent Hub / MCP）分组或筛选，便于在条目较多时快速定位。

#### 场景: 关键词过滤
- **前提**：摘要列表包含 10 条以上 Tool。
- **操作**：在搜索框输入关键词。
- **结果**：列表实时过滤匹配项；清空搜索恢复全量。

#### 场景: 按来源筛选
- **前提**：列表同时包含 Agent Hub Tool 与 MCP callback。
- **操作**：选择仅看 MCP 或仅看 Agent Hub。
- **结果**：列表仅展示所选来源条目。

---

### 功能组 3：工程与非破坏

<a name="req-4"></a>
### Requirement: 4. API 客户端分层

<a name="openspec-req-4"></a>系统应当（SHALL）通过独立 service 层调用 SuperAgents Tool 摘要接口；页面与组件不得直连 fetch/axios；类型定义与后端响应字段对齐。

#### 场景: 页面发起加载
- **前提**：用户打开 Tool 摘要页。
- **操作**：页面挂载。
- **结果**：经 service 层请求 API；类型安全的响应映射至 UI；网络错误统一处理。

---

<a name="req-5"></a>
### Requirement: 5. 增量交付与视觉一致

<a name="openspec-req-5"></a>系统应当（SHALL）以增量菜单/路由挂载 Tool 摘要页，不改动对话、知识库、Skill 管理台及 BasicLayout；视觉与 Agent Hub 卡片列表模式一致，并通过 Impeccable shape → craft 验收。

#### 场景: 变更后回归
- **前提**：Tool 摘要页已上线。
- **操作**：访问原 tools 快照页、对话页、Skill 管理台。
- **结果**：上述页面无布局与功能回归；新页与 Agent Hub 风格统一。

---
