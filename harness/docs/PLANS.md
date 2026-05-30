# Harness 执行计划

> 与 OpenSpec `openspec/changes/<id>/tasks.md` 配合使用。

## 状态机

- [x] 骨架搭建（Step 2）
- [x] 集成与文档（Step 3）
- [ ] 首个 OpenSpec 变更 apply
- [ ] 验证通过（make verify）
- [ ] 归档

## 当前焦点

完善 AetherStack Monorepo 整合：OpenSpec + Harness + Superpower 已就位。

## 验证命令

```powershell
make verify
```

等价于 `harness/harness.config.yaml` 中 verify.steps。

## 子计划目录

复杂任务拆分至 `harness/docs/plans/`（按需创建）。
