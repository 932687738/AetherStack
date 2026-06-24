# AI 编排路由（Orchestrator）— 模型路由动态化

## 模型路由变更 需求说明（前提/操作/结果）

> 描述 ModelRouter 从硬编码改为动态配置驱动后的行为变更。

---

## MODIFIED Requirements
（变更行为）

<a name="req-1"></a>
### Requirement: 1. 模型路由从数据库配置动态解析

<a name="openspec-req-1"></a>系统应当（SHALL）将 `ModelRouter.resolveModelName()` 和 `completionPort()` 的实现从硬编码/环境变量改为读取数据库模型配置表。

#### 场景: 动态解析模型名
- **前提**：数据库中存在已激活的模型配置，且至少一个标记为默认
- **操作**：`ModelRouter.resolveModelName(ModelTaskType.AGENT_REASONING)` 被调用
- **结果**：从缓存中查找任务类型为 AGENT_REASONING 的已激活模型；命中则返回 modelName；未命中则返回默认模型的 modelName

#### 场景: 缓存刷新
- **前提**：管理员修改了模型配置（新增/激活/禁用）
- **操作**：模型配置变更事件触发
- **结果**：ModelRouter 内部缓存自动刷新，后续请求使用最新配置

#### 场景: 无已激活模型时的兜底
- **前提**：数据库中无任何已激活模型（首次部署或全部禁用）
- **操作**：`ModelRouter.resolveModelName()` 被调用
- **结果**：回退到环境变量 `DASHSCOPE_CHAT_MODEL` 配置的默认模型（兼容现有部署方式）
