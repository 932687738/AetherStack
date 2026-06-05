# 设计审查（design-review）

> **Schema**：`standard-spec-driven`  
> **审查方式**：Superpowers `brainstorming`（设计审查模式）  
> **输入**：`proposal.md`、`specs/aether-frontend-umi-desk/spec.md`、`design.md` v0.2  
> **Status**：`Reviewed`

## 审查基线

| 项 | 值 |
|---|---|
| Change | `frontend-umi-refactor` |
| design.md 版本 | 0.2（2026-06-03） |
| 审查执行 | AI + brainstorming 设计审查 |
| 审查人确认 | **已确认**（2026-06-03 用户「确认 design-review」 |

## 审查结论摘要

- **总体结论**：**通过**（阻塞项已修订 design v0.2，用户已确认）
- **阻塞项数量**：3（均已修订 design.md）
- **建议项数量**：5（不阻断进入 tasks；部分在 tasks 落地）

## 模式评估（design-review 联动）

| 开关 | 结论 |
|------|------|
| `aiTddMode: disabled` | 维持 **disabled**；无 L1 后端单测 |
| `uiCraftMode: enabled` | 维持 **enabled**；U1 界面清单已列 §3.4 |

---

## 审查维度与发现

### 1. 需求与 spec 对齐

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-01 | 阻塞 | Spec REQ-4 要求 knowledge meta/citations；design 有 onMeta 但未列出现网 `KnowledgeCitationPanel`、meta 归一化逻辑 | 增加 UX parity 清单，tasks 显式覆盖 | **已修订** v0.2 §4.7 |
| DR-02 | 建议 | Spec REQ-9 Agent Hub 四视图；流程图 2.2.2 缺 tools/mcp 节点 | 补全 mermaid | **已修订** v0.2 §2.2.2 |
| DR-03 | 建议 | Spec REQ-8 检索阈值；design 仅在 settings 一笔带过 | tasks 绑定 `conversationConfigService` | 待 tasks |
| DR-04 | 建议 | Spec REQ-10 要求更新 integration-contracts | design 已述，无具体文件 diff | 待 tasks |

### 2. 架构与分层（前端规范）

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-05 | 阻塞 | `frontend-umi-standards` 禁止 fetch；design §4.3 计划 StreamSse 用 fetch | 限定 **仅** `StreamSse.ts` + `chatService` 调用；REST 全走 `request` | **已修订** v0.2 §4.3 |
| DR-06 | 阻塞 | `.umirc.ts` 混用 `umi dev` 与 `@umijs/max` openAPI 路径 | 统一 **@umijs/max** 脚手架 | **已修订** v0.2 §4.1、§4.2 |
| DR-07 | 建议 | `legacy-vite/` 与并行仓库策略未定义 cutover 分支策略 | tasks 明确：feature 分支开发，P6 合并删 Vite | 待 tasks |
| DR-08 | 建议 | 存量 `services/conversationHistory.js` 含 meta 归一化；design 仅提 conversationService | 迁移逻辑入 `hooks/useConversationHistory` 或 service 层 | 待 tasks |

### 3. 接口与契约

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-09 | 建议 | HIL 走 `/springai` 非 `/api`；integration-contracts 主表未列 | tasks 增量登记或引用 human-loop 变更归档路径 | 待 tasks |
| DR-10 | 建议 | `conversationConfig` PUT 方法在存量为 PUT；需在 openapi 生成后核对 | apply 时对照 springdoc | 待 apply |
| DR-11 | 建议 | SuperAgents 管理 API 标为 P1 可选 | 与 proposal 一致，tasks 标 OPTIONAL | 豁免 |

### 4. 非功能与可观测性

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-12 | 阻塞 | Spec/harness 规范要求 `harness build` 含 E2E；design 初稿未定义 | P6 引入 Playwright 冒烟；P0~P5 build 不含 E2E | **已修订** v0.2 §4.1、§4.7 |
| DR-13 | 建议 | LLM 输出 XSS：design §7.3 已禁 dangerouslySetInnerHTML | apply 若引入 Markdown 渲染须 DOMPurify | 已记录 |
| DR-14 | 建议 | 三主题 dzj/lv/yxy 现网存在；design 初稿仅写 theme | parity 清单补充 | **已修订** v0.2 §4.7 |

### 5. Spring AI / 铁三角

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| — | — | 纯前端重构，无 LLM 编排变更 | **不适用** | — |

### 6. 风险、假设与备选方案

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-15 | 建议 | OpenAPI springdoc 与 SSE 流无 schema，typings 可能缺 ChatStreamHandlers | 流式 handlers 类型放 `types/chat.ts`（非 DTO） | 待 tasks |
| DR-16 | 建议 | 全量重写 + Impeccable 周期长 | 坚持 P0~P6 分 phase；每 phase 可独立 merge | 已记录 §4.7 |
| DR-17 | 建议 | ai_react ARCHITECTURE.md 过时（仍写 localStorage 历史） | P6 重写 ARCHITECTURE | 待 tasks |

---

## 阻塞项清单（须清零后方可 Status → Reviewed）

- [x] DR-05：SSE fetch 例外范围 — design v0.2 §4.3
- [x] DR-06：@umijs/max 统一选型 — design v0.2 §4.1
- [x] DR-12：E2E 分阶段策略 — design v0.2 §4.1、§4.7
- [x] DR-01：citations/parity 清单 — design v0.2 §4.7

---

## design.md 修订记录

| 章节 | 修订摘要 | 对应 DR |
|------|----------|---------|
| §2.2.2 | 路由图补 agent-hub/tools、mcp | DR-02 |
| §4.1 | @umijs/max、harness build E2E 分阶段 | DR-06、DR-12 |
| §4.3 | StreamSse fetch 例外与分层禁令 | DR-05 |
| §4.7 | UX parity 清单（Typewriter、三主题等） | DR-01、DR-14 |

---

## 用户确认

- [x] 审查结论已阅读，同意进入 test-cases / tasks 阶段

**确认话术**：回复「**确认 design-review**」后，我将把 Status 改为 `Reviewed` 并继续生成 `tasks.md`（test-cases 需测试同学提供或跳过占位）。

> 已于 2026-06-03 确认。
