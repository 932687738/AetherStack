# 文档同步规则

## 治理层文档（离线维护）

以下目录可在不启动前后端的情况下编辑：

- `openspec/` — 规范与变更（含 `references/*-standards.md` 完整细则）
- `.aetherstack/` — AI 配置源（Cursor 规则真源；改后 **必须** `make sync-config`）
- `harness/docs/` — Harness 计划与设计
- 根目录 `AGENTS.md`、`ARCHITECTURE.md`、`STEP1-DESIGN.md`

### 规范变更同步清单

修改 `.aetherstack/rules/` 或 `openspec/references/` 中 Spring AI 相关规范时，须交叉检查：

| 检查项 | 说明 |
|--------|------|
| 章节编号 | `engineering-standards.md` §4.0~§4.6 与 `spring-ai-*-standards.md` 交叉引用一致 |
| 铁三角 | multi-agent / rag / react-graph 三份 rules 与 references 同步更新 |
| Cursor 落地 | 运行 `make sync-config` 刷新 `.cursor/rules/*.mdc`、`.codex/`、`.cursorrules` |
| OpenSpec | `openspec/config.yaml`、`aether-rules.md` §5.11~§5.13 / §8 索引与 AGENTS.md 关键词速查 |
| 验证脚本 | `check-spring-ai-*.ps1` 通过标准与规范描述一致 |

修改前端 Umi 相关规范时，须交叉检查：

| 检查项 | 说明 |
|--------|------|
| 工程基线 | `engineering-standards.md` §5 与 `frontend-umi-standards.md` 一致 |
| 技术栈 | `tech-stack.md`、`context/tech-stack.yaml` 同步 |
| CR 入口 | `superpowers.md` 中 `cr frontend` 维度与必读清单 |
| UI Craft | `ui-craft.md` 验收命令（harness vs 存量 npm） |

## 应用层文档

修改关联仓库 **ai** 或 **ai_react** 代码后，同步更新：

| 变更范围 | 需更新 |
|----------|--------|
| 后端 API/模块 | `ai/docs/`、`ARCHITECTURE.md` 相关章节（在 ai 仓库） |
| 前端页面/交互 | `ai_react/CHANGELOG.md`、`ai_react/ARCHITECTURE.md` |
| 前后端契约 | `.aetherstack/context/api-contracts.yaml`（本仓；仓库路径段由 sync 从 repos.yaml 生成） |
| 关联仓库路径 | **仅** `.aetherstack/context/repos.yaml` → `make sync-config` |

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
