# 设计审查（design-review）

> **Schema**：`standard-spec-driven`  
> **审查方式**：Superpowers `brainstorming`（设计审查模式）  
> **输入**：`proposal.md`、`specs/**/spec.md`、`design.md` v0.3  
> **Status**：`Reviewed`

## 审查基线

| 项 | 值 |
|---|---|
| Change | `aether-agent-platform-foundation` |
| design.md 版本 | 0.3（2026-06-02） |
| 审查执行 | AI + brainstorming 设计审查 |
| 审查人确认 | **已确认**（用户指定 superAgents 落点 + 确认 design-review） |

## 审查结论摘要

- **总体结论**：**通过**
- **阻塞项数量**：4（均已修订 design.md v0.2）
- **建议项数量**：6（DR-09/DR-16 待 tasks 落地）
- **用户追加约束（DR-20）**：本变更**全部新增 Java 类**落于 `com.yxy.deepseek.superAgents`（四层结构不变）；已写入 design v0.3 §1.3、§4.2

## 模式评估（design-review 联动）

| 开关 | 结论 |
|------|------|
| `aiTddMode: enabled` | 维持 **enabled**；L1 单测路径同步为 `src/test/java/.../superAgents/**` |
| `uiCraftMode: auto` | P1 **无 U1**，不升级为 enabled；P2 `AgentProgress` 为 **UI-FUNC** |

---

## 审查维度与发现

### 1. 需求与 spec 对齐

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-01 | 阻塞 | PrepGraph / STREAM_ROUTE 映射 | 补充映射表 + Prepare 节点 | **已修订** v0.2 |
| DR-02 | 阻塞 | SSE 缺 `PlatformAgent.stream()` | 增加流式端口 + Adapter | **已修订** v0.2 |
| DR-03 | 建议 | P2 spec 仅占位 | 分阶段 apply | 豁免 |
| DR-04 | 建议 | 粘性路由 | StickyRouteContext | **已修订** v0.2 |

### 2. 架构与分层（DDD / 四层）

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-05 | 阻塞 | domain 依赖 ChatClient | `LlmCompletionPort` | **已修订** v0.2 |
| DR-06 | 阻塞 | RAG 直连 knowledgehub | `KnowledgeRetrievalPort` | **已修订** v0.2 |
| DR-07 | 建议 | AgentRegistry 类名冲突 | 新 Registry 在 superAgents；agents 不迁移 | **已修订** v0.3 §4.2.1 |
| DR-08 | 建议 | Router 职责重叠 | 合并 PlatformRouterFacade | **已修订** v0.2 |
| **DR-20** | **用户约束** | 代码落点 | **全部新增类** → `com.yxy.deepseek.superAgents.**`；agents 仅薄委托 | **已修订** v0.3 |

### 3. 接口与契约

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-09 | 建议 | Registry API 未入 integration-contracts | tasks 同步 | 待 tasks |
| DR-10 | 建议 | health API vs Job | 即时探测 vs 周期 | **已修订** v0.2 |
| DR-11 | 建议 | DIRECT_* 兼容 | P1 保留 deprecated | **已修订** v0.2 |

### 4. 非功能与可观测性

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-12 | 建议 | trace_id P1 铺垫 | MDC traceId | **已修订** v0.2 |
| DR-13 | 建议 | Registry 写 API 鉴权 | admin-api-key | **已修订** v0.2 |

### 5. Spring AI / 铁三角

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-14 | 建议 | ModelRouter 性能 | 命名 ChatClient Bean | **已修订** v0.2 |
| DR-15 | 建议 | 工具数 >5 | 总路由仅子 Agent 工具 | 豁免 |
| DR-16 | 建议 | @Tool 四段式 | tasks + check script | 待 tasks |

### 6. 风险、假设与备选方案

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-17 | 建议 | bean_name 不一致 | StartupValidator | **已修订** v0.2 |
| DR-18 | 建议 | 跳过 design-draft | 分阶段 acceptable | 豁免 |
| DR-19 | 建议 | embedding 1024 | 与 knowledgehub 一致 | 已记录 |

---

## 阻塞项清单

- [x] DR-01 ~ DR-06：design v0.2 已修订
- [x] DR-20：superAgents 代码落点 — design v0.3 已修订

---

## design.md 修订记录

| 章节 | 修订摘要 | 对应 DR |
|------|----------|---------|
| §1.3、§4.2 | **superAgents 包**全量落点 + agents 薄委托边界 | DR-20 |
| §3.2~§8.3 | 路径、时序、改造分析、单测包名同步 | DR-01~08, DR-20 |

---

## 用户确认

- [x] 审查结论已阅读，同意进入 test-cases / tasks 阶段
- [x] 代码落点：`com.yxy.deepseek.superAgents`（2026-06-02 用户确认）
