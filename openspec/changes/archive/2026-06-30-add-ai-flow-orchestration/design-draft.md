# AI 流程编排 - 整体方案

## 一、核心问题

**要解决什么问题**：当前 Agent Hub 的 AI 编排逻辑完全硬编码在 `AgentHubRouter` + `PrepareAgentChatNode` 中，新增/修改 AI 工作流需要改代码、重新部署，无法通过可视化方式灵活编排 AI 流程。

**技术挑战**：
- 需要将流程定义 DSL 适配到现有 `CompiledGraph` 编排体系（Spring AI Alibaba Graph）
- 前端画布组件需要与后端流程引擎实时联动（调试运行、节点高亮、日志推送）
- 流程引擎需要与现有 Agent Hub 路由层（`AgentChatApplicationService`）无缝集成，不破坏已有对话链路
- 节点类型需要支持 LLM 调用、RAG 检索、脚本执行、HTTP 请求等多种异构操作

---

## 二、整体思路

**业务场景**：
- 用户在可视化画布上拖拽节点、连线构建 AI 工作流 → 保存为流程定义 JSON
- 流程发布后，AI 应用可关联该流程 → 对话请求走流程引擎执行
- 调试模式下，用户可实时运行流程并查看每个节点的输入/输出

**技术实现思路**：
- **流程定义**：前端画布产出 JSON DSL（节点列表 + 连线列表 + 节点配置），存储到数据库
- **流程引擎**：后端将 JSON DSL 转换为 `CompiledGraph`（复用 Spring AI Alibaba Graph 框架），每个节点类型对应一个 `NodeAction`
- **前端画布**：采用 React Flow（@xyflow/react）作为画布库，轻量且社区活跃
- **调试联动**：流程执行通过 SSE 推送节点状态变更，前端实时高亮对应节点
- **应用集成**：`AgentChatApplicationService` 的 `PrepareAgentChatNode` 增加流程路由分支，若应用关联了 flowId 则直接走流程引擎

---

## 三、技术选型

| 功能场景 | 技术组件 | 使用理由 |
|---------|---------|---------|
| 前端流程画布 | React Flow (@xyflow/react) | 开源、轻量、React 原生、社区活跃、支持自定义节点 |
| 流程定义存储 | PostgreSQL JSON 列 | 流程定义结构灵活，无需独立节点表；版本快照用 JSON 字段 |
| 流程执行引擎 | Spring AI Alibaba CompiledGraph | 复用现有 Graph 框架，与 knowledgehub 保持一致的编排范式 |
| 节点执行上下文 | `OverAllState` 扩展 | 复用 Graph State 机制，节点间数据传递 |
| 调试实时推送 | SSE (Server-Sent Events) | 与现有聊天 SSE 保持一致，前端 EventSource 消费 |
| 脚本节点沙箱 | Groovy Sandbox（或 Nashorn） | Java 生态内安全执行用户脚本，可控超时 |
| HTTP 请求节点 | Spring `RestClient` | 与现有 Spring Boot 技术栈一致 |

---

## 四、影响范围

### 系统间影响
- 无外部系统影响（纯内部新增能力）

### 模块改动
- **agent-hub**（`ai/.../agents/flow/`）：新增流程引擎子包，包含流程定义、执行器、节点类型
- **agent-hub**（`ai/.../agents/graph/chat/PrepareAgentChatNode.java`）：增加流程路由分支判断
- **agent-hub**（`ai/.../agents/application/AgentChatApplicationService.java`）：新增流程执行 SSE 入口
- **platform-persistence**：新增 Flyway 迁移脚本（流程定义表）
- **ai_react**（前端）：新增流程设计器页面、流程管理页面

### 接口变更
- 新增：`POST /api/agent-hub/flow` — 创建流程
- 新增：`GET /api/agent-hub/flow/list` — 流程列表
- 新增：`PUT /api/agent-hub/flow/{id}` — 更新流程定义
- 新增：`DELETE /api/agent-hub/flow/{id}` — 删除流程
- 新增：`POST /api/agent-hub/flow/{id}/publish` — 发布流程
- 新增：`POST /api/agent-hub/flow/{id}/invoke` — 同步调用流程
- 新增：`POST /api/agent-hub/flow/{id}/stream` — SSE 流式调用流程
- 新增：`POST /api/agent-hub/flow/{id}/debug` — 调试运行（SSE，含节点级进度）
- 修改：应用配置 API 增加 `flowId` 字段

---

## 五、数据设计

### 数据模型关系
- `ai_flow` 1:N `ai_flow_version`（一个流程多个版本）
- `ai_flow` N:1 `ai_app`（多个应用可关联同一流程，但当前设计一个应用只关联一个流程）

### 表结构要点
```sql
-- 新增表：ai_flow（流程定义）
-- 核心字段：id, name, description, status(draft/published/disabled), current_version, 
--           definition(jsonb), created_by, create_time, updated_by, update_time, deleted
-- 索引：idx_status, idx_create_time

-- 新增表：ai_flow_version（流程版本快照）
-- 核心字段：id, flow_id, version_no, definition(jsonb), published_by, publish_time, remark
-- 索引：idx_flow_id_version

-- 新增表：ai_flow_execution（流程执行记录）
-- 核心字段：id, flow_id, flow_version, trigger_type(api/app/mcp/debug), status, 
--           input_params(jsonb), output_result(jsonb), node_logs(jsonb), 
--           duration_ms, token_usage, create_time
-- 索引：idx_flow_id, idx_create_time

-- 修改表：ai_app（假设已有应用表）
-- 新增字段：flow_id（关联 ai_flow.id，可选）
```

---

## 六、约束与风险

### 技术约束
- 性能：单次流程执行超时默认 120s，节点级超时 30s（脚本节点）/ 60s（LLM 节点）
- 业务：单个流程节点数上限 50 个；版本数不限制但定期归档
- 技术：流程定义 JSON 需校验 DAG 无环；执行上下文大小限制 1MB

### 风险点

| 风险 | 应对措施 |
|------|---------|
| CompiledGraph 动态构建的性能开销 | 流程发布时预编译 Graph 并缓存；版本变更时刷新缓存 |
| 脚本节点安全性（恶意代码） | Groovy Sandbox 白名单限制可用类；禁止 System/Runtime 调用；强制超时 |
| 前端画布库升级兼容性 | 锁定 React Flow 大版本；流程定义 DSL 与画布组件解耦（中间转换层） |
| 流程引擎与现有路由层冲突 | 流程路由优先级高于 AgentHubRouter，但仅在 flowId 非空时生效；互不干扰 |

---

## 七、待 AI 细化

- [ ] 完整 DDL（字段类型、长度、索引）
- [ ] 接口详细设计（请求/响应 JSON）
- [ ] 流程定义 JSON DSL 详细规范
- [ ] 节点执行器接口设计
- [ ] CompiledGraph 动态构建适配器设计
- [ ] 前端画布组件结构设计
- [ ] 错误码清单
- [ ] 时序图（调试运行、应用对话走流程）
- [ ] 测试用例
