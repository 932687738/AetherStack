# AetherStack 关联仓库与模块路径

> **AUTO-GENERATED** — 勿手改。路径真源：`.aetherstack/context/repos.yaml`，改后执行 `make sync-config`。

## 代码仓库

| 键 | 仓库 | 本地路径 |
|----|------|----------|
| **backend** | `ai` | `D:\cache\workspace\ai` |
| **frontend** | `ai_react` | `D:\cache\workspace\ai_react` |

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
| `cr backend` | `D:\cache\workspace\ai` |
| `cr frontend` | `D:\cache\workspace\ai_react` |

OpenSpec 变更目录：`openspec/changes/`（本仓）。

## Cursor 多仓工作区

```text
文件 → 从文件打开工作区 → aether-dev.code-workspace
```

`aether-dev.code-workspace`、`.cursor/sandbox.json`、`.cursor/permissions.json`、`.cursor/mcp.json` 由 `sync-config` 根据 `repos.yaml` 生成。

## CodeGraph（代码智能索引）

三仓各自独立索引，路径与 `repos.yaml` 对齐：

| 键 | 索引目录 | MCP Server |
|----|----------|------------|
| governance | AetherStack 本仓 | `codegraph` |
| backend | `D:\cache\workspace\ai` | `codegraph-backend` |
| frontend | `D:\cache\workspace\ai_react` | `codegraph-frontend` |

```powershell
# 首次或克隆后重建索引
make codegraph-init

# 查看三仓索引状态
make codegraph-status
```

索引数据在各自仓库的 `.codegraph/`（本地生成，不入库）。修改 `repos.yaml` 后须 `make sync-config` 刷新 MCP 路径，再 `make codegraph-init` 重建关联仓索引。

## 解析路径

```powershell
.\scripts\resolve-repos.ps1 -Repo backend
.\scripts\resolve-repos.ps1 -Repo frontend
```
