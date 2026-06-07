> **任务编号规则**  
> SPEC_ID = 变更期 `specs/` 一层目录名；前缀缩写：**P0**（公共层）、**REG**（registry-ui）、**OPS**（platform-ops-ui）、**TOOLS**（tools-catalog-ui）、**DOC**（文档门禁）  
> **uiCraftMode: enabled** | **aiTddMode: disabled**  
> **design-review**: `Reviewed`（2026-06-07）

## 0. 公共层与 Skill 回归（P0，前置）

- [x] 0.1 前端：**UI-FUNC** 新增 `platformAdminCommon.ts`（tenant/adminKey sessionStorage + `platformHeaders()`）；`platformSkillService.ts` 改为引用并 **re-export** 既有 storage API — **可验证**：`/agent-hub/skills` 列表/发布/状态流转回归通过
- [x] 0.2 前端：**UI-FUNC** 扩展 `ApiPaths.ts`、`routes.ts`；新增 `types/platform*.ts`（AgentRegistry、ToolCatalog、ModelProvider、UncoveredIntent）— **可验证**：TypeScript 编译无 any
- [x] 0.3 前端：**UI-FUNC** 新增 5 个 service（registry、toolCatalog、modelProvider、uncoveredIntent、mcpAdmin）— **可验证**：pages/components 无直连 fetch
- [x] 0.4 前端：**UI-AUDIT** 抽取 `PlatformAdminSettingsDrawer`；Skill 页改用共享组件 — **impeccable: audit+polish** — **可验证**：租户/密钥 Drawer 行为与抽取前一致
- [x] 0.5 测试：**MANUAL** Skill 管理台 P0 回归 — **ManualReason**：DR-17；需后端联调
- [x] 0.6 路由：**UI-FUNC** `.umirc.ts` + `menuConfig.ts` 追加 4 路由与菜单项 — **可验证**：侧栏可见 4 个新入口

**依赖**：本节为全部后续任务前置。

---

## 1. 平台 Agent 注册表列表（aether-agent-superagents-registry-ui · REG-REQ1）

- [x] 1.1 后端：无 — **可验证**：N/A
- [x] 1.2a **UI-CRAFT**：Impeccable `shape` → `craft` `PlatformAgentRegistryManager` 列表区（Table、空态、错误重试）— **impeccable: shape+craft**
- [x] 1.2 前端：**UI-CRAFT** `pages/agent-hub/platform-agents` + `platformAgentRegistryService.listPlatformAgents` — **impeccable: shape+craft** — **可验证**：GET `/api/super-agents/agents` 展示 name/displayName/status/version
- [x] 1.3 测试：**MANUAL** 列表加载/空态/失败重试 — **ManualReason**：test-cases 未提供；TC-REG-REQ1-01 占位
- [x] 1.6 **MANUAL**：打开 `/agent-hub/platform-agents` 可见平台注册表标题与 subtitle（含「平台 API」说明）

---

## 2. 与本地 Agent 快照页隔离（aether-agent-superagents-registry-ui · REG-REQ2）

- [x] 2.1 后端：无 — **可验证**：N/A
- [x] 2.2 前端：**UI-FUNC** **不修改** `pages/agent-hub/agents/index.tsx` 及 `useAgentHubStatus` 数据源 — **可验证**：git diff 无 agents 页逻辑变更
- [x] 2.3 测试：**MANUAL** 快照页回归 — **ManualReason**：TC-REG-REQ2-01
- [x] 2.6 **MANUAL**：访问 `/agent-hub/agents` 仍展示 agent-hub/status 本地 subAgents；与 platform-agents 数据独立

---

## 3. 注册新平台 Agent（aether-agent-superagents-registry-ui · REG-REQ3）

- [x] 3.1 后端：无 — **可验证**：N/A
- [x] 3.2 前端：**UI-CRAFT** 注册 Drawer（name/displayName/capabilityDescription/beanName/healthCheckUrl/permissionTags Tags）；`registerPlatformAgent`；表单校验 name+beanName 必填 — **impeccable: shape+craft** — **可验证**：201 后列表刷新；409 展示冲突
- [x] 3.3 测试：**MANUAL** 成功注册 / 重复标识 / 401 密钥 — **ManualReason**：TC-REG-REQ3-01~03
- [x] 3.6 **MANUAL**：写操作携带 `X-Admin-Api-Key`（配置后）

---

## 4. 按需健康探测（aether-agent-superagents-registry-ui · REG-REQ4）

- [x] 4.1 后端：无 — **可验证**：N/A
- [x] 4.2 前端：**UI-CRAFT** Table 行操作「健康探测」+ `probePlatformAgentHealth`；loading 态与行 status 更新 — **impeccable: craft**（合并在 1.2a 组件内）
- [x] 4.3 测试：**MANUAL** 探测成功/失败 — **ManualReason**：TC-REG-REQ4-01~02
- [x] 4.6 **MANUAL**：POST `/agents/{name}/health` 后行状态更新

---

## 5. 租户与管理密钥配置（aether-agent-superagents-registry-ui · REG-REQ5）

