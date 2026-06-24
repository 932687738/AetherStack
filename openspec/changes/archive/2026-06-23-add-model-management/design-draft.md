# AI 模型管理 - 整体方案

## 一、核心问题
**要解决什么问题**：模型配置硬编码在代码枚举中，无法动态管理、测试和降级。

## 二、整体思路
- 新增 `ai_model` 表存储模型配置（提供商、API Key、模型名、参数）
- 前端提供模型管理 UI（CRUD + 测试按钮 + 激活开关）
- 重构 `ModelRouter`：从枚举路由改为数据库配置驱动
- 模型不可用时自动降级到默认模型

## 三、技术选型
| 功能场景 | 技术组件 | 使用理由 |
|---------|---------|---------|
| 模型配置存储 | PostgreSQL | 与现有数据库一致 |
| 模型测试 | Spring AI ChatClient | 复用现有 LLM 调用能力 |
| 动态路由 | 缓存 + 数据库 | 避免每次查询数据库 |

## 四、影响范围
- 后端：新增 model 子包；重构 ModelRouter/ModelProvider
- 前端：新增模型管理页面
- 数据库：新增 `ai_model` 表

## 五、数据设计
```sql
-- ai_model: id, name, provider, model_name, api_key, base_url, 
--           params(jsonb: temperature/max_tokens等), activate_flag, is_default, 
--           created_by, create_time, updated_by, update_time, deleted
```

## 六、约束与风险
- API Key 需加密存储（AES 加密）
- 模型配置缓存刷新需考虑并发安全
