# 弹性与兜底（P3 验收闭环）

> 本 delta 强化 REQ-1、REQ-3 的可验证验收口径；对齐 `api-conventions.md` §5。

---

## MODIFIED Requirements

<a name="req-3"></a>
### Requirement: 3. 限流与 429 [P3]

<a name="openspec-req-3"></a>系统 SHALL 内置多维度限流（tenantId、userId、IP、API/Tool）；超阈值返回 HTTP 429，响应 body 含 `RATE_LIMIT_EXCEEDED`，Header 含 `Retry-After`（秒）；阈值须可通过配置调整。

#### 场景: 租户 QPS 超限返回 429
- **前提**：租户 A 配置 `max_requests=2/window`（测试环境）。
- **操作**：同一窗口内第 3 次调用受保护 REST 路径。
- **结果**：HTTP 429；JSON `code` 为 `RATE_LIMIT_EXCEEDED`；`Retry-After` 为正整数。

---

<a name="req-1"></a>
### Requirement: 1. Tool 失败重试与降级 [P3]

<a name="openspec-req-1"></a>系统 SHALL 对 Tool 调用失败实施指数退避重试（可配置次数）；耗尽后返回清晰 ToolResult 错误；本变更验收须包含可配置重试次数的 AUTO-UT 或集成测试。

#### 场景: 可配置重试次数耗尽
- **前提**：Tool 依赖服务持续返回 503；`maxAttempts=2`。
- **操作**：子 Agent 调用该 Tool。
- **结果**：恰好 2 次尝试后 ToolResult 含 errorCode；无未捕获异常泄漏至用户。
