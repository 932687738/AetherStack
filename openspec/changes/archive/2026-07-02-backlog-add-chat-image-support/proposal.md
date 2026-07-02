## Why
- 背景：JeecgBoot 的聊天界面支持发送图片和展示图片（含 VL 模型、ImageViewer 组件）。AetherStack 前端聊天界面以纯文本为主，缺少图片交互能力。
- 目标：支持对话中发送图片和展示 AI 回复中的图片。

## What Changes
- **新增**：聊天输入框支持上传图片（拖拽/粘贴/点击上传）
- **新增**：VL 模型对接（图片 + 文本多模态输入）
- **新增**：AI 回复中图片渲染（Markdown 图片语法解析 + ImageViewer）
- **新增**：图片消息存储（OSS/本地文件 + URL 引用）

## Capabilities
### New Capabilities
- `aether-agent/chat-image`：对话图片上传、VL 模型对接、图片渲染

## Impact
- 后端：agent-hub 扩展 ChatClient 支持多模态消息（UserMessage with Image）
- 前端：聊天组件增加图片上传和 ImageViewer
- 存储：图片文件存储（本地或 OSS）
