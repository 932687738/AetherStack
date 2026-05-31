# 前端 UI Craft 规范（Impeccable + OpenSpec）

> **适用范围**：OpenSpec 变更启用 **UI-Craft 模式**（`uiCraftMode: enabled` 或 `auto` 判定命中）时的 **ai_react** 前端开发。  
> **工具**：Cursor skill [Impeccable](.cursor/skills/impeccable/SKILL.md)（非 obra Superpowers，非后端 TDD）

---

## 1. 阶段化引入策略

### 1.1 原则

**不**对所有前端改动强制 Impeccable。按交付物类型分层：

| 层级 | 范围 | uiCraftMode enabled 时 | 示例 |
|------|------|------------------------|------|
| **U1 强制** | 可见 UI 的新增/改版 | **必须** 走 Impeccable | 聊天区布局、侧边栏、上传页、设置面板、空状态、表单交互 |
| **U2 推荐** | 触及 U1 后的收尾 | **推荐** `polish` / `audit` | 对比度、间距、动效、文案、响应式 |
| **U3 豁免** | 纯逻辑 / 契约 | **不要求** Impeccable | `src/api/*`、`request.js`、状态机、无视觉变更的 bugfix |

### 1.2 U1 判定（命中任一则属 UI Craft）

- 新增或重构 **页面 / 视图**（`pages/`、`components/` 中用户可见结构）
- **布局、信息架构、视觉层次** 有明确要求（spec/design 描述交互或样式）
- 新 **组件** 含样式、动效、空态、错误态
- 产品明确要求「更好看 / 改版 / 统一设计语言」
- bugfix 但 **复现涉及 UI 呈现**（错位、不可读、无响应式）

### 1.3 U3 豁免（即使 uiCraftMode: enabled 也可跳过）

- 仅改 API 路径、请求体、SSE 解析
- 仅改 i18n 文案键值（无布局变化）
- 删除 dead code、eslint 修复、build 修复
- 后端联调，界面结构与样式不变

---

## 2. OpenSpec 开关（uiCraftMode）

变更目录 `.openspec.yaml`：

```yaml
schema: standard-spec-driven
aiTddMode: auto
uiCraftMode: enabled   # enabled | disabled | auto
```

| 值 | 行为 |
|----|------|
| `enabled` | 凡 U1 前端任务 **必须** Impeccable；tasks 含 `1.2a` shape/craft 或 audit |
| `disabled` | 仅功能实现 + `npm run lint/build`（默认纯后端/API 变更） |
| `auto`（默认） | design 列出 U1 界面或 spec 含可见交互变更时等同 `enabled` |

**0.1 前置检查第 5 步**由用户选择；可与 `aiTddMode` 独立配置（例如后端 AI-TDD + 前端 UI-Craft 同时开启）。

---

## 3. 任务标记（tasks.md）

在 Requirement 的前端任务上标注 **UI 交付类型**：

| 标记 | 含义 | uiCraft enabled |
|------|------|-----------------|
| `UI-CRAFT` | 新 UI 或显著改版 | 必须：`shape` → `craft`（或 `document` 已有 DESIGN 时直接 `craft`） |
| `UI-AUDIT` | 改现有 UI | 必须：`audit` 或 `critique`，修复后 `polish` |
| `UI-FUNC` | 仅逻辑/API | 不强制 Impeccable |
| `UI-POLISH` | 可选收尾 | 推荐：`polish` |

**阻断规则**：`UI-CRAFT` / `UI-AUDIT` 任务在 uiCraft enabled 时，未完成 Impeccable 验收 **不得** 勾选对应 `1.1` 实现任务。

---

## 4. Impeccable 执行范式（apply 阶段）

命中 U1 且 uiCraft enabled 时 **必须**：

1. 读取 `.cursor/skills/impeccable/SKILL.md`
2. 首次会话运行：`node .cursor/skills/impeccable/scripts/context.mjs`（按 skill 说明）
3. 按任务类型选择子命令（读 `reference/<command>.md`）：

| 场景 | 推荐命令链 |
|------|------------|
| 新功能 UI | `shape` → `craft` → （可选）`audit` → `polish` |
| 改版/优化 | `audit` 或 `critique` → 修复 → `polish` |
| 仅配色/排版 | `layout` / `colorize` / `typeset` → `polish` |
| 文案/微交互 | `clarify` / `animate` → `polish` |

4. 在 **ai_react** 仓库路径开发（见 `LOCALPATH.md`）
5. 验收：`npm run lint` + `npm run build`；U1 任务附加 Impeccable 自检（对比度、响应式、空态）

### 与 Nebula Desk 的约定

- 产品 UI 注册表：读 Impeccable `reference/product.md`（非 marketing `brand.md`）
- 现有样式：`ai_react/src/styles/index.css`、代表页面 `HomePage.jsx` 等
- 无 `PRODUCT.md` / `DESIGN.md` 时按 skill 走 `init` 或 `document --seed`，不阻塞纯 U3 任务

---

## 5. design.md 要求（uiCraft auto/enabled）

design 须包含 **「前端 UI 界面清单」** 小节：

```markdown
### 前端 UI 界面清单（UI-Craft）

| 界面/组件 | 路径（ai_react） | UI 类型 | 说明 |
|-----------|------------------|---------|------|
| 历史侧边栏 | `components/...` | UI-CRAFT | 新增重命名交互 |
| 会话 API 客户端 | `api/conversationHistory.js` | UI-FUNC | 无视觉变更 |
```

`auto` 模式据此判定是否等同 `enabled`。

---

## 6. 分级质量控制

### 6.1 必须（uiCraftMode enabled + U1）

- [ ] design 含 UI 界面清单
- [ ] tasks 含 `1.2a` Impeccable 任务（shape/craft 或 audit）
- [ ] apply 读取 Impeccable skill 并按 reference 执行
- [ ] `npm run lint` + `npm run build` 通过

### 6.2 推荐

- [ ] 变更结束对 U1 组件跑 `critique` 或 `audit`
- [ ] 关键页面 `polish` 收尾
- [ ] 更新 i18n 与无障碍（focus、对比度）

---

## 7. 与 OpenSpec / Superpowers / AI-TDD 关系

```text
OpenSpec 0.1
  ├─ aiTddMode   → 后端 ai + Superpowers TDD
  └─ uiCraftMode → 前端 ai_react + Impeccable

二者独立、可组合：
  后端 CompiledGraph 重构：aiTddMode=enabled, uiCraftMode=disabled
  聊天 UI 改版：         aiTddMode=disabled, uiCraftMode=enabled
  全栈新功能：           两者均可 enabled / auto
```

OpenSpec **不会自动** invoke Impeccable；仅 `uiCraftMode` 命中或用户说 `/impeccable`、`UI-Craft` 时触发。

---

## 8. 参考路径

| 类型 | 路径 |
|------|------|
| Impeccable skill | `.cursor/skills/impeccable/SKILL.md` |
| 项目规则 | `.aetherstack/rules/ui-craft.md` |
| 前端工程标准 | `openspec/references/engineering-standards.md` |
| 契约 | `openspec/references/integration-contracts.md` |
