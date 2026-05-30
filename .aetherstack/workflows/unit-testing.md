# Superpower 工作流：单元测试（AetherStack）

> 真源：`.aetherstack/workflows/unit-testing.md`（由 `skills-index.yaml` 路由）

## 触发

关键词：单测、unit test、写单测、生成单测、AUTO-UT、Service 测试

## 前置

1. 确定被测模块在关联仓库 **ai**（后端）或 **ai_react**（前端）
2. 读取：
   - `openspec/references/tech-stack.md` §测试策略
   - `openspec/references/engineering-standards.md` §6 测试策略
   - `harness/adapters/java-maven/test-templates.md`（Java）
   - `harness/adapters/frontend-npm/test-templates.md`（前端，若适用）
3. 若来自 OpenSpec 变更，读取 `openspec/changes/<name>/.openspec.yaml` 的 `schema:`，再读对应 `openspec/schemas/<schema>/templates/test-cases.md`

## 后端（ai 仓库）

- 测试目录：`src/test/java/`
- 框架：JUnit 5 + Mockito
- 命名：`方法名_场景_预期结果`
- 优先 Service 层单测；Mock Repository、VectorStore、LLM 客户端
- 执行：`cd <ai路径> && mvn test -Dtest=XxxTest`
- `AUTO-UT` 用例必须映射到 `*Test.java`；SSE/LLM 联调标记 `MANUAL`

## 前端（ai_react 仓库）

- Lint：`npm run lint`
- 构建：`npm run build`
- 流式/SSE 交互标记 `MANUAL`

## 验证

- 本地：`make verify`（在关联仓库跑 test/lint/build）
- Harness 阶段 4：见 `harness/agents/hev-verifier.md`

## 追溯

回复末尾追加：`Skills: unit-testing`
