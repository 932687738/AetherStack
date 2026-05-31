# AetherStack 关联仓库与模块路径

> **架构原则**：AetherStack **不内嵌**前后端源码；代码真源在独立仓库，本仓通过路径关联使用。

## 代码仓库（真源）

| 键 | 仓库 | 本地路径 | 说明 |
|----|------|----------|------|
| **backend** | `ai` | `D:\cache\workspace\ai` | Spring AI Agent Hub |
| **frontend** | `ai_react` | `D:\cache\workspace\ai_react` | Nebula Desk（React） |

机器级覆盖（可选）：

```powershell
$env:AETHER_BACKEND_REPO = "D:\path\to\ai"
$env:AETHER_FRONTEND_REPO = "D:\path\to\ai_react"
```

配置真源：`.aetherstack/context/repos.yaml`

## AetherStack 本仓（治理层）

| 键 | 路径 | 说明 |
|----|------|------|
| openspec | `openspec/` | OpenSpec 规范与变更 |
| harness | `harness/` | Harness 工程实践 |
| aetherstack | `.aetherstack/` | AI 单一配置源（rules + context） |

## 框架参考（只读，不内嵌业务代码）

| 项目 | 路径 |
|------|------|
| OpenSpec 框架来源 | `D:\cache\workspace\qwmsspec` |
| Harness 框架来源 | `D:\cache\workspace\harness-engineering-open` |

## Code Review 目标

| 命令 | 审查目录 |
|------|----------|
| `cr backend` | `D:\cache\workspace\ai`（或 `AETHER_BACKEND_REPO`） |
| `cr frontend` | `D:\cache\workspace\ai_react`（或 `AETHER_FRONTEND_REPO`） |

OpenSpec 变更目录固定在本仓：`openspec/changes/`。

## 解析路径脚本

```powershell
.\scripts\resolve-repos.ps1 -Repo backend
.\scripts\resolve-repos.ps1 -Repo frontend
```
