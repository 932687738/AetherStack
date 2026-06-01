# obra Superpowers 插件（AI 工作流）

## 定位

通用 AI 开发工作流由 **[obra Superpowers](https://github.com/obra/superpowers)** Cursor 插件提供。AetherStack **不再维护**平行工作流（`workflows/`、`skills-index.yaml`、`aether-skills/` 已移除）。

AetherStack 仅通过 **rules + context** 叠加项目约束（多仓库、DDD、Harness、OpenSpec）。

## Cursor 安装

```text
/add-plugin superpowers
```

更新：`/plugin-update superpowers`。卸载：`/plugin-remove superpowers`。

## 插件 skill 映射

| 场景 | obra 插件 skill | 关键词示例 |
|------|-----------------|------------|
| 代码审查 | `requesting-code-review` | `cr`、`code review`、`代码审查` |
| 接收审查反馈 | `receiving-code-review` | 收到 CR 意见、review comment |
| 单元测试 / TDD | `test-driven-development` | 单测、unit test、AUTO-UT |
| 方案探索 | `brainstorming` | 设计新功能、方案讨论 |
| 实施计划 | `writing-plans` | 实现计划、任务拆分 |
| 执行计划 | `executing-plans` | 按计划实现 |
| 系统化调试 | `systematic-debugging` | 排查 bug、随机失败 |
| 完成前验证 | `verification-before-completion` | 声称完成前 |

非 Cursor 环境：读取 GitHub 上对应 skill（`https://github.com/obra/superpowers/tree/main/skills/<skill-name>`）。

## AetherStack 项目约束（叠加于插件流程）

### 代码审查（`cr` / `cr backend` / `cr frontend`）

1. 读取 `LOCALPATH.md` 解析目标仓库（`scripts/resolve-repos.ps1`）
2. `cr backend` → 关联仓库 **ai**；`cr frontend` → **ai_react**
3. 必读：`.aetherstack/rules/core.md`、`openspec/references/engineering-standards.md`、`openspec/references/spring-ai-core-standards.md`；涉及 API 时读 `integration-contracts.md`；触及 Agent/`@Tool` 时读 `spring-ai-multi-agent-standards.md`；触及 ReactAgent/CompiledGraph 时读 `spring-ai-react-graph-standards.md`；触及 knowledgehub/RAG 时读 `spring-ai-rag-standards.md`
4. 审查维度：

| 维度 | 检查点 |
|------|--------|
| Spring AI 核心 | ChatClient 入口、密钥非硬编码、Prompt 外部化、异常容错、traceId/指标、Prompt 注入防护 |
| 分层 | Controller 不直连 Repository；领域层不依赖 Spring Web |
| 事务 | 应用层事务内不调外部 HTTP/LLM |
| 契约 | REST/SSE 与 integration-contracts 一致 |
| 多 Agent/Tool | RouterAgent + `transferToAgent`；`@Tool` 描述含反例/适用场景；单次 LLM ≤5 工具；路由/Tool 日志脱敏 |
| React/Graph | `maxIterations` + `FINAL ANSWER`；Graph 单例 compile；节点无 `web.dto`；HIL 审计与补偿 |
| 知识库 RAG | 多库分层；元数据最小集；阈值/Top-K/rerank；增量更新；来源格式化；PII/租户隔离 |
| 测试 | AUTO-UT 有对应 `*Test.java` |
| 安全 | 无硬编码密钥；输入校验 |

### 单元测试 / TDD

1. 被测模块在 **ai**（后端）或 **ai_react**（前端）
2. 必读：`openspec/references/tech-stack.md`、`engineering-standards.md` §6、`harness/adapters/java-maven/test-templates.md`
3. OpenSpec 变更：读 `openspec/schemas/<schema>/templates/test-cases.md`
4. 后端：JUnit 5 + Mockito；`AUTO-UT` → `*Test.java`；SSE/LLM 联调标 `MANUAL`
5. 验证：`make verify`；Harness 阶段 4 见 `harness/agents/hev-verifier.md`

### AI 应用 TDD（阶段化，OpenSpec 可开关）

**触发**：OpenSpec `aiTddMode: enabled|auto(命中L1)`，或关键词 `/tdd`、`AI-TDD`、`按 AI 测试规范`。

1. **必须 invoke** `test-driven-development`
2. 必读：`openspec/references/ai-tdd-standards.md`、`harness/adapters/java-maven/ai-test-templates.md`、`.aetherstack/rules/ai-tdd.md`
3. **L1 强制**（ChatClient 封装、Prompt 组装、路由决策、Graph prep、流式 ApplicationService）：先写单测再实现
4. **L3 放宽**：简单 CRUD/DTO 映射沿用常规 `AUTO-UT`，不强制 AI 范式
5. Mock DashScope/ChatClient；Prompt 断言关键片段；Flux 用 `StepVerifier`
6. `AUTO-AI-UT` 任务勾选前必须 `mvn -Dtest=XxxTest test` 通过

## 禁止

- 禁止在仓库内复制 obra 插件 skill 正文
- 禁止重建 `workflows/`、`skills-index.yaml`、`aether-skills/` 平行路由

## 与 OpenSpec / Harness 分工

| 层 | 职责 |
|----|------|
| obra Superpowers | 通用方法论（TDD、审查、brainstorming、调试） |
| `.aetherstack/rules/` | 项目 DDD、OpenSpec、文档、Harness 约束 |
| OpenSpec | 需求追溯（spec/tasks） |
| Harness | 实现编排与 verify |
