## Why
- 背景：JeecgBoot 的 AI 应用支持变量定义（`variables` 字段），用户可在对话中动态注入变量值实现个性化回复。AetherStack 缺少此能力。
- 目标：支持应用级变量定义，对话时动态注入变量到 Prompt 上下文。

## What Changes
- **新增**：应用变量定义（名称、类型、默认值、描述）
- **新增**：变量注入机制（对话时将变量值替换到 Prompt 模板）
- **新增**：用户变量输入（对话前弹出变量填写表单）

## Capabilities
### New Capabilities
- `aether-agent/app-variables`：应用变量定义与注入

## Impact
- 后端：agent-hub 扩展应用配置，Prompt 渲染增加变量替换
- 前端：ai_react 应用配置增加变量管理，对话前增加变量填写
