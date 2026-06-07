# Agent 注册与发现

## Agent Hub / AgentRegistry 需求说明（前提/操作/结果）
> 子 Agent 元数据持久化、运行时注册/发现、健康检查；总路由通过 Registry 获取可用子 Agent 并转化为工具暴露。
> 交付阶段：**P1**。详见 proposal `aether-agent/registry`。

---

## Requirements

### 功能组 1：注册与发现

<a name="req-1"></a>
### Requirement: 1. Agent 元数据注册 [P1]

<a name="openspec-req-1"></a>系统应当（SHALL）支持将子 Agent 元数据（名称、能力描述、权限范围、版本、健康检查地址）注册到持久化注册表；同一租户下 Agent 名称唯一。

#### 场景: 新 Agent 注册
- **前提**：运维或开发者提交合法 Agent 元数据。
- **操作**：调用注册 API 或启动时自动注册。
- **结果**：注册表新增记录；总路由可在下次刷新时发现该 Agent。

#### 场景: 重复名称注册
- **前提**：同租户已存在同名 Agent。
- **操作**：再次注册同名 Agent。
- **结果**：拒绝注册并返回明确错误；不覆盖静默。

---

<a name="req-2"></a>
### Requirement: 2. 运行时发现与工具转化 [P1]

<a name="openspec-req-2"></a>系统应当（SHALL）使总路由 Agent 能从注册中心拉取**活跃且健康**的子 Agent 列表，并将其转化为符合 Spring AI 工具调用规范的子 Agent 工具描述。

#### 场景: 刷新可用 Agent 列表
- **前提**：注册表有 2 个 active、1 个 deprecated Agent。
- **操作**：总路由刷新工具列表。
- **结果**：仅 2 个 active Agent 进入工具集；deprecated 不可被路由选中。

---

<a name="req-3"></a>
### Requirement: 3. 健康检查 [P1]

<a name="openspec-req-3"></a>系统应当（SHALL）对注册了健康检查地址的子 Agent 定期或按需探测；连续失败达阈值时将 Agent 标记为不可用，总路由不再路由至该 Agent。

#### 场景: 健康检查失败
- **前提**：某子 Agent 健康端点返回 5xx。
- **操作**：执行健康检查周期任务。
- **结果**：该 Agent 状态变为 unhealthy；路由列表排除；恢复后自动重新纳入。

---

