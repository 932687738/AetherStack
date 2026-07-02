# Harness 执行计划

> 与 OpenSpec `openspec/changes/<id>/tasks.md` 配合使用。

## 状态机

- [x] 骨架搭建（Step 2）
- [x] 集成与文档（Step 3）
- [x] `/opsx-apply` × Harness 接线（harness-apply skill）
- [x] Mode B 文档对齐（OpenSpec apply 兼岗 hev-*；前端 harness.mjs 真源）
- [x] verify-all Spring AI `-Strict` + `make doctor` + 追溯校验增强
- [x] 首个 OpenSpec 变更 apply（端到端跑通）— **试点**：`add-app-variables`（已 apply + gate），见 [harness-e2e-pilot.md](plans/harness-e2e-pilot.md)
- [x] 验证通过（make verify / verify-all.ps1）— 2026-06-29 本地通过（mvn test + harness lint + build E2E 3/3）
- [x] 归档 — `add-app-variables` → `openspec/changes/archive/2026-06-29-add-app-variables/`

## 当前焦点

1. ~~验证链路已补齐~~；`verify-all.ps1` 已跑通；Spring AI 检查默认 `-Strict`
2. ~~试点 `add-app-variables`~~ 已归档
3. **待办**：自托管 CI 全量 verify、active 变更推进至 tasks

## Maven 解析

Agent/Cursor 终端若 PATH 含未展开的 `%MAVEN_HOME%`，`verify-all.ps1` 会通过 `resolve-mvn.ps1` 读取用户级 `MAVEN_HOME` 或 ai 仓 `mvnw.cmd`。

```powershell
make doctor
powershell -File .aetherstack/scripts/doctor.ps1 -SkipVerifySmoke
```

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
