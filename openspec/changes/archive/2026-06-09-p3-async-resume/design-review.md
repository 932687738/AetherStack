# 设计审查（design-review）

> **Schema**：`standard-spec-driven`  
> **审查方式**：设计审查（brainstorming 模式要点自检）  
> **输入**：`proposal.md`、`specs/**/spec.md`、`design.md` v1.0  
Status: Reviewed

## 审查基线

| 项 | 值 |
|----|-----|
| 变更 ID | `p3-async-resume` |
| 复杂度 | 中等 |
| 铁三角 | 不涉及 RAG/多 Agent 新增；Graph 节点仅补测 |
| 分层 | 桥接在 application；Repository 接口在 domain |

## 检查清单

| # | 检查项 | 结论 |
|---|--------|------|
| 1 | REQ-1~3 与存量代码路径一致 | ✅ `WorkflowSuspendService` / `Resume` / `Query` |
| 2 | collaboration REQ-3 有明确实现点 | ✅ `findActiveSuspendedBySession` + chat 桥接 |
| 3 | 不引入每请求 compile Graph | ✅ 复用存量 CompiledGraph Bean |
| 4 | 事务边界：resume 内先 DB 后 EventBus | ✅ 与存量 `WorkflowResumeService` 顺序一致 |
| 5 | 租户隔离：查询带 tenantId | ✅ 复用 `TenantGuard` / 显式 tenant 参数 |
| 6 | 测试可落在 aether-platform | ✅ 不依赖 deepseek 聚合 |
| 7 | 无前端 U1 范围蔓延 | ✅ uiCraftMode disabled |
| 8 | OpenAPI/契约无破坏性变更 | ✅ 行为增强 only |

## 阻塞项

无。

## 建议项（非阻塞）

1. P4：MQ 出站 Webhook 与 `PlatformEventBus.onSuspended` 实装
2. P4：双租户集成测（Testcontainers）补挂起→恢复全链路

## 审查结论

设计可进入 test-cases / tasks / apply。无阻塞项。
