# Linter 配置与命令参考

## Maven 命令

### 单独执行各检查

```bash
# Checkstyle - 代码风格
mvn checkstyle:check

# SpotBugs - 缺陷检测
mvn spotbugs:check

# Spotless - 格式检查
mvn spotless:check

# Spotless - 自动修复格式
mvn spotless:apply

# JaCoCo - 覆盖率报告
mvn jacoco:report
# 报告位置: target/site/jacoco/index.html
```

### 组合命令

```bash
# 三步验证第一步：Linter 全量检查
mvn checkstyle:check spotbugs:check spotless:check

# 三步验证第二步：编译检查
mvn compile -DskipTests

# 三步验证第三步：单测 + 覆盖率
mvn test jacoco:report
```

## 配置文件位置

| 文件 | 位置 | 说明 |
|------|------|------|
| checkstyle.xml | `config/checkstyle/checkstyle.xml` | 代码风格规则 |
| checkstyle-suppressions.xml | `config/checkstyle/checkstyle-suppressions.xml` | 排除规则 |
| spotbugs-exclude.xml | `config/spotbugs/spotbugs-exclude.xml` | SpotBugs 排除 |
| .editorconfig | `.editorconfig` | 基础格式约定 |

## 常见问题排查

### Checkstyle 报错

| 错误 | 原因 | 修复 |
|------|------|------|
| LineLength | 行超150字符 | 拆行或加到 suppressions |
| MethodLength | 方法超80行 | 拆分方法 |
| AvoidStarImport | `import xxx.*` | 改为具体 import |
| CyclomaticComplexity | 圈复杂度>15 | 简化条件分支 |

### SpotBugs 报错

| 错误码 | 说明 | 修复 |
|--------|------|------|
| NP_NULL_ON_SOME_PATH | 可能空指针 | 添加 null 检查 |
| RCN_REDUNDANT_NULLCHECK | 冗余 null 检查 | 移除多余检查 |
| EI/EI2 | 暴露内部可变对象 | 返回副本 |
| DM_NUMBER_CTOR | 使用 Number 构造器 | 用 valueOf |
| RV_RETURN_VALUE_IGNORED | 忽略返回值 | 处理返回值 |

### Spotless 报错

运行 `mvn spotless:apply` 可自动修复大部分格式问题。

## JaCoCo 覆盖率阈值

当前最低覆盖率：**50%**（LINE 级别）

调整方式：修改 pom.xml 中 `jacoco-maven-plugin` 的 `<minimum>` 值。

验证覆盖率是否达标：
```bash
mvn verify
# 构建失败表示覆盖率未达标
```
