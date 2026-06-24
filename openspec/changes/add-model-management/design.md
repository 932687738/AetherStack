# AI 模型管理 - 技术方案

## 一. 概述

### 1.1 术语

| 术语 | 英文 | 说明 |
|------|------|------|
| 模型配置 | Model Config | 存储在数据库中的 LLM 模型参数配置（API Key、Base URL、模型名等） |
| 提供商 | Provider | 模型厂商（DeepSeek、OpenAI、通义千问、Ollama 等） |
| 任务类型 | TaskType | 模型用途分类（INTENT_ROUTING / AGENT_REASONING / EMBEDDING） |
| 激活 | Activate | 模型通过连通性测试后标记为可用状态 |

### 1.2 需求背景

**需求描述**：将模型配置从硬编码/环境变量改为数据库驱动，提供可视化管理界面。
**产品PRD**：`openspec/changes/add-model-management/proposal.md`

### 1.3 本期目标

| 序号 | 内容 | 任务点 |
|------|------|--------|
| 1 | 模型配置 CRUD | 后端 API + 前端管理页面 |
| 2 | 模型测试与激活 | 连通性测试 + 状态管理 |
| 3 | ModelRouter 动态化 | 重构 resolveModelName/completionPort 为数据库驱动 |
| 4 | 自动降级 | 模型不可用时降级到默认模型 |

### 1.4 影响分析

**受影响的系统：**
- [x] 后端 `ai-core` 模块：`ModelRouter` 接口不变，实现类重构
- [x] 后端 `ai-spring` 模块：ChatClient 动态构建
- [x] 后端 `agent-hub` 模块：`PrepareAgentChatNode` 间接依赖
- [x] 后端 `platform-persistence`：新增 Flyway 迁移
- [x] 前端 `ai_react`：新增模型管理页面

---

## 二. 业务分析

### 2.1 核心场景

| 场景 | 类型 | 说明 |
|------|------|------|
| 管理员添加模型 | 正常 | 填写配置 → 保存 → 测试 → 激活 |
| 模型 API Key 过期 | 边界 | 调用失败 → 自动降级 → 通知管理员 |
| 首次部署无配置 | 边界 | 回退到环境变量默认模型 |
| 并发修改模型配置 | 异常 | 乐观锁 + 缓存刷新 |
| 全部模型禁用 | 异常 | 返回明确错误，不静默失败 |

---

## 三. 系统设计

### 3.1 架构概览

```text
前端(ai_react) → REST API → ModelConfigController → ModelConfigService
                                                          ↓
                                              ai_model 表(PostgreSQL)
                                                          ↓
                                              ModelConfigCache(Caffeine)
                                                          ↓
                                              DynamicModelRouter(实现 ModelRouter 接口)
                                                          ↓
                                              DynamicChatClientFactory
                                                          ↓
                                              ChatClient(按配置动态构建)
```

### 3.2 核心组件

| 组件 | 位置 | 职责 |
|------|------|------|
| `ModelConfigController` | `agent-hub/.../model/controller/` | REST API：CRUD + 测试 + 激活 |
| `ModelConfigService` | `agent-hub/.../model/service/` | 业务逻辑：配置管理、状态校验 |
| `ModelConfigRepository` | `platform-persistence/.../model/` | 数据访问：MyBatis Mapper |
| `ModelConfigCache` | `agent-hub/.../model/service/` | Caffeine 本地缓存，配置变更时刷新 |
| `DynamicModelRouter` | `deepseek/.../infrastructure/model/` | 实现 `ModelRouter` 接口（infrastructure 层），从缓存读取配置 |
| `DynamicChatClientFactory` | `deepseek/.../infrastructure/model/` | 接口，按 provider 分派到不同工厂实现 |
| `ModelProviderConnectionFactory` | `deepseek/.../infrastructure/model/` | 适配器接口，隔离 Spring AI 内部类型；按 provider 实现（OpenAi/Custom） |
| `OpenAiModelProviderConnectionFactory` | `deepseek/.../infrastructure/model/` | OpenAI 兼容协议的 ChatModel 工厂实现 |

### 3.3 时序图：模型测试

```text
用户 → 前端 → POST /api/agent-hub/model/{id}/test
  → ModelConfigController → ModelConfigService.testModel(id)
    → 从 DB 读取配置
    → DynamicChatClientFactory.create(config) 构建临时 ChatClient
    → ChatClient.prompt().user("ping").call()
    → 记录响应时间、Token 消耗
    → 返回 TestResult(success, latency, tokens, errorMsg)
```

### 3.4 时序图：动态模型路由

