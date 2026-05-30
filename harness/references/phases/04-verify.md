# 阶段4：验证计划

## 目标

自动验证代码质量，失败则修复再验证，循环直到通过或超限升级用户。

## 流程

```
代码变更完成
    ↓
更新 PLANS.md 状态为 Verifying
    ↓
Step 1: Linter 检查
    ↓ 通过/失败
Step 2: 编译验证
    ↓ 通过/失败
Step 3: 单元测试
    ↓ 通过/失败
    ↓
全部通过 → 阶段5
任一失败 → 修复代码 → 重新三步验证（循环 ≤ 3次）
循环超限 → 升级用户
```

## 三步验证

### Step 1: Linter 检查

| 适配器 | 命令 | 自动修复 |
|--------|------|---------|
| java-maven | `mvn checkstyle:check spotbugs:check spotless:check` | `mvn spotless:apply` |
| python-pip | `ruff check . && mypy .` | `ruff check --fix .` |
| node-npm | `npx eslint . && npx tsc --noEmit` | `npx eslint --fix .` |

**通过标准**：0 Error（Warning 不阻塞，但记录在报告中）

**失败处理**：
1. 先尝试自动修复（如 `mvn spotless:apply`）
2. 自动修复后仍有 Error → 人工修复
3. 修复后重新从 Step 1 开始验证

### Step 2: 编译验证

| 适配器 | 命令 |
|--------|------|
| java-maven | `mvn compile -DskipTests` |
| python-pip | `python -m py_compile src/` |
| node-npm | `npx tsc --noEmit` |

**通过标准**：0 Error

**失败处理**：分析编译错误，修复代码，重新从 Step 1 开始

### Step 3: 单元测试

| 适配器 | 命令 |
|--------|------|
| java-maven | `mvn test` |
| python-pip | `pytest` |
| node-npm | `npx jest` |

**通过标准**：100% 测试通过

**失败处理**：
1. 分析测试失败原因
2. 区分：代码 Bug vs 测试本身的问题
3. 修复代码或测试，重新从 Step 1 开始

## 循环保护

```
verifyLoopCount = 0

每次验证不通过:
  verifyLoopCount++
  if verifyLoopCount ≤ 3:
    修复代码 → 重新三步验证
  if verifyLoopCount > 3:
    升级用户
```

### 升级用户时输出

```markdown
## 验证循环超限（3次）

### 当前问题清单
1. [Linter] User.java:42 - 缺少 Javadoc
2. [编译] RoleService.java:15 - 找不到符号 UserRepository
3. [测试] UserServiceTest.testCreate - 断言失败

### 修复历史
- 第1次: 修复了 Javadoc 缺失，但编译仍有错误
- 第2次: 添加了 import 语句，但测试断言不匹配
- 第3次: 调整了测试数据，但仍有编译错误

### 建议
- 可能需要重新审视技术方案中的接口设计
- 建议人工检查 UserRepository 是否已在其他子计划中定义
```

## exec-plan 验证标准勾选

验证过程中，按以下规则操作 exec-plan 中的验证标准 checkbox：

### 勾选规则

| 时机 | 动作 | 格式 |
|------|------|------|
| Linter 通过（0 Error） | 勾选 "Linter 通过" | `[ ]` → `[x]` |
| 编译通过（0 Error） | 勾选 "编译通过" | `[ ]` → `[x]` |
| 单测通过（100%） | 勾选 "单测通过" | `[ ]` → `[x]` |
| 三步全部通过 | 勾选 "人工审查项"（如有） | `[ ]` → `[x]` |

### 操作方式

使用 Edit 工具修改 exec-plan 文件中的验证标准行：

```
# 勾选前
- [ ] Linter 通过（0 Error）

# 勾选后
- [x] Linter 通过（0 Error）
```

**注意**：
- 验证失败时不勾选，只在对应步骤通过时勾选
- 修复后重新验证时，如果之前已勾选的步骤需重验，先取消勾选（`[x]` → `[ ]`），通过后再勾选
- 文档更新清单的 checkbox 在阶段6归档时处理，不在验证阶段勾选

### 三步验证完成守卫（MUST）

验证三步 MUST 依次执行，MUST NOT 跳过任何步骤：

| 步骤 | 命令 | 通过条件 | 跳过条件 |
|------|------|----------|----------|
| Step 1: Linter | `mvn checkstyle:check` 或等效 | 0 Error | 项目无 Linter 配置 |
| Step 2: Compile | `mvn compile -q` | BUILD SUCCESS | 无 |
| Step 3: Test | `mvn test -pl {module}` | 0 Failure | 无 |

**跳过声明**：若 Step 1 被跳过，MUST 在验证报告中显式声明：
`[SKIP] Step 1 Linter — 原因：项目无 checkstyle 配置`

**完成声明**：三步完成后 MUST 打印：
`[VERIFY-COMPLETE] Linter={PASS|SKIP} Compile={PASS|FAIL} Test={PASS|FAIL|SKIP}`

⚠️ Step 2 或 Step 3 FAIL → 进入 hev-verifier 修复循环（最多 3 次）
⚠️ 3 次修复后仍 FAIL → MUST 标记该 SP 为 Blocked，不得标记 Completed

## 验证报告格式

验证通过时输出：

```markdown
## 验证通过 ✓

| 步骤 | 结果 | 详情 |
|------|------|------|
| Linter | ✓ | 0 Error, 2 Warning（非阻塞） |
| 编译 | ✓ | 0 Error |
| 测试 | ✓ | 8/8 通过 |

### 人工审查建议（非阻塞）
- [ ] UserService.create() 缺少幂等性保护
- [ ] 缺少分布式场景下的并发控制
```
