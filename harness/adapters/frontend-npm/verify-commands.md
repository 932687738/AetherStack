# Frontend/npm 验证命令（ai_react）

> 关联仓库路径见 `LOCALPATH.md` / `.aetherstack/context/repos.yaml`。  
> 工程命令 **必须** 经 `scripts/harness.mjs`（`harness lint` / `harness build`），与 `openspec/references/frontend-umi-standards.md` 一致。

## 三步验证

### Step 1: Linter + 类型检查

在 **ai_react** 仓库根目录：

```powershell
node scripts/harness.mjs lint
# 或（npm bin 已链接时）
npx harness lint
```

等价于 `max lint && tsc --noEmit`（ESLint + Stylelint + TypeScript）。

**通过标准**：0 Error；Warning 按项目 lint 配置（默认不阻塞，除非 task 明确要求 `--max-warnings=0`）。

**常见错误与修复指令**：

| 错误 | 修复指令 |
|------|---------|
| ESLint: unused vars | 删除未使用 import/变量，或前缀 `_` |
| `@typescript-eslint/no-explicit-any` | 改用 `typings.d.ts` 或明确类型 |
| `tsc` 类型不匹配 | 对齐 OpenAPI 类型；禁止手写接口 DTO |
| Stylelint 规则失败 | 按提示修 CSS/LESS；或 `stylelint --fix` |
| import 路径错误 | 使用 `@/` 别名，禁止相对路径穿越 `pages` 直连 API |

**错误消息提炼规则**：输出超过 20 行时，hev-verifier 只提取 ERROR 行与文件路径，不全文灌入上下文。

### Step 2: 生产构建 + E2E

```powershell
node scripts/harness.mjs build
# 或
npx harness build
```

`harness build` 顺序（见 `ai_react/scripts/harness.mjs`）：

1. `npx max build`（环境变量 `HARNESS_E2E_BUILD=1`、`MOCK_CHAT=true`）
2. `npx playwright test`

**通过标准**：Umi 构建成功 **且** Playwright 冒烟全部通过。

**Scoped 验证（单 task apply）**：UI 变更 task 至少跑 Step 1；涉及路由/页面/构建产物时加 Step 2。纯 `services/` / SSE 解析无 UI 时可仅 Step 1（须在 task 或 Verify 输出中注明）。

**常见错误与修复指令**：

| 错误 | 修复指令 |
|------|---------|
| Umi 构建失败 / 模块找不到 | 检查 import、`tsconfig` paths；勿改 `.umi/` |
| Playwright 超时 | 确认 `MOCK_CHAT=true`；检查 selector 与 mock 路由 |
| E2E 断言失败 | 对照 `e2e/` 用例；UI 改版须同步更新 spec |
| OpenAPI 类型缺失 | 后端 springdoc 可用时 `harness dev` 触发类型生成，勿手改 `src/openapi/` |

### Step 3: 单元测试（按需）

OpenSpec task 标记 `AUTO-UT` 或变更 Hook/工具函数时：

```powershell
# 若项目已配置 vitest/jest，按 task 指定命令；默认以 lint + build 为主门禁
npm test
```

**通过标准**：task 或 `test-cases.md` 中声明的用例 100% 通过。

## 与 `make verify` 的关系

AetherStack 治理仓 `make verify` → `.aetherstack/scripts/verify-all.ps1`：

| 阶段 | 仓库 | 命令 |
|------|------|------|
| 后端 | ai | `mvn -B -q test` + Spring AI 检查脚本 |
| 前端 | ai_react | `node scripts/harness.mjs lint` → `node scripts/harness.mjs build` |

**禁止**在归档门禁场景仅用 `npm run build`（不含 Playwright）代替 `harness build`。

## Harness CLI 速查

| 命令 | 用途 |
|------|------|
| `node scripts/harness.mjs install` | 安装依赖 |
| `node scripts/harness.mjs dev` | 开发服务器 |
| `node scripts/harness.mjs lint` | Step 1 |
| `node scripts/harness.mjs build` | Step 2（含 E2E） |

## UI-Craft / completion-gate

`uiCraftMode: enabled` 的 U1 任务：Impeccable 命令链完成后，Verify 阶段 **必须** 在 ai_react 执行 Step 1 + Step 2；tasks 勾选行须含 `impeccable: shape+craft`（或 audit+polish）。见 `openspec/references/completion-gate.md`。

## 参考

- Linter 细则：`harness/adapters/frontend-npm/linter-config-guide.md`
- 构建：`harness/adapters/frontend-npm/compile-guide.md`
- 单测模板：`harness/adapters/frontend-npm/test-templates.md`
- 工程规范：`openspec/references/frontend-umi-standards.md`
