# Prompt 模板管理 - 整体方案

## 一、核心问题
**要解决什么问题**：Prompt 硬编码在代码中，无法统一管理、版本化和实验优化。

## 二、整体思路
- 新增 `aether-agent/prompt-management` 能力，后端在 agent-hub 新增 `prompt/` 子包
- 模板内容存储支持 `{{variable}}` 占位符，调用时动态替换
- A/B 实验通过加权随机算法分流
- 表设计：`ai_prompt_template` + `ai_prompt_version` + `ai_prompt_invoke_log`

## 三、技术选型
| 功能场景 | 技术组件 | 使用理由 |
|---------|---------|---------|
| 模板存储 | PostgreSQL + JSONB | 模板内容灵活，变量元数据用 JSON |
| 实验分流 | 加权随机算法 | 简单高效，无外部依赖 |

## 四、影响范围
- 后端：agent-hub 新增 `prompt/` 子包（entity/service/controller）
- 前端：ai_react 新增 Prompt 管理页面（CRUD + 实验配置 + 调用记录）
- 数据库：新增 3 张表

## 五、数据设计
```sql
-- ai_prompt_template: id, name, content, category, tags, current_version, status
-- ai_prompt_version: id, template_id, version_no, content, create_time
-- ai_prompt_invoke_log: id, template_id, version_no, input_summary, output_summary, tokens, duration_ms
```

## 六、约束与风险
- 模板内容大小限制 10KB
- 实验分流精度：百分比级别
