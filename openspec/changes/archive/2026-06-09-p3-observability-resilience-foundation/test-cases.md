# 测试用例（standard-spec-driven）

## 0. 测试基线来源

- Source：`OpenSpec 派生（依据 spec/design，待 Reviewed）`
- OpenSpec 基线：`specs/aether-agent-observability/spec.md`、`specs/aether-agent-resilience/spec.md` + `design.md`
- 外部测试基线：无
- 采用方式：仅 OpenSpec
- Status：`Reviewed`（与 design-review 同步确认，开发自测基线）

> 说明：本变更为 P3 验收闭环，用例以 AUTO-UT 为主；Actuator 全链路可选 MANUAL。

---

## 1. 用例主体

# [S] 可观测性（observability）

## [S] Requirement 5：Prometheus 指标

### [C] TC-REQ5-01 MeterRegistry 注册聊天指标
验证 `SuperAgentPlatformMetrics` 调用后注册 `spring_ai_platform_chat_requests_total` 与 `spring_ai_platform_chat_duration_seconds`。
[Automation]
`AUTO-UT`

[前置条件]
- 使用 `SimpleMeterRegistry` 或 Mockito `MeterRegistry`

#### 步骤1
调用 `startChat("tenant-a")` 后 `recordChat(sample, "tenant-a", "success")`

##### 预期结果
- Counter `spring_ai_platform_chat_requests_total` 标签 `tenant=tenant-a` 计数 ≥ 1
- Timer `spring_ai_platform_chat_duration_seconds` 存在且 `outcome=success`

#### 可观测性断言
- 指标断言：MeterRegistry 含上述两个指标名

### [C] TC-REQ5-02 Actuator Prometheus 端点可抓取（可选联调）
[Automation]
`MANUAL`
[ManualReason]
需完整 Spring Boot 上下文 + 至少一次真实或集成触发的 chat 路径

[前置条件]
- 应用已启动；`management.endpoints.web.exposure.include` 含 `prometheus`

#### 步骤1
GET `/actuator/prometheus`，过滤 `spring_ai_platform_chat_requests_total`

##### 预期结果
- 响应 200；文本含指标名与 `tenant` 标签

#### 可观测性断言
- 接口断言：HTTP 200；body 含 `spring_ai_platform_chat_requests_total`

---

## [S] Requirement 1：全链路 Trace

### [C] TC-REQ1-01 Span 父子关系落库
验证 ROUTER 与 SUB_AGENT 连续记录时第二条 span 的 `parentSpanId` 非空且与栈一致。
[Automation]
`AUTO-UT`

[前置条件]
- `aether.platform.observability.enabled=true`
- `PlatformTraceContext.bind(traceId, tenant, conv, user)` 已执行

#### 步骤1
依次调用 `recordPrepRoute(...)` 与 `recordSubAgent("customer-service", now, "OK")`

##### 预期结果
- `TraceSpanRepository.insert` 调用 2 次
- 两条记录 `traceId` 相同
- 第二条 `parentSpanId` 非空（对应 ROUTER 层 push 后的 spanId）
- 第一条 `spanType=ROUTER`，第二条 `spanType=SUB_AGENT`

#### 可观测性断言
- 数据库断言：mock 捕获的 `TraceSpanRecord` 字段符合上述关系

### [C] TC-REQ1-02 observability 关闭时不落库
[Automation]
`AUTO-UT`

[前置条件]
- `observability.enabled=false`

#### 步骤1
调用 `recordSubAgent(...)`

##### 预期结果
- `traceSpanRepository.insert` 从未调用

---

# [S] 弹性（resilience）

## [S] Requirement 3：限流与 429

### [C] TC-REQ3-01 租户窗口内超限返回 429
[Automation]
`AUTO-UT`

[前置条件]
- `aether.platform.rate-limit.enabled=true`
- `max-requests-per-window=2`，`window-seconds=60`

#### 步骤1
对同一路径连续 3 次 MockMvc 请求，Header `X-Tenant-Id: tenant-a`

##### 预期结果
- 第 1、2 次非 429
- 第 3 次 HTTP 429
- body JSON `code=RATE_LIMIT_EXCEEDED`
- Header `Retry-After` 为正整数

#### 可观测性断言
- 接口断言：429 + `Content-Type: application/json`

### [C] TC-REQ3-02 限流关闭时不拦截
[Automation]
`AUTO-UT`

[前置条件]
- `rate-limit.enabled=false`

#### 步骤1
连续 10 次请求同租户

##### 预期结果
- 均无 429

### [C] TC-REQ3-03 不同租户独立计数
[Automation]
`AUTO-UT`

[前置条件]
- `max-requests-per-window=2`

#### 步骤1
tenant-a 发 2 次；tenant-b 发 2 次

##### 预期结果
- 均未 429；tenant-a 第 3 次才 429

---

## [S] Requirement 1：Tool 失败重试与降级

### [C] TC-REQ1-03 瞬态失败重试后成功
[Automation]
`AUTO-UT`

[前置条件]
- `maxAttempts=3`；mock `PlatformDegradationService`
- Tool 前 2 次返回 `UNAVAILABLE`，第 3 次成功

#### 步骤1
`executeWithRetry(supplier)`

##### 预期结果
- `result.isSuccess()==true`
- supplier 调用 3 次

#### 可观测性断言
- 日志断言：无未捕获异常

### [C] TC-REQ1-04 重试耗尽返回 DEGRADED
[Automation]
`AUTO-UT`

[前置条件]
- `maxAttempts=3`；`degradation-enabled=true`
- 注入 mock `PlatformDegradationService.degradedToolResult` 返回 `DEGRADED`

#### 步骤1
持续返回 `UNAVAILABLE` 的 supplier

##### 预期结果
- `errorCode=DEGRADED`（非业务堆栈泄漏）
- 尝试次数 = 3

### [C] TC-REQ1-05 业务错误不重试
[Automation]
`AUTO-UT`

[前置条件]
- Tool 返回 `FORBIDDEN`

#### 步骤1
`executeWithRetry(supplier)`

##### 预期结果
- `errorCode=FORBIDDEN`
- supplier 仅调用 1 次

---

## 2. 口径冲突清单

无（用例与 design v1.0 + design-review 修订一致）。

---

## 3. AUTO-UT 标记汇总（tasks 追溯用）

| TC | REQ | 目标测试类 |
|----|-----|------------|
| TC-REQ5-01 | observability-5 | `SuperAgentPlatformMetricsTest` |
| TC-REQ1-01 | observability-1 | `TraceSpanRecorderTest#parentChildSpanLinked` |
| TC-REQ1-02 | observability-1 | `TraceSpanRecorderTest#skipsWhenDisabled` |
| TC-REQ3-01 | resilience-3 | `PlatformRateLimitFilterTest#returns429WhenExceeded` |
| TC-REQ3-02 | resilience-3 | `PlatformRateLimitFilterTest#passesWhenDisabled` |
| TC-REQ3-03 | resilience-3 | `PlatformRateLimitFilterTest#isolatesTenants` |
| TC-REQ1-03 | resilience-1 | `PlatformToolRetryExecutorTest#retriesTransientFailureThenSucceeds` |
| TC-REQ1-04 | resilience-1 | `PlatformToolRetryExecutorTest#exhaustsRetriesReturnsDegraded` |
| TC-REQ1-05 | resilience-1 | `PlatformToolRetryExecutorTest#doesNotRetryBusinessErrors` |
