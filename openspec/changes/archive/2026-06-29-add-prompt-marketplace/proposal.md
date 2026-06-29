## Why
- 背景：JeecgBoot 提供了 Prompt 市场（预置模板库）和快捷指令功能，用户可快速选用预置 Prompt。AetherStack 缺少此能力。
- 目标：提供 Prompt 预置市场和应用级快捷指令，降低 AI 应用配置门槛。

## What Changes
- **新增**：Prompt 市场（预置模板库，按场景分类：翻译、摘要、代码审查等）
- **新增**：快捷指令（应用级预置命令，用户一键触发）
- **新增**：Prompt 生成（AI 根据描述自动生成 Prompt）

## Capabilities
### New Capabilities
- `aether-agent/prompt-marketplace`：Prompt 预置市场与快捷指令

## Impact
- 后端：预置 Prompt 数据（JSON 种子数据）+ 快捷指令 API
- 前端：Prompt 市场弹窗 + 快捷指令面板
