# Java/Maven 验证命令

## 三步验证

### Step 1: Linter 检查

```bash
# Checkstyle + SpotBugs + Spotless
mvn checkstyle:check spotbugs:check spotless:check
```

自动修复（仅 Spotless 格式化）：
```bash
mvn spotless:apply
```

**通过标准**：0 Error（Warning 不阻塞）

**常见错误与修复指令**：

| 错误 | 修复指令 |
|------|---------|
| Missing Javadoc | 添加 `@param`/`@return` 注释，或 `@SuppressWarnings("checkstyle:missingjavadocmethod")` |
| Import 顺序错误 | 执行 `mvn spotless:apply` 自动修复 |
| SpotBugs: EI_EXPOSE_REP2 | DTO 中可变对象返回防御性拷贝，或添加 `@SuppressFBWarnings("EI_EXPOSE_REP2")` |
| SpotBugs: RCN_REDUNDANT_NULLCHECK | try-with-resources 误报，添加 `@SuppressFBWarnings("RCN_REDUNDANT_NULLCHECK")` |
| SpotBugs: NP_NULL_ON_SOME_PATH | 添加空值检查 `if (obj != null)`，或 `Objects.requireNonNull()` |
| Line too long | 手动换行，或 `mvn spotless:apply` 自动格式化 |
| Unused import | 执行 `mvn spotless:apply` 自动删除 |
| Magic number | 提取为常量 `private static final int XXX = 123;` |
| Missing switch default | 添加 `default:` 分支或 `// no-op` 注释 |

**错误消息提炼规则**：Linter 输出超过 20 行时，hev-verifier 只提取 `[ERROR]` 行和对应修复指令，不全文灌入上下文。

### Step 2: 编译验证

```bash
mvn compile -DskipTests
```

**通过标准**：0 Error

**常见错误与修复指令**：

| 错误 | 修复指令 |
|------|---------|
| 找不到符号 (cannot find symbol) | 检查 import 语句是否缺失，类名是否拼写正确，依赖是否引入 |
| 类型不匹配 (incompatible types) | 检查泛型参数、返回值类型是否匹配，是否需要强制转换 |
| 依赖缺失 | 检查 pom.xml 是否添加依赖，执行 `mvn dependency:tree` 确认 |
| 方法签名不匹配 (@Override) | 确认接口方法签名，检查参数类型和返回值 |
| 包不存在 (package does not exist) | 检查包名拼写，确认依赖版本是否正确 |

### Step 3: 单元测试

```bash
mvn test
```

**通过标准**：100% 测试通过

**常见错误与修复指令**：

| 错误 | 修复指令 |
|------|---------|
| AssertionError | 检查测试期望值是否与实际逻辑一致，是否需要调整断言 |
| NullPointerException in test | Mock 对象返回值未设置，使用 `when().thenReturn()` 设置 |
| 测试超时 | 检查是否有阻塞调用未 Mock，添加 `@Timeout` 注解 |
| 依赖注入失败 | 检查 `@InjectMocks` 和 `@Mock` 配置是否正确 |

**测试编写规范**：
- 测试目录：`src/test/java/`
- 测试类命名：`*Test.java`
- 框架：JUnit 5 + Mockito
- 只写 Service 层单元测试
- 不写 Controller 层集成测试

## Maven 常用命令

| 命令 | 用途 |
|------|------|
| `mvn dependency:tree` | 查看依赖树（替代 scan_dependencies） |
| `mvn compile -DskipTests` | 仅编译 |
| `mvn test -pl module -Dtest=TestClass` | 运行单个测试类 |
| `mvn spotless:apply` | 自动格式化 |
| `mvn checkstyle:check` | 仅检查代码风格 |
| `mvn spotbugs:check` | 仅检查代码缺陷 |

## Linter 配置参考

### Checkstyle

配置文件：`checkstyle.xml`（项目根目录或 src/main/resources/）

关键规则：
- 行长度限制
- Javadoc 要求
- Import 顺序
- 命名规范

### SpotBugs

排除配置：`spotbugs-exclude.xml`

常见排除项：
- `EI_EXPOSE_REP2`（DTO 构造器接受可变对象）
- `RCN_REDUNDANT_NULLCHECK`（try-with-resources 误报）

### Spotless

配置在 `pom.xml` 的 `<plugins>` 中：

```xml
<plugin>
    <groupId>com.diffplug.spotless</groupId>
    <artifactId>spotless-maven-plugin</artifactId>
    <configuration>
        <java>
            <googleJavaFormat/>
            <removeUnusedImports/>
            <trimTrailingWhitespace/>
        </java>
    </configuration>
</plugin>
```
