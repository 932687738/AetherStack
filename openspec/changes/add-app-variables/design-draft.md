# AI 应用变量系统 - 整体方案

## 一、核心问题
**要解决什么问题**：AI 应用无法动态注入用户变量，Prompt 无法个性化。

## 二、整体思路
- 应用配置增加 `variables` JSON 字段（变量名、类型、默认值、描述）
- Prompt 模板支持 `{{var_name}}` 引用应用变量
- 对话前弹出变量填写表单（若有未填变量）
- 变量值注入到 ConversationContext，传递给 ChatClient

## 三、技术选型
| 功能场景 | 技术组件 | 使用理由 |
|---------|---------|---------|
| 变量存储 | JSONB 字段 | 灵活定义，无需独立表 |
| 变量替换 | Spring Expression 或自定义模板引擎 | 简单可靠 |

## 四、影响范围
- 后端：应用实体增加 variables 字段；Prompt 渲染增加变量替换
- 前端：应用配置增加变量管理 UI

## 五、数据设计
```sql
-- 修改 ai_app 表（或等效应用表）
-- 新增字段：variables jsonb（[{name, type, defaultValue, description, required}]）
```

## 六、约束与风险
- 变量名需校验（仅允许字母数字下划线）
- 变量值大小限制 1KB
