# 阶段5：完成计划

## 目标

确认子计划验证通过，提交代码，更新计划状态。

## 前置条件

- 阶段4 验证全部通过（Linter + 编译 + 测试）
- PLANS.md 当前子计划状态为 Verifying

### Commit 隔离验证（MUST）

每个 SP 完成后 MUST 独立提交：

1. 验证当前 commit 仅包含当前 SP 的变更文件
2. 若混入其他 SP 文件 → MUST 拆分提交
3. commit message 格式：`feat({scope}): {SP描述}`

**验证命令**：
```bash
git diff --name-only HEAD~1  # 检查上一个 commit 包含的文件
```

**提交前 MUST 确认**：
- [ ] 变更文件均属于当前 SP
- [ ] 三步验证已通过（Linter + Compile + Test）
- [ ] exec-plan 中该步骤标记为完成

## 完成检查清单

```
1. Linter: 0 Error ✓
2. 编译: 0 Error ✓
3. 测试: 100% 通过 ✓
4. exec-plan 验证标准全部勾选 ✓（通过 Edit 将 `[ ]` 改为 `[x]`）
5. 无遗留 TODO/FIXME（如有则说明原因）✓
6. 变更文件均在 exec-plan 声明范围内 ✓
```

## 提交代码

### 提交规范

```bash
git add <变更文件列表>
git commit -m "feat: <子计划摘要> (#P1)"
```

- commit message 格式：`feat/fix/refactor/docs: <摘要> (#计划编号)`
- 变更文件列表来自 exec-plan 中声明的文件
- **需用户确认后才执行提交**（不自动提交）

### 提交时机

- 单个子计划完成后提交一次
- 不跨子计划提交
- 不在验证循环中提交（只在验证通过后提交）

## 更新 PLANS.md

将当前子计划状态从 Verifying 更新为 Completed：

```markdown
| sp1 | 用户管理CRUD | Completed | — | [方案](plans/user-mgmt/sp1-user-crud.md) | [计划](plans/user-mgmt/sp1-user-crud-exec.md) |
```

## 产出 summary

为后续子计划提供上下文，生成简要 summary（≤50行）：

```markdown
## P1 用户管理CRUD - 执行摘要

### 关键决策
- 使用 JPA Specification 实现动态查询
- 密码使用 BCrypt 加密存储

### 变更文件
- User.java, UserRepository.java, UserService.java, UserController.java

### 接口暴露
- GET /api/users, POST /api/users, PUT /api/users/{id}, DELETE /api/users/{id}

### 后续影响
- P2(角色管理) 依赖 UserService.findById()
```

## 异常处理

| 情况 | 处理 |
|------|------|
| 验证通过但有遗留 TODO | 在 summary 中记录，询问用户是否接受 |
| 变更文件超出 exec-plan 范围 | 解释原因，询问用户是否接受额外变更 |
| 用户拒绝提交 | 暂停，等待用户指示 |
