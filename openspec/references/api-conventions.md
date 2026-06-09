# API 通用约定（AetherStack）

本文件为 **REST/SSE 接口的横切约定真源**，与路径白名单 [`integration-contracts.md`](integration-contracts.md)、机器可读清单 [`.aetherstack/context/api-contracts.yaml`](../../.aetherstack/context/api-contracts.yaml) 配套使用。

> **维护规则**：新增/修改/废弃 API 时，须同步更新上述三处 + [`api-changelog.md`](api-changelog.md)；若废弃还须更新 [`api-deprecations.md`](api-deprecations.md)。

---

## 1. 版本与路径前缀

| 前缀 | 用途 | 生产 |
|------|------|------|
| `/api/agent-hub/*` | Agent Hub、Knowledge Hub、会话、CLI | 是 |
| `/api/super-agents/*` | SuperAgents 平台（路由、注册表、Skill、挂起恢复） | 是 |
| `/springai/demo/*` | 教程 / Graph HIL Demo | **否**（`@Profile("demo")`） |
| `/swagger-ui.html`、`/v3/api-docs` | springdoc OpenAPI（运行时） | 开发/运维 |

- **破坏性变更**（路径删除、请求体必填字段新增、语义变更）须在 OpenSpec `proposal.md` 标注 `BREAKING`，并给出前端/集成方迁移策略。
- **非破坏性扩展**（可选字段、新 SSE 事件类型）须保证老客户端可忽略未知字段（见 [`aether-integration-chat-sse-contract`](../specs/aether-integration-chat-sse-contract/spec.md)）。

---

## 2. 认证与请求 Header

当前平台以 **Header 传递租户与运维身份**（非 JWT/OAuth2 中心网关）；生产接入方应在 API 网关层补齐统一认证后再转发下列 Header。

| Header | 必填场景 | 说明 |
|--------|----------|------|
| `X-Tenant-Id` | SuperAgents 多租户读写（推荐始终传） | 默认 `default`；见 `SUPER_AGENTS_TENANT_ID` 环境变量 |
| `X-User-Id` | 审计、成本归因（推荐） | 写入 `audit_log` / `trace_spans` |
| `X-User-Roles` | 权限切面（可选） | 逗号分隔角色名 |
| `X-Admin-Api-Key` | 平台写操作（注册 Agent、发布 Skill、关闭挂起流等） | 与配置 `aether.platform.admin-api-key` 比对；禁止硬编码 |
| `Content-Type` | POST/PUT/PATCH 含 body | `application/json`；上传为 `multipart/form-data` |
| `Accept` | SSE | `text/event-stream` |

**校验失败口径**：

| HTTP | 场景 |
|------|------|
| 401 | 缺少或无效 `X-Admin-Api-Key`（受保护写接口） |
| 403 | 租户无权访问资源 |
| 400 | 必填 Header/Body 缺失或格式错误 |

> 完整多租户强制过滤见 [`aether-platform-multi-tenant`](../specs/aether-platform-multi-tenant/spec.md)（P3）。

---

## 3. 统一错误响应

REST 接口（非 SSE 流内错误）推荐 JSON 结构：

```json
{
  "code": "RATE_LIMIT_EXCEEDED",
  "message": "请求过于频繁，请稍后重试",
  "traceId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
}
```

| HTTP | 典型 `code` | 说明 |
|------|-------------|------|
| 400 | `VALIDATION_ERROR` | 参数校验失败 |
| 401 | `UNAUTHORIZED` | 未认证 |
| 403 | `FORBIDDEN` | 无权限 |
| 404 | `NOT_FOUND` | 资源不存在 |
| 409 | `CONFLICT` | 幂等冲突或状态不允许 |
| 429 | `RATE_LIMIT_EXCEEDED` | 限流；见 §5 |
| 503 | `SERVICE_UNAVAILABLE` | 下游/LLM 不可用；Agent 层宜转为友好文案 |

- 每次请求应在日志与响应中携带 **`traceId`**（与可观测性 spec 对齐）。
- SSE 连接建立前的 HTTP 错误按上表返回；流内错误通过正文 chunk 或结构化 progress 事件传递（见 integration-contracts §4）。

---

## 4. 分页约定

列表类接口统一 query 参数：

| 参数 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `page` | int | `1` | 1-based 页码 |
| `pageSize` | int | `20` | 单页条数，上限 `100` |
| `keyword` | string | — | 可选模糊搜索 |

