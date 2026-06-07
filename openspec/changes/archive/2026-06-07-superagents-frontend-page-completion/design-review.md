# 设计审查（design-review）

> **Schema**：`standard-spec-driven`  
> **审查方式**：Superpowers `brainstorming`（设计审查模式）  
> **输入**：`proposal.md`、`specs/**/spec.md`、`design.md` v0.2  
> **Status**：`Reviewed`

## 审查基线

| 项 | 值 |
|---|---|
| Change | `superagents-frontend-page-completion` |
| design.md 版本 | v0.2（2026-06-07） |
| 审查执行 | AI + brainstorming 设计审查 |
| 审查人确认 | **已确认**（2026-06-07 用户「确认 design-review」） |

## 审查结论摘要

- **总体结论**：**通过**
- **阻塞项数量**：1（已修订）
- **建议项数量**：7

## 模式评估（design-review 联动）

| 开关 | 结论 |
|------|------|
| `aiTddMode: disabled` | 维持 **disabled**；无 L1 后端模块，tasks 不强制 AUTO-AI-UT |
| `uiCraftMode: enabled` | 维持 **enabled**；design §3.4 已列 4×UI-CRAFT + 2×UI-AUDIT，tasks 须含 `1.2a` Impeccable |

---

## 审查维度与发现

### 1. 需求与 spec 对齐

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-01 | **阻塞** | platform-ops spec REQ-1 要求 ModelProvider「可读说明」，后端 DTO 仅有 `providerId`/`enabled` | 用 i18n 友好名映射表展示厂商列，未知 id 回退 raw | **已修订** v0.2 §4.8/§4.9 |
| DR-02 | 建议 | registry spec REQ-3 注册表单字段多，design 未列前端校验规则 | tasks 补充：name/beanName 必填、permissionTags  Tag 输入 | 待 tasks |
| DR-03 | 建议 | tools spec REQ-3 检索/分组 | design §4.4.1 已覆盖 `agent-hub`/`mcp` source 值 | 已对齐 |
| DR-04 | 建议 | 三份 spec 均要求 Impeccable | design §3.4 + §7.7 P4 已声明 | 已对齐 |

**spec 覆盖核对**：

| Capability | Requirements | design 覆盖 |
|------------|--------------|-------------|
| superagents-registry-ui | REQ 1–6 | §3.3 P1、§6.2 隔离、§6.4 注册/探测 |
| superagents-platform-ops-ui | REQ 1–7 | §3.3 P3、§4.9 ModelProvider、§6.3 MCP OpsBar |
| superagents-tools-catalog-ui | REQ 1–5 | §3.3 P2、§4.4.1 筛选、§6.2 tools 快照不变 |

### 2. 架构与分层（DDD / 四层）

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-05 | 建议 | 前端分层：pages 薄包装 + services | design §3.3、§6.1–§6.5 已明确 | 已对齐 |
| DR-06 | 建议 | `platformSkillService` refactor 须 re-export storage API | P0 任务：`platformSkillService` 从 common re-export，避免破坏现有 import | 待 tasks |
| DR-07 | 建议 | 快照页与平台页并存 | §6.2 明确 agents/tools 不改 | 已对齐 |

### 3. 接口与契约

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-08 | 建议 | SuperAgents 管理 API 未入 `integration-contracts.md` | apply P4 同步 `api-contracts.yaml` + ARCHITECTURE | 待 tasks（§7.6 已列） |
| DR-09 | 建议 | Tool summary `source` 值为 `agent-hub`/`mcp`（非 camelCase） | §4.4.1 与后端 `PlatformToolCatalogApplicationService` 一致 | 已对齐 |
| DR-10 | 建议 | POST agents 返回 201，Umi request 须正确处理 | service 层不剥离 status；mutation 用 response body | 待 tasks |
| DR-11 | 建议 | Webhook resume 无 UI | proposal/design 已排除 | 豁免 |

### 4. 非功能与可观测性

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-12 | 建议 | Admin Key sessionStorage 安全 | §7.2 已列 Password 输入、不 log | 已对齐 |
| DR-13 | 建议 | e2e smoke 标「可选」偏弱 | tasks 至少 1 条 smoke：4 新路由可达 | 待 tasks |
| DR-14 | 建议 | Agent Hub 菜单 4 项增量可能拥挤 | 本期接受；subtitle 区分「平台」；后续可收拢 Tab 页 | 豁免 |

### 5. Spring AI / 铁三角

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| — | — | 纯前端对接，无 LLM/Agent/RAG/Graph 变更 | **不适用** | — |

### 6. 风险、假设与备选方案

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-15 | 建议 | MCP OpsBar 追加可能挤压 mcp 页首屏 | UI-AUDIT 对比前后；OpsBar 单行 compact | 待 Impeccable audit |
| DR-16 | 建议 | test-cases 由测试同学提供 | 本变更以 MANUAL 联调为主；test-cases 可简化为 smoke 清单或用户确认跳过 | 待用户 |
| DR-17 | 建议 | P0 Skill refactor 回归风险 | P0 完成须手动回归 `/agent-hub/skills` | 待 tasks |

---

## 阻塞项清单（须清零后方可 Status → Reviewed）

- [x] **DR-01**：ModelProvider 可读说明 — design v0.2 §4.8/§4.9 已增补 i18n 友好名策略

---

## design.md 修订记录

| 章节 | 修订摘要 | 对应 DR |
|------|----------|---------|
| §4.8 | 新增 `platformModelProvider.label.*` i18n 键 | DR-01 |
| §4.9 | ModelProvider 可读说明策略（无后端 description） | DR-01 |
| 文末修订表 | v0.2 记录 | DR-01 |

---

## 用户确认

- [x] 审查结论已阅读，同意进入 test-cases / tasks 阶段
- [x] ModelProvider 展示策略（i18n 友好名 + unknown 回退）可接受
- [x] Webhook resume 无 UI、快照页不改行为 — 可接受
