# 前端 Umi 4 开发规范（AetherStack）

> **适用范围**：关联仓库 **ai_react** 中基于 **React 18 + Umi 4 + TypeScript + Ant Design 5 + Zustand + ES7+** 的前端开发与 OpenSpec design/tasks。  
> **配套**：`.aetherstack/rules/frontend-umi.md`、`integration-contracts.md`、`ui-craft-standards.md`（U1 视觉）  
> **路径**：见 `LOCALPATH.md`（frontend → `ai_react`）

---

## 1. 规范分层

| 层级 | 文档 | 职责 |
|------|------|------|
| Cursor 精简规则 | `.aetherstack/rules/frontend-umi.md` | AI 编码时的强制摘要 |
| **本规范** | 完整细则、design 必填项、验收口径 | Harness / OpenSpec / Superpower 三大支柱 |
| 接口契约 | `integration-contracts.md` | REST/SSE 路径与语义 |
| UI 视觉 | `ui-craft-standards.md` | U1 界面 Impeccable（与功能规范独立） |

所有 **ai_react** 新需求 **默认须满足本规范**；U1 可见 UI 变更 **叠加** UI-Craft 要求。

---

## 2. Harness — 工程化与环境约定

### 2.1 项目结构

严格遵守 Umi 4 约定式目录结构，**不允许**随意新增顶层目录。

业务代码全部放在 `src/` 下：

| 目录 | 职责 |
|------|------|
| `pages/` | 页面组件（Umi 约定式路由） |
| `components/` | 公共业务组件 |
| `hooks/` | 自定义 Hooks |
| `models/` | Zustand stores（**不使用** Umi `@umijs/max` 数据流） |
| `services/` | API 请求层，每个文件对应一组后端接口 |
| `types/` | 全局类型定义 |
| `utils/` | 纯工具函数 |

**自动生成目录严禁手动修改**：

- `.umi/`
- `src/openapi/`（可修改 `request.ts` 的配置部分，**不可**修改接口类型文件）

### 2.2 命令与工具

所有工程操作 **必须** 通过项目自带的 **`harness`** CLI 完成，**禁止** 直接使用 `npm`、`yarn`、`pnpm`：

| 操作 | 命令 |
|------|------|
| 安装依赖 | `harness install` |
| 开发服务器（含 OpenAPI 类型生成） | `harness dev` |
| 生产构建（含类型检查与 E2E 校验） | `harness build` |
| 代码检查 | `harness lint`（ESLint + Stylelint + TypeScript） |

- 环境变量统一在 `.env` 定义，经 `process.env` 或 Umi `define` 访问
- **禁止**在代码中硬编码环境相关值（后端地址、AppKey 等）
- Git 提交强制 Husky + lint-staged；**不可**绕过或关闭

### 2.3 Umi 配置

- 所有 Umi 配置集中在 `.umirc.ts`
- 优先使用 Umi 内置能力（路由、请求、Mock 等），避免冗余第三方库
- **约定式路由**，无需手写路由表
- 代理、主题、插件等配置 **仅** 出现在 `.umirc.ts`，保持单一来源

---

## 3. OpenSpec — API 层与类型安全

### 3.1 接口类型生成

后端 OpenAPI（Swagger）自动生成代码，产物位于 `src/openapi/`：

| 文件 | 内容 |
|------|------|
| `src/openapi/typings.d.ts` | 所有接口 TypeScript 类型 |
| `src/openapi/request.ts` | 统一请求配置（错误处理、拦截器） |

- **禁止**手动编写接口类型；入参、出参须从 `typings.d.ts` 引用
- 自动生成类型不满足场景时：**先**更新 OpenAPI 规范并重新生成，**绝不允许**在业务代码硬编码接口类型

### 3.2 API 组织与调用

- `src/services/` 按业务域组织，如 `userService.ts`、`orderService.ts`
- 每个 service 方法 **必须** 显式声明参数和返回值类型，引用 `typings.d.ts`
- 请求须使用 Umi `request` 或封装实例；**禁止** `fetch` / `axios`

**示例**：

```typescript
import { request } from 'umi';
import type { ApiResult, UserInfoParams, UserInfo } from '@/openapi/typings';

export async function getUserInfo(params: UserInfoParams) {
  return request<ApiResult<UserInfo>>('/api/user/info', {
    method: 'GET',
    params,
  });
}
```

### 3.3 错误处理与类型守卫

- 接口调用须处理异常；UI 层友好提示（通常由全局拦截器统一处理，业务层避免重复 try-catch）
- 访问业务字段前做类型守卫或空值检查，避免 `undefined` 运行时错误

---

## 4. Superpower — 开发增强与组件规范

### 4.1 状态管理（Zustand）

