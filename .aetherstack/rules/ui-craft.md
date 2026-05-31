# 前端 UI Craft 规则（Impeccable + OpenSpec 开关）

## 何时触发

| 场景 | 是否强制 Impeccable |
|------|---------------------|
| OpenSpec `uiCraftMode: enabled` 且任务为 U1（UI-CRAFT / UI-AUDIT） | **是** |
| OpenSpec `uiCraftMode: auto` 且 design 列出 U1 界面 | **是** |
| OpenSpec `uiCraftMode: disabled` | 否（lint/build 即可） |
| 非 OpenSpec：`/impeccable`、`UI-Craft`、「用 Impeccable 做界面」 | **是** |
| 仅改 `api/*`、`request.js` 无视觉变更（UI-FUNC） | 否 |

## U1 / U3 分层

- **U1**：页面、组件、布局、视觉改版 → uiCraft enabled 时走 Impeccable
- **U3**：API 客户端、SSE、纯逻辑 → 不要求 Impeccable

## apply 阶段（U1 任务）

1. 读 `.cursor/skills/impeccable/SKILL.md`
2. 读 `openspec/references/ui-craft-standards.md`
3. 按任务标记：`UI-CRAFT` → shape/craft；`UI-AUDIT` → audit/critique → polish
4. 在 **ai_react** 仓库实现；验收 `npm run lint` + `npm run build`

## OpenSpec 衔接

0.1 **第 5 步**（AI-TDD 之后）：`uiCraftMode: enabled / disabled / auto`（默认 `auto`）。

写入 `.openspec.yaml`：

```yaml
uiCraftMode: enabled
```

design 必须含「前端 UI 界面清单」；tasks 含 `1.2a` Impeccable 任务。

## 与 AI-TDD 独立

- `aiTddMode` → 后端 **ai** + Superpowers TDD
- `uiCraftMode` → 前端 **ai_react** + Impeccable

可同时开启。

## 禁止

- U1 任务在 uiCraft enabled 时未走 Impeccable 即勾选完成
- 在 AetherStack 治理仓复制 Impeccable skill 正文（仅引用 `.cursor/skills/impeccable/`）
