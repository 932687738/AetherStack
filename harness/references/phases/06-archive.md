# 阶段6：文档更新/归档

## 目标

更新项目文档，归档方案文件，推送代码，压缩上下文，为下一个子计划做准备。

## 流程

```
1. 更新项目文档（按 exec-plan 声明）
    ↓
2. 归档方案和执行计划
    ↓
3. 检查文档行数，超标则压缩
    ↓
4. 推送代码
    ↓
5. 生成 summary
    ↓
6. 压缩/清空上下文
    ↓
7. 加载下一个子计划
```

## 1. 更新项目文档

按 exec-plan 中的文档更新清单执行：

| 变更类型 | 需更新文档 | 更新内容 |
|---------|-----------|---------|
| 新增/修改 API | ARCHITECTURE.md | API 端点列表 |
| 新增/修改编码约定 | DESIGN.md | 规范条目 |
| 新增业务模块 | AGENTS.md + ARCHITECTURE.md | 模块索引 + 架构图 |
| 完成计划 | PLANS.md | 标记 Completed |
| 新增文档文件 | INDEX.md | 文档索引条目 |

**注意**：更新时检查行数约束，超标则同时执行压缩。

## 2. 归档操作

整任务文件夹移动到归档目录：

```bash
# 移动整个任务文件夹到归档
mv docs/plans/{task-key}/ docs/archive/{task-key}/

# 在归档文件夹内生成任务级摘要
# docs/archive/{task-key}/{task-key}-summary.md
```

归档后更新 INDEX.md 指向，将文档条目标记为 `[已归档]`。

### 任务级摘要

归档后在文件夹内生成 `{task-key}-summary.md`（≤50行），覆盖整个任务的执行结果：

```markdown
> 创建: yyyy-MM-dd HH:mm:ss

# {task-key} - 任务摘要

## 任务概述
<!-- 一段话描述任务目标和最终结果 -->

## 子计划执行结果

| # | 子计划 | 状态 | 关键决策 |
|---|--------|------|---------|
| sp1 | | Completed | |
| sp2 | | Completed | |

## 关键决策
- <决策1>
- <决策2>

## 接口暴露
- <新增/修改的 API>

## 后续影响
- <对其他模块的影响>

## 交接信息（context reset 时使用）
- **当前任务状态**：已完成
- **已完成工作清单**：<具体列表>
- **待办事项**：<如有未完成项>
- **阻塞项**：<如有>
```

归档文件保留原始内容，不删除。

## 3. 文档压缩

### 行数约束

| 文件 | 约束 |
|------|------|
| CLAUDE.md, README.md, AGENTS.md | ≤100 行 |
| ARCHITECTURE.md, DESIGN.md | ≤300 行 |
| PLANS.md, INDEX.md | ≤100 行 |

### 压缩触发条件

文件行数 > 约束值 × 1.2

### 压缩方法

**拆分法**（主要方法）：
- 将大段独立内容拆到 `docs/guides/` 子文档
- 原文件保留摘要 + 链接
- 示例：ARCHITECTURE.md 的 API 详细参数 → `docs/guides/api-reference.md`

**摘要法**（用于 archive 文件）：
- archive/ 文件 > 500 行 → 生成 `<name>-summary.md`（≤50行）
- summary 内容：关键决策 + 最终结果 + 影响范围
- 原文件保留

**合并法**（用于索引文件）：
- 多行描述合并为表格行
- 每个模块/文档占一行

### CLAUDE.md 压缩规则（超100行）

```
1. 开发约定：只保留一句话规则，详细说明移至 docs/guides/dev-conventions.md
2. 索引加载策略：保留完整（核心机制）
3. 完成后检查清单：保留简版（≤5项），详细版移至 docs/guides/post-task-checklist.md
```

### ARCHITECTURE.md 压缩规则（超300行）

```
1. API 列表：只保留 Method + Path，详细参数移至 docs/guides/api-reference.md
2. 架构图：保留
3. 数据流：保留简版，详细流程移至对应 design-doc
4. 多租户模型：保留结构图，字段定义移至 docs/database/
```

### DESIGN.md 压缩规则（超300行）

```
1. 代码示例：全部移至 docs/guides/ 对应指南
2. 详细规范：每条只保留一行摘要，详细版移至 docs/guides/
   - Javadoc 规范 → docs/guides/javadoc-guide.md
   - 日志规范 → docs/guides/logging-guide.md
   - AI 路由 → docs/guides/ai-routing-guide.md
```

