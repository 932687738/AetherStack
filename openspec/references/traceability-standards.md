# 需求—任务—测试追溯规范

> 配合 `check-traceability.ps1` 与 `make completion-gate` 在归档前自动检查。

## 1. 标识体系

| 层级 | 格式 | 示例 |
|------|------|------|
| Requirement | `REQ-n` / `req-n`（spec.md） | `REQ-3` |
| 测试用例 | `TC-REQn-yy`（test-cases.md `[C]`） | `TC-REQ3-01` |
| 任务 | `SPEC_ID-REQ_NO`（tasks.md 章节标题） | `aether-agent-orchestrator-3` |
| 单测 | `XxxTest.java#methodName` | `OrchestratorRoutingTest#routesToKnowledgeHub` |

## 2. tasks.md 强制标记

对含 `AUTO-UT` 或 `AUTO-AI-UT` 且已勾选 `- [x]` 的任务行，**必须**包含追溯片段之一：

```markdown
- [x] 1.5 trace: TC-REQ3-01 → OrchestratorRoutingTest#routesToKnowledgeHub
- [x] 1.4 AUTO-AI-UT trace: TC-REQ3-02 → PromptAssemblyTest
```

## 3. test-cases.md

- 每条 `[C]` 用例标题或正文含 `TC-REQn-yy`
- `Automation: AUTO-UT` / `AUTO-AI-UT` 与 spec Requirement 一一对应

## 4. Java 单测（ai 仓库）

```java
/** TC-REQ3-01 → routesToKnowledgeHub */
@DisplayName("TC-REQ3-01 intent routes to knowledge hub")
@Test
void routesToKnowledgeHub() { ... }
```

## 5. 提交信息（推荐）

```
feat(agent): orchestrator routing [REQ-3] [TC-REQ3-01]
```

## 6. 门禁

`make completion-gate CHANGE=<id>` 对未完成追溯的已勾选测试任务报 **CRITICAL**。

追溯脚本 `check-traceability.ps1` 还会校验 tasks 行中 `→ XxxTest.java` 是否在 **ai** 仓库 `src/test/java` 下存在对应文件。
