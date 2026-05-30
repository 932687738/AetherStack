# 前端编译与依赖验证指南

本文档提供前端项目的编译、类型检查和依赖验证标准化命令。

---

## TypeScript 类型检查

### 全量类型检查

```bash
npx tsc --noEmit
```

### 监视模式（开发时使用）

```bash
npx tsc --noEmit --watch
```

### 检查结果判断

```bash
echo $?  # 0=成功，非0=有类型错误
```

---

## 构建命令

### 开发构建

```bash
npm run dev
# 或
yarn dev
```

### 生产构建

```bash
npm run build
# 或
yarn build
```

### 构建结果检查

```bash
# 构建成功 + 无 TypeScript 错误
npm run build && echo "BUILD SUCCESS"
```

---

## 依赖验证

### 检查依赖安装状态

```bash
npm ls
# 或检查特定包
npm ls <package-name>
```

### 依赖验证三步法

#### 步骤1：确认依赖已安装

```bash
npm ls <package-name>
```

如果显示 `UNMET DEPENDENCY` 或空，执行安装：

```bash
npm install <package-name>
```

#### 步骤2：确认类型定义可用

```bash
# 检查是否有 @types 包
npm ls @types/<package-name>

# 安装类型定义
npm install -D @types/<package-name>
```

#### 步骤3：确认版本兼容

```bash
# 查看已安装版本
npm ls <package-name> --depth=0

# 查看过期包
npm outdated
```

---

## 常见编译问题对照表

| 问题 | 命令 | 说明 |
|------|------|------|
| TypeScript 错误 | `npx tsc --noEmit` | 查看完整类型错误 |
| 构建失败 | `npm run build` | 查看构建错误详情 |
| 依赖缺失 | `npm ls` | 检查缺失的依赖 |
| 版本冲突 | `npm ls <package>` | 检查重复版本 |
| 类型定义缺失 | `npm ls @types/<pkg>` | 检查类型定义 |
| 包大小分析 | `npx webpack-bundle-analyzer` | 分析打包体积 |

---

## 三步验证标准流程

### 步骤1：Linter 检查

```bash
npx eslint . --max-warnings=0
npx prettier --check .
```

### 步骤2：类型检查 + 构建

```bash
npx tsc --noEmit && npm run build
```

### 步骤3：单测

```bash
npx vitest run
```
