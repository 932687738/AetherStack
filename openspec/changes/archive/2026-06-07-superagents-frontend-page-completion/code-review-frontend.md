# Frontend Code Review: superagents-frontend-page-completion

**Scope**: ai_react — SuperAgents 平台管理 UI 增量  
**Date**: 2026-06-07  
**Reviewer**: Cursor Agent (`cr frontend`)  
**Verdict**: **Approved**（2 项 Important 跟进，不阻断归档）

---

## 审查维度

| 维度 | 结论 |
|------|------|
| Harness / 目录 | ✅ pages 薄包装、services 分层、`.umirc.ts` + menuConfig 增量 |
| OpenSpec API | ⚠️ `src/types/platform*.ts` 手写类型（与既有 Skill 一致；OpenAPI 未覆盖 SuperAgents 管理端点） |
| 状态 | ✅ TanStack Query + `tenantId` queryKey；全局 `staleTime: 30_000` |
| 组件 | ✅ Ant Design 5；pages/components 无直连 `request` |
| 契约隔离 | ✅ agents/tools 快照页未改；MCP OpsBar 增量挂载 |
| 安全 | ✅ Admin Key 存 sessionStorage + `Input.Password` |
| i18n | ✅ 中英文键完整；ModelProvider 友好名 + unknown 回退 |
| 质量 | ✅ 无 `any`/debugger；401 统一 `handlePlatformUnauthorized` |

---

## 优点

1. **公共层抽取**：`platformAdminCommon` + `usePlatformAdminConfig` + `PlatformAdminSettingsDrawer` 复用合理，Skill 页回归路径清晰。
2. **数据源隔离**：`/agent-hub/agents|tools` 仍走 `useAgentHubStatus`，平台 API 独立路由，符合 spec REQ-2。
3. **错误处理**：写操作 mutation 统一 401 → 打开连接设置 Drawer，符合 OPS-REQ6。
4. **工程验收**：e2e smoke 4 路由；`npm run build` 通过；Switch 深色对比度已修复。

---

## Important（建议 apply 后迭代）

### I-1 全局 `errorHandler` 可能与 mutation 重复弹 toast — **已修复**

SuperAgents 写操作 service 统一 `platformWriteRequestOptions`（`skipErrorHandler: true`）。

### I-2 Skill 页 refactor 后未接入 `handlePlatformUnauthorized` — **已修复**

`PlatformSkillManager` publish/status mutation 已对齐新平台页 401 引导。

---

## Minor

| # | 项 | 说明 |
|---|-----|------|
| M-1 | 409 注册冲突 | 现为 `message.error`；design 建议 Drawer 内 Alert（verification-report 已记） |
| M-2 | 手写 DTO | 后续补 OpenAPI → `typings.d.ts`，删除 `src/types/platform*.ts` 重复 |
| M-3 | 内联样式 | `PlatformToolCatalogScreen` Select `style={{ minWidth: 160 }}` → less class |
| M-4 | 构建产物 | `src/.umi-production/` 勿提交版本库（若 diff 含生成文件应 gitignore） |

---

## 文件清单（核心）

- `services/platformAdminCommon.ts` + 5 个 platform*Service
- `components/platform{Agent,Tool,Ops,Admin}/**`
- `pages/agent-hub/{platform-agents,platform-tools,model-providers,uncovered-intents}/`
- `pages/agent-hub/mcp/index.tsx`（OpsBar 增量）
- `hooks/usePlatformAdminConfig.ts`、`utils/platformUnauthorized.ts`

---

## 结论

架构与 spec/design **对齐**，可进入 `make completion-gate`（MANUAL 联调完成后）。Important 项为 UX 一致性改进，**不阻断**本次 CR 批准。