```text
PrepareAgentChatNode → AgentHubRouter → AgentHubLlmRouter
  → ModelRouter.resolveModelName(AGENT_REASONING)
    → DynamicModelRouter → ModelConfigCache.get(AGENT_REASONING)
      → 命中：返回 modelName
      → 未命中：返回 defaultModel.modelName
  → ChatClient.prompt().model(modelName).call()
```

---

## 四. 详细设计

### 4.1 数据模型

```sql
CREATE TABLE ai_model (
    id              VARCHAR(64) PRIMARY KEY,
    name            VARCHAR(128) NOT NULL,           -- 显示名称
    provider        VARCHAR(32) NOT NULL,            -- DEEPSEEK/OPENAI/DASHSCOPE/OLLAMA/CUSTOM
    model_name      VARCHAR(128) NOT NULL,           -- 模型标识（如 deepseek-chat, gpt-4o）
    api_key         VARCHAR(512),                    -- AES 加密存储
    base_url        VARCHAR(256),                    -- OpenAI 兼容地址
    task_types      VARCHAR(256),                    -- 绑定的任务类型，逗号分隔（AGENT_REASONING,INTENT_ROUTING）
    params          JSONB DEFAULT '{}',              -- {temperature, max_tokens, top_p, ...}
    status          VARCHAR(16) DEFAULT 'inactive',  -- inactive/active/disabled
    is_default      BOOLEAN DEFAULT FALSE,
    activate_flag   INTEGER DEFAULT 0,               -- 0=未激活, 1=已激活
    test_passed     BOOLEAN DEFAULT FALSE,
    last_test_time  TIMESTAMP,
    created_by      VARCHAR(64),
    create_time     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by      VARCHAR(64),
    update_time     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted         INTEGER DEFAULT 0
);

CREATE INDEX idx_ai_model_status ON ai_model(status);
CREATE INDEX idx_ai_model_provider ON ai_model(provider);
CREATE UNIQUE INDEX uk_ai_model_default ON ai_model(is_default) WHERE is_default = TRUE AND deleted = 0;
```

### 4.2 API 设计

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/agent-hub/model/list` | 分页查询模型列表 |
| POST | `/api/agent-hub/model` | 创建模型配置 |
| PUT | `/api/agent-hub/model/{id}` | 更新模型配置 |
| DELETE | `/api/agent-hub/model/{id}` | 删除模型配置 |
| POST | `/api/agent-hub/model/{id}/test` | 测试模型连通性 |
| POST | `/api/agent-hub/model/{id}/activate` | 激活模型 |
| POST | `/api/agent-hub/model/{id}/deactivate` | 禁用模型 |
| POST | `/api/agent-hub/model/{id}/set-default` | 设为默认模型 |
| GET | `/api/agent-hub/model/providers` | 获取支持的提供商列表 |

### 4.3 DynamicChatClientFactory 设计

```java
/**
 * 适配器接口（DR-04 修订）：隔离 Spring AI 内部类型。
 * 按 provider 分派到不同工厂实现，上层仅依赖此接口。
 */
public interface ModelProviderConnectionFactory {
    /** 是否支持该提供商。 */
    boolean supports(String provider);
    /** 根据配置构建 ChatModel。 */
    ChatModel createChatModel(ModelConfig config);
}

/**
 * OpenAI 兼容协议实现（DeepSeek/OpenAI/自定义均走此路径）。
 */
@Component
public class OpenAiModelProviderConnectionFactory implements ModelProviderConnectionFactory {
    @Override
    public boolean supports(String provider) {
        return Set.of("DEEPSEEK", "OPENAI", "DASHSCOPE", "OLLAMA", "CUSTOM").contains(provider);
    }
    @Override
    public ChatModel createChatModel(ModelConfig config) {
        OpenAiChatOptions options = OpenAiChatOptions.builder()
                .model(config.getModelName())
                .temperature(config.getTemperature())
                .maxTokens(config.getMaxTokens())
                .build();
        return OpenAiChatModel.builder()
                .openAiApi(new OpenAiApi(config.getBaseUrl(), config.getDecryptedApiKey()))
                .defaultOptions(options)
                .build();
    }
}

/**
 * 动态 ChatClient 工厂：通过 ConnectionFactory 接口构建，不直接引用 Spring AI 内部类型。
 */
@Component
public class DynamicChatClientFactory {
    @Autowired
    private List<ModelProviderConnectionFactory> connectionFactories;
    
    public ChatClient create(ModelConfig config) {
        ModelProviderConnectionFactory factory = connectionFactories.stream()
                .filter(f -> f.supports(config.getProvider()))
                .findFirst()
                .orElseThrow(() -> new IllegalStateException("Unsupported provider: " + config.getProvider()));
        ChatModel chatModel = factory.createChatModel(config);
        return ChatClient.builder(chatModel).build();
    }
}
```

### 4.4 ModelConfigCache 设计

```java
@Component
public class ModelConfigCache {
    
