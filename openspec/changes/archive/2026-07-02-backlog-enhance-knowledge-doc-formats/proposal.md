## Why
- 背景：JeecgBoot 使用 Apache Tika 解析文档，支持 Markdown（含图片保持）、PDF（格式保持）、Word/Excel/PPT。AetherStack 的 knowledge-hub 文档解析能力有限，Markdown 图片和 PDF 格式支持不够完善。
- 目标：增强知识库文档解析能力，支持 Markdown 图片保持、PDF 格式保持。

## What Changes
- **新增**：Markdown 图片提取与保持（解析图片链接，嵌入到 chunk 元数据）
- **新增**：PDF 格式保持（使用 Tika 或 pdf.js 提取，保持标题/段落/表格结构）
- **增强**：Word/Excel/PPT 解析（Tika 统一解析）

## Capabilities
### Modified Capabilities
- `aether-knowledge/upload`：增强文档解析，支持更多格式和图片保持

## Impact
- 后端：knowledge-hub 文档解析模块增强，引入 Apache Tika
- 前端：无 UI 变更（上传流程不变）