- Store 文件：`src/models/useXxxStore.ts`
- 仅通过导出 **hook** 暴露状态与操作；**禁止**直接导出整个 store 对象
- 服务端数据 **优先** TanStack Query（或 Umi 数据请求 hook）缓存；Zustand 仅管理纯客户端状态
- 组件内按需 select，避免不必要重渲染：

```typescript
const userName = useUserStore((state) => state.name);
```

### 4.2 组件开发

- 优先 Ant Design 5，配置式而非侵入式写法
- 业务组件须有 TS Props（`interface` / `type`）并导出
- 函数式组件 + Hooks；**禁止** class 组件
- 页面：`pages/`，小写或中划线命名（如 `user/detail/index.tsx`）
- 公共组件：`components/` 下每组件一目录，含 `index.tsx`、`index.less`、`types.ts`

### 4.3 Hooks 与工具函数

| 类型 | 位置 | 命名 |
|------|------|------|
| 自定义 Hook | `hooks/` | `use` 开头 |
| 纯工具函数 | `utils/` | 函数小驼峰；**文件**大驼峰（如 `FormatDate.ts`） |

Hook 与工具函数须有 JSDoc（用途、参数、返回值）。

### 4.4 样式与主题

- 动态主题：Ant Design 5 CSS-in-JS
- 页面级：`*.less` + CSS Modules
- 全局变量：`global.less` 或 `ConfigProvider` 主题；**禁止**组件内硬编码颜色、字号
- 布局：Flexbox / Grid，考虑响应式

### 4.5 ES7+ 语法

- 使用：`async/await`、可选链 `?.`、空值合并 `??`、解构、箭头函数
- **禁止** `var`；统一 `const` / `let`
- 数组优先函数式（`map` / `filter` / `reduce`），避免命令式循环

### 4.6 代码质量与命名

- 命名语义化；禁止无意义缩写（`id`、`url` 等公认缩写除外）
- 文件命名：
  - 组件：大驼峰（`UserCard`）
  - Hook：小驼峰（`useUserInfo`）
  - 工具文件：大驼峰（`FormatDate.ts`，项目内统一）
  - 类型：`types.ts` 或 `接口名.d.ts`
- 格式化由 Prettier 统一管理

---

## 5. 通用禁止事项

| 禁止项 | 说明 |
|--------|------|
| 直接操作 DOM | 除非自定义 Hook 内且绝对必要 |
| pages/components 内直接调 API | 必须经 `services/` |
| `any` | 极特殊场景须注释说明 |
| `console.log` / `debugger` | 禁止提交 |
| 修改 `.umi/`、`src/openapi/` 生成物 | `request.ts` 配置段除外 |
| 手动同步或重复定义接口类型 | 以 OpenAPI 生成产物为准 |
| 直接使用 npm/yarn/pnpm | 须走 `harness` CLI |

---

## 6. OpenSpec design 必填项（前端相关）

触及 **ai_react** 实现的 design / design-lite **须**包含：

1. **技术栈确认**：Umi 4 + TS + Ant Design 5 + Zustand（或说明豁免理由）
2. **目录与分层**：页面/组件/services/models 路径清单
3. **API 方案**：引用 `integration-contracts.md`；OpenAPI 类型生成与 `services/` 文件映射
4. **状态方案**：客户端状态（Zustand）vs 服务端缓存（TanStack Query / Umi hook）
5. **U1 界面清单**（若 `uiCraftMode` 命中）：见 `ui-craft-standards.md`

---

## 7. 验证与 Harness 衔接

| 阶段 | 命令 / 动作 |
|------|-------------|
| 本地 lint | `harness lint` |
| 本地构建 | `harness build` |
| 治理层统一验证 | `make verify`（经 `.aetherstack/scripts/verify-all.ps1`） |
| 代码审查 | `cr frontend` — 必读本规范 + `engineering-standards.md` §5 |

---

## 8. 存量与迁移

| 现状 | 目标 |
|------|------|
| 部分模块仍为 Vite + JavaScript | 新功能与重构对齐 Umi 4 + TypeScript 栈 |
| API 在 `src/api/*.js` | 迁移至 `services/` + OpenAPI 类型 |
| 直接 `npm run` | 迁移至 `harness` CLI 封装 |

存量小范围补丁须在 PR 注明；**不得**扩大违反 services 分层或手写类型的范围。

---

## 9. 参考索引

- Cursor 规则：`.aetherstack/rules/frontend-umi.md`
- 工程基线：`engineering-standards.md` §5
- 技术栈：`tech-stack.md` §前端
- Harness 前端适配器：`harness/adapters/frontend-npm/`
- UI Craft：`ui-craft-standards.md`
