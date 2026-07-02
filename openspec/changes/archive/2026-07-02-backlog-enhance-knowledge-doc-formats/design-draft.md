# 知识库文档格式支持 - 整体方案

## 一、核心问题
**要解决什么问题**：文档解析不支持 Markdown 图片保持和 PDF 格式保持。

## 二、整体思路
- 引入 Apache Tika 作为统一文档解析引擎
- Markdown 解析：提取图片链接，将图片 URL 嵌入 chunk 元数据（检索时可还原）
- PDF 解析：使用 Tika 提取结构化文本，保持标题/段落层级
- 新增文档类型枚举：md、pdf、docx、xlsx、pptx

## 三、技术选型
| 功能场景 | 技术组件 | 使用理由 |
|---------|---------|---------|
| 统一文档解析 | Apache Tika | JeecgBoot 验证过的方案，支持多格式 |
| Markdown 图片 | flexmark-java | 精确解析 Markdown AST |

## 四、影响范围
- 后端：knowledge-hub 文档解析模块（parse 节点增强）
- 数据库：chunk 元数据增加 image_urls 字段

## 五、数据设计
```sql
-- 修改 knowledge_chunks 表
-- 新增字段：metadata jsonb（增加 image_urls、heading_level 等）
```

## 六、约束与风险
- 图片需可访问（外部图片需下载缓存）
- PDF 扫描件需 OCR 支持（后续迭代）
