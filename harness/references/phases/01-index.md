# 阶段1：目录索引

## 目标

在 AI 开始工作前，建立项目的索引体系，确保 AI 按需加载信息，避免一次性注入超大文件导致上下文浪费或失效。

## 第一步：读取配置

**在加载任何索引文件之前，先读取 `harness.config.yaml`**：

1. 读取项目根目录的 `harness.config.yaml`
2. 获取项目基本信息（language, framework, adapter）
3. 获取索引文件路径（index 段）
4. 获取 Agent 调度配置（agents 段，供阶段3 使用）
5. 获取验证配置（verify 段，供阶段4 使用）
6. 获取上下文管理配置（context 段，含利用率阈值）

**如果 harness.config.yaml 不存在**，运行 Bootstrap 初始化：
```bash
powershell ~/.claude/skills/harness-engineering-open/bootstrap/init.ps1
```

## 索引文件体系

| 文件 | 作用 | 加载时机 | 行数约束 |
|------|------|---------|---------|
| `CLAUDE.md` | 项目约定、开发规则、索引加载策略 | 始终加载 | ≤100 |
| `README.md` | 项目概览、快速开始 | 始终加载 | ≤100 |
| `AGENTS.md` | 模块索引（每模块一行） | 始终加载 | ≤100 |
| `ARCHITECTURE.md` | 架构概览、API 列表、数据流 | 涉及架构变更时 | ≤300 |
| `docs/DESIGN.md` | 编码标准、API 约定 | 涉及编码规范时 | ≤300 |
| `docs/INDEX.md` | 文档总索引 | 需要查找文档时 | ≤100 |
| `docs/PLANS.md` | 计划追踪 | 规划/执行计划时 | ≤100 |

## 加载策略

写入 CLAUDE.md 的标准加载策略：

```markdown
## 索引加载策略
- 始终加载：CLAUDE.md, README.md, AGENTS.md
- 按需加载：ARCHITECTURE.md（架构变更）、DESIGN.md（编码规范）、INDEX.md（查找文档）、PLANS.md（规划/执行）
- 不主动加载：docs/archive/、docs/database/、docs/audits/（仅在被引用时加载）
- 超长文档：单文档 > 500 行时仅加载目录部分，按需读取具体章节
```

## 按需加载场景

| 触发动作 | 加载文件 |
|---------|---------|
| 用户提出新需求 | AGENTS.md（理解模块结构）+ INDEX.md（查找相关文档） |
| 涉及 API 变更 | ARCHITECTURE.md（查看现有 API） |
| 涉及编码实现 | DESIGN.md（查看编码规范） |
| 规划任务 | PLANS.md（查看当前计划状态） |
| 查找历史决策 | INDEX.md → archive/ 下的 summary 文件 |

## 目录结构约定

```
项目根目录/
├── CLAUDE.md              # 项目约定 + 索引加载策略
├── README.md              # 项目概览
├── AGENTS.md              # 模块索引
├── ARCHITECTURE.md        # 架构文档
├── docs/
│   ├── INDEX.md           # 文档总索引
│   ├── PLANS.md           # 计划追踪（层级化）
│   ├── DESIGN.md          # 设计规范
│   ├── plans/             # 技术方案 + 执行计划（按任务组织）
│   │   └── {task-key}/    # 任务文件夹
│   │       ├── {task-key}.md          # 任务汇总
│   │       ├── sp1-{name}.md         # 子计划1 技术方案
│   │       ├── sp1-{name}-exec.md    # 子计划1 执行计划
│   │       └── ...
│   ├── archive/           # 已归档任务文件夹+summary
│   ├── guides/            # 开发指南（从索引文件拆出的详细内容）
│   ├── database/          # 数据库相关
│   └── audits/            # 审计报告
└── harness.config.yaml    # Harness 配置
```

## 项目不存在索引文件时

如果项目缺少上述索引文件，应先运行 Bootstrap 初始化：

```bash
powershell ~/.claude/skills/harness-engineering-open/bootstrap/init.ps1
```

Bootstrap 会扫描项目代码结构，自动生成缺失的索引文件。

## 行数超标时的处理

如果索引文件超过行数约束，应执行文档压缩（详见 doc-compression.md）：

1. 详细内容拆分到 `docs/guides/` 子文档
2. 索引文件仅保留摘要 + 链接
3. 压缩在阶段6（文档更新/归档）时自动检测并执行
