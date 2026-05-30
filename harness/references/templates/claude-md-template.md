# CLAUDE.md — {{PROJECT_NAME}}

> 本文件由 Harness Engineering 自动生成，请根据项目实际情况调整。

## 开发约定

- 语言：{{LANGUAGE}} / 框架：{{FRAMEWORK}} / 构建：{{BUILD_TOOL}}
- 遵循项目编码规范（见 `docs/DESIGN.md`）
- 模块结构见 `AGENTS.md`，架构见 `ARCHITECTURE.md`

## 索引加载策略

- 始终加载：CLAUDE.md, README.md, AGENTS.md
- 按需加载：ARCHITECTURE.md（架构变更）、DESIGN.md（编码规范）、INDEX.md（查找文档）、PLANS.md（规划/执行）
- 不主动加载：docs/archive/、docs/database/、docs/audits/（仅在被引用时加载）
- 超长文档：单文档 > 500 行时仅加载目录部分，按需读取具体章节

## Harness Engineering 流程规则

### 文档驱动开发

所有非平凡改动（> 单行修复）必须遵循六阶段流程：

1. **目录索引** — 按需加载项目文档
2. **沟通计划** — 拆分子计划，注册到 PLANS.md
3. **执行计划** — 按 exec-plan 编码
4. **验证计划** — Linter + 编译 + 测试
5. **完成计划** — 确认 + 提交
6. **文档更新/归档** — 更新索引 + 归档 + 推送

### PLANS.md 状态

| 状态 | 含义 |
|------|------|
| Planned | 已登记待执行 |
| In Progress | 正在执行 |
| Verifying | 验证中 |
| Completed | 已完成 |
| Blocked | 阻塞，需人工干预 |

### 文档时间戳规则

所有 `docs/` 下的文档新增或更新时，必须在文件头部标注时间：

```
> 创建: yyyy-MM-dd HH:mm:ss | 更新: yyyy-MM-dd HH:mm:ss
```

### 完成后必须检查

每次代码变更完成后，检查并更新受影响的文档：
- 新增/修改了 API？→ 更新 ARCHITECTURE.md
- 新增/修改了编码约定？→ 更新 DESIGN.md
- 新增了业务模块？→ 更新 AGENTS.md + ARCHITECTURE.md
- 完成了一个计划？→ PLANS.md 标记完成
- 新增了文档文件？→ 更新 INDEX.md
