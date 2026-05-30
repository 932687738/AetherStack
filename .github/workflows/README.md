# GitHub Actions 说明

## 工作流

| 文件 | 作用 | 开关 |
|------|------|------|
| `ci.yml` | 本仓治理层：`sync-config` 生成物一致性 | `CI_ENABLED=false` 跳过 |
| `openspec-validate.yml` | OpenSpec CLI 校验 | `OPENSPEC_VALIDATE_ENABLED=false` 跳过 |

## 前后端 CI

**不在 AetherStack 仓库跑 backend/frontend 构建。** 代码真源在独立仓库：

| 仓库 | 本地路径 | 建议 CI |
|------|----------|---------|
| ai | `D:\cache\workspace\ai` | `mvn test` |
| ai_react | `D:\cache\workspace\ai_react` | `npm run lint && npm run build` |

本地统一验证：`make verify`（在关联路径执行上述命令）。

## 关闭 CI

仓库 Settings → Actions → Variables：`CI_ENABLED=false`

## 手动触发

Actions 页 Run workflow（`workflow_dispatch`）
