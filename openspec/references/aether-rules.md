# AetherStack Rules (OpenSpec 1.x)

本文件为 **AetherStack 项目级规则与判定标准**，工件级写作规范以 schema + templates 为准。

- **模板（结构/示例）**：`openspec/schemas/*/templates/`
- **流程与工件规则**：`openspec/schemas/*/schema.yaml`
- **规则摘要**：`openspec/config.yaml`

如有冲突：**工件写作要求以 schema + templates 为准**；全局流程/判定规则以本文件为准。

## 0.0 规则边界（必读）

- **schema.yaml + templates**：工件级写作要求与结构规范（proposal/spec/design/tasks）
- **aether-rules.md**：跨流程的全局规则（流程选择、命名/目录、交互要求、复杂度判定等）
- **准入优先级（强制）**：是否可进入实现（apply）以所选 schema 的 `apply.requires` 为唯一准入条件；本文件中的测试门禁用于质量约束与回填要求，不得覆盖 schema 的准入定义。

## 0. 工作流选择规则（全局）

工作流由用户选择，并在 proposal.md 中记录所选 schema（见 0.1）。AI 可给出建议，但必须等待用户确认后再进入对应流程。

### 0.1 前置检查（OpenSpec 流程强制）

- 仅当用户明确进入 OpenSpec 流程（创建/继续变更、生成或修改 proposal/spec/design/tasks、调用 OpenSpec 相关技能）时，才需要按以下顺序完成并记录：
  1. **工单链接（可选）**：GitHub Issue / Jira；允许回答「无工单」
  2. **选择流程（schema）**：请选择 1/2/3
     1) standard-spec-driven（复杂需求流程）
     2) simple-spec-driven（简单需求流程）
     3) bugfix-spec-driven（修改 bug 流程）
  3. **需求材料（必填）**：PRD/需求描述，或缺陷描述

- 若请求仅为普通问答、方案讨论或非 OpenSpec 文档编辑，不触发 0.1。
- **探索阶段不触发 0.1**：需求探讨/方案讨论/可行性分析阶段不属于 OpenSpec 流程，禁止调用 OpenSpec 相关技能；当明确进入产物阶段（proposal/spec/design/tasks）时再执行 0.1。

**AI 交互式执行要求（强制）**

- AI 必须按 0.1 的顺序逐项提问并等待回答，不得一次性要求用户提供全部信息
- 若用户选择「无工单」，第 1 步可跳过，直接进入第 2 步
- 若用户提供工单链接，仅收集链接本身，在未明确请求前 **不得读取/抓取** 工单内容
- 询问第 2 项时，必须逐项列出 1/2/3 且包含对应中文说明

### 0.2 需求材料收集（强制）

- 完成 0.1 后，进入第 3 步：仅请求 **PRD 或需求描述**（二选一）
- 不得再次索要工单链接
- 推荐话术（必须使用）：

  「第三步：提供需求材料  
  请提供以下任一材料（根据流程生成不同工件）：  
  - standard-spec-driven / simple-spec-driven：PRD（产品需求文档）或需求描述（背景、目标、功能点），用于生成 proposal.md  
  - bugfix-spec-driven：缺陷描述（现象/复现步骤/影响范围）或截图/日志，用于生成 bug-report.md  
  提供后，我将创建变更目录并生成对应首个工件，继续后续流程。  
  请提供需求材料。」

### 0.3 AI 工作流与规则读取（工具无关）

- **obra Superpowers 插件**（Cursor）：`/add-plugin superpowers` — 通用 TDD、代码审查、brainstorming 等；详见 `.aetherstack/rules/superpowers.md`
- **AetherStack 项目规则**：`.aetherstack/rules/`（DDD、OpenSpec、文档、Harness；随 sync-config 加载）
- 禁止在仓库内复制 obra 插件 skill 正文；禁止重建已移除的 `workflows/`、`skills-index.yaml`、`aether-skills/`
- 需求命中 code review 关键词：invoke 插件 `requesting-code-review`，并遵循 `rules/superpowers.md` 中 AetherStack 审查约束
  - 关键词示例：`cr`、`cr backend`、`code review`、`发起cr`、`代码审查`
- 需求命中单测关键词：invoke 插件 `test-driven-development`，并遵循 `rules/superpowers.md` 中测试约束
  - 关键词示例：单测、unit test、UT、AUTO-UT、Service 测试
- 需求涉及提交类写接口 DDD 设计：读取 `.aetherstack/rules/ddd-commit-design.md`
- 需求涉及文档同步：读取 `.aetherstack/rules/documentation.md`

