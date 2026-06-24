## Why
- 背景：AetherStack 的模型配置通过 `ModelRouter` / `ModelProvider` 代码枚举管理，无法动态添加/切换/测试模型。JeecgBoot 提供了完整的可视化模型管理界面。
- 目标：引入可视化模型管理，支持动态配置模型参数、测试激活、自动降级。

## What Changes
- **新增**：模型配置 CRUD（名称、提供商、API Key、模型名、参数）
- **新增**：模型测试与激活（在线测试连通性，激活后才可用于对话）
- **新增**：模型自动降级（未激活/不可用时自动切换到默认模型）
- **新增**：多提供商支持（DeepSeek、OpenAI、通义千问、Ollama 等）

## Capabilities
### New Capabilities
- `aether-agent/model-management`：模型配置 CRUD、测试激活、自动降级

### Modified Capabilities
- `aether-agent/orchestrator`：模型路由从硬编码改为动态读取模型配置

## Impact
- 后端：新增模型管理模块，重构 ModelRouter 为动态配置驱动
- 前端：ai_react 新增模型管理页面
- 数据库：新增模型配置表
