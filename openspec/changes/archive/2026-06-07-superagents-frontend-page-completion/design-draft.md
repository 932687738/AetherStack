# SuperAgents 前端接口补全 - 整体方案

## 一、核心问题

**要解决什么问题**：`superAgents/web` 包 8 个 Controller 已暴露平台 REST 能力，但 Nebula Desk 仅对接 SSE 对话与 Skill 管理台；其余管理类接口无 service/页面，且 Agent Hub 的 agents/tools/mcp 三页仍展示 `GET /api/agent-hub/status` 的**本地 Bean 快照**，与 SuperAgents 平台语义不一致，运维无法在 UI 完成注册、模型开关、MCP 刷新与未覆盖意图复盘。

**技术挑战**：
- **双数据源并存**：同一 Agent Hub 导航下须区分「本地快照」与「平台 API」，不得替换既有只读页行为
- **写操作鉴权**：多个 Controller 依赖 `X-Admin-Api-Key` / `X-Tenant-Id`，须与 Skill 管理台统一配置入口，避免各页重复实现
- **增量交付 + Impeccable**：4～5 个 U1 新页须 shape → craft，且 `harness lint/build` 通过，不影响对话/知识库/Skill 布局

---

## 二、整体思路

**策略：对照矩阵驱动 + 增量路由挂载（Strangler 前端侧）**

1. **盘点**：以 `SuperAgentApiPaths` 为真源，产出「后端接口 ↔ ApiPaths ↔ service ↔ 路由/组件」矩阵（design.md §五）
2. **抽取公共层**：从 `platformSkillService.ts` 抽出 `platformAdminCommon.ts`（tenant/adminKey/sessionStorage + `platformHeaders()`），Skill 与各新 service 共用
3. **新增 4 个独立页面**（不改动原 agents/tools/mcp 页核心逻辑）：
   - 平台 Agent 注册表
   - 平台 Tool 摘要
   - ModelProvider 管理
   - 未覆盖意图复盘
4. **MCP 刷新**：在既有 `/agent-hub/mcp` 页**顶部增量**挂载「运维工具栏」（仅刷新按钮 + 结果反馈），不改动下方 Provider/Callback 只读卡片
5. **导航**：Agent Hub 分组追加 4 个菜单项（i18n 带「平台」前缀以区分快照页）；`.umirc.ts` + `routes.ts` + `menuConfig.ts` 同步
6. **类型**：在 `src/types/` 新增窄化 TS 类型；`openapi/typings.d.ts` 按需补充（springdoc 未覆盖时 hand-maintain，与 `platformSkill` 模式一致）
7. **验收**：Impeccable shape → craft（每 U1 页）→ `npm run lint` + `npm run build`

**业务场景 → 处理方式**：

| 场景 | 处理方式 |
|------|----------|
| 查看平台 Agent 注册表 | 新页 `GET /api/super-agents/agents` + Table |
| 注册 Agent / 健康探测 | Drawer 表单 + `POST agents` / `POST .../health` |
| 查看 Tool 摘要 | 新页 `GET /api/super-agents/tools` + 搜索/来源筛选 |
| 切换 LLM 厂商 | 新页 `GET/PATCH model-providers` + Switch |
| 重建 ModelProvider 绑定 | 新页按钮 `POST model-providers/refresh` |
| MCP 工具缓存刷新 | mcp 页工具栏 `POST mcp/refresh` |
| 未覆盖意图复盘 | 新页 `GET uncovered-intents?limit=` |
| Webhook 恢复 | **不建 UI**（外部回调；design.md 文档说明） |
| 本地 agents/tools/mcp 快照 | **保持** `useAgentHubStatus()` 不变 |

---

## 三、技术选型

| 功能场景 | 技术组件 | 使用理由 |
|---------|---------|---------|
| 路由 | Umi 4 显式 routes（`.umirc.ts`） | 与现网一致；增量 4 path |
| UI 框架 | Ant Design 5 Table / Form / Drawer / Switch / Alert | 对齐 `PlatformSkillManager` 交互范式 |
| 服务端数据 | TanStack React Query | 列表类 GET + mutation 后 invalidate |
| HTTP | Umi `request`（`@/openapi/request`） | 规范强制；禁止 pages 直连 fetch |
| 鉴权 Header | `platformAdminCommon.ts` | 与 Skill 管理台共用 sessionStorage 键 |
| i18n | `zh-CN.ts` / `en-US.ts` | 新菜单与页面 copy |
| 样式 | CSS Modules less + Agent Hub 现有 `nebula-agent-hub-*` 类 | Impeccable craft 在此基础上 polish |
| 状态 | 无新增 Zustand | 租户/密钥仍 sessionStorage（与 Skill 一致） |

