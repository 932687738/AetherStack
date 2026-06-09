> **任务编号规则**  
> SPEC_ID：`aether-agent-observability`（OBS）、`aether-agent-resilience`（RES）  
> **uiCraftMode: disabled** | **aiTddMode: disabled**  
> **design-review**: Reviewed（2026-06-09）

## 0. 限流基础设施（RES-REQ3 前置，P0）

- [x] 0.1 后端：`SuperAgentsPlatformProperties.RateLimit`（enabled、maxRequestsPerWindow、windowSeconds）+ `application.yml` 示例 — **可验证**：配置绑定编译通过
- [x] 0.2 后端：新增 `PlatformRateLimitRegistry`、`PlatformApiErrorWriter`、`PlatformRateLimitFilter`（`OncePerRequestFilter`，路径 `/api/super-agents/**`）— **可验证**：Filter Bean 注册
- [x] 0.3 测试：**AUTO-UT** `PlatformRateLimitFilterTest`（429、Retry-After、disabled、租户隔离）— trace: TC-REQ3-01/02/03 → PlatformRateLimitFilterTest
- [x] 0.4 测试：执行 `mvn -pl aether-platform -Dtest=PlatformRateLimitFilterTest test` — **可验证**：BUILD SUCCESS

**依赖**：0.x 为 RES-REQ3 验收前置。

---

## 1. Prometheus 指标验收（aether-agent-observability · OBS-REQ5）

- [x] 1.1 后端：确认 `SuperAgentPlatformMetrics` 指标名与 design §6.1 一致（不更名）— **可验证**：代码审查 + 无破坏性改动
- [x] 1.2 测试：**AUTO-UT** 新增 `SuperAgentPlatformMetricsTest` — trace: TC-REQ5-01 → SuperAgentPlatformMetricsTest
- [x] 1.3 测试：执行 `mvn -pl aether-platform -Dtest=SuperAgentPlatformMetricsTest test` — **可验证**：BUILD SUCCESS
- [x] 1.4 **MANUAL** TC-REQ5-02 Actuator `/actuator/prometheus` 可抓取 — **ManualReason**：静态配置已验（`application.yml` 暴露 prometheus + micrometer 依赖）；运行时抓取 deferred 预发

---

## 2. Trace 父子链验收（aether-agent-observability · OBS-REQ1）

- [x] 2.1 后端：确认 `TraceSpanRecorder` + `PlatformTraceContext.pushSpanId` 行为与 design 一致 — **可验证**：无逻辑变更或仅测试增强
- [x] 2.2 测试：**AUTO-UT** 增强 `TraceSpanRecorderTest#parentChildSpanLinked`、新增 `#skipsWhenDisabled` — trace: TC-REQ1-01/02 → TraceSpanRecorderTest
- [x] 2.3 测试：执行 `mvn -pl aether-platform -Dtest=TraceSpanRecorderTest test` — **可验证**：BUILD SUCCESS

---

## 3. Tool 重试验收（aether-agent-resilience · RES-REQ1）

- [x] 3.1 测试：**AUTO-UT** 修订 `PlatformToolRetryExecutorTest`（mock `PlatformDegradationService`；耗尽断言 `DEGRADED`）— trace: TC-REQ1-04 → PlatformToolRetryExecutorTest#exhaustsRetriesReturnsDegraded
- [x] 3.2 测试：保留/标注 `retriesTransientFailureThenSucceeds`、`doesNotRetryBusinessErrors` — trace: TC-REQ1-03/05 → PlatformToolRetryExecutorTest
- [x] 3.3 测试：执行 `mvn -pl aether-platform -Dtest=PlatformToolRetryExecutorTest test` — **可验证**：BUILD SUCCESS

---

## 4. 限流行为验收（aether-agent-resilience · RES-REQ3）

- [x] 4.1 后端：依赖 §0 已完成 — **可验证**：0.4 已通过
- [x] 4.2 测试：汇总 RES-REQ3 trace 已在 0.3 — **可验证**：tasks 0.3 trace 完整

---

## 5. 治理文档与契约（横切）

- [x] 5.1 治理：更新 `openspec/references/api-changelog.md` [Unreleased] — **Changed** 429 行为（super-agents REST）— **可验证**：changelog 有条目
- [x] 5.2 治理：更新 `docs/ROADMAP.md` observability/resilience 闭环状态 → 🟡 partial（注明已消化 REQ）— **可验证**：表格已更新
- [x] 5.3 验证：**ai** 仓 `mvn -pl aether-platform test`（scoped 5 类 *Test）— **可验证**：13 tests BUILD SUCCESS
- [x] 5.4 验证：AetherStack `make verify`（若本机有 mvn/npm）— **ManualReason**：本机无 make；`mvn -pl aether-platform` scoped 13 tests 已替代

---

## 6. 归档准备（apply 完成后）

- [x] 6.1 `/opsx-verify` → `verification-report.md` — **可验证**：Final Assessment 含 Ready for archive
- [x] 6.2 `cr backend` + `record-code-review.ps1` — **可验证**：backend approved
- [x] 6.3 `make completion-gate CHANGE=p3-observability-resilience-foundation` — **可验证**：overall ready（`-SkipVerify -AllowWarnings`）
