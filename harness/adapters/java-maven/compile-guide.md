# 编译命令标准化指南

本文档提供 Harness Engineering 流程中标准化的编译、依赖验证和类结构查看命令。

---

## 标准编译命令

### 全量编译

```bash
mvn compile -e 2>&1 | tee /tmp/compile.log | grep -E "^\[ERROR\]|error:|cannot find"
```

### 单模块编译（推荐）

```bash
mvn compile -pl <module> -am -e 2>&1 | tee /tmp/compile.log | grep -E "^\[ERROR\]|error:|cannot find"
```

参数说明：
- `-pl <module>`：指定编译模块
- `-am`：同时编译依赖模块
- `-e`：显示完整错误堆栈
- `2>&1`：合并标准错误到标准输出
- `tee /tmp/compile.log`：同时输出到终端和日志文件
- `grep -E`：过滤出关键错误信息

### 增量编译（仅编译变更模块）

```bash
mvn compile -pl <module> -e 2>&1 | tee /tmp/compile.log | grep -E "^\[ERROR\]|error:|cannot find"
```

### 编译结果判断

```bash
# 检查退出码
echo $?  # 0=成功，1=失败
```

### 提取编译错误详情

```bash
grep -B2 -A2 "error:" /tmp/compile.log
```

---

## 依赖版本确认命令

### 查看依赖树（含版本）

```bash
mvn dependency:tree -pl <module> 2>&1 | grep -E "<groupId>|<artifactId>"
```

### 按 groupId 过滤依赖

```bash
mvn dependency:tree -pl <module> -Dincludes=<groupId> 2>&1
```

### 查看实际解析的版本（检查版本冲突）

```bash
mvn dependency:tree -pl <module> -Dverbose 2>&1 | grep -i "omitted\|conflict"
```

---

## 外部类结构查看命令

### 使用 javap 查看类公共 API

```bash
javap -cp <jar-path> <类全名>
```

### 使用 javap 查看类完整结构（含私有成员）

```bash
javap -p -cp <jar-path> <类全名>
```

### 在 JAR 中搜索类

```bash
jar tf <jar-path> | grep -i "<关键词>"
```

### 定位 JAR 路径

```bash
# 方法1：从 Maven 本地仓库定位
mvn dependency:tree -pl <module> -Dincludes=<groupId> 2>&1 | grep <artifactId>

# 方法2：直接搜索本地仓库
find ~/.m2/repository/<groupId-path> -name "*.jar" -type f
```

---

## 三步法：依赖验证标准流程

### 步骤1：定位 JAR 路径

```bash
mvn dependency:tree -pl <module> -Dincludes=<groupId>
```

从输出中获取 artifactId 和版本号，推算本地仓库路径：
`~/.m2/repository/<groupId-path>/<artifactId>/<version>/<artifactId>-<version>.jar`

### 步骤2：搜索类全名（避免猜测）

```bash
jar tf <jar-path> | grep -i "<关键词>"
```

**禁止猜测类名**，必须通过搜索确认。

### 步骤3：确认类结构

优先使用 maven-source-viewer Skill（保留注释），备选 javap：

```bash
javap -p -cp <jar-path> <类全名>
```

---

## 常见问题对照表

| 问题 | 命令 | 说明 |
|------|------|------|
| 编译错误定位 | `mvn compile -pl <module> -am -e 2>&1 \| tee /tmp/compile.log \| grep -E "error:"` | 过滤关键错误 |
| 类找不到 | `jar tf <jar-path> \| grep -i "<关键词>"` | 搜索类全名 |
| 版本冲突 | `mvn dependency:tree -pl <module> -Dverbose \| grep "omitted"` | 查看被忽略的版本 |
| 方法签名确认 | `javap -p -cp <jar-path> <类全名>` | 查看完整类结构 |
| 依赖未引入 | `mvn dependency:tree -pl <module> -Dincludes=<groupId>` | 确认依赖是否存在 |
