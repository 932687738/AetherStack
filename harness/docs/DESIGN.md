# Harness 设计文档

## 系统上下文

AetherStack Monorepo 整合四类来源：

- OpenSpec（qwmsspec）→ 规范层
- Harness（harness-engineering-open）→ AI 工程流程
- backend（ai）→ Spring AI Agent Hub
- frontend（ai_react）→ Nebula Desk

## 关键决策

| 决策 | 选择 | 原因 |
|------|------|------|
| 配置源 | `.aetherstack/` 单一源 | 三工具规则一致 |
| Harness 部署 | 项目内 vendoring | 不依赖 ~/.claude |
| 迁移 | 仅复制 | 源项目保持独立 |
| 工单 | 可选 | 降低 OpenSpec 门槛 |
| CI | GitHub Actions + 开关 | 可选启用 |

## 架构引用

- [ARCHITECTURE.md](../../ARCHITECTURE.md)
- [openspec/references/architecture.md](../../openspec/references/architecture.md)

## 接口契约

- [openspec/references/integration-contracts.md](../../openspec/references/integration-contracts.md)

## 非功能性

- 治理层离线可用
- 前后端开发必须启动
- verify 与 CI 命令对齐
