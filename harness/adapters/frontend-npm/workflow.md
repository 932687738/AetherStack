# Harness Engineering 前端工作流状态机与子 Agent 调度规范

## 状态转换图

```
INIT ──→ REQUIREMENT_DONE ──→ ANALYSIS_DONE ──→ CODING_DONE ──→ VERIFY_DONE ──→ COMPLETED
   │         (需求确认)          (方案确认)         (代码实现)      (三步验证)      (完成)
   │                                                ↑              │
   │                                                │   未通过      │
   │                                                └── (fix) ←────┘
   │                                                loop ≤ 3: 回 CODING_DONE
   │                                                loop > 3: ESCALATE
   │
   └─ Bug场景 → CODING_DONE (跳过分析)
   └─ CRUD场景 → ANALYSIS_DONE (简化分析)
```

## 状态转换表

| 当前状态 | 触发条件 | 下一动作 | 交互点 |
|---------|---------|---------|--------|
| INIT | 场景判断+需求确认 | AskUserQuestion 确认需求 | 需要时 |
| REQUIREMENT_DONE | 调度 hev-analyzer | 分析功能点+数据源 | — |
| ANALYSIS_DONE | 展示方案 | AskUserQuestion 确认方案 | 是 |
| PLAN_CONFIRMED | 调度 hev-coder | 代码实现 | — |
| CODING_DONE | 调度 hev-verifier | 三步验证 | — |
| VERIFY_DONE (通过) | 展示验证报告 | AskUserQuestion 确认完成 | 是 |
| VERIFY_DONE (未通过, loop≤3) | 生成问题清单，调度 hev-coder | 修复代码 | — |
| VERIFY_DONE (未通过, loop>3) | 输出问题清单+修复历史 | AskUserQuestion 人工决策 | 是 |

## 子 Agent 调度规范

### hev-analyzer（分析 Agent）

**触发状态**：REQUIREMENT_DONE

**工具**：Read, Grep, Glob, Explore

**职责**：
1. 分解需求为原子条件（boolean 可判定）
2. 定位每个条件的数据源和获取方式
3. 验证数据源可用性（API端点、Store定义、路由配置）
4. 输出条件-数据源映射表 + 组件结构 + 实现文件清单

**Prompt 模板**：
```
分析技术方案，需求：{需求摘要}
场景类型：{CRUD/Bug/新功能/重构}
遵循 references/tech-design-principles_frontend.md 的条件-数据源映射法。
输出格式见 references/tech-design-template_frontend.md。
```

### hev-coder（代码生成+修复 Agent）

**触发状态**：PLAN_CONFIRMED（首次）/ VERIFY_FAILED（修复）

**工具**：Read, Edit, Write, Grep, Glob, Bash

**职责**：
- 首次：按技术方案实现代码
- 修复：根据 verifier 问题清单修复代码

**Prompt 模板（首次）**：
```
按技术方案实现代码。
方案：{技术方案摘要}
涉及文件：{文件清单}
编码规范见 references/code-patterns_frontend.md。
反模式警告见 references/common-mistakes_frontend.md。
```

**Prompt 模板（修复）**：
```
修复验证问题，问题清单：
{分类问题清单}
修复流程见 references/fix-guide.md。
```

### hev-verifier（验证 Agent）

**触发状态**：CODING_DONE

**工具**：Read, Edit, Write, Grep, Glob, Bash

**职责**：三步验证

**三步验证流程**：
1. **Linter 检查**：
   ```bash
   npx eslint . --max-warnings=0 && npx prettier --check .
   ```
   任一失败 → 生成 Linter 问题清单

2. **类型检查 + 构建**：
   ```bash
   npx tsc --noEmit && npm run build
   ```
   失败 → 生成类型/构建错误清单

3. **单测验证**：
   - 为变更的组件/Hook 编写单元测试
   - 运行 `npx vitest run`
   - 失败 → 生成测试失败清单

**Prompt 模板**：
```
验证代码质量，变更文件：{文件清单}
执行三步验证：
1. Linter: npx eslint . --max-warnings=0 && npx prettier --check .
2. 类型+构建: npx tsc --noEmit && npm run build
3. 单测: 为变更的组件/Hook 编写单元测试 + npx vitest run
Linter 配置见 references/linter-config-guide_frontend.md。
单测模板见 references/test-templates_frontend.md。
人工审查项见 references/manual-review-checklist.md。
```

## 循环保护机制

- 单一循环计数器 `verifyLoopCount`，初始值 0
- 每次 verifier 返回未通过 → `verifyLoopCount++`
- `verifyLoopCount ≤ 3`：调度 hev-coder 修复，回 CODING_DONE
- `verifyLoopCount > 3`：进入 ESCALATE

## 场景自动跳过

| 场景 | 关键词 | 流程调整 |
|------|--------|---------|
| CRUD | "增加/查询/修改/删除/CRUD" | 简化技术分析，跳过条件-数据源映射 |
| Bug修复 | "修复/bug/异常/报错/崩溃" | 跳过分析，直入 coder |
| 重构 | "重构/优化/整理" | 正常流程 |
| 新功能 | 其他 | 正常流程 |

## 绝对禁止

1. 主 Agent 不写业务代码（只调度）
2. 不猜测 API 字段名（必须查看接口文档或已有代码）
3. 不自动 git commit（用户确认后操作）

## 必须遵守

1. 类型检查必须在 Linter 之后、单测之前
2. 单测只写 Hook/工具函数 + 组件测试
3. 修复只改问题清单中的问题，不做额外重构
4. 每次修复后必须重新走完整三步验证
5. 问题清单必须按优先级分类（P0 Linter/类型 > P1 测试 > P2 建议）
6. 人工审查项作为 SUGGESTION 输出，不阻塞提交
