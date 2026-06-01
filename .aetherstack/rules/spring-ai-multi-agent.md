---
description: Spring AI 多智能体开发规范 - Agent/Tool 拆分、路由、描述、动态注入约束
globs: "**/*.java"
alwaysApply: false
---

# Spring AI 多 Agent / 多 Skill / 多 Tool 开发规范

> **适用范围**：关联仓库 **ai** 中 Agent Hub、`@Tool`、ReactAgent、Router 相关 Java 代码。  
> **配套**：`openspec/references/spring-ai-multi-agent-standards.md`、`.aetherstack/rules/backend-ai.md`、`.aetherstack/rules/spring-ai-core.md`、`.aetherstack/rules/spring-ai-react-graph.md`、`.aetherstack/rules/spring-ai-rag.md`（铁三角）

## 一、架构原则

- **垂直拆分**：按业务领域拆分为独立 Agent（如 OrderAgent、ProductAgent），每个 Agent 只处理本领域内事务。
- **RouterAgent 统一调度**：必须存在 RouterAgent，其唯一工具为 `transferToAgent`，负责将用户意图分发到子 Agent；`transferToAgent` 的 description 须列出所有可用子 Agent 名称及职责边界。
- **Skill 封装**：复杂流程封装为 Skill，对外表现为一个 `@Tool` 方法，内部可编排多个底层工具。
- **接口契约不变**：对外 REST 路径与响应格式不得修改；仅允许重构内部 Service / Agent 实现（OpenSpec `paths` 不变）。

## 二、`@Tool` 描述规范（强制）

每个 `@Tool` 的 `description` 必须包含：

1. **功能说明**：一句话核心功能。
2. **典型用户问法/关键词**：至少 2 个示例。
3. **反例**：什么情况下**不能**使用此工具。
4. **前提条件**（如存在）：调用前必须满足的状态或参数。

示例：

```java
@Tool(description = """
查询用户订单状态。
适用场景：“我的订单到哪了”、“查一下物流”。
不适用：创建新订单、修改订单。
需要提供订单号或用户ID。
""")
public String inquireOrder(String orderId, String userId) { ... }
```

## 三、工具候选数量约束

- 任意一次 LLM Function Calling 上下文中，暴露的工具定义 **不得超过 5 个**。
- 某 Agent 可用工具超过 5 个时，必须 **向量检索动态注入**：
  - 工具描述文本预先向量化（Pgvector / Redis Stack 等与项目一致）。
  - 用户 prompt 到来时，相似度检索 Top 3~5 个工具。
  - 仅将检索结果注入本次 LLM 调用。

## 四、日志与可观测性

- 必须记录每次 RouterAgent 选中的子 Agent 名称。
- 必须记录最终被调用的 Tool 名称及参数（**脱敏后**）。

## 五、代码风格

- 使用 Spring AI 1.0.0+ 编程模型（`ChatClient`、`ToolCallback` 等）；编排选型仍遵循 `backend-ai.md`（CompiledGraph / ReactAgent 优先）。
- 面向中文业务的工具描述、系统 prompt 使用 **简体中文**。
- 新增类须注明职责与所属领域（类级 Javadoc 或包注释）。

## 六、验证与 OpenSpec

- 本地：`make verify` 或 `.aetherstack/scripts/check-spring-ai-tools.ps1`（扫描 `@Tool` 描述完整性）。
- OpenSpec design 涉及多 Agent/Tool 时，须引用 `spring-ai-multi-agent-standards.md` 并说明 Router、工具注入策略。
- 代码审查（`cr backend`）须核对 §二、§三、§四。
