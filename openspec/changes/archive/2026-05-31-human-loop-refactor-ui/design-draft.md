# 人工审核 Human Loop - 整体方案

## 一、核心问题
**要解决什么问题**：HIL 演示能力代码散落在 `springai` 教程包，前端无操作入口，无法在工作台内完成草稿审核、工具审批与企业工作流演示。

**技术挑战**：
- 约 10+ 类跨 Controller / Service / Configuration / Contracts 迁移，须保持 Spring Bean 与 REST 契约不变
- 三类 HIL 场景 UI 信息密度高，需在单页 Tab 内兼顾可读性与 Impeccable 视觉质量
- Demo 编排含 CompiledGraph stream / updateState / Agent invoke，属 L1，需评估 AI-TDD

---

## 二、整体思路

**业务场景**：
- Graph 草稿 HIL → 用户填 threadId/prompt → step1 看草稿 → step2 编辑/采纳 → 看最终答复
- 工具审批 → invoke 至中断 → 展示待审批工具 → APPROVED/EDITED/REJECTED resume
- 企业工作流 → 合同/客服同步调用；自媒体 step1/step2 人工放行

**技术实现思路**：
- 后端：新建 `com.yxy.deepseek.humanLoop` 包，按 web / application / config / contract / tool 分层；类名可去 `AlibabaGraph` 前缀，URL 前缀不变
- 前端：侧边栏「对话」分组新增菜单；`HumanReviewWorkbench` 三 Tab + `api/humanLoop.js`；Impeccable shape → craft
- 无 DB；Checkpoint 仍由 Graph MemorySaver 管理

---

## 三、技术选型
| 功能场景 | 技术组件 | 使用理由 |
|---------|---------|---------|
| Graph 草稿 HIL | CompiledGraph + interruptBefore | 存量实现，迁移不重写 |
| 工具审批 | ReactAgent + HumanInTheLoopHook | 存量实现 |
| 企业工作流 | 三个 CompiledGraph Bean | 存量演示 |
| REST 网关 | Spring MVC Controller | 保持现有 JSON 契约 |
| 前端工作台 | React + 现有 sidebar 模式 | 与 Nebula Desk 一致 |
| U1 设计 | Impeccable shape → craft | uiCraftMode: enabled |

---

## 四、影响范围

### 系统间影响
- 无跨系统 MQ/RPC；仅 ai ↔ ai_react HTTP

### 模块改动
- **ai**：新增 `humanLoop` 包；删除/弃用 `springai` 下对应类；更新教程 Controller `@see`
- **ai_react**：HomePage 侧边栏、constants、新页面、API 模块、i18n
- **AetherStack**：integration-contracts 登记 HIL 端点

### 接口变更
- **新增**：无新 URL（首期）
- **修改**：无（行为与 JSON 不变，仅代码归属变更）

---

## 五、数据设计

无数据库变更。Graph checkpoint 与 Agent Memory 由框架 MemorySaver 管理，threadId 由前端用户输入。

---

## 六、约束与风险

### 技术约束
- 性能：演示级，无 SLA；LLM 调用可能数秒至数十秒，前端须 loading
- 业务：三类场景均为 demo，不接入生产 Agent Hub 对话
- 技术：包迁移后须验证 `@SpringBootApplication` 扫描 `com.yxy.deepseek` 子包

### 风险点
| 风险 | 应对措施 |
|------|---------|
| Bean 名称 / `@Qualifier` 迁移遗漏 | 保留 Configuration 内 BEAN_NAME 常量；迁移后跑集成 smoke |
| 前端 Tab 状态与 threadId 混淆 | 各 Tab 独立 state；共享仅 session 级默认值 |
| L1 无单测 | aiTddMode auto 判定 enabled，补 Demo Service AUTO-AI-UT |

---

## 七、待 AI 细化
- [x] 包结构与类映射表 → 见 design.md §4.2 / §6
- [x] 接口 JSON 与错误码 → 见 design.md §5
- [x] 前端 UI 界面清单 → 见 design.md §3.4
- [x] 时序图 → 见 design.md §4.3
- [ ] test-cases.md（测试同学提供）
