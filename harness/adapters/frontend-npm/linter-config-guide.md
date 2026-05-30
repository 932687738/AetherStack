# 前端 Linter 配置与命令参考

## Linter 工具链

### ESLint - 代码质量检查

```bash
# 检查所有文件
npx eslint .

# 检查特定目录
npx eslint src/

# 检查并自动修复
npx eslint . --fix

# 严格模式：0 warning 允许
npx eslint . --max-warnings=0
```

### Prettier - 代码格式化

```bash
# 检查格式问题
npx prettier --check .

# 自动格式化
npx prettier --write .

# 检查特定文件类型
npx prettier --check "src/**/*.{ts,tsx,css}"
```

### Stylelint - 样式检查

```bash
# 检查样式文件
npx stylelint "src/**/*.css" "src/**/*.scss"

# 自动修复
npx stylelint "src/**/*.css" --fix
```

### TypeScript 编译器检查

```bash
# 类型检查
npx tsc --noEmit
```

---

## 组合命令（三步验证第一步）

```bash
# Linter 全量检查：ESLint + Prettier
npx eslint . --max-warnings=0 && npx prettier --check .
```

---

## 配置文件位置

| 文件 | 说明 |
|------|------|
| `.eslintrc.*` / `eslint.config.*` | ESLint 规则配置 |
| `.prettierrc` / `prettier.config.*` | Prettier 格式化配置 |
| `.stylelintrc.*` | Stylelint 样式检查配置 |
| `tsconfig.json` | TypeScript 编译配置 |

---

## 常见 ESLint 错误修复表

| 错误规则 | 说明 | 修复 |
|---------|------|------|
| `no-unused-vars` | 未使用的变量 | 移除变量或添加 `_` 前缀 |
| `no-explicit-any` | 使用了 any 类型 | 替换为具体类型或 unknown |
| `react-hooks/exhaustive-deps` | Hook 依赖不完整 | 补充依赖数组 |
| `react-hooks/rules-of-hooks` | Hook 调用规则违反 | 将 Hook 移到组件顶层 |
| `no-console` | console 调用 | 移除或替换为 logger |
| `prefer-const` | 可用 const 的地方用了 let | 改为 const |
| `no-shadow` | 变量名遮蔽外层作用域 | 重命名内层变量 |
| `@typescript-eslint/no-non-null-assertion` | 非空断言 `!` | 添加空值检查 |

---

## 常见 Prettier 错误修复

运行 `npx prettier --write .` 可自动修复所有格式问题。

常见不一致：
- 缩进：2 空格 vs 4 空格
- 引号：单引号 vs 双引号
- 行尾分号：有 vs 无
- 行宽：80 vs 100 字符
- 尾逗号：有 vs 无

---

## 常见 TypeScript 错误修复表

| 错误 | 说明 | 修复 |
|------|------|------|
| `TS2322` | 类型不匹配 | 检查赋值类型 |
| `TS2339` | 属性不存在 | 检查接口定义或类型守卫 |
| `TS2345` | 参数类型错误 | 修正参数类型 |
| `TS2307` | 模块未找到 | 安装依赖或检查路径 |
| `TS2769` | 函数重载不匹配 | 检查函数签名 |
| `TS2571` | 对象可能为 unknown | 添加类型收窄 |
