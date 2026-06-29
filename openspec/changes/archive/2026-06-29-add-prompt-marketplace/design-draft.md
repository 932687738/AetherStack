# Prompt 市场 / 快捷指令 - 整体方案

## 一、核心问题
**要解决什么问题**：用户配置 AI 应用时缺少 Prompt 灵感，快捷操作入口。

## 二、整体思路
- Prompt 市场：预置 JSON 种子数据（分类 + 模板内容），前端弹窗展示
- 快捷指令：应用级配置，存储为 JSON 数组，前端以按钮/下拉菜单展示
- AI 生成 Prompt：调用 LLM 根据用户描述生成 Prompt 模板

## 三、技术选型
| 功能场景 | 技术组件 | 使用理由 |
|---------|---------|---------|
| 预置数据 | JSON 种子文件 | 简单，无需数据库表 |
| 快捷指令 | 应用配置 JSONB 字段 | 与应用绑定 |
| AI 生成 | ChatClient | 复用现有 LLM 能力 |

## 四、影响范围
- 后端：预置数据 + 快捷指令 API + AI 生成 API
- 前端：Prompt 市场弹窗 + 快捷指令面板

## 五、数据设计
```sql
-- 快捷指令存储在应用表的 quick_commands jsonb 字段
-- Prompt 市场使用 JSON 种子文件（resources/prompts/marketplace.json）
```

## 六、约束与风险
- 预置模板需定期更新维护
- AI 生成 Prompt 质量依赖模型能力
