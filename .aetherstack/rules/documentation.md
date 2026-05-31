# 文档同步规则

## 治理层文档（离线维护）

以下目录可在不启动前后端的情况下编辑：

- `openspec/` — 规范与变更
- `.aetherstack/` — AI 配置源
- `harness/docs/` — Harness 计划与设计
- 根目录 `AGENTS.md`、`ARCHITECTURE.md`、`STEP1-DESIGN.md`

## 应用层文档

修改关联仓库 **ai** 或 **ai_react** 代码后，同步更新：

| 变更范围 | 需更新 |
|----------|--------|
| 后端 API/模块 | `ai/docs/`、`ARCHITECTURE.md` 相关章节（在 ai 仓库） |
| 前端页面/交互 | `ai_react/CHANGELOG.md`、`ai_react/ARCHITECTURE.md` |
| 前后端契约 | `.aetherstack/context/api-contracts.yaml`（本仓） |

## 文档同步流程

触发：用户要求更新文档、同步 CHANGELOG、或代码变更后需维护文档。

1. 识别变更范围（backend / frontend / openspec / 根文档）
2. 按上表更新对应文件
3. 若 API 变更，更新 `.aetherstack/context/api-contracts.yaml`
4. 修改 `.aetherstack/` 后运行 `make sync-config`

## 配置同步

```bash
make sync-config
# 或
.aetherstack/scripts/sync-config.ps1
```

## 禁止

- 不要在 `.cursor/skills` 维护技能正文副本（OpenSpec CLI skills 除外）
- 不要直接编辑生成的 `.cursorrules`、`.codex/`、`CLAUDE.md`（除检查 diff）
