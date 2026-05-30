<!-- AUTO-GENERATED - DO NOT EDIT -->
<!-- Edit .aetherstack/templates/CLAUDE.md then run: make sync-config -->

# AetherStack - Claude Code Index

> 始终加载本文件（≤100 行）。细节按需读取链接文档。

## 项目

- 治理层 + 关联仓库 ai (Spring AI) + ai_react (React) + openspec + harness
- AI 配置源：`.aetherstack/`（改后运行 `make sync-config`）

## 必读

1. `AGENTS.md` - OpenSpec 与 Skills 入口
2. `ARCHITECTURE.md` - 架构
3. `LOCALPATH.md` - 模块路径

## Harness

- 配置：`harness/harness.config.yaml`
- 验证：`make verify`

## 启动边界

- 治理层离线可用；关联仓库 ai / ai_react 开发时必须在各自路径启动（见 LOCALPATH.md）。

## OpenSpec

- `openspec/config.yaml`
- `openspec/references/aether-rules.md`
