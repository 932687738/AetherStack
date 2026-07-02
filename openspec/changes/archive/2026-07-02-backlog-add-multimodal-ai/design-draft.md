# 多模态 AI 应用 - 整体方案

## 一、核心问题
**要解决什么问题**：AetherStack 仅有文本对话能力，缺少视频/语音/OCR/写作/绘画等多模态 AI 能力。

## 二、整体思路
- 每个模态作为独立能力（SubAgent 或 Tool），通过 Agent Hub 统一调度
- 视频/语音/绘画等耗时操作采用异步任务模式（提交 → 轮询/回调）
- OCR 和写作可同步返回结果
- 前端为每个模态提供独立页面

## 三、技术选型
| 功能场景 | 技术组件 | 使用理由 |
|---------|---------|---------|
| 视频生成 | 外部 API（如可灵/Runway） | 需专业视频生成模型 |
| 语音合成 | DashScope TTS / Edge TTS | 与现有 DashScope 集成一致 |
| OCR | DashScope OCR / Tesseract | 与现有模型提供商一致 |
| 写作 | ChatClient + 长文 Prompt | 复用现有 LLM 能力 |
| 绘画 | DashScope Wanx / DALL-E | 与现有模型提供商一致 |

## 四、影响范围
- 后端：agent-hub 新增 `multimodal/` 子包（video/voice/ocr/writer/poster）
- 前端：ai_react 新增 5 个模态页面
- 数据库：新增 `ai_task`（异步任务表）

## 五、数据设计
```sql
-- ai_task: id, type(video/voice/ocr/writer/poster), status(pending/running/success/failed), 
--          input_params(jsonb), output_url, error_msg, create_time, update_time
```

## 六、约束与风险
- 视频生成耗时长（分钟级），需异步任务 + 进度通知
- 外部 API 成本需控制（限流 + 配额管理）
