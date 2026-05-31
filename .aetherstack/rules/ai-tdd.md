# AI 应用 TDD 规则（阶段化 + OpenSpec 开关）

## 何时触发

| 场景 | 是否强制 AI-TDD |
|------|-----------------|
| OpenSpec 变更 `aiTddMode: enabled` | **是** |
| OpenSpec 变更 `aiTddMode: auto` 且 design 触及 L1 模块 | **是** |
| OpenSpec 变更 `aiTddMode: disabled` | 否（仅常规 AUTO-UT） |
| 非 OpenSpec，用户说 `/tdd`、`AI-TDD`、`按 AI 测试规范` | **是** |
| 非 OpenSpec，普通 AI 编码无上述关键词 | 推荐 L1 补测，不阻断 |

## L1 核心模块（强制 TDD 范围）

ChatClient 封装、Prompt 组装、模型/SubAgent 路由、CompiledGraph prep 节点、ApplicationService 流式分支、SSE 组装逻辑。

简单 CRUD / DTO 映射 **不在** L1 范围。

## /tdd 阶段（invoke Superpowers）

命中 AI-TDD 时 **必须** invoke obra `test-driven-development`，并读取：

1. `openspec/references/ai-tdd-standards.md`
2. `harness/adapters/java-maven/ai-test-templates.md`

### 测试范式（强制）

- **Mock AI 外部依赖**：DashScope/ChatClient/EmbeddingModel 用 Mockito，禁止真实 API
- **Prompt 断言**：验证关键片段与占位符替换，**禁止**整串 `assertEquals`
- **Flux 流式**：`StepVerifier` 或 WebTestClient 验证顺序、完成、前缀 chunk

### Automation 标记

- `AUTO-AI-UT`：L1 单元测试（AI-TDD 开启时 mandatory）
- `AUTO-AI-IT`：复杂 RAG 集成测试（recommended）
- `MANUAL`：真实 LLM、端到端 SSE 联调

## OpenSpec 流程衔接

0.1 前置检查 **第 4 步**（schema 之后）：询问 AI-TDD 模式 `enabled / disabled / auto`。

写入变更 `.openspec.yaml`：

```yaml
aiTddMode: enabled
```

apply 阶段：凡 `AUTO-AI-UT` 任务，先写 `*Test.java` 再改生产代码；勾选前 `mvn -Dtest=... test` 通过。

## 禁止

- L1 模块在 AI-TDD 开启时无单测即标记 tasks 完成
- 单测调用真实 DashScope
