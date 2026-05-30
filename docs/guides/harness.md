# Harness 使用指南

Harness 是 **AI 驱动开发操作系统**（项目内 vendoring），与 GitHub Actions CI 互补。

## 1. 核心文件

| 路径 | 说明 |
|------|------|
| `harness/harness.config.yaml` | 验证命令、Agent、文档路径 |
| `harness/agents/hev-analyzer.md` | 技术分析 |
| `harness/agents/hev-coder.md` | 编码实现 |
| `harness/agents/hev-verifier.md` | 验证修复 |
| `harness/references/phases/` | 六阶段细则 |
| `harness/docs/PLANS.md` | 当前计划 |

## 2. 六阶段

```mermaid
flowchart LR
    P1[1 索引] --> P2[2 计划]
    P2 --> P3[3 执行]
    P3 --> P4[4 验证]
    P4 --> P5[5 完成]
    P5 --> P6[6 归档]
```

| 阶段 | 读什么 | 产出 |
|------|--------|------|
| 索引 | CLAUDE.md、AGENTS.md、harness.config | 上下文就绪 |
| 计划 | openspec tasks、PLANS.md | 子计划 |
| 执行 | hev-coder | 代码变更 |
| 验证 | hev-verifier、make verify | 测试通过 |
| 完成 | 文档更新 | 摘要 |
| 归档 | docs/archive/ | 历史留存 |

## 3. 验证命令（与 CI 一致）

```yaml
# harness/harness.config.yaml
verify:
  steps:
    - command: "cd backend && mvn -B test"
    - command: "cd frontend && npm run lint"
    - command: "cd frontend && npm run build"
```

本地一键：`make verify`

## 4. Claude Code 示例

```
1. 读 CLAUDE.md → AGENTS.md → harness/harness.config.yaml
2. 读 openspec/changes/xxx/tasks.md
3. 按 hev-analyzer 分析 backend 影响范围
4. 按 hev-coder 实现
5. 按 hev-verifier 运行 make verify
6. 更新 harness/docs/PLANS.md 勾选状态
```

## 5. 与 OpenSpec 协作

- OpenSpec 提供 **tasks.md**（做什么）
- Harness 提供 **怎么做 + 怎么验**
- apply 阶段：先满足 OpenSpec 准入，再跑 Harness verify

## 6. 适配器

- Java：`harness/adapters/java-maven/`
- 前端：`harness/adapters/frontend-npm/`
