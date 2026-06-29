# Harness 执行计划

> 与 OpenSpec `openspec/changes/<id>/tasks.md` 配合使用。

## 状态机

- [x] 骨架搭建（Step 2）
- [x] 集成与文档（Step 3）
- [x] `/opsx-apply` × Harness 接线（harness-apply skill）
- [ ] 首个 OpenSpec 变更 apply（端到端跑通）— **试点**：`add-app-variables`（制品已齐，待 `/opsx-apply`），见 [harness-e2e-pilot.md](plans/harness-e2e-pilot.md)
- [x] 验证通过（make verify / verify-all.ps1）— 2026-06-29 本地通过（mvn test + harness lint + build E2E 3/3）
- [ ] 归档

## 当前焦点

1. ~~验证链路已补齐~~；`verify-all.ps1` 已跑通
2. 下一步：`/opsx-apply` 实现 `add-app-variables` → completion-gate → archive

## 验证命令

```powershell
make verify
```

等价于 `harness/harness.config.yaml` 中 verify.steps。

## 子计划目录

| 子计划 | 说明 |
|--------|------|
| [plans/harness-e2e-pilot.md](plans/harness-e2e-pilot.md) | 首个 E2E 试跑清单（试点 `add-app-variables`） |
| [plans/_template.md](plans/_template.md) | 变更级进度模板 |
