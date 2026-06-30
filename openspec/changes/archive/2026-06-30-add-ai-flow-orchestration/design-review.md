# 设计审查（design-review）

> **Schema**：`standard-spec-driven`  
> **审查方式**：brainstorming 设计审查模式（批判性审视 design.md，非重新头脑风暴）  
> **输入**：`proposal.md`、`specs/**/spec.md`、`design.md`  
> **Status**: Reviewed（2026-06-30 用户确认）  
> **Gate**: Status: Reviewed

## 审查基线

| 项 | 值 |
|---|---|
| Change | `add-ai-flow-orchestration` |
| design.md 版本 | Draft v1.1（2026-06-30） |
| 审查执行 | AI + Superpowers brainstorming（设计审查模式） |
| 审查人确认 | 待用户确认 |

## 审查结论摘要

- **总体结论**：**有条件通过**（阻塞项已在 design v1.1 修订；确认后可标 `Reviewed`）
- **阻塞项数量**：0（原 2 条已修订）
- **建议项数量**：6（已记录采纳/豁免，不阻断 tasks）

### 模式评估（`.openspec.yaml`）

| 开关 | 结论 | 当前值 |
|------|------|--------|
| `aiTddMode` | 命中 L1：Graph 编译、prep 分支、SSE 组装 | `enabled` ✅ |
| `uiCraftMode` | 命中 U1：设计器/管理页；design §3.5 含界面清单 | `enabled` ✅ |

---

## 审查维度与发现

### 1. 需求与 spec 对齐

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-01 | ~~阻塞~~ | 原 §6.2 在 `route` **之前**用 sticky 查 `flow_id`，首条消息或未粘性子 Agent 时无法触发流程 | 改为 **`PlatformRouteDecision.selectedEntry.flowId`** 判定；`message`→`question` 参数映射 | **已修订** §2.2.2、§6.2 |
| DR-02 | 建议 | designer spec REQ-4 要求 Groovy/JS 脚本；design 声明 v1 仅 Groovy | 保留 `aether-debt`；tasks 中 JS 标 deferred | **豁免**（§4.2 已标注） |
| DR-03 | 建议 | orchestrator spec 写 `AgentChatApplicationService`；现网主路径为 SuperAgents | design §6.5 明确 SuperAgents 落地 + agent-hub prep 豁免 | **已修订** §6.5 |

### 2. 架构与分层（DDD / 四层）

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-04 | ~~阻塞~~ | 原设计 AI 节点依赖 superAgents `ModelRouter`，违反 **agent-hub 不依赖 aether-platform** | AI 节点改用 agent-hub `AgentChatService`；新增 `FlowExecutionBridge` 供 platform 调用 | **已修订** §3.4、§4.3.3、§6.2、§八 |
| DR-05 | 建议 | MCP 注册需写 `PlatformToolCatalog`（platform 模块） | tasks 增加 `FlowToolRegistrationPort` 防腐层或 platform 侧 Adapter | 待 tasks 落实 |
| DR-06 | 建议 | 聚合 `FlowDefinition.publish()` 应唯一写事务入口 | tasks 明确 `@Transactional` 仅在 Repository/Application publish 方法 | 待 tasks 落实 |

### 3. 接口与契约

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-07 | 建议 | integration spec 示例路径为 `/flow/{id}`，design 用 `/flows/{id}`（复数） | 以 design 为准（REST 资源复数）；apply 时更新 `api-changelog.md` | **已修订** §5.1 |
| DR-08 | 建议 | 列表 API 缺分页字段 | 补充 `page`/`size`/`total` | **已修订** §5.2 |
| DR-09 | 建议 | engine spec REQ-4 节点重试 | 节点 `data.retry` 结构与默认策略 | **已修订** §4.2、§4.3.3 |

### 4. 非功能与可观测性

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-10 | 建议 | JVM 内 compile 缓存多实例不一致 | `aether-debt` 已标注；P4 改 Redis evict | **豁免** |
| DR-11 | 建议 | 脚本/HTTP 节点安全（SSRF、Sandbox） | design §7.4 已列；tasks 须含 AUTO-UT 非法 URL/脚本用例 | 待 test-cases |
| DR-12 | 建议 | 单流程 120s 超时与 LLM 流式 backpressure | apply 时 AI 节点用 `Flux` + 全局 timeout 熔断 | 待 tasks 落实 |

### 5. Spring AI / 铁三角

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-13 | 建议 | CompiledGraph 单例 compile ✅；HIL Interrupt 本期不含 | `aether-debt` §八 已声明 | **豁免** |
| DR-14 | 建议 | RAG 节点须阈值/Top-K/来源格式 | design §4.3.3 + §八 已对齐 `spring-ai-rag.md` | **通过** |
| DR-15 | 建议 | MCP `@Tool` 四段式 | §4.6 已要求；tasks 增加 Tool 描述审查任务 | 待 tasks |

### 6. 风险、假设与备选方案

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-16 | 建议 | MULTI_AGENT_SERIAL 与 flow 优先级 | 维持现状：混合意图优先于 flow（spec 未覆盖该交叉场景） | **豁免**；tasks MANUAL 备注 |
| DR-17 | 建议 | `@xyflow/react` 新 npm 依赖 | design §八 已论证；apply 前 `npm` 安全审计 | **通过** |
| DR-18 | 建议 | 前端画布 DAG 防环仅后端校验不够 | 连线时前端预校验 + 后端 Kahn 双保险 | 待 tasks（UI-FUNC） |

---

## 阻塞项清单（须清零后方可进入 test-cases / tasks）

（无未决阻塞项）

- [x] DR-01：flow 路由时机 → design v1.1 §6.2 已修订
- [x] DR-04：模块依赖方向 → design v1.1 §3.4 已修订

---

## design.md 修订记录

| 章节 | 修订摘要 | 对应 DR |
|------|----------|---------|
| §2.2.2 | 流程图改为 route 后检查 `selectedEntry.flow_id` | DR-01 |
| §3.4 | 模块依赖约束 + `FlowExecutionBridge` | DR-04 |
| §4.2 / §4.3.3 | 节点 retry；AI 节点改用 AgentChatService | DR-04、DR-09 |
| §5.2 | 列表分页契约 | DR-08 |
| §6.2 | prep 路由改造代码片段 | DR-01 |
| §八 | Spring AI 核心路径修正 | DR-04 |
| §九 | 版本 v1.1 | — |

---

## 用户确认

- [x] 审查结论已阅读，同意进入 test-cases / tasks 阶段（2026-06-30）

确认无误请回复 **「确认 design-review」**，将把本文件与 `design.md` 的 Status 改为 `Reviewed`，并继续生成 `test-cases.md` / `tasks.md`。
