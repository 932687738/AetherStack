# 通用代码规范

本文档定义快速开发模式 V2 的通用代码规范，涵盖命名、实体类、异常处理、日志监控等。

---

## 命名规范

| 类型 | 规范 | 示例 |
|------|------|------|
| 类名 | 大驼峰 | `UserService`、`OrderDTO`、`OrderStatusEnum` |
| 方法名 | 小驼峰 | `getUserById()`、`processOrder()` |
| 变量名 | 小驼峰，有语义 | `userList`、`orderId`、`orderCount` |
| 常量 | 全大写下划线 | `MAX_RETRY_COUNT`、`DEFAULT_PAGE_SIZE` |
| 包名 | 全小写 | `com.example.service` |

---

## 实体类规范

### DTO/Entity 类

```java
/**
 * 用户信息DTO
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserDTO {
    /** 用户ID */
    private Long id;

    /** 用户名称 */
    private String name;

    /** 用户状态 */
    private Integer status;
}
```

**要点**：
- 使用 lombok 注解：`@Data`、`@NoArgsConstructor`、`@AllArgsConstructor`、`@Builder`
- 每个字段添加 JavaDoc 注释
- 字段使用包装类（Long 而非 long）
- JSON 字段使用 `@JsonProperty` 注解

### 枚举类

```java
/**
 * 订单状态枚举
 */
public enum OrderStatus {
    /** 待支付 */
    PENDING(1, "待支付"),
    /** 已支付 */
    PAID(2, "已支付"),
    /** 已取消 */
    CANCELLED(3, "已取消");

    private final int code;
    private final String desc;

    OrderStatus(int code, String desc) {
        this.code = code;
        this.desc = desc;
    }

    public int getCode() { return code; }
    public String getDesc() { return desc; }
}
```

---

## 空值检查

### 方法入参检查

```java
public void process(OrderDTO order) {
    // 使用 Objects.requireNonNull
    Objects.requireNonNull(order, "order cannot be null");
    Objects.requireNonNull(order.getId(), "orderId cannot be null");

    // 或使用条件判断
    if (order == null || order.getId() == null) {
        log.warn("订单信息为空");
        return;
    }
}
```

### 集合操作前检查

```java
// 使用 CollectionUtils
if (CollectionUtils.isNotEmpty(list)) {
    for (Item item : list) {
        // 处理
    }
}

// 使用 StringUtils
if (StringUtils.isNotBlank(str)) {
    // 处理
}
```

### RPC 返回值逐层判空

```java
// ❌ 错误：链式调用
String name = userService.getUser(userId).getName();

// ✅ 正确：逐层判空
User user = userService.getUser(userId);
String name = user != null ? user.getName() : null;

// ✅ 正确：使用 Optional
String name = Optional.ofNullable(userService.getUser(userId))
    .map(User::getName)
    .orElse(null);
```

---

## 异常处理

### Service 层异常处理模板

```java
public Result<Order> createOrder(OrderRequest request) {
    long start = System.currentTimeMillis();
    try {
        Order order = orderRepository.save(request);
        return Result.success(order);
    } catch (BusinessException e) {
        log.error("创建订单失败, request=={}, error=={}", request, e.getMessage());
        MetricsUtil.recordOne(this.getClass().getSimpleName() + ".createOrder.businessError");
        return Result.fail(e.getCode(), e.getMessage());
    } catch (Exception e) {
        log.error("创建订单异常, request=={}", request, e);
        MetricsUtil.recordOne(this.getClass().getSimpleName() + ".createOrder.error");
        return Result.fail("SYSTEM_ERROR", "系统繁忙");
    } finally {
        MetricsUtil.recordQuantile(this.getClass().getSimpleName() + ".createOrder.total",
            System.currentTimeMillis() - start);
    }
}
```

**要点**：
- 区分业务异常和系统异常
- 日志包含关键业务信息（使用中文）
- 异常不会吞没堆栈信息
- 添加监控埋点

---

## 日志规范

### 日志级别

