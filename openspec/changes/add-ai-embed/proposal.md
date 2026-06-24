## Why
- 背景：JeecgBoot 支持将 AI 聊天助手通过 iframe 一键嵌入第三方系统。AetherStack 的 AI 能力仅能通过 API 调用，无法快速集成到外部系统。
- 目标：提供 iframe 嵌入能力，让第三方系统通过嵌入脚本快速拥有 AI 对话能力。

## What Changes
- **新增**：嵌入页面（独立路由，精简 UI，仅保留聊天核心功能）
- **新增**：嵌入配置（应用选择、主题色、欢迎语、位置等）
- **新增**：嵌入脚本生成（一键复制 `<iframe>` 或 JS 嵌入代码）

## Capabilities
### New Capabilities
- `aether-agent/embed`：AI 对话嵌入能力

## Impact
- 前端：ai_react 新增 `/embed/{appId}` 路由和嵌入配置页面
- 后端：无新增 API（复用现有聊天 SSE 接口），需配置 CORS 允许跨域
