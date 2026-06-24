## Why
- 背景：JeecgBoot 提供了视频生成、语音合成、OCR、AI 写作、AI 绘画等多模态 AI 能力。AetherStack 当前仅有文本对话和 RAG 问答，缺少多模态 AI 应用能力。
- 目标：引入多模态 AI 应用模块，支持视频生成、语音合成（TTS）、OCR 识别、AI 写作、AI 绘画等能力。

## What Changes
- **新增**：AI 视频生成（对接视频生成 API，异步任务 + 结果回调）
- **新增**：AI 语音合成 TTS（文本转语音，支持多音色）
- **新增**：AI OCR 识别（图片/文档文字识别）
- **新增**：AI 写作助手（长文生成、大纲生成、续写）
- **新增**：AI 绘画/海报（文生图、图生图）

## Capabilities
### New Capabilities
- `aether-ai/video-generation`：AI 视频生成
- `aether-ai/voice-synthesis`：AI 语音合成
- `aether-ai/ocr-recognition`：AI OCR 识别
- `aether-ai/writing-assistant`：AI 写作助手
- `aether-ai/image-generation`：AI 绘画/海报

## Impact
- 后端：新增 `ai-multimodal` 模块或在 agent-hub 新增多模态子包
- 前端：ai_react 新增各模态应用页面
- 外部依赖：需对接视频/语音/图像生成 API
