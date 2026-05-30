# 文档压缩规则

## 目标

长期迭代后，项目文档会膨胀。压缩机制确保索引文件始终在行数约束内，AI 能高效加载。

## 行数约束

| 文件 | 约束 | 触发压缩阈值（×1.2） |
|------|------|---------------------|
| CLAUDE.md | ≤100 行 | >120 行 |
| README.md | ≤100 行 | >120 行 |
| AGENTS.md | ≤100 行 | >120 行 |
| ARCHITECTURE.md | ≤300 行 | >360 行 |
| DESIGN.md | ≤300 行 | >360 行 |
| PLANS.md | ≤100 行 | >120 行 |
| INDEX.md | ≤100 行 | >120 行 |

## 压缩方法

### 1. 拆分法（主要）

将文件中独立的大段内容拆到子文档，原文件保留摘要 + 链接。

**适用**：文件中有可独立成文的章节（如 API 列表、代码规范细则）

**示例**：
```
ARCHITECTURE.md (350行，超标)
  → 拆出 API 详细参数到 docs/guides/api-reference.md
  → ARCHITECTURE.md 只保留 Method + Path（约200行）
  → 原文件添加链接：详见 [API参考](guides/api-reference.md)
```

**拆分目标目录**：`docs/guides/` 或 `docs/reference/`

### 2. 摘要法

对纯信息性内容生成压缩摘要。

**适用**：archive/ 下的历史文档

**示例**：
```
docs/archive/architecture-upgrade-plan.md (2023行)
  → 生成 docs/archive/architecture-upgrade-plan-summary.md (≤50行)
  → 原文件保留（不删除）
  → 后续只需加载 summary
```

**summary 格式**：
```markdown
> 创建: yyyy-MM-dd HH:mm:ss

## <方案名称> - 摘要

### 关键决策
- 决策1
- 决策2

### 最终结果
- 结果描述

### 影响范围
- 受影响模块
```

### 3. 合并法

多个小条目合并为表格行，减少行数。

**适用**：AGENTS.md、INDEX.md 等索引文件

**规则**：
- AGENTS.md：每个模块占一行
- INDEX.md：每个文档占一行
- 不使用多行描述

## 具体文件压缩规则

### CLAUDE.md（>120行时压缩）

1. **开发约定**：只保留一句话规则，详细说明移至 `docs/guides/dev-conventions.md`
2. **索引加载策略**：保留完整（核心机制，不可下沉）
3. **完成后检查清单**：保留简版（≤5项），详细版移至 `docs/guides/post-task-checklist.md`
4. **Harness 流程规则**：保留简版（状态表 + 流程名称），详细规则移至 Skill references

### ARCHITECTURE.md（>360行时压缩）

1. **API 端点列表**：只保留 Method + Path（去掉 Params 列），详细参数移至 `docs/guides/api-reference.md`
2. **架构图**：保留 ASCII 图
3. **数据流**：保留当前实现简版，Phase 3+ 详细流程移至对应 design-doc
4. **多租户模型**：保留结构图，字段定义移至 `docs/database/`
5. **基础设施表**：保留简表

### DESIGN.md（>360行时压缩）

1. **代码示例**：全部移至 `docs/guides/` 对应指南
2. **Javadoc 规范详细条目** → `docs/guides/javadoc-guide.md`
3. **日志规范详细条目** → `docs/guides/logging-guide.md`
4. **AI 模型路由详细定义** → `docs/guides/ai-routing-guide.md`
5. **DESIGN.md 每条规范只保留一行摘要**

### AGENTS.md（>120行时压缩）

1. 每模块只占一行：`| 模块名 | 路径 | 一句话描述 |`
2. 删除多行描述
3. 详细说明移至对应模块的 design-doc

### PLANS.md（>120行时压缩）

1. 已完成任务整段移至 archive，PLANS.md 只保留 `[已完成]` 汇总表
2. 每个任务占一行

### INDEX.md（>120行时压缩）

1. 每个文档占一行
2. 删除多行描述

## 压缩执行时机

压缩在 **阶段6（文档更新/归档）** 时自动检测并执行：

```
1. 更新文档后
2. 检查所有索引文件行数
3. 超过阈值的文件 → 选择合适的压缩方法
4. 执行压缩：
   a. 创建子文档
   b. 原文件替换为摘要 + 链接
   c. 更新 INDEX.md
5. 输出压缩报告
```

## 压缩报告格式

```markdown
## 文档压缩报告

| 文件 | 压缩前 | 压缩后 | 方法 | 拆出文件 |
|------|--------|--------|------|---------|
| ARCHITECTURE.md | 350行 | 210行 | 拆分 | docs/guides/api-reference.md |
| DESIGN.md | 380行 | 180行 | 拆分 | docs/guides/logging-guide.md, ai-routing-guide.md |
```
