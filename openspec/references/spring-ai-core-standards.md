# Spring AI 核心开发规范（AetherStack）

> **适用范围**：关联仓库 **ai** 中所有 Spring AI / Spring AI Alibaba 框架使用、配置、ChatClient、Tool、Prompt、安全与可观测性相关设计与实现。  
> **配套**：`engineering-standards.md` §4.0、`.aetherstack/rules/spring-ai-core.md`、`.aetherstack/rules/backend-ai.md`、`tech-stack.md`  
> **专项延伸**：`spring-ai-multi-agent-standards.md`、`spring-ai-rag-standards.md`、`spring-ai-react-graph-standards.md`

---

## 1. 规范分层

| 层级 | 文档 | 职责 |
|------|------|------|
| 编排选型 | `backend-ai.md` | CompiledGraph / ReactAgent / ChatClient 选型与 DDD 分层 |
| **核心框架** | **本规范** | BOM、配置、ChatClient、Tool 基础、Prompt、异常、安全、指标、测试 |
| 多 Agent | `spring-ai-multi-agent-standards.md` | Router、Tool 描述四段式、≤5 动态注入 |
| RAG | `spring-ai-rag-standards.md` | 文档处理、向量、检索、RAG `@Tool` |
| Graph/ReactAgent | `spring-ai-react-graph-standards.md` | StateGraph、HIL、节点禁令、迭代熔断 |

所有 AI 后端变更 **默认须满足本规范**；触及上表专项时 **叠加** 对应文档。

---

## 2. 版本与依赖管理

| 要求 | 说明 |
|------|------|
| 版本 | Spring AI **1.0.0+** 正式版；本项目基线见 `tech-stack.md`（**1.1.x + Spring AI Alibaba 1.1.x**） |
| BOM | 通过 `spring-ai-bom` / Alibaba BOM 统一版本，禁止子模块各自声明冲突版本 |
| 依赖最小化 | 仅引入实际使用的 starter（如 `spring-ai-alibaba-starter-dashscope`）；禁止 unused 供应商依赖 |
| 禁止 | SNAPSHOT、已 EOL 里程碑版用于生产 |

---

## 3. 配置管理

### 3.1 模型与密钥

- API Key **必须**环境变量或配置中心注入（`DASHSCOPE_API_KEY` 等）。
- **禁止**硬编码密钥、提交 `.env` 含真实 Secret。
- 不同场景配置不同模型参数（客服较高 temperature，提取类较低 temperature）。
- 多模型：`@Qualifier`、命名 Bean 或 `ChatClient` 多实例。

### 3.2 超时与重试

| 项 | 建议 |
|----|------|
| connect-timeout | 60s |
| read-timeout | 60s |
| 重试 | `RetryTemplate`，最多 3 次，指数退避 |
| 429 / 503 | 必须退避；耗尽后降级或转人工 |

### 3.3 向量与嵌入

- 连接：`spring.ai.vectorstore.*`（细则见 `spring-ai-rag-standards.md`）。
- 启动时校验嵌入维度与表/索引维度一致，不一致 **fail-fast**。

**DashScope 配置示例**：

```yaml
spring:
  ai:
    dashscope:
      api-key: ${DASHSCOPE_API_KEY}
      base-url: ${DASHSCOPE_BASE_URL:}
      chat:
        options:
          model: ${DASHSCOPE_CHAT_MODEL:qwen-plus}
          temperature: 0.3
      embedding:
        options:
          model: text-embedding-v3
```

**OpenAI 兼容示例**（仅当 design 明确选用时）：

```yaml
spring:
  ai:
    openai:
      api-key: ${OPENAI_API_KEY}
      chat:
        options:
          model: gpt-4o
          temperature: 0.3
      embedding:
        options:
          model: text-embedding-3-small
```

### 3.4 业务扩展配置

