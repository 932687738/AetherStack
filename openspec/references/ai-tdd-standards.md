# AI 应用 TDD 规范（AetherStack）

> **适用范围**：OpenSpec 变更启用 **AI-TDD 模式**（`aiTddMode: enabled` 或 `auto` 判定命中）时的后端 `ai` 仓库开发。  
> **配套**：`tech-stack.md`、`engineering-standards.md`、`harness/adapters/java-maven/ai-test-templates.md`、obra Superpowers `test-driven-development`

---

## 1. 阶段化引入策略

### 1.1 原则

**不**对全部代码立即强制 TDD。按模块风险分层：

| 层级 | 模块类型 | TDD 要求 | 示例 |
|------|----------|----------|------|
| **L1 强制** | AI 核心调用与编排 | 开启 AI-TDD 时 **必须** 先写/补单测 | `AgentChatService`、`AgentPromptService`、CompiledGraph prep 节点、意图路由、Prompt 组装 |
| **L2 推荐** | 复杂 RAG / 多步检索 | **推荐** 集成测试 | `MultiRetrievalNode`、rerank、记忆压缩 |
| **L3 放宽** | 简单 CRUD / DTO 映射 | 沿用常规 `AUTO-UT`，不强制 AI 范式 | Repository 转换、Controller 参数校验 |

### 1.2 L1 核心模块判定（命中任一则属 AI 核心）

- `ChatClient` / `ChatModel` 封装层（含 tool 注册、memory advisor）
- Prompt 模板渲染与变量注入（`AgentPromptService`、Graph `*Prompt*Node`）
- 模型/能力/SubAgent **路由决策**（`IntentRouter`、`ChatModePlanResolver`、`AgentChatDomainService`）
- CompiledGraph / ReactAgent **prep 节点**（非纯 CRUD 持久化节点）
- ApplicationService 中 **流式路径分支**（直答 / SubAgent / LLM）
- SSE 输出组装（前缀、meta 事件、生命周期 Hook）

---

## 2. OpenSpec 开关（aiTddMode）

变更目录 `.openspec.yaml` 或 `proposal.md` 中声明：

```yaml
aiTddMode: enabled   # enabled | disabled | auto
```

| 值 | 行为 |
|----|------|
| `enabled` | 强制 AI-TDD：`AUTO-AI-UT` 任务 + Superpowers TDD |
| `disabled` | 仅常规 `AUTO-UT` / `MANUAL`（默认非 AI 需求） |
| `auto` | design 完成后评估；触及 L1 模块则等同 `enabled` |

**0.1 前置检查第 4 步**由用户选择；未声明时 `auto`。

---

## 3. Automation 标记扩展

在既有 `AUTO-UT` / `MANUAL` 之外：

| 标记 | 含义 | 是否强制 |
|------|------|----------|
| `AUTO-AI-UT` | L1 AI 核心逻辑单元测试（Mock LLM，见第 4 节） | AI-TDD 开启时 **必须** |
| `AUTO-AI-IT` | L2 RAG/Graph 集成测试（Testcontainers 或 Mock Port） | **推荐** |
| `AUTO-UT` | 普通 Service 单测 | 按原规则 |
| `MANUAL` | SSE 联调、真实 DashScope、UI | 按原规则 |

---

## 4. AI 应用测试范式（/tdd 阶段强制）

实施 AI 核心模块时 **必须 invoke** obra Superpowers `test-driven-development`，并遵守：

### 4.1 Mock 外部 AI 依赖

- **禁止**单测中调用真实 DashScope / OpenAI API
- Mock `ChatClient`、`ChatModel`、`EmbeddingModel` 或封装它们的 Service
- 使用 `@ExtendWith(MockitoExtension.class)` + `@Mock` / `@InjectMocks`

```java
@Mock
private ChatClient.Builder chatClientBuilder;
@Mock
private ChatClient chatClient;
@Mock
private ChatClient.ChatClientRequestSpec requestSpec;
// stream().content() 返回 Flux.just("token")
```

### 4.2 验证 Prompt 模板（禁止整串相等）

- 断言 **关键片段存在**（角色、工具名、路由目标、禁止项）
- 断言 **变量已替换**（无残留 `{{routedAgent}}`）
- 使用 `assertThat(rendered).contains(...)` / `doesNotContain(...)`
- **禁止**对完整 system prompt 做 `isEqualTo`（模板微调会导致脆弱测试）

### 4.3 流式响应（Flux / SSE）

- 使用 Reactor `StepVerifier` 验证 `Flux<String>` 顺序与完成信号
- Controller 层可用 `WebTestClient` + `expectBody(String.class)` 分段断言
- 验证：首 chunk 为路由摘要、错误时 Hook 仍触发、空流行为

```java
StepVerifier.create(service.streamAgentChat("cid", "hello"))
    .expectNextMatches(chunk -> chunk.startsWith("【路由】"))
    .thenConsumeWhile(Objects::nonNull)
    .verifyComplete();
```

### 4.4 Graph prep 节点

- 节点单测：Given `OverAllState` inputs → When `execute` → Then state keys
- ApplicationService：Mock `CompiledGraph.invoke` 返回固定终态，断言 stream 分支

---

## 5. 分级质量控制

### 5.1 必须规则（AI-TDD enabled）

- [ ] design.md 列出触及的 L1 模块清单
- [ ] test-cases.md 中 L1 行为至少一条 `AUTO-AI-UT`
- [ ] tasks.md 含「先写单测再实现」任务项（1.x.4a）
- [ ] apply 阶段：L1 代码变更 **不得** 在无对应 `*Test.java` 时勾选完成
- [ ] 执行 `mvn -Dtest=XxxTest test` 通过

### 5.2 推荐规则

- [ ] 复杂 RAG 链路标注 `AUTO-AI-IT`
- [ ] Graph 线性链至少 1 个节点集成测试
- [ ] 覆盖率不强制数字，但 L1 public 方法需有正常 + 边界用例

---

## 6. 与 Superpowers / OpenSpec 衔接

```text
OpenSpec 0.1 → aiTddMode 选择
    → design 列出 L1 模块
    → test-cases 标注 AUTO-AI-UT
    → tasks 拆分 TDD 任务
    → apply: invoke test-driven-development（L1 任务）
    → verification-before-completion（可选）
```

**非 OpenSpec 的 AI 开发**：用户说「AI-TDD」「/tdd」「按 AI 测试规范」时，同样 invoke `test-driven-development` 并读本文件。

---

## 7. 参考路径

| 类型 | 路径 |
|------|------|
| 测试模板 | `harness/adapters/java-maven/ai-test-templates.md` |
| 普通单测模板 | `harness/adapters/java-maven/test-templates.md` |
| 插件约束 | `.aetherstack/rules/ai-tdd.md` |
