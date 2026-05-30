# Superpower 工作流：代码审查

> 真源：`.aetherstack/workflows/code-review.md`（由 `skills-index.yaml` 路由，勿复制到工具私有目录）

## 触发

关键词：`cr`、`code review`、`review`、`代码审查`、`发起cr`

变体：`cr backend` → 审查关联仓库 **ai**；`cr frontend` → **ai_react**。路径见 `LOCALPATH.md` / `.aetherstack/context/repos.yaml`。

## 前置

1. 读取 `LOCALPATH.md`，解析目标仓库（可用 `scripts/resolve-repos.ps1`）
2. 读取规范（按优先级）：
   - `.aetherstack/rules/core.md`（DDD、分层）
   - `openspec/references/engineering-standards.md`
   - `openspec/references/integration-contracts.md`（涉及 API 时）
3. 若用户未指定范围，基于 `git diff` 或最近变更文件审查

## 审查维度

| 维度 | 检查点 |
|------|--------|
| 分层 | Controller 不直连 Repository；领域层不依赖 Spring Web |
| 事务 | 应用层事务内不调外部 HTTP/LLM |
| 契约 | REST/SSE 路径与 integration-contracts 一致 |
| 测试 | AUTO-UT 是否有对应 `*Test.java` |
| 安全 | 无硬编码密钥；输入校验 |

## 输出格式

```markdown
## 代码审查报告

### 范围
- 仓库：<ai | ai_react>
- 分支/对比：<branch 或 diff 说明>

### 问题清单
| 严重度 | 文件 | 说明 | 建议 |
|--------|------|------|------|
| blocking | ... | ... | ... |

### 通过项
- ...

### 结论
- [ ] 可合并 / 需修改后复审
```

## 追溯

回复末尾追加：`Skills: code-review`
