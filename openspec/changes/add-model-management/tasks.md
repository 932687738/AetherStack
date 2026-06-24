# AI 模型管理 - 实施任务

## 后端任务

### REQ-1: 模型配置 CRUD

- [ ] 1.1 Flyway 迁移脚本：创建 `ai_model` 表（`platform-persistence/src/main/resources/db/migration/V_model_config.sql`）
  - 可验证输出：应用启动后 `ai_model` 表存在，字段与索引正确
- [ ] 1.2 实体类 `ModelConfig.java`（`agent-hub/.../model/entity/`）
  - 可验证输出：实体字段与 DDL 对齐，MyBatis 映射正确
- [ ] 1.3 MyBatis Mapper `ModelConfigMapper.java` + XML（`platform-persistence/.../model/`）
  - 可验证输出：CRUD 方法可执行，分页查询正确
- [ ] 1.4 `ModelConfigService.java`：CRUD 业务逻辑（创建/更新/删除/列表/详情）
  - 可验证输出：创建模型返回 ID；删除默认模型被拒绝；更新后缓存刷新
- [ ] 1.5 `ModelConfigController.java`：REST API（GET/POST/PUT/DELETE）
  - 可验证输出：`curl GET /api/agent-hub/model/list` 返回分页数据

### REQ-2: 模型测试与激活

- [ ] 2.1 `ModelProviderConnectionFactory.java` 接口 + `OpenAiModelProviderConnectionFactory.java` 实现（`deepseek/.../infrastructure/model/`）
  - 可验证输出：给定 DEEPSEEK/OPENAI 配置可构建 ChatModel（DR-04 修订）
- [ ] 2.1b `DynamicChatClientFactory.java`：通过 ConnectionFactory 接口动态构建 ChatClient
  - 可验证输出：给定配置可构建 ChatClient，调用 ping 返回响应
- [ ] 2.2 `ModelConfigService.testModel(id)`：测试连通性逻辑
  - 可验证输出：测试成功返回 latencyMs + tokens；失败返回 errorMsg
- [ ] 2.3 `ModelConfigService.activate/deactivate`：状态管理
  - 可验证输出：未通过测试的模型激活被拒绝；激活后 status=active
- [ ] 2.4 REST API：`POST /model/{id}/test`、`POST /model/{id}/activate`、`POST /model/{id}/deactivate`
  - 可验证输出：API 调用返回正确结果

### REQ-3: 默认模型与自动降级

- [ ] 3.1 `ModelConfigCache.java`：Caffeine 缓存，按任务类型索引
  - 可验证输出：缓存命中不访问 DB；刷新后数据最新
- [ ] 3.2 `DynamicModelRouter.java`（`deepseek/.../infrastructure/model/`）：实现 `ModelRouter` 接口
  - 可验证输出：`resolveModelName(AGENT_REASONING)` 返回已激活模型名；无配置时回退环境变量（DR-03 修订）
- [ ] 3.3 自动降级逻辑：调用失败时尝试同类型下一个模型 → 默认模型 → 抛异常
  - 可验证输出：Mock 模型超时后自动降级到默认模型
- [ ] 3.4 `POST /model/{id}/set-default`：设置默认模型 API
  - 可验证输出：设置后全局唯一默认，原默认自动取消

### REQ-4: 提供商适配

- [ ] 4.1 `ModelProviderAdapter.java`：提供商枚举 + 默认 Base URL 映射
  - 可验证输出：`GET /model/providers` 返回 5 种内置提供商
- [ ] 4.2 自定义 OpenAI 兼容提供商支持
  - 可验证输出：填入自定义 baseUrl + apiKey 后可正常调用

---

## 前端任务

- [ ] 5.1 模型管理页面框架（`ai_react/src/pages/settings/models/`）
  - 可验证输出：页面渲染，展示模型列表表格
- [ ] 5.2 模型创建/编辑弹窗（表单：名称、提供商、API Key、Base URL、模型名、参数）
  - 可验证输出：表单提交后列表刷新
- [ ] 5.3 模型测试按钮 + 结果展示（成功/失败 + 延迟 + Token）
  - 可验证输出：点击测试后展示结果
- [ ] 5.4 激活/禁用/设为默认操作按钮
  - 可验证输出：状态变更后列表实时更新
- [ ] 5.5 提供商图标展示（DeepSeek/OpenAI/DashScope/Ollama logo）
  - 可验证输出：列表中展示对应提供商图标

---

## 测试任务

- [ ] 6.1 后端单测：ModelConfigService CRUD 逻辑（待 test-cases 补充）
- [ ] 6.2 后端单测：DynamicModelRouter 路由 + 降级逻辑（待 test-cases 补充）
- [ ] 6.3 后端单测：DynamicChatClientFactory 构建逻辑（待 test-cases 补充）
- [ ] 6.4 前端 E2E：模型管理页面 CRUD 流程（待 test-cases 补充）

---

## 依赖关系

- 1.1 → 1.2 → 1.3 → 1.4 → 1.5（串行）
- 2.1 → 2.2 → 2.3（串行，依赖 1.x）
- 3.1 → 3.2 → 3.3（串行，依赖 2.x）
- 4.1 → 4.2（依赖 2.1）
- 5.x 前端任务依赖后端 1.5 + 2.4 API 就绪
- 6.x 测试任务依赖对应实现任务完成
