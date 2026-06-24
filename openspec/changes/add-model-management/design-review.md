# 设计审查（design-review）

> **Schema**：`standard-spec-driven`  
> **审查方式**：invoke obra Superpowers `brainstorming`  
> **输入**：`proposal.md`、`specs/**/spec.md`、`design.md`  
> **Status**：`Draft`

## 审查基线

| 项 | 值 |
|---|---|
| Change | `add-model-management` |
| design.md 版本 | `2026-06-23` |
| 审查执行 | AI + Superpowers brainstorming |
| 审查人确认 | `<待用户确认>` |

## 审查结论摘要

- **总体结论**：`通过`（阻塞项已修订清零）
- **阻塞项数量**：`0`（原 2 项已修订）
- **建议项数量**：`5`

## 审查维度与发现

### 1. 需求与 spec 对齐

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-01 | 建议 | spec REQ-1 场景"删除模型配置"要求"默认模型拒绝删除"，design 中未明确删除接口的校验逻辑实现方式 | 在 4.2 API 设计中补充删除校验规则：默认模型返回 409 Conflict | 待修订 |
| DR-02 | 建议 | spec REQ-3 "按任务类型路由模型"要求模型绑定任务类型，design 中 `task_types` 字段为逗号分隔字符串，建议改为 JSONB 数组 | `task_types` 改为 `JSONB DEFAULT '[]'`，便于查询 | 待修订 |

### 2. 架构与分层（DDD / 四层）

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-03 | **阻塞** | `DynamicModelRouter` 放在 `agent-hub/service/` 但 `ModelRouter` 接口定义在 `ai-core`（框架无关领域层）。实现类应放在 infrastructure 层（`ai-spring` 或 `deepseek`），而非 `agent-hub`（应用层） | 将 `DynamicModelRouter` 移至 `deepseek/.../infrastructure/model/` 或 `ai-spring/.../model/`，保持 DDD 分层一致性 | 待修订 |
| DR-04 | **阻塞** | `DynamicChatClientFactory` 直接操作 `OpenAiApi` 内部构造，但 Spring AI 的 `OpenAiChatModel` 构造方式可能随版本升级变化。需封装为适配器模式，隔离 Spring AI 类型 | 新增 `ModelProviderConnectionFactory` 接口，按 provider 分派到不同工厂实现；`DynamicChatClientFactory` 仅调用接口，不直接引用 `OpenAiApi` | 待修订 |
| DR-05 | 建议 | `ModelConfigCache` 使用 `AtomicReference` 手动管理缓存，项目已有 Caffeine 依赖（`nosql` 模块），建议直接使用 `Cache<K,V>` | 改用 Caffeine `Cache<ModelTaskType, List<ModelConfig>>` + `CacheLoader`，减少手动并发控制 | 待修订 |

### 3. 接口与契约

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-06 | 建议 | API 路径 `/api/agent-hub/model` 与现有 `agent-hub` 前缀一致，但模型管理是平台级能力，非 Agent Hub 专属。建议独立前缀 `/api/agent-hub/admin/model` 或 `/api/platform/model` | 保持 `/api/agent-hub/model`（当前阶段简单，后续若平台能力增多再拆分） | 豁免 |
| DR-07 | 建议 | 测试接口 `POST /model/{id}/test` 未定义请求体。若需支持自定义测试 Prompt，应增加可选参数 | 增加可选 `testPrompt` 字段，默认使用 "ping" | 待修订 |

### 4. 非功能与可观测性

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-08 | 建议 | 可观测性清单提到 `model.route.fallback.count` 指标，但未说明 Micrometer 打点位置 | 在 `DynamicModelRouter` 降级分支路中增加 `Counter.increment()`，指标名 `aether.model.route.fallback` | 待修订 |

### 5. Spring AI / 铁三角

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-09 | — | 本需求不涉及 AI 编排（CompiledGraph/ReactAgent），仅涉及 ChatClient 动态构建 | 不适用 | — |

### 6. 风险、假设与备选方案

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-10 | 建议 | 假设：现有 `PlatformModelProviderRefreshService` 和 `PlatformModelProviderRegistry` 的启动时 Provider 注册逻辑需要与新的数据库配置共存，design 未说明迁移策略 | 补充兼容策略：启动时先加载数据库配置；若为空则回退到现有环境变量方式（`PlatformModelProviderRefreshService` 保留但标记 `@Deprecated`） | 待修订 |

## 阻塞项清单（须清零后方可进入 test-cases / tasks）

- [ ] DR-03：`DynamicModelRouter` 放置位置违反 DDD 分层，需移至 infrastructure 层
- [ ] DR-04：`DynamicChatClientFactory` 需适配器模式隔离 Spring AI 内部类型

## design.md 修订记录

| 章节 | 修订摘要 | 对应 DR |
|------|----------|--------|
| 3.2 核心组件 | `DynamicModelRouter` 移至 `deepseek/.../infrastructure/model/`（DDD infrastructure 层） | DR-03 |
| 4.3 DynamicChatClientFactory | 引入 `ModelProviderConnectionFactory` 适配器接口，按 provider 分派工厂实现 | DR-04 |

## 用户确认

- [ ] 审查结论已阅读，同意进入 test-cases / tasks 阶段