## 1. 能力命名与目录规则（必须遵守）

### 1.1 Capabilities 命名（DDD 目录）

- 目录层次格式（默认）：`aether-{domain}/{capability}`
- 子域策略：默认不新增子域；仅在复杂领域且存在稳定复用边界时允许 `aether-{domain}/{subdomain}/{capability}` 作为例外
- 目录与能力命名使用 `kebab-case`（小写 + 连字符）
- 领域名称优先与 `openspec/references/domain-models.md` 对齐
- 示例：`aether-agent/orchestrator`、`aether-knowledge/upload`、`aether-hub/status`

### 1.2 目录层级约束（OpenSpec 工具限制）

- **变更期 changes/**：`specs/` 下 **最多 1 层**目录
  - 示例：`changes/<id>/specs/aether-agent-orchestrator/spec.md`
- **归档后 specs/**：默认 **2 层**（`aether-{domain}/{capability}`）；复杂领域可按例外使用 **3 层**
  - 默认示例：`specs/aether-agent/orchestrator/spec.md`
  - 子域例外示例：`specs/aether-knowledge/upload/parse-document/spec.md`
- 若 `openspec validate` 报 “Change must have at least one delta”，优先检查目录层级是否超限
- 目录示例请参考：`openspec/references/directory-examples.md`

### 1.3 变更期与归档期目录映射（必须遵守）

- 变更期 1 层命名需与归档期能力路径一一映射
- 默认映射规则：`aether-{domain}-{capability}` → `aether-{domain}/{capability}`
  - 示例：`aether-agent-orchestrator` → `aether-agent/orchestrator`
  - 示例：`aether-knowledge-upload` → `aether-knowledge/upload`
- 子域例外映射：`aether-knowledge-upload-parse` → `aether-knowledge/upload/parse`

### 1.4 目录组织建议（非强制）

- 能力命名保持单一职责（动宾或名词形式）
- 默认优先两层目录；仅当复杂领域确有稳定边界时再引入子领域
- 变更期目录结构需与 `specs/` 保持一致

## 2. proposal.md（需求概要与范围）

- proposal 写作规范见对应 schema 模板与 instruction
- 可在 proposal 中注明 Issue/Jira 链接（可选）
- 背景与目标、全局需求概览统一放在 proposal（spec 不再重复）

## 3. spec.md（双层结构）

> spec 结构与格式要求见对应 schema 模板与 instruction

### 3.1 spec 边界（强制）

- spec 仅表达业务需求与业务口径，不混入测试设计方法（测试策略/测试步骤/测试矩阵）
- spec 中允许且建议明确关键业务口径（如批量处理、失败处理、回退边界），避免 design/test 产生歧义
- 测试可观测性、并发与性能验收口径统一放在 design/design-lite 与 test-cases 中，不放入 spec 正文

## 4. 复杂度判定与设计流程

复杂度判定与设计流程要求以 `openspec/schemas/*/schema.yaml` 的 instruction 为准。

| 条件 | 建议 schema |
|------|-------------|
| 跨模块、新聚合、架构变更 | standard-spec-driven |
| 单模块小改动 | simple-spec-driven |
| 缺陷修复 | bugfix-spec-driven |

## 5. design.md / design-lite.md（技术方案）

- 技术方案写作规范见对应 schema 模板与 instruction
- 核心场景必须覆盖「正常 / 边界 / 异常」三类：
  - 常规需求：核心场景不少于 3 个
  - 涉及跨模块、异步任务、外部 LLM/API 任一项：核心场景不少于 6 个
- 若 PRD 涉及外部系统改造（如 DashScope API、MCP Server、第三方回调），设计文档必须单列「外部系统改造点」
- 若 design/design-lite 补充流程图、时序图、组件图，粒度必须优先到「组件/模块级」，至少体现 Controller、Orchestrator、Graph Node、Repository 等关键节点
- design/design-lite 必须包含「可观测性清单」（接口返回、SSE 事件、日志、Actuator、数据库、向量检索，按需列出并给出验证口径）
- design/design-lite 的「非功能性需求设计」章节必须包含：
  - 并发与幂等验收口径
  - 性能与容量验收口径（含 embedding/检索延迟）
- 前后端 API 变更必须引用并对齐 `integration-contracts.md`

### 5.1 查询与导出条件设计约束（强制）

- 若页面/接口存在「单号条件」与「时间区间条件」二选一、或多组条件组合校验，必须在 spec/design 中显式写成 **条件组规则**
- 条件组规则必须明确：字段分组、组内填制规则、组间关系
- API 示例必须至少覆盖两类合法请求；非法组合需明确错误口径
- 列表、统计、导出、异步任务共用的查询条件，design 必须说明统一的条件构造/校验入口

### 5.2 批量操作与 selectedIds 语义约束（强制）

- 任何批量操作/异步任务在 design 中必须明确 `selectedIds` 的业务语义（如 `knowledgeBaseId`、`documentId`）
- 若接口同时传 `selectedIds` 与 `queryCondition`，必须明确两者职责
- 禁止在 design 中省略 `selectedIds` 语义，导致实现阶段默认按数据库主键理解

### 5.3 Job checkpoint 与 retry 设计约束（强制）

- 任何按时间窗口扫描的 job，只要存在 checkpoint 推进逻辑，design 必须单列说明推进时机、失败处理与 retry 管道
- 若对象在 checkpoint 推进后会离开首刷窗口，必须明确「先持久化失败可重试状态，再推进 checkpoint」

### 5.4 新旧模型并存时的兼容投影约束（强制）

- 若需求引入新表/新模型但仍需兼容旧接口或旧读模型，design 必须单列「兼容投影/回刷策略」

### 5.5 高并发/高频查询字段冗余约束（建议强制）

- 高频筛选字段应优先评估在读模型/业务表中冗余，而非运行期联表
- design 应明确字段来源、赋值时机、更新责任链路与回填脚本

### 5.6 状态写链路收口约束（强制）

- 多入口状态流转（如 API / job / hook）必须明确「统一状态写入收口点」
- 禁止每个入口各自直接改主状态字段

### 5.7 状态冲突优先级与同时刻判定约束（强制）

- design 必须显式定义多来源事实冲突规则与 tie-break 规则

### 5.8 查询排序白名单约束（强制）

- 若接口支持 `orderBy`，design 必须提供「业务字段 -> 安全排序列」白名单映射，不得直接透传前端字段名

### 5.9 关键业务前提假设约束（强制）

- design 必须单列 `Assumptions` 小节，包含假设内容、失效风险、降级策略、验证方式

### 5.10 批量接口返回契约约束（强制）

- 批量接口必须先明确执行语义：`全量原子` 或 `部分成功（逐对象隔离）`
- 部分成功时必须返回逐对象 success/fail 明细，含 `errorCode` 与 `errorMessage`

## 6. test-cases.md（测试设计质量门禁）

> 用例生成的完整执行规范以各 schema 的 test-cases instruction 为准，本章仅保留跨流程的全局约束。

### 6.1 产物定位（强制）

- `test-cases.md` 是可直接执行的测试稿，不是覆盖提纲
- 用例正文必须写清入口、操作对象、步骤、可观测预期结果
- 禁止使用「功能正常」「系统成功」「数据正确」等空泛表述

### 6.2 Automation 标记与下游任务映射（强制）

- 每条 `[C]` 用例必须标注 `Automation: AUTO-UT` 或 `Automation: MANUAL`
- `AUTO-UT`：可在 `ai/src/test/` 稳定验证的场景；`MANUAL`：SSE 联调、前端交互、强环境依赖
- `tasks.md` 必须基于 Automation 标记拆分任务
- `AUTO-UT` 可追溯注释要求：
  - 测试类需包含 `TC-REQ -> TestMethod` 映射注释
  - 每个测试方法需通过 `@DisplayName` 或方法注释标注 `TC-REQx-yy` 与 Requirement

### 6.3 未定口径处理（强制）

- 未定口径必须在 `test-cases.md` 中显式标记「待确认」，不得擅自补齐
- 外部测试稿与 spec/design 冲突时，必须在文档末尾增加「口径冲突」小节

## 7. AI 流程检查点（强制）

- **proposal + spec 完成后**：必须进行复杂度评估
- **复杂需求**：先 design-draft，再 design
- **test-cases.md 生成后**：等待 review（Status → Reviewed）后再推进测试任务
- **开始实现前**：以 schema `apply.requires` 为准；`AUTO-UT` 用例需映射到 `*Test.java`
- **simple-spec-driven 特例**：是否可进入实现以 `simple-spec-driven/schema.yaml` 的 `apply.requires` 为准

## 8. 参考文档（按需加载）

- `openspec/references/tech-stack.md`
- `openspec/references/engineering-standards.md`
- `openspec/references/integration-contracts.md`
- `openspec/references/architecture.md`
- `openspec/references/domain-models.md`
- `openspec/references/directory-examples.md`
- `.aetherstack/rules/superpowers.md`