    private final AtomicReference<Map<ModelTaskType, List<ModelConfig>>> cache = new AtomicReference<>(Map.of());
    
    /**
     * 按任务类型获取已激活模型列表（按优先级排序）。
     * 缓存未命中时从 DB 加载并缓存。
     */
    public List<ModelConfig> getActiveModels(ModelTaskType taskType) { ... }
    
    /** 获取默认模型。 */
    public ModelConfig getDefaultModel() { ... }
    
    /** 配置变更时刷新缓存（由 ModelConfigService 在 CRUD 后调用）。 */
    public void refresh() { ... }
}
```

### 4.5 自动降级策略

```text
1. 尝试当前任务类型的已激活模型（按配置优先级）
2. 当前模型调用失败 → 尝试同任务类型的下一个模型
3. 同类型全部失败 → 降级到默认模型
4. 默认模型也失败 → 抛出 ModelUnavailableException（前端展示明确错误）
```

---

## 五. 代码改造分析

### 5.1 现有代码位置

| 文件 | 当前实现 | 改造要点 |
|------|---------|---------|
| `ai-core/.../ModelRouter.java` | 接口定义（不变） | 接口保持不变，实现类替换 |
| `ai-core/.../ModelRouteDecision.java` | 值对象（不变） | 不变 |
| `ai-core/.../ModelTaskType.java` | 枚举（不变） | 不变 |
| `deepseek/.../PlatformModelProviderRefreshService` | 启动时刷新 Provider | 增加数据库配置刷新 |
| `ai-spring/.../config/` | ChatClient Bean 配置 | 保留为默认配置，新增动态覆盖逻辑 |

### 5.2 新增文件清单

| 文件 | 模块 | 说明 |
|------|------|------|
| `ModelConfig.java` | agent-hub/entity | 模型配置实体 |
| `ModelConfigController.java` | agent-hub/controller | REST API |
| `ModelConfigService.java` | agent-hub/service | 业务逻辑 |
| `ModelConfigRepository.java` | platform-persistence | MyBatis Mapper |
| `ModelConfigCache.java` | agent-hub/service | Caffeine 缓存 |
| `DynamicModelRouter.java` | agent-hub/service | 实现 ModelRouter 接口 |
| `DynamicChatClientFactory.java` | agent-hub/service | 动态构建 ChatClient |
| `ModelProviderAdapter.java` | agent-hub/adapter | 提供商协议适配 |
| `V_model_config.sql` | platform-persistence | Flyway 迁移脚本 |

---

## 六. 接口契约

### 6.1 创建模型配置

```json
POST /api/agent-hub/model
Request:
{
  "name": "DeepSeek V3",
  "provider": "DEEPSEEK",
  "modelName": "deepseek-chat",
  "apiKey": "sk-xxx",
  "baseUrl": "https://api.deepseek.com",
  "taskTypes": ["AGENT_REASONING", "INTENT_ROUTING"],
  "params": { "temperature": 0.7, "maxTokens": 4096 }
}
Response:
{ "code": 0, "result": { "id": "model-001" } }
```

### 6.2 测试模型

```json
POST /api/agent-hub/model/{id}/test
Response:
{
  "code": 0,
  "result": {
    "success": true,
    "latencyMs": 320,
    "tokensUsed": 15,
    "errorMsg": null
  }
}
```

---

## 七. 可观测性清单

| 维度 | 口径 |
|------|------|
| 接口返回 | 模型 CRUD 返回标准 Result 包装；测试接口返回 TestResult |
| SSE 事件 | 无新增 SSE 事件 |
| 日志 | 模型路由决策：`model.route decision taskType={} model={} source={db/default}` |
| Actuator | 新增 `model.config.cache.size`、`model.route.fallback.count` 指标 |
| 数据库 | `ai_model` 表 + `ai_model_test_log`（测试记录，可选） |

---

## 八. 非功能性需求设计

### 并发与幂等
- 模型配置更新使用乐观锁（`update_time` 版本控制）
- 激活/禁用操作幂等（状态相同时直接返回成功）

### 性能与容量
- 模型配置缓存（Caffeine），读取不访问数据库
- 缓存刷新频率：配置变更时立即刷新 + 5 分钟兜底刷新
- 模型配置数量预期 < 100 条，无性能瓶颈

---

## 九. 安全风险

| 风险 | 应对措施 |
|------|---------|
| API Key 泄露 | AES 加密存储，接口返回时脱敏（仅显示后 4 位） |
| 未授权访问模型管理 | 接口加权限校验（`@RequiresPermissions("model:manage")`） |
| 恶意模型配置（注入攻击） | baseUrl 白名单校验 + SSRF 防护 |