响应包装（推荐）：

```json
{
  "items": [],
  "page": 1,
  "pageSize": 20,
  "total": 42,
  "hasMore": true
}
```

**已采用示例**：`GET /api/super-agents/hooks/suspended`（query `page`/`pageSize`/`keyword`/`status`/`skillName`）。

---

## 5. 限流与 429

与 [`aether-agent-resilience`](../specs/aether-agent-resilience/spec.md) REQ-3 对齐。

- 维度：`tenantId`、`userId`、客户端 IP、API 路径（可配置）。
- 超限响应：**HTTP 429**，body 含 `RATE_LIMIT_EXCEEDED`；响应 Header 含 **`Retry-After`**（秒）。
- Agent/SSE 路径：可在建立连接前返回 429；已建立流内不中断，由应用层友好提示。

---

## 6. 幂等性

| 类型 | 约定 |
|------|------|
| **Tool / `@Tool`** | 须幂等或多次调用安全无害（见 `spring-ai-core-standards.md`） |
| **写 REST** | 创建类接口推荐客户端传 `Idempotency-Key`（UUID）；服务端 24h 内同 key 返回同一结果 |
| **会话消息追加** | `POST .../messages` 以 `conversationId` + 客户端 `messageId` 去重（若实现） |
| **批量删除** | `batch-delete` 以资源 ID 列表为准，重复删除视为成功 |

OpenSpec design 涉及写接口时，须在「非功能性需求」中写明幂等验收口径。

---

## 7. SSE 约定（摘要）

完整契约见 [`integration-contracts.md`](integration-contracts.md) §4 与 [`aether-integration-chat-sse-contract`](../specs/aether-integration-chat-sse-contract/spec.md)。

- `Content-Type: text/event-stream`
- 正文：纯文本 token 分片，或 `aether.platform.sse.structured-events=true` 时 JSON 行
- 增量事件：`AgentProgress`（`type=progress`）与正文可交错；老客户端忽略未知类型
- 知识库模式结束：**meta** 事件（citations、sessionId 等）

---

## 8. 废弃与 Sunset 政策

详细登记见 [`api-deprecations.md`](api-deprecations.md)。流程摘要：

```text
active → deprecated（仍可用，日志 WARN，文档标注）
      → sunset（只读或 410 Gone，响应 Header 提示替代路径）
      → removed（下一大版本删除，须 BREAKING proposal）
```

| 规则 | 说明 |
|------|------|
| 兼容期 | 非 BREAKING 废弃至少 **90 天** 或 **2 个 minor** 发布周期 |
| 文档 | `integration-contracts` 表列标注 legacy；springdoc `deprecated: true` |
| 响应 Header（推荐） | `Deprecation: true`、`Sunset: <RFC3339>`、`Link: <rel="successor">` |
| Skill 废弃 | 走 [`aether-agent-governance`](../specs/aether-agent-governance/spec.md) 状态机，与 HTTP API 登记分离 |

---

## 9. Changelog 与 OpenAPI

| 产物 | 路径 | 用途 |
|------|------|------|
| 人类 Changelog | [`api-changelog.md`](api-changelog.md) | 按版本记录 Added/Changed/Deprecated/Removed |
| 路径清单 | `api-contracts.yaml` | 脚本与 OpenSpec design 引用 |
| 运行时 OpenAPI | `GET /v3/api-docs`（**ai** 仓 springdoc） | 联调；定期导出至 `openspec/contracts/openapi.yaml`（待自动化） |

**OpenSpec apply 检查清单**（触及 API 的 task 勾选前）：

- [ ] `integration-contracts.md` 白名单已更新
- [ ] `api-contracts.yaml` 已更新
- [ ] `api-changelog.md` 已追加条目
- [ ] 若废弃 → `api-deprecations.md` 已登记 Sunset
- [ ] 前端 `ApiPaths.ts` / `services/*` 已对齐

---

## 10. 相关规范索引

- 接口白名单：[`integration-contracts.md`](integration-contracts.md)
- 弹性/限流：[`aether-agent-resilience`](../specs/aether-agent-resilience/spec.md)
- 可观测性：[`aether-agent-observability`](../specs/aether-agent-observability/spec.md)
- 多租户：[`aether-platform-multi-tenant`](../specs/aether-platform-multi-tenant/spec.md)
- 工程分层：[`engineering-standards.md`](engineering-standards.md)