### Push 策略

根据 `harness.config.yaml` → `extensions.push_strategy` 决定 push 行为：

| 策略 | 行为 |
|------|------|
| `per-sp`（默认） | 每个 SP commit 后自动 push |
| `per-session` | 所有 SP 完成后统一 push |
| `manual`（最安全） | 不自动 push，仅提示用户确认后 push |

⚠️ **MUST NOT** 在未确认的情况下自动 push

### Deploy 行为

根据 `harness.config.yaml` → `extensions.deploy_trigger`：

| 值 | 行为 |
|-----|------|
| `auto` | push 后自动触发部署 |
| `manual` | 提示用户手动部署 |
| `none`（默认） | 不执行部署，MUST 在归档报告中声明：`[DEPLOY] deploy_trigger=none — 需手动部署` |

⚠️ `deploy_trigger=none` 时 MUST NOT 尝试调用部署工具或 Agent

## 4. 推送代码

```bash
git push origin <branch>
```

**需用户确认后才推送**。

## 5. 生成 summary

写入 `docs/archive/{task-key}/{task-key}-summary.md`（≤50行）：

```markdown
> 创建: yyyy-MM-dd HH:mm:ss

## <任务名称> - 执行摘要

### 关键决策
- <决策1>
- <决策2>

### 变更范围
- <文件列表>

### 接口暴露
- <新增/修改的 API>

### 后续影响
- <对其他模块的影响>

### 交接信息（context reset 时使用）
- **当前任务状态**：已完成 / 部分完成
- **已完成工作清单**：<具体列表>
- **待办事项**：<如有未完成项>
- **阻塞项**：<如有>
```

## 6. Context Reset（上下文重置）

**核心洞察**：上下文利用率超过 40% 后，Agent 质量急剧下降。子计划完成后，宁可重启干净 Agent，也不要塞满历史信息。

### 操作步骤

1. 确认 summary 已生成（含交接信息字段）
2. 更新 `docs/.harness-progress.json` 记录当前执行状态
3. 提示用户：**"子计划 P1 已完成。建议执行 /clear 压缩上下文后再继续下一个子计划。"**
4. 用户执行 /clear 后，按交接文档重建上下文：
   - CLAUDE.md（始终加载）
   - AGENTS.md（始终加载）
   - `docs/.harness-progress.json`（恢复执行状态）
   - 当前子计划的 exec-plan
   - 前置子计划的 summary（如有依赖）

### 交接信息字段说明

| 字段 | 用途 | 示例 |
|------|------|------|
| 当前任务状态 | context reset 后快速定位 | "P1 已完成，P2 待执行" |
| 已完成工作清单 | 避免重复执行 | "UserService CRUD, /api/v1/users" |
| 待办事项 | 接续未完成工作 | "P2 需要引入 OrderClient 依赖" |
| 阻塞项 | 升级给用户的问题 | "第三方接口字段格式待确认" |

## 6. 压缩/清空上下文

**这是 Harness Engineering 的关键机制**。

子计划完成后，AI 上下文中积累了大量代码细节。在进入下一个子计划前，必须压缩：

### 操作步骤

1. 确认 summary 已生成
2. 提示用户：**"子计划 P1 已完成。建议压缩/清空上下文后再继续。"**
3. 用户执行上下文压缩（Claude Code 的自动压缩机制，或用户手动 /clear）
4. 重新加载必要上下文：
   - CLAUDE.md（始终加载）
   - AGENTS.md（始终加载）
   - 当前子计划的 exec-plan
   - 前置子计划的 summary（如有依赖）

### 上下文保留策略

| 内容 | 是否保留 | 原因 |
|------|---------|------|
| 项目索引文件 | ✓ 保留 | 后续计划需要 |
| 当前 exec-plan | ✓ 保留 | 正在执行 |
| 前置子计划 summary | ✓ 保留 | 依赖参考 |
| 已完成子计划的代码细节 | ✗ 不保留 | summary 已覆盖 |
| 验证日志 | ✗ 不保留 | 已归档 |

## 7. 加载下一个子计划

```
1. 从 PLANS.md 找到下一个 Planned 状态的子计划
2. 检查前置依赖是否已完成
3. 加载其 exec-plan
4. 进入阶段3（执行）
```

如果没有更多子计划，输出：

```markdown
## 全部计划已完成 ✓

已完成子计划：P1, P2, P3, P4
总变更文件数：32
总提交次数：4
建议：创建 PR 合并到主分支
```
