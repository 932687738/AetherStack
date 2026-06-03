# 开发者 SDK

## Platform / 开发者体验 需求说明（前提/操作/结果）
> CLI/Maven 插件生成 Agent、Tool、Skill 模板；OpenAPI 与工具描述摘要；本地 Trace 回放（P4 可选）。
> 交付阶段：**P4**。详见 proposal `aether-platform/dev-sdk`。

---

## ADDED Requirements
（新增用户故事）

<a name="req-1"></a>
### Requirement: 1. 脚手架生成 Agent/Tool/Skill [P4]

<a name="openspec-req-1"></a>系统 shall 提供 CLI 或 Maven 插件，一键生成符合四层规范与 DDD 分包的 Agent、Tool、CompiledGraph Skill 模板代码。

#### 场景: 新建子 Agent
- **前提**：开发者执行 generate agent 命令。
- **操作**：输入 Agent 名称与包名。
- **结果**：生成接口实现骨架、Configuration、Prompt 资源占位与 README 说明。

---

<a name="req-2"></a>
### Requirement: 2. OpenAPI 与 Tool 摘要 [P4]

<a name="openspec-req-2"></a>系统 shall 自动生成平台 REST API 的 OpenAPI 文档及已注册 Tool 的描述摘要，供集成方查阅。

#### 场景: 导出 Tool 目录
- **前提**：平台已注册多个 @Tool。
- **操作**：运行文档导出命令。
- **结果**：输出 Markdown/JSON 摘要，含 Tool 名、描述、参数说明。

---

<a name="req-3"></a>
### Requirement: 3. 本地 Trace 回放 [P4]

<a name="openspec-req-3"></a>系统 should 支持开发者用历史 trace_id 在本地重放决策链，辅助调试（不调用真实 LLM 时可 Mock）。

#### 场景: 回放路由决策
- **前提**：生产采样 trace 已导出。
- **操作**：本地 replay 命令。
- **结果**：逐步展示 span 与 Tool 选择；可选 Mock LLM。

---