- 框架能力：`spring.ai.*`。
- 项目分域 YAML：如 `application-knowledge.yml`。
- 自定义 `@ConfigurationProperties`：前缀在 design 中声明（如 `app.ai.*` 或模块专用 prefix），**不得**与 `spring.ai` 语义冲突。

---

## 4. ChatClient 使用规范

### 4.1 原则

- **统一入口**：业务代码通过 `ChatClient` 调用；`*ChatModel` 仅在 `@Configuration` 装配层使用。
- **禁止**：Controller / Graph 节点 / Tool 内 `new OpenAiChatModel(...)` 等直连底层实现。

### 4.2 构建与调用

```java
ChatClient chatClient = ChatClient.builder(chatModel)
    .defaultSystem("系统提示词")
    .defaultTools(toolCallbacks)
    .build();

// 同步
String answer = chatClient.prompt()
    .user(userMessage)
    .call()
    .content();

// 流式
Flux<String> stream = chatClient.prompt()
    .user(userMessage)
    .stream()
    .content();
```

### 4.3 流式

- SSE / 实时对话使用 `.stream().content()`。
- 须正确处理 backpressure；ApplicationService 负责 SSE 事件组装（见 `engineering-standards.md` §2）。
- **禁止**在 `@Transactional` 内发起 LLM 流式调用。

### 4.4 Prompt 模板

- 固定 System Prompt：`PromptTemplate` + `classpath:/prompts/{domain}/*.st` 或 Mustache。
- 动态变量经模板参数传入，**禁止** `+` 拼接用户原文。

---

## 5. Tool 开发规范

| 项 | 要求 |
|----|------|
| 注解 | `@Tool`（`org.springframework.ai.tool`） |
| Bean | 工具类注册为 Spring Bean |
| 可见性 | 方法 `public` |
| 参数 | 简单类型或 POJO；复杂参数 `@ToolParam` 描述 |
| 幂等 | 同一参数多次调用结果一致或安全无害 |
| 异常 | 捕获并转为友好业务消息；禁止未处理异常中断 Agent |
| 描述 | 四段式、日志脱敏等见 **`spring-ai-multi-agent-standards.md`** |

静态检查：`.aetherstack/scripts/check-spring-ai-tools.ps1`。

---

## 6. Prompt 管理

| 项 | 要求 |
|----|------|
| 存放 | `ai/src/main/resources/prompts/`，按领域分子目录 |
| 语法 | StringTemplate / Mustache |
| 变量 | 使用前非空校验 |
| 安全 | 模板内无密钥；日志脱敏 |
| 测试 | 渲染结果单测（关键片段断言，见 `ai-tdd-standards.md`） |

---

## 7. 异常处理与容错

| 场景 | 处理 |
|------|------|
| `AiClientException` | try-catch；用户侧友好文案 + 服务端详细日志 |
| 429 / 503 | 退避重试 → 降级回复 / 转人工 |
| Tool 失败 | 自然语言解释，不暴露堆栈 |
| Graph / Agent | 超时熔断见 `spring-ai-react-graph-standards.md` |

---

## 8. 可观测性

### 8.1 指标（Micrometer / Prometheus）

| 指标 | 说明 |
|------|------|
| `spring_ai_chat_requests_total` | tag: model, status |
| `spring_ai_chat_duration_seconds` | LLM 调用耗时 |
| `spring_ai_tool_calls_total` | Tool 调用次数 |
| `spring_ai_embedding_duration_seconds` | 向量化耗时 |

项目已有 Actuator + Prometheus（见 `tech-stack.md`）；新增 AI 能力须注册等价 meter 或沿用上表命名。

### 8.2 日志

- 每条 LLM 交互含 **traceId** / sessionId。
- 记录 prompt tokens、completion tokens（若 API 返回）。
- Tool 日志：工具名、参数（脱敏）、结果摘要。

Graph / Router 专项日志见 multi-agent、react-graph 规范。

---

## 9. 安全规范

