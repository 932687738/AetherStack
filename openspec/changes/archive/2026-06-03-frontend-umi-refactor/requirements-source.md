# 需求材料来源

| 项 | 值 |
|----|-----|
| 来源 | 用户提供 `React重构.md` |
| 路径 | `c:\Users\93268\Desktop\React重构.md` |
| 工单 | 无 |
| Schema | standard-spec-driven |
| aiTddMode | disabled |
| uiCraftMode | auto |

## 摘要

从零重构 **ai_react**（Nebula Desk）前端：原代码全部弃用，仅保留 API 交互逻辑与页面布局结构作为参考。新栈为 **React 18 + Umi 4 + TypeScript + Ant Design 5 + Zustand + OpenAPI 类型层**，严格遵循 Harness / OpenSpec / Superpower 规范（见 `openspec/references/frontend-umi-standards.md`）。

## 执行步骤（PRD 原文要点）

1. 分析原项目：接口清单 + 页面路由/布局
2. 生成 OpenAPI 类型层（`src/openapi/`）
3. 搭建 Umi 4 工程骨架（`.umirc.ts`、`harness` CLI）
4. 重新实现布局（`src/layouts/`）
5. 逐页面重构（Ant Design 5 + `services/` + `hooks/`）
6. 接入 Zustand（`src/models/`，仅客户端状态）

## 禁止事项

- 禁止拷贝原项目代码逻辑
- 禁止 `any`、页面内直连 API、修改 OpenAPI 生成类型文件
- 禁止 `console.log` / `debugger`、直接操作 DOM
