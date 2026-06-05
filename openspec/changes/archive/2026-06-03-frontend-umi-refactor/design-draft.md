# Nebula Desk Umi 重构 - 整体方案

## 一、核心问题

**要解决什么问题**：ai_react 存量 Vite + JavaScript 单页（`HomePage.jsx` 超千行）与 AetherStack 前端规范（Umi 4 + TS + OpenAPI + harness CLI）严重脱节，无法安全演进。

**技术挑战**：
- 在 **不改动后端契约** 前提下，完整复刻 SSE 三种聊天模式与 knowledge meta/citations 解析
- 从单页 `sidebarView` 状态机迁移到 Umi 约定式路由 + Layout，且保持现网导航语义
- OpenAPI 类型生成链路在本地 dev 环境可重复执行（springdoc → typings）
- 全量 U1 界面 Impeccable 验收与工程 harness 门禁并行

---

## 二、整体思路

**分阶段替换（Strangler）**：在 ai_react 仓库内新建 Umi 4 工程骨架（可先用 `legacy-vite/` 归档或 git 分支保留旧代码），按模块逐页重写；每阶段 `harness dev` 可运行、可联调。

**粗步骤**：
1. 初始化 Umi 4 + harness CLI + `.umirc.ts`（代理 `/api`、`/springai`）
2. 从 springdoc 或契约推导生成 `src/openapi/`，封装 `services/` + SSE stream 工具
3. 实现 `src/layouts/BasicLayout`（侧边栏三模块 + 历史会话槽位 + outlet）
4. 逐页迁移：聊天三模式 → 知识库 → 人工审核 → Agent Hub 浏览 → 设置
5. Zustand 接管 theme/language/sidebar；TanStack Query 接管列表类服务端数据
6. 退役 Vite 入口，更新文档与 integration-contracts 引用

**业务场景 → 处理方式**：

| 场景 | 处理方式 |
|------|----------|
| 三种 SSE 聊天 | `services/chatService.ts` + 复刻 `postStream` 语义于 `openapi/request.ts` |
| 会话历史 | `services/conversationService.ts` + React Query 缓存 |
| 知识库 CRUD/上传 | `services/knowledgeService.ts` + 独立 pages |
| HIL 演示 | `services/humanLoopService.ts`，路径 `/springai/demo/...` 代理不变 |
| 主题/语言 | `useAppStore` + ConfigProvider theme |

---

## 三、技术选型

| 功能场景 | 技术组件 | 使用理由 |
|---------|---------|---------|
| 框架与路由 | Umi 4 + 约定式路由 | 规范强制；替代 HomePage 内 view 状态机 |
| UI | Ant Design 5 + ConfigProvider | 规范强制；Layout/Menu/Form/Table |
| 客户端状态 | Zustand | 规范强制；theme/language/sidebar |
| 服务端缓存 | @tanstack/react-query | 规范推荐；会话列表、KB 列表、status |
| HTTP/SSE | Umi `request` + 自定义 stream | 统一拦截；SSE 逻辑集中 |
| 类型 | OpenAPI Generator → `src/openapi/` | OpenSpec 强制 |
| 工程 CLI | `harness`（封装 npm scripts） | 规范强制 |
| i18n | Umi locale 或保留 messages 模块 | design 细化为 TS 字典 |
| 样式 | Ant Design token + CSS Modules less | U1 Impeccable 对齐 |

**不使用**：Umi `@umijs/max` 内置 data flow、axios 直连、拷贝旧 JSX 逻辑。

---

## 四、影响范围

### 系统间影响
- **ai 后端**：无 BREAKING；需保证 dev 环境 springdoc 可访问供类型生成
- **AetherStack 治理层**：更新 integration-contracts 前端引用列、api-contracts.yaml

### 模块改动（ai_react）
- **废弃**：`src/main.jsx`、`vite.config.js`、`src/api/*.js`（迁移完成后删除或移入 `legacy/`）
- **新增**：`.umirc.ts`、`src/app.tsx`、`src/layouts/`、`src/pages/**`、`src/services/**`、`src/openapi/**`、`src/models/**`、`scripts/harness.mjs`
- **重写**：全部页面与组件（Ant Design 5 + TS）

### 接口变更
- **新增**：无后端接口
- **修改**：无（前端实现路径与 header 语义保持，如 `X-Tenant-Id`）
- **前端 services 映射**：见 design.md §五

---

## 五、数据设计

**无数据库变更。** 前端无新增持久化表；localStorage 仅用于 theme/language 偏好（与现网 hooks 行为一致）。

---

## 六、约束与风险

### 技术约束
- SSE 须兼容 knowledge 模式 meta JSON 帧（`includeInFullText` 过滤逻辑）
- HIL 走 `/springai` 前缀，Umi dev proxy 须单独配置
- TypeScript 严格模式；禁止 `any`（第三方缺口用 `unknown` + 守卫）

### 风险点

| 风险 | 应对措施 |
|------|----------|
| OpenAPI 与真实 SSE 响应不一致 | 流式接口在 services 层补充窄化类型；契约测试对照 integration-contracts |
| 全量重写周期 long | 分 phase 交付；每 phase 可独立验收 |
| Impeccable 与功能进度冲突 | UI 界面清单分 UI-CRAFT / UI-AUDIT；layout 先 shape 再逐页 craft |
| 旧 Vite 与 Umi 并行混乱 | 明确目录边界；cutover 后删 Vite 入口 |

---

## 七、待 AI 细化（→ design.md）

- [x] 完整目录与路由映射表
- [x] services ↔ integration-contracts 对照
- [x] SSE 时序与 meta 解析设计
- [x] Zustand / Query 边界
- [x] 前端 UI 界面清单（uiCraftMode: auto → **enabled**）
- [x] 分 phase 实施顺序
- [x] Assumptions 与 OpenSpec 前端 design 必填项