**不使用**：替换 agents/tools/mcp 数据源、新增全局 Layout 结构、后端代码变更。

---

## 四、影响范围

### 系统间影响

| 系统 | 影响 |
|------|------|
| **ai 后端** | 无代码变更；消费既有 SuperAgents REST |
| **ai_react** | 新增 pages/components/services/types/routes/i18n/e2e smoke |
| **AetherStack 治理** | 更新 `api-contracts.yaml`；变更归档后可选同步 OpenAPI |

### 模块改动（ai_react）

| 模块 | 改动点 |
|------|--------|
| `src/constants/ApiPaths.ts` | 补充 model-providers、uncovered-intents、mcp/refresh（agents/tools 已有部分常量） |
| `src/constants/routes.ts` | 4 个新 ROUTES 常量 |
| `src/services/platformAdminCommon.ts` | **新增**；从 platformSkillService 抽取 header/storage |
| `src/services/platformSkillService.ts` | 改为引用 common（行为不变） |
| `src/services/platformAgentRegistryService.ts` | **新增** list/register/probeHealth |
| `src/services/platformToolCatalogService.ts` | **新增** listToolSummaries |
| `src/services/platformModelProviderService.ts` | **新增** list/update/refresh |
| `src/services/platformUncoveredIntentService.ts` | **新增** listRecent |
| `src/services/platformMcpAdminService.ts` | **新增** refreshMcpTools |
| `src/types/platform*.ts` | **新增** 与后端 DTO 对齐的类型 |
| `src/pages/agent-hub/platform-agents/` | **新增** U1 |
| `src/pages/agent-hub/platform-tools/` | **新增** U1 |
| `src/pages/agent-hub/model-providers/` | **新增** U1 |
| `src/pages/agent-hub/uncovered-intents/` | **新增** U1 |
| `src/components/agentHub/PlatformMcpOpsBar.tsx` | **新增**；挂载于 mcp 页顶部 |
| `src/pages/agent-hub/mcp/index.tsx` | **仅追加** OpsBar，不改 AgentHubMcpScreen props |
| `src/layouts/BasicLayout/menuConfig.ts` | 4 个新菜单项 |
| `.umirc.ts` | 4 条 routes |
| `e2e/smoke.spec.ts` | 可选 smoke 新页可达 |
| `ARCHITECTURE.md` / `CHANGELOG.md` | 文档同步 |

**明确不改动**：`pages/agent-hub/agents|tools|skills/index.tsx` 核心逻辑、`BasicLayout` 结构、对话/知识库页。

### 接口变更

| 类型 | 说明 |
|------|------|
| **新增（前端消费）** | 无后端新接口；前端首次调用既有 7 组 REST |
| **修改** | 无 |
| **排除 UI** | `POST /api/super-agents/hooks/resume` |

### 后端接口 ↔ 前端映射（矩阵草案）

| 方法 | 路径 | Service 方法 | 页面/组件 | 读/写 |
|------|------|--------------|-----------|-------|
| GET | `/api/super-agents/agents` | `listPlatformAgents` | `/agent-hub/platform-agents` | 读 |
| POST | `/api/super-agents/agents` | `registerPlatformAgent` | 同上 Drawer | 写 |
| POST | `/api/super-agents/agents/{name}/health` | `probePlatformAgentHealth` | 同上 Table 行操作 | 写 |
| GET | `/api/super-agents/tools` | `listPlatformToolSummaries` | `/agent-hub/platform-tools` | 读 |
| GET | `/api/super-agents/model-providers` | `listModelProviders` | `/agent-hub/model-providers` | 读 |
| PATCH | `/api/super-agents/model-providers/{id}` | `setModelProviderEnabled` | 同上 Switch | 写 |
| POST | `/api/super-agents/model-providers/refresh` | `refreshModelProviders` | 同上按钮 | 写 |
| POST | `/api/super-agents/mcp/refresh` | `refreshMcpTools` | `PlatformMcpOpsBar` on `/agent-hub/mcp` | 写 |
| GET | `/api/super-agents/uncovered-intents` | `listUncoveredIntents` | `/agent-hub/uncovered-intents` | 读 |
| POST | `/api/super-agents/chat` | 已有 | `/chat/agent` | — |
| GET/POST/PATCH skills | 已有 | `/agent-hub/skills` | — |