| 级别 | 使用场景 |
|------|----------|
| ERROR | 影响业务正常运行的错误，需要立即关注 |
| WARN | 潜在问题，但不影响运行 |
| INFO | 关键业务流程节点 |
| DEBUG | 调试信息 |

### 日志格式

```java
// ✅ 正确：中文 + 关键参数 + 堆栈
log.info("订单创建成功, orderId=={}, userId=={}", orderId, userId);
log.error("支付失败, orderId=={}, reason=={}", orderId, e.getMessage(), e);

// ❌ 错误：英文、无关键信息
log.info("success");
log.error("error occurred");
```

### 敏感信息脱敏

```java
// ❌ 错误：敏感信息明文
log.info("用户登录, password=={}", password);

// ✅ 正确：敏感信息脱敏
log.info("用户登录, password=={}", "***");
log.info("用户登录, phone=={}", DesensitizationUtil.phone(phone));
```

---

## 监控埋点规范

### MetricsUtil 使用规范

```java
// ✅ 正确：固定名称，可穷举
MetricsUtil.recordOne("UserService.register.success");
MetricsUtil.recordOne("OrderService.createOrder.error");
MetricsUtil.recordQuantile("OrderService.queryOrder.total", costMs);

// ❌ 错误：变量拼接，导致指标暴增
MetricsUtil.recordOne("error." + errorType);
MetricsUtil.recordOne("api." + apiName + ".count");
```

### 监控命名规范

- 格式：`类名.方法名.指标类型`
- 示例：`UserService.register.error`、`OrderService.createOrder.total`
- 必须使用驼峰命名
- 名称必须是可穷举的

---

## 安全解析

### 整数解析

```java
// ❌ 禁止：可能抛出 NumberFormatException
int value = Integer.parseInt(str);

// ✅ 正确：使用工具类
int value = NumberUtils.toInt(str, 0);
```

### 金额计算

```java
// ❌ 禁止：浮点数精度问题
double total = price * quantity;

// ✅ 正确：使用 BigDecimal
BigDecimal total = price.multiply(quantity);
// 注意：使用字符串构造
BigDecimal price = new BigDecimal("0.1");
```

---

## 事务边界

### 外部调用事务边界

```java
// ❌ 错误：外部调用在事务内
@Transactional
public void process(Order order) {
    orderRepository.save(order);
    paymentService.notify(order); // 外部调用在事务内
}

// ✅ 正确：外部调用在事务外
public void process(Order order) {
    saveOrder(order);
    paymentService.notify(order);
}

@Transactional
private void saveOrder(Order order) {
    orderRepository.save(order);
}
```

---

## 架构原则

> 完整阶梯与白名单见 **`.aetherstack/rules/implementation-discipline.md`**、`engineering-standards.md` §1.1。

### 复用现有方案

- 检查项目是否已有类似实现
- 复用现有工具类和公共方法（优先查找 util/utils 包）
- 避免重复造轮子

### 避免过度设计

- 不添加用户未明确要求的功能
- 不创建不确定会用到的抽象（**Repository/DomainService 等架构强制抽象除外**）
- 优先使用简单直接的方式实现

### Bugfix 根因

- 改 symptom 前 grep 所有 caller 与共享入口
- 优先在 domain / 共享 Service 修一次，禁止只在单路径打补丁

### 依赖新增

- 新 Maven 依赖须 OpenSpec design 说明；优先现有 starter
- 禁止为少量逻辑引入第三方库

### 删优于加

- 重构时先评估删除 legacy 分支；必须兼容时在 design 注明

### `aether-debt:` 标记

- 有意简化或已知性能上限时留 `// aether-debt: …` 注释

### 分布式场景

- 所有的项目都是基于分布式场景开发
- 注意分布式场景下的数据一致性问题
- 避免使用本地缓存（除非用户明确要求）

### Spring 框架规范

- 被 Spring 管理的类，使用 `@Autowired` 或 `@Resource` 注入时，不需要额外判空
- `@Transactional` 必须放在 public 方法上
- 避免在同一个类的内部方法调用中使用事务注解