- [x] 5.1 后端：无 — **可验证**：N/A
- [x] 5.2 前端：**UI-FUNC** 各平台页集成 `PlatformAdminSettingsDrawer`；修改 tenant 后 invalidate 相关 Query — **可验证**：sessionStorage 持久化；切换租户后列表变化
- [x] 5.3 测试：**MANUAL** 租户切换 — **ManualReason**：TC-REG-REQ5-01
- [x] 5.6 **MANUAL**：刷新浏览器后 tenant/key 仍生效

---

## 6. 注册表非破坏性（aether-agent-superagents-registry-ui · REG-REQ6）

- [x] 6.1 后端：无 — **可验证**：N/A
- [x] 6.2 前端：**UI-FUNC** 确认 BasicLayout、对话页、Skill 页无结构性改动 — **可验证**：scope 内 diff 仅 agent-hub 增量
- [x] 6.3 测试：**MANUAL** 全量回归清单（对话、Skill、agents/tools/mcp 快照）— **ManualReason**：TC-REG-REQ6-01
- [x] 6.6 **MANUAL**：上述页面功能与布局无回归

---

## 7. ModelProvider 列表与开关（aether-agent-superagents-platform-ops-ui · OPS-REQ1~3）

- [x] 7.1 后端：无 — **可验证**：N/A
- [x] 7.2a **UI-CRAFT**：Impeccable `shape` → `craft` `ModelProviderManager` — **impeccable: shape+craft**
- [x] 7.2 前端：**UI-CRAFT** `pages/agent-hub/model-providers`；GET list + PATCH Switch + POST refresh；i18n 友好名（§4.9）— **impeccable: shape+craft** — **可验证**：Switch 切换 enabled；refresh 展示 providers 摘要
- [x] 7.3 测试：**MANUAL** 列表/Switch/refresh/401 — **ManualReason**：TC-OPS-REQ1~03
- [x] 7.6 **MANUAL**：未知 providerId 回退 raw id 展示

---

## 8. MCP 外部工具刷新（aether-agent-superagents-platform-ops-ui · OPS-REQ4）

- [x] 8.1 后端：无 — **可验证**：N/A
- [x] 8.2a **UI-AUDIT**：Impeccable `audit` → `polish` `PlatformMcpOpsBar`（compact 顶栏）— **impeccable: audit+polish**
- [x] 8.2 前端：**UI-AUDIT** 挂载于 `pages/agent-hub/mcp/index.tsx` 顶部；`platformMcpAdminService.refreshMcpTools`；`AgentHubMcpScreen` props 不变 — **impeccable: audit+polish** — **可验证**：展示 externalToolsBefore/After 与 mcpCallbacks
- [x] 8.3 测试：**MANUAL** MCP 刷新成功/401 — **ManualReason**：TC-OPS-REQ4-01
- [x] 8.6 **MANUAL**：下方 Provider/Callback 只读卡片与变更前一致

---

## 9. 未覆盖意图列表（aether-agent-superagents-platform-ops-ui · OPS-REQ5）

- [x] 9.1 后端：无 — **可验证**：N/A
- [x] 9.2a **UI-CRAFT**：Impeccable `shape` → `craft` `UncoveredIntentScreen` — **impeccable: shape+craft**
- [x] 9.2 前端：**UI-CRAFT** `pages/agent-hub/uncovered-intents`；`listUncoveredIntents(limit)` + clamp 1–100 — **impeccable: shape+craft** — **可验证**：Table 展示 userQuery/createdAt/conversationId
- [x] 9.3 测试：**MANUAL** 列表/空态/limit — **ManualReason**：TC-OPS-REQ5-01~02
- [x] 9.6 **MANUAL**：切换 tenant 后列表按租户刷新

---

## 10. 运维写操作鉴权（aether-agent-superagents-platform-ops-ui · OPS-REQ6）

- [x] 10.1 后端：无 — **可验证**：N/A
- [x] 10.2 前端：**UI-FUNC** 统一 `handlePlatformUnauthorized()`：401 → message + 打开 Settings Drawer — **可验证**：ModelProvider Switch、MCP refresh、Agent 注册均复用
- [x] 10.3 测试：**MANUAL** 无密钥写操作 — **ManualReason**：TC-OPS-REQ6-01
- [x] 10.6 **MANUAL**：401 不暴露堆栈

---

## 11. 运维页 Impeccable 与增量挂载（aether-agent-superagents-platform-ops-ui · OPS-REQ7）

- [x] 11.1 后端：无 — **可验证**：N/A
- [x] 11.2 前端：**UI-CRAFT** 确认 model-providers、uncovered-intents 与 Agent Hub 视觉一致 — **impeccable: polish**
- [x] 11.3 测试：**MANUAL** 运维页面上线后 MCP 只读回归 — **ManualReason**：TC-OPS-REQ7-01
- [x] 11.6 **MANUAL**：Impeccable 验收标记写入已勾选 UI 任务

---

## 12. 平台 Tool 摘要浏览（aether-agent-superagents-tools-catalog-ui · TOOLS-REQ1）