### 路由与菜单方案（草案）

| 路由 | 菜单 labelId（zh 示意） | 与快照页关系 |
|------|---------------------------|--------------|
| `/agent-hub/platform-agents` | 平台 Agent 注册表 | 并存 `/agent-hub/agents`（本地快照） |
| `/agent-hub/platform-tools` | 平台 Tool 摘要 | 并存 `/agent-hub/tools` |
| `/agent-hub/model-providers` | 模型厂商 | 新能力 |
| `/agent-hub/uncovered-intents` | 未覆盖意图 | 新能力 |
| `/agent-hub/mcp` | MCP（不变） | 顶栏 +刷新，下方只读不变 |

---

## 五、数据设计

**无数据库变更。** 前端无新增持久化表。

**sessionStorage 键（沿用）**：
- `aether.platform.adminApiKey`
- `aether.platform.tenantId`

**React Query Key 建议**：
- `['platform-agents']`
- `['platform-tools']`
- `['model-providers']`
- `['uncovered-intents', tenantId, limit]`

---

## 六、约束与风险

### 技术约束

- 写操作须在 Header 携带 `X-Admin-Api-Key`（后端配置非空时）；401 统一 message + 引导打开设置 Drawer
- `uncovered-intents` 的 `limit` 前端 clamp 1～100，默认 20
- pages/components **禁止** import `@/openapi/request` 以外 HTTP；pages **禁止**直连 API
- U1 页面须 Impeccable：`uiCraftMode: enabled`

### 风险点

| 风险 | 应对措施 |
|------|----------|
| 用户混淆快照页与平台页 | 菜单与页面 subtitle 明确标注「平台 API」vs「本地 Bean 快照」 |
| mcp 页加工具栏影响布局 | 仅顶部一条 OpsBar；Impeccable audit 对比前后截图 |
| Admin Key 分散配置 | 抽取 `PlatformAdminSettingsDrawer` 共享组件（Skill 页已有 Drawer 逻辑可复用） |
| OpenAPI typings 未覆盖 SuperAgents 管理接口 | hand-maintain `src/types/*`；design.md 列 JSON 样例 |
| 菜单项过多 | 4 项可接受；若后续膨胀再收拢为「平台中心」Tab 页（本期不采用） |

---

## 七、待 AI 细化（→ design.md）

- [ ] 完整 API 对照矩阵与请求/响应 JSON 样例（逐字段）
- [ ] 前端 UI 界面清单（uiCraftMode: **enabled**，UI-CRAFT/UI-FUNC 标注）
- [ ] 组件树：`PlatformAgentRegistryManager` 等命名与文件路径
- [ ] `PlatformAdminSettingsDrawer` 抽取方案与 Skill 页 refactor 范围
- [ ] i18n 键名清单
- [ ] Assumptions（默认租户、adminKey 未配置时的 UX）
- [ ] e2e smoke 范围
- [ ] 与 `integration-contracts.md` / `api-contracts.yaml` 同步条目
- [ ] 错误码与 HTTP 状态映射（401/409 等）前端文案表

---

## 八、实施分期建议（tasks 参考）

| Phase | 交付物 | 可验证输出 |
|-------|--------|------------|
| **P0 公共层** | `platformAdminCommon` + ApiPaths 扩展 + 类型 | Skill 页回归通过 |
| **P1 注册表** | platform-agents 页 + service | 列表/注册/探测 E2E 手动 |
| **P2 Tool 摘要** | platform-tools 页 | GET tools 展示 + 筛选 |
| **P3 运维三连** | model-providers + uncovered-intents + mcp OpsBar | 写操作 + 401 提示 |
| **P4  polish** | Impeccable craft 全页 + lint/build + 文档 | completion-gate 就绪 |

---

**Status**: Draft — 待用户确认后进入 `design.md` 细化。
