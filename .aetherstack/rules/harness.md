# Harness 工程实践规则

## 定位

Harness 是 **AI 驱动开发流程**（项目内 `harness/`），不是 CI 替代品。CI 由 `.github/workflows/` 提供（Step 3，可配置开关）。

## 六阶段（概要）

1. 索引 — 读 `CLAUDE.md` / `AGENTS.md` / `harness/harness.config.yaml`
2. 计划 — `harness/docs/PLANS.md` 或 `docs/plans/`
3. 执行 — hev-coder 或人工实现
4. 验证 — linter → compile → test（见 `harness/adapters/`）
5. 完成 — 摘要与文档更新
6. 归档 — `docs/archive/`

## Agent 分工

| Agent | 文件 | 职责 |
|-------|------|------|
| hev-analyzer | `harness/agents/hev-analyzer.md` | 接口与依赖分析 |
| hev-coder | `harness/agents/hev-coder.md` | 编码实现 |
| hev-verifier | `harness/agents/hev-verifier.md` | 验证与修复 |

## 本地验证

```bash
make verify
# 或 .aetherstack/scripts/verify-all.sh
```

## 配置

- 项目配置：`harness/harness.config.yaml`
- Java 适配器：`harness/adapters/java-maven/`
- 前端适配器：`harness/adapters/frontend-npm/`
