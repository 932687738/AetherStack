# AetherStack 关联仓库与模块路径

> **AUTO-GENERATED** — 勿手改。路径真源：`.aetherstack/context/repos.yaml`，改后执行 `make sync-config`。

## 代码仓库

| 键 | 仓库 | 本地路径 |
|----|------|----------|
| **backend** | `{{BACKEND_NAME}}` | `{{BACKEND_PATH_WIN}}` |
| **frontend** | `{{FRONTEND_NAME}}` | `{{FRONTEND_PATH_WIN}}` |

机器级覆盖（可选，优先于 repos.yaml）：

```powershell
$env:AETHER_BACKEND_REPO = "D:\path\to\ai"
$env:AETHER_FRONTEND_REPO = "D:\path\to\ai_react"
```

## AetherStack 本仓（治理层）

| 键 | 路径 | 说明 |
|----|------|------|
| openspec | `openspec/` | OpenSpec 规范与变更 |
| harness | `harness/` | Harness 工程实践 |
| aetherstack | `.aetherstack/` | AI 配置源 |

## Code Review 目标

| 命令 | 审查目录 |
|------|----------|
| `cr backend` | `{{BACKEND_PATH_WIN}}` |
| `cr frontend` | `{{FRONTEND_PATH_WIN}}` |

OpenSpec 变更目录：`openspec/changes/`（本仓）。

## Cursor 多仓工作区

```text
文件 → 从文件打开工作区 → aether-dev.code-workspace
```

`aether-dev.code-workspace`、`.cursor/sandbox.json`、`.cursor/permissions.json` 由 `sync-config` 根据 `repos.yaml` 生成。

## 解析路径

```powershell
.\scripts\resolve-repos.ps1 -Repo backend
.\scripts\resolve-repos.ps1 -Repo frontend
```