| 风险 | 要求 |
|------|------|
| Prompt 注入 | 用户输入仅经模板参数，禁止直接拼接进 System Prompt |
| 输入长度 | 限制（如 4000 字符），超限截断 + 提示 |
| Tool 权限 | 调用前校验用户/租户有权执行 |
| 危险能力 | 禁止 LLM 直接 SQL / shell；仅预定义 Tool |
| 向量注入 | 参数化元数据过滤（`spring-ai-rag-standards.md`） |
| 密钥 | 环境变量；日志脱敏 |

---

## 10. 性能优化

| 策略 | 说明 |
|------|------|
| 模型分级 | 分类/路由用小模型 |
| 检索缓存 | 同 Session 重复检索 Caffeine ~5min（可配置） |
| 流式消费 | 及时 subscribe，防缓冲堆积 |
| 批量嵌入 | 单次 ≤20 分段 |
| Graph Bean | CompiledGraph 单例 compile（`backend-ai.md`） |

---

## 11. 代码组织

### 11.1 模块映射

| 上下文 | 包路径 | 说明 |
|--------|--------|------|
| Agent Hub | `com.yxy.deepseek.agents` | 对话、Tool、Orchestrator |
| Knowledge Hub | `com.yxy.deepseek.knowledgehub` | RAG、上传、Graph |
| Demo | `com.yxy.deepseek.springai` | `@Profile("demo")`，生产禁止依赖 |

### 11.2 层内职责

与 `engineering-standards.md` §1 一致：

- `*.config` / `*.graph` / `*.agent` — 装配
- `*.application` — 用例编排
- `*.domain` — 业务规则（不依赖 Spring Web）
- `*.infrastructure` / `*.repository` — 外部适配
- `*.web` — HTTP/SSE/DTO

### 11.3 命名

- Bean：小驼峰（`knowledgeQueryChatClient`）
- Prompt 文件：kebab-case，含领域前缀

---

## 12. 测试规范

| 类型 | 要求 |
|------|------|
| Tool 单测 | 正常 + 边界；Mock 依赖 |
| ChatClient | Mock `ChatModel` / `ChatClient`；禁止真实 DashScope |
| Prompt | 渲染关键片段断言（非整串 equals） |
| 向量 IT | Testcontainers + pgvector（recommended） |
| Agent 路由 | Mock LLM 验证 Tool 选择（`AUTO-AI-UT`） |
| 标记 | `AUTO-UT` / `AUTO-AI-UT` / `MANUAL` 见 `ai-tdd-standards.md` |

---

## 13. 版本迁移

1. 升级前阅读 Spring AI / Alibaba **Migration Guide**。
2. 弃用 API 在同一 PR 内替换，不留 `@Deprecated` 调用链。
3. 扩展仅依赖 public API，禁止 `org.springframework.ai.*.internal`。
4. 准备回滚：BOM 版本 pin、feature flag 或配置开关。

---

## 14. OpenSpec design 必填项

所有 AI 相关 design.md **至少**包含：

| 项 | 内容 |
|----|------|
| 模型 | 名称、temperature、超时、重试策略 |
| 调用方式 | ChatClient / Graph / ReactAgent 选型及理由 |
| Prompt | 模板路径、变量列表 |
| Tool 清单 | 名称、幂等性、异常处理（若有多 Agent 则交叉引用） |
| 安全 | 输入限制、权限、Prompt 注入防护 |
| 可观测 | 指标、日志字段、traceId |
| 测试 | AUTO-UT / AUTO-AI-UT / MANUAL 划分 |

---

## 15. 参考索引

| 文档 | 用途 |
|------|------|
| `.aetherstack/rules/spring-ai-core.md` | Cursor / Codex 规则源 |
| `openspec/references/tech-stack.md` | 版本号、环境变量 |
| `openspec/references/engineering-standards.md` | 分层矩阵、§4.0 |
| `openspec/references/ai-tdd-standards.md` | L1 单测范式 |
| `openspec/references/backend-design-guide.md` | 存量债务与演进 |
| `harness/adapters/java-maven/verify-commands.md` | 本地验证 |
