# GitHub Actions 说明

## 工作流

| 文件 | 作用 | 开关 |
|------|------|------|
| `ci.yml` | 本仓治理层：`sync-config` 生成物一致性 | `CI_ENABLED=false` 跳过 |
| `openspec-validate.yml` | OpenSpec CLI 校验 | `OPENSPEC_VALIDATE_ENABLED=false` 跳过 |
| `completion-gate.yml` | OpenSpec 变更 completion-gate（默认 SkipVerify；关联仓可用或 `COMPLETION_GATE_FULL_VERIFY=true` 时全量） | `COMPLETION_GATE_ENABLED=false` 跳过 |
| `verify-linked.yml` | 全量 `verify-all`（关联仓 mvn + harness）；workflow_dispatch / 每周 cron | `VERIFY_LINKED_ENABLED=false` 跳过 |

细则见 [harness/docs/plans/harness-phase3-ci.md](../harness/docs/plans/harness-phase3-ci.md)。

## 前后端 CI

**不在 AetherStack 仓库跑 backend/frontend 构建**（除非 `verify-linked.yml` 或 completion-gate 全量模式）。代码真源在独立仓库：

| 仓库 | 本地路径 | 建议 CI |
|------|----------|---------|
| ai | `D:\cache\workspace\ai` | `mvn test` |
| ai_react | `D:\cache\workspace\ai_react` | `node scripts/harness.mjs lint && node scripts/harness.mjs build` |

本地统一验证：

```powershell
make verify
make verify-strict   # 含 Spring AI -Strict，与 completion-gate 一致
```

环境变量可覆盖路径：`AETHER_BACKEND_REPO`、`AETHER_FRONTEND_REPO`（见 `.aetherstack/context/repos.yaml`）。

## 关闭 CI

仓库 Settings → Actions → Variables：`CI_ENABLED=false`

## 手动触发

Actions 页 Run workflow（`workflow_dispatch`）：

- **Completion Gate**：指定 `change` id；`skip_verify=false` 且关联仓可用时跑全量 verify
- **Verify Linked Repos**：全量跨仓 verify；可选 `checkout_linked` clone 关联仓
