# 文档同步规则

## 治理层文档（离线维护）

以下目录可在不启动前后端的情况下编辑：

- `openspec/` — 规范与变更
- `.aetherstack/` — AI 配置源
- `aether-skills/` — 技能定义
- `harness/docs/` — Harness 计划与设计
- 根目录 `AGENTS.md`、`ARCHITECTURE.md`、`STEP1-DESIGN.md`

## 应用层文档

修改关联仓库 **ai** 或 **ai_react** 代码后，同步更新：

| 变更范围 | 需更新 |
|----------|--------|
| 后端 API/模块 | `ai/docs/`、`ARCHITECTURE.md` 相关章节（在 ai 仓库） |
| 前端页面/交互 | `ai_react/CHANGELOG.md`、`ai_react/ARCHITECTURE.md` |
| 前后端契约 | `.aetherstack/context/api-contracts.yaml`（本仓） |

## 配置同步

修改 `.aetherstack/` 后必须运行：

```bash
make sync-config
# 或
.aetherstack/scripts/sync-config.ps1
```

## 禁止

- 不要在 `.cursor/skills` 维护技能正文副本；真源在 `aether-skills/`。
- 不要直接编辑生成的 `.cursorrules`、`.codex/`、`CLAUDE.md`（除检查 diff）。