- [x] 12.1 后端：无 — **可验证**：N/A
- [x] 12.2a **UI-CRAFT**：Impeccable `shape` → `craft` `PlatformToolCatalogScreen` — **impeccable: shape+craft**
- [x] 12.2 前端：**UI-CRAFT** `pages/agent-hub/platform-tools` + `listPlatformToolSummaries` — **impeccable: shape+craft** — **可验证**：展示 source/name/summary
- [x] 12.3 测试：**MANUAL** 加载/空态 — **ManualReason**：TC-TOOLS-REQ1-01~02
- [x] 12.6 **MANUAL**：GET `/api/super-agents/tools` 联调

---

## 13. 与本地 Tool 快照页并存（aether-agent-superagents-tools-catalog-ui · TOOLS-REQ2）

- [x] 13.1 后端：无 — **可验证**：N/A
- [x] 13.2 前端：**UI-FUNC** **不修改** `pages/agent-hub/tools/index.tsx` — **可验证**：git diff 无 tools 页逻辑变更
- [x] 13.3 测试：**MANUAL** 快照页回归 — **ManualReason**：TC-TOOLS-REQ2-01
- [x] 13.6 **MANUAL**：subtitle 标注「平台 Tool 摘要」vs 快照页「Tools」

---

## 14. Tool 列表检索与分组（aether-agent-superagents-tools-catalog-ui · TOOLS-REQ3）

- [x] 14.1 后端：无 — **可验证**：N/A
- [x] 14.2 前端：**UI-CRAFT** 搜索框 + 来源筛选（all / agent-hub / mcp）；`filterTools` useMemo — **impeccable: craft**
- [x] 14.3 测试：**MANUAL** 关键词过滤与来源筛选 — **ManualReason**：TC-TOOLS-REQ3-01~02
- [x] 14.6 **MANUAL**：清空搜索恢复全量

---

## 15. API 客户端分层（aether-agent-superagents-tools-catalog-ui · TOOLS-REQ4）

- [x] 15.1 后端：无 — **可验证**：N/A
- [x] 15.2 前端：**UI-FUNC** `platformToolCatalogService` 经 `@/openapi/request`；pages 无 request import — **可验证**：eslint 无违规
- [x] 15.3 测试：**MANUAL** — **ManualReason**：结构约束，随 12.2 一并验收
- [x] 15.6 **MANUAL**：类型与 `PlatformToolSummaryResponse` 字段对齐

---

## 16. Tool 摘要增量交付（aether-agent-superagents-tools-catalog-ui · TOOLS-REQ5）

- [x] 16.1 后端：无 — **可验证**：N/A
- [x] 16.2 前端：**UI-CRAFT** platform-tools 页 Impeccable polish 收尾 — **impeccable: polish**
- [x] 16.3 测试：**MANUAL** 对话/Skill/tools 快照回归 — **ManualReason**：TC-TOOLS-REQ5-01
- [x] 16.6 **MANUAL**：BasicLayout 结构无改动

---

## 17. 文档、契约与 e2e（DOC）

- [x] 17.1 治理层：更新 `.aetherstack/context/api-contracts.yaml` SuperAgents 管理 API 前端消费列 — **可验证**：7 组 REST 与 design §5.1 一致
- [x] 17.2 前端：更新 `ai_react/ARCHITECTURE.md`、`CHANGELOG.md` — **可验证**：SuperAgents 表格补全
- [x] 17.3 前端：**UI-FUNC** `e2e/smoke.spec.ts` 追加 4 新路由可达 smoke — **可验证**：Playwright 通过（DR-13）
- [x] 17.4 **MANUAL** 对照 design §5.1 矩阵逐条 services 映射 — **可验证**：verification-report.md §Completeness 矩阵 9/9 ✅

---

## 18. 收尾与门禁（跨 REQ）

- [x] 18.1 `npm run lint && npm run build`（ai_react）— **可验证**：BUILD SUCCESS（2026-06-07 apply）
- [x] 18.2 OpenSpec `/opsx-verify` + `verification-report.md` — **可验证**：18 Requirements + §5.1 九组 API 对齐（2026-06-07 verify）
- [x] 18.3 `cr frontend` + record-code-review — **可验证**：`code-review-frontend.md` Approved（2026-06-07）
- [x] 18.4 `make completion-gate CHANGE=superagents-frontend-page-completion` — **可验证**：uiCraft 门禁通过（2026-06-07）

---

**依赖关系（建议 apply 顺序）**：

```text
0 (P0 公共层) → 1~6 (REG 注册表，可 1+3+4 同组件迭代)
→ 12~16 (TOOLS) → 7~11 (OPS) → 17 (DOC) → 18 (门禁)
2/13 快照隔离与 6/16 回归贯穿各 phase 末尾 MANUAL 验收
```

**test-cases.md**：未由测试同学提供；各节 x.3/x.6 以 **MANUAL** + TC 占位编号追溯 spec Scenario。后续若补充 test-cases Reviewed，可回填 trace 映射。

**Harness apply**：每项实现任务按 **hev-analyzer → hev-coder → hev-verifier**；U1 须先完成 x.2a Impeccable 再勾选 x.2。

**排除范围**：`POST /api/super-agents/hooks/resume` 无 UI（design DR-11）。
