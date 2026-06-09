# 设计审查（design-review）

> **Schema**：`standard-spec-driven`  
> **审查方式**：Superpowers `brainstorming`（设计审查模式）  
> **输入**：`proposal.md`、`specs/**/spec.md`、`design.md` v0.2  
> **Status**：`Reviewed`  
> **Gate**：`Status: Reviewed`

## 审查基线

| 项 | 值 |
|---|---|
| Change | `add-text2sql-schema-artifacts` |
| design.md 版本 | v0.2（2026-06-09） |
| 审查执行 | AI + brainstorming 设计审查 |
| 审查人确认 | **已确认**（2026-06-09；首版仅 aether-platform Flyway + ILIKE Top-K MVP） |

## 审查结论摘要

- **总体结论**：**通过**
- **阻塞项数量**：4（均已修订 design.md v0.2）
- **建议项数量**：5（不阻断进入 test-cases / tasks）

## 模式评估（design-review 联动）

| 开关 | 结论 |
|------|------|
| `aiTddMode: enabled` | 维持 **enabled**；L1 覆盖 SqlGuard、Prompt 渲染、Graph 路由、SSE artifact 解析 |
| `uiCraftMode: enabled` | 维持 **enabled**；design §1.5 已列 U1 界面清单（ArtifactRenderer / SqlReview / Table / Code） |

---

## 审查维度与发现

### 1. 需求与 spec 对齐

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-01 | 阻塞 | spec 要求多轮确认与历史可恢复，design 未定义 artifact 持久化 | 扩展 `ConversationMessage.meta.artifacts` + persistAgentTurn | **已修订** §5.3、§6.7 |
| DR-02 | 阻塞 | Schema 语义检索（spec REQ-6）design 未说明 MVP 口径 | 首版 ILIKE Top-K + embedding 列预留 | **已修订** §6.5 |
| DR-03 | 建议 | 6 份 spec / 28+ Requirement 已映射 §十追溯表 | 维持 | 已覆盖 |
| DR-04 | 建议 | DB Skill 与 CompiledGraph 并存，text2sql 选型已明确 Graph | 不新增 DB Skill 并行路径 | 豁免 |

### 2. 架构与分层（DDD / 四层）

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-05 | 阻塞 | text2sql 挂起与 Workflow 挂起可能冲突 | 定义 prep 优先级 + 互斥规则 + 独立 session 表 | **已修订** §6.6 |
| DR-06 | 建议 | SqlGuard 放 domain 层（纯 JDK）符合规范 | JSQLParser 适配放 infrastructure | **已修订** §4.2、§6.4 |
| DR-07 | 建议 | Catalog 同步放 application 编排，解析放 infrastructure | 维持 | 已覆盖 |

### 3. 接口与契约

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-08 | 阻塞 | SSE artifact 契约完整，但未写 conversation API 扩展 | §5.3 补充 meta.artifacts | **已修订** §5.3 |
| DR-09 | 建议 | integration-contracts / api-changelog 登记在 impact 但未列 tasks 条目 | tasks 阶段同步 | 待 tasks |
| DR-10 | 建议 | Catalog refresh 管理 API 可选，需 admin-api-key | 对齐 SkillController 模式 | 待 tasks |

### 4. 非功能与可观测性

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-11 | 阻塞 | 只读执行仅描述「只读连接可选」过弱 | 强制 READ ONLY 事务 + timeout + 单语句 | **已修订** §7.4 |
| DR-12 | 建议 | 可观测性清单 §7.6 完整 | 维持 | 已覆盖 |
| DR-13 | 建议 | Flyway 多模块迁移范围未界定 | 首版仅 aether-platform migration 目录 | **已修订** §6.5 |

### 5. Spring AI / 铁三角

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-14 | 建议 | Text2SQL 用 CompiledGraph + dataAnalysis ReactAgent 符合 backend-ai | 注册 `Text2SqlReadonlySkillTemplate` + CodeSkillRouterTool | 待 tasks |
| DR-15 | 建议 | 子 Agent 工具数：rag + skill_router + text2SqlPlatformTool = 3 ≤ 5 | 维持单 Tool 入口 | 豁免 |
| DR-16 | 建议 | Prompt 外部化 `prompts/text2sql-*.st` | AUTO-AI-UT 断言关键片段 | 待 tasks |
| DR-17 | 建议 | maxIterations / FINAL ANSWER 对 ReactAgent 仍适用 | Graph 节点内 LLM 节点单独 timeout | 待 tasks |

### 6. 风险、假设与备选方案

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-18 | 建议 | JSQLParser 对 PG 方言覆盖不全 | 白名单 + READ ONLY 双保险 | **已修订** §7.4、§7.7 |
| DR-19 | 建议 | structured-events=false 时 artifact 降级 | fallbackPlainText 已设计 | 已覆盖 |
| DR-20 | 建议 | 首版不扫 knowledgehub 全库 schema | Assumptions 已记录 | **已修订** §6.5、§7.7 |

---

## 阻塞项清单（须清零后方可进入 test-cases / tasks）

- [x] DR-01：artifact / 多轮持久化 — design §5.3、§6.7 已修订
- [x] DR-05：挂起优先级与互斥 — design §6.6 已修订
- [x] DR-08：conversation API meta 扩展 — design §5.3 已修订
- [x] DR-11：只读执行强制策略 — design §7.4 已修订

---

## design.md 修订记录

| 章节 | 修订摘要 | 对应 DR |
|------|----------|---------|
| §5.3 | 新增 assistant `meta.artifacts` / `text2sqlSessionId` 持久化契约 | DR-01, DR-08 |
| §6.5 | Flyway 扫描范围、MVP 语义检索 ILIKE、embedding 预留 | DR-02, DR-13, DR-20 |
| §6.6 | Workflow vs text2sql 挂起优先级与互斥 | DR-05 |
| §6.7 | persistAgentTurn / typings 扩展 | DR-01 |
| §7.4 | 强制 READ ONLY 事务 + jsqlParser 依赖说明 | DR-11, DR-18 |
| Revision | v0.2 | — |

---

## 用户确认

- [x] 审查结论已阅读，同意进入 test-cases / tasks 阶段
- [x] 首版 Catalog 仅扫描 aether-platform Flyway — **已确认**
- [x] Schema 语义检索 MVP 使用 ILIKE Top-K — **已确认**
