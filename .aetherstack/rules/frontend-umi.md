---
description: 前端 Umi 4 开发规范 - Harness 工程化、OpenSpec API 类型、Zustand/Ant Design 组件约定
globs: "**/*.tsx,**/*.ts,**/.umirc.ts,**/.env*,**/src/pages/**,**/src/components/**,**/src/services/**,**/src/models/**"
alwaysApply: false
---

# 前端 Umi 4 开发规范

> **适用范围**：关联仓库 **ai_react**（目标栈：React 18 + Umi 4 + TypeScript + Ant Design 5 + Zustand）。  
> **配套**：`openspec/references/frontend-umi-standards.md`（完整细则）、`integration-contracts.md`（REST/SSE 契约）  
> **视觉层**：U1 界面另见 `.aetherstack/rules/ui-craft.md` + Impeccable

## 三大规范支柱

| 支柱 | 职责 |
|------|------|
| **Harness** | 工程命令（`harness install/dev/build/lint`）、目录约定、Umi 配置单一来源 |
| **OpenSpec** | OpenAPI 生成类型、`services/` 分层、禁止手写接口类型 |
| **Superpower** | Zustand 状态、Ant Design 组件、Hooks/工具、ES7+ 与命名 |

## Harness — 工程化（强制）

- 业务代码仅在 `src/`：`pages/`、`components/`、`hooks/`、`models/`（Zustand）、`services/`、`types/`、`utils/`
- **禁止**使用 Umi `@umijs/max` 数据流；全局状态用 Zustand
- **禁止**修改 `.umi/`、`src/openapi/`（`request.ts` 配置段除外）
- 工程操作走 **`harness`** CLI，禁止直接 `npm/yarn/pnpm`（install/dev/build/lint）
- Umi 配置集中在 `.umirc.ts`；约定式路由；环境变量仅 `.env` + `process.env` / `define`

## OpenSpec — API 层（强制）

- 类型真源：`src/openapi/typings.d.ts`；请求封装：`src/openapi/request.ts`
- `services/` 按业务域组织；方法显式声明入参/返回值，类型引用 OpenAPI 产物
- 使用 Umi `request` 或项目封装实例；**禁止** `fetch`/`axios` 直连
- **禁止**在业务代码手写接口类型；特殊场景先改 OpenAPI 再重新生成

## Superpower — 组件与状态（强制）

- Zustand Store：`src/models/useXxxStore.ts`；仅导出 hook；服务端数据优先 TanStack Query / Umi 请求 hook
- 组件：函数式 + TS Props；Ant Design 5 配置式写法；公共组件一目录（`index.tsx` + `index.less` + `types.ts`）
- `pages/`/`components/` **禁止**直接调 API，须经 `services/`
- 样式：Ant Design CSS-in-JS / CSS Modules；禁止硬编码颜色字号
- **禁止** `any`（须注释原因）、`console.log`/`debugger`、直接操作 DOM（Hook 内必要除外）

## 验证

- 本地：`harness lint` + `harness build`（或 `make verify` 经 Harness 编排）
- OpenSpec 前端 design 须引用 `frontend-umi-standards.md` 并说明目录/API/状态方案

## 存量说明

当前 **ai_react** 若仍为 Vite + JS 存量，新模块与迁移须对齐本规范；存量补丁须在 PR 注明，不得扩大违反分层/API 类型的范围。
