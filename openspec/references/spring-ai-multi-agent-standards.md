# Spring AI 多 Agent / 多 Skill / 多 Tool 规范（AetherStack）

> **适用范围**：关联仓库 **ai** 中 Agent Hub、Spring AI `@Tool`、ReactAgent、Router 调度相关设计与实现。  
> **配套**：`engineering-standards.md` §4.3、`.aetherstack/rules/spring-ai-multi-agent.md`、`.aetherstack/rules/backend-ai.md`、`spring-ai-core-standards.md`、`integration-contracts.md`

---

## 1. 架构原则

| 原则 | 要求 |
|------|------|
| 垂直拆分 | 按业务领域独立 Agent，单 Agent 不跨域处理事务 |
| RouterAgent | 统一调度；唯一路由工具 `transferToAgent`；description 列出全部子 Agent 及边界 |
| Skill 封装 | 复杂流程对外一个 `@Tool`，内部编排多底层工具 |
| 接口契约 | **REST 路径与响应 schema 不变**；OpenSpec / `integration-contracts.yaml` 的 `paths` 不因内部 Agent 重构而变更 |

与 `backend-ai.md` 的关系：编排实现优先 CompiledGraph / ReactAgent；本规范约束 **多 Agent 拓扑、Tool 元数据、注入规模与可观测性**。

---

## 2. `@Tool` 描述规范（强制）

每个 `@Tool` 方法 `description` **必须**包含四段（可用中文多行文本块）：

| 段落 | 内容 |
|------|------|
| 功能说明 | 一句话核心能力 |
| 典型问法 | ≥2 个用户说法或关键词 |
| 反例 | 明确**不得**调用本工具的场景 |
| 前提条件 | 可选；参数/状态前置要求 |

**示例**（与 Cursor 规则一致）：

```java
@Tool(description = """
查询用户订单状态。
适用场景：“我的订单到哪了”、“查一下物流”。
不适用：创建新订单、修改订单。
需要提供订单号或用户ID。
""")
public String inquireOrder(String orderId, String userId) { ... }
```

### 2.1 OpenSpec design 必填项

涉及新增或修改 `@Tool` / 子 Agent 时，design.md 须包含：

- 工具清单表（名称、所属 Agent、四段描述摘要）
- 是否超过 5 个候选工具；若超过，动态注入方案（向量库、TopK、刷新策略）
- RouterAgent 子 Agent 列表与 `transferToAgent` 描述草案

### 2.2 tasks 建议

- `AUTO-UT`：Tool 选择/路由逻辑的 Mock 单测（与 `ai-tdd-standards.md` L1 对齐时标 `AUTO-AI-UT`）
- `MANUAL`：真实 LLM 下工具选择与路由联调

---

## 3. 工具候选数量约束

| 约束 | 说明 |
|------|------|
| 上限 | 单次 LLM Function Calling 上下文 ≤ **5** 个工具定义 |
| 超限 | 必须向量检索动态注入：描述向量化 → 按用户 prompt Top **3~5** → 仅注入命中工具 |

design 须说明：向量存储选型、索引更新时机、与 `ToolRegistry` / ReactAgent 的集成点。

---

## 4. 日志与可观测性

| 事件 | 要求 |
|------|------|
| Router 决策 | 记录选中的子 Agent 名称（结构化日志，含 traceId/sessionId） |
| Tool 执行 | 记录 Tool 名与参数（密钥、token、PII **脱敏**） |

与 Harness 验证：`.aetherstack/scripts/check-spring-ai-tools.ps1` 不替代运行时日志，仅静态检查描述格式。

---

## 5. 代码风格与分层

- Spring AI 1.0.0+：`ChatClient`、`ToolCallback` 等；禁止回退到已废弃 API。
- 中文业务：工具描述、系统 prompt 使用简体中文。
- 新增类：类级注释标明职责与领域（与 `engineering-standards.md` 分层一致）。
- **禁止**：Controller 直接拼装 tool call；**禁止** 事务内调 LLM（见 `engineering-standards.md` §4.6）。

---

## 6. Harness 与本地验证

治理仓执行（扫描 **ai** 仓库 Java 源码）：

```powershell
.aetherstack/scripts/check-spring-ai-tools.ps1
```

`make verify` 在 backend 测试通过后可选执行上述检查（见 `verify-all.ps1`）。

检查项（静态）：

- 存在 `@Tool` 时，`description` 非空
- 描述含「不适用」或「反例」类表述
- 描述含「适用」或「场景」类表述

未通过时以 **警告** 列出文件与方法名；CI 可逐步升级为失败门闩。

---

## 7. 与 OpenSpec 契约的关系

| 变更类型 | OpenSpec 处理 |
|----------|----------------|
| 仅重构 Agent/Service 实现 | **不**改 delta spec 的 HTTP paths；tasks 注明「契约不变」 |
| 新增/修改 REST | 必须更新 `integration-contracts.md` 与 delta spec，**不受**本规范「契约不变」豁免 |

---

## 8. 与 React/Graph、RAG 铁三角

| 规范 | 衔接 |
|------|------|
| `spring-ai-react-graph-standards.md` | Router 可作单步 ReactAgent/Graph；Tool 注入与迭代上限 |
| `spring-ai-rag-standards.md` | RAG `@Tool` 须同时满足本规范四段式 |

---

## 9. 参考索引

| 文档 | 用途 |
|------|------|
| `.aetherstack/rules/spring-ai-multi-agent.md` | Cursor / Codex 规则源 |
| `.aetherstack/rules/backend-ai.md` | CompiledGraph / ReactAgent 选型 |
| `openspec/references/backend-design-guide.md` | Agent Hub 现状与演进 |
| `openspec/references/ai-tdd-standards.md` | L1 路由/Tool 单测 |
| `harness/adapters/java-maven/verify-commands.md` | 验证步骤含 Tool 描述检查 |
