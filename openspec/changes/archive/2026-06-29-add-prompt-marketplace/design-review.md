# 设计审查（design-review）

> **Schema**：`simple-spec-driven`（本 schema 不强制 design-review；用户主动要求执行）  
> **审查方式**：AI 审查（参照 standard-spec-driven brainstorming 维度）  
> **输入**：`proposal.md`、`specs/aether-agent-prompt-marketplace/spec.md`、`design-lite.md`、`tasks.md`  
> **Status**：`Reviewed`（design-lite v2 已处置全部阻塞项）

## 审查基线

| 项 | 值 |
|---|---|
| Change | `add-prompt-marketplace` |
| design-lite.md 版本 | v2（2026-06-24 Skill 复用方案修订） |
| 审查执行 | AI design-review |
| 审查人确认 | `<待用户确认>` |

## 审查结论摘要

- **总体结论**：`有条件通过`
- **阻塞项数量**：`3`
- **建议项数量**：`6`

---

## 审查维度与发现

### 1. 需求与 spec 对齐

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-01 | 建议 | spec REQ-1「选用模板到应用」：design-lite 写"模板 content 写入目标应用 System Prompt 字段"，但当前 `aether-platform` 模块无明确的"应用"实体表含 System Prompt 字段；`PlatformAgent` 是接口而非实体 | design-lite §三 须明确：选用的"应用"对应哪张表、哪个字段 | **已修订** v2：明确 `appId` = `agent_registry.name`，新增 `system_prompt TEXT` 列 |
| DR-02 | 建议 | spec REQ-4「AI 生成 Prompt 可保存为自定义模板」：design-lite §四 任务 4.2 提到"复用收藏机制或独立存储"，未确定方案 | design-lite 须明确生成结果的持久化路径 | **已修订** v2：AI 生成结果写入 `prompt_templates` 表，`source='generated'` |

### 2. 架构与分层（DDD / 四层）

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-03 | **阻塞** | design-lite §二 快捷指令使用 JSONB + 乐观锁 `version`，但 JSONB 数组内的元素无法单独附加 `version` 字段；乐观锁语义与 JSONB 存储方式存在矛盾 | 二选一修订：**(a)** 改为独立 `quick_commands` 表；或 **(b)** 保留 JSONB，放弃乐观锁 | **已修订** v2：改为独立 `quick_commands` 表（方案 a），支持 version 乐观锁 |
| DR-04 | 建议 | 模块归属正确（`aether-platform`），新增 `prompt` 子包与现有 `agent`/`tool`/`skill` 平级 | 建议补充说明 | **已修订** v2：§2.2 明确 `domain/prompt/` 与 `domain/skill/` 平级 |

### 3. 接口与契约

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-05 | **阻塞** | `POST /prompts/generate`（SSE）未说明事件类型/结束条件/错误传播 | 补充 SSE 契约 | **已修订** v2：§2.3 补充 `type=token` + 关闭连接结束 + `type=progress` error event + 503 超时 |
| DR-06 | 建议 | toggle 收藏响应体未定义 | 明确响应体 | **已修订** v2：响应 `{promptId, favorited}` |
| DR-07 | 建议 | `appId` 参数语义未对齐 DR-01 | 与 DR-01 同步明确 | **已修订** v2：`appId` = `agent_registry.name`，body 改为 `{templateId, agentName}` |

### 4. 非功能与可观测性

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-08 | 建议 | 可观测性仅列日志事件，缺 Micrometer 指标 | 补充 token 消耗/调用耗时 | **已修订** v2：§六 补充 `prompt.tokens` / `completion.tokens` / `llm.duration.ms` |

### 5. Spring AI / 铁三角（如适用）

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-09 | **阻塞** | ChatClient 使用须补充 Spring AI 设计小节或豁免依据 | 补充设计小节 | **已修订** v2：新增 §2.4 Spring AI 设计，写明单次 ChatClient 豁免理由 + Prompt 外置 + 降级 + 密钥 + 可观测 |

### 6. 前端 Umi 规范

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-10 | 建议 | 前端路径 `src/api/` 违反规范 | 修正为 `services/` + `models/` | **已修订** v2：§3.2 修正为 `src/services/promptMarketplace.ts` + `src/models/usePromptStore.ts` |
| DR-11 | 建议 | 未说明 OpenAPI 类型生成路径与 services 映射 | 补充类型引用规范 | **已修订** v2：§3.2 明确类型从 `typings.d.ts` 引用，禁止手写；静态数据用 `useRequest`，客户端状态走 Zustand |

### 7. 风险、假设与备选方案

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-12 | **阻塞**（规范强制） | 缺 Assumptions 小节（§5.9 强制） | 补充假设与风险 | **已修订** v2：新增 §十 假设与风险（5 条：模板量/同构复用/字段容量/AI 质量/指令长度） |

---

## 阻塞项清单（已全部处置 ✅）

- [x] **DR-03**：快捷指令改为独立 `quick_commands` 表，支持 version 乐观锁（design-lite v2 §2.1）
- [x] **DR-05**：SSE 契约已补充（design-lite v2 §2.3）
- [x] **DR-09**：Spring AI 设计小节已补充（design-lite v2 §2.4）
- [x] **DR-12**：假设与风险小节已补充（design-lite v2 §十）

> 注：本变更使用 `simple-spec-driven`，apply 准入仅要求 `tasks`，**不强制**阻塞项清零；但建议修订后再进入 apply 以减少实现返工。

---

## design-lite.md 修订记录（v2 Skill 复用方案）

| 章节 | 修订摘要 | 对应 DR |
|------|----------|--------|
| §2.1 技术选型 | Prompt 市场改为 `prompt_templates` 独立表（仿 skills）；快捷指令改为 `quick_commands` 独立表；`agent_registry` 新增 `system_prompt` 列 | DR-01/03/07 |
| §2.3 API 设计 | 补充 SSE 契约（type=token + 关闭连接 + progress error + 503）；toggle 响应体 `{promptId, favorited}` | DR-05/06 |
| §2.4 Spring AI 设计 | 新增小节：单次 ChatClient 豁免 + Prompt 外置 + 降级 + 密钥 + Micrometer | DR-09 |
| §3.1 后端文件 | 所有新增文件标注 Skill 参照对象；MyBatis 替代 JSON/JDBC | — |
| §3.2 前端 | 路径修正为 `services/` + `models/`；类型从 `typings.d.ts` 引用 | DR-10/11 |
| §七 数据落点 | AI 生成模板写入 `prompt_templates`（source='generated'） | DR-02 |
| §十 假设与风险 | 新增 5 条假设 + 失效风险 + 降级策略 + 验证方式 | DR-12 |

---

## 用户确认

- [x] 审查结论已阅读（待用户确认）
- [x] 阻塞项已全部在 design-lite v2 中处置
- [ ] 同意进入下一阶段（apply）（待用户确认）
