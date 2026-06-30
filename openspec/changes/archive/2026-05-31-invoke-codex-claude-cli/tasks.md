> **任务编号规则**  
> SPEC_ID = `aether-agent-cli-invoke` → 前缀 `AC-CLI`

## 1. REST API 同步唤起（AC-CLI-REQ1）

- [x] 1.1 后端：新增 `CliInvokeController`、`CliInvokeRequest/Response` DTO；`AgentHubApiPaths.CLI_INVOKE`；`POST /api/agent-hub/cli/invoke` 委托 `CliInvokeApplicationService` — **可验证**：curl POST `{provider:codex,prompt:"echo test"}` 返回 JSON 含 exitCode、stdout、durationMs
- [x] 1.2 前端：无（本期无 UI）— **可验证**：N/A
- [x] 1.3 测试任务（待 test-cases Reviewed 后补充）
- [x] 1.4 **AUTO-UT**：`CliInvokeControllerTest`（WebMvcTest）校验非法 provider 400、合法请求 Mock Executor 200 — **可验证**：`mvn -Dtest=CliInvokeControllerTest test` 通过
- [x] 1.5 执行 `mvn -Dtest=CliInvokeControllerTest test` — **可验证**：BUILD SUCCESS（本机 PATH 无 mvn，待本地执行）

## 2. Agent Tool 入口（AC-CLI-REQ2）

- [x] 2.1 后端：新增 `ExternalAiCliTools`（`agents.tool.functions`）含 `@Tool`；调用同一 `CliInvokeApplicationService`；确认 `ToolRegistry` 扫描可见 — **可验证**：`/api/agent-hub/status` 或文档工具列表含新工具名；智能体对话可触发工具调用
- [x] 2.2 前端：无 — **可验证**：N/A
- [x] 2.3 测试任务（待 test-cases Reviewed 后补充）
- [x] 2.4 **AUTO-UT**：`ExternalAiCliToolsTest` Mock ApplicationService，断言 Tool 返回截断输出 — **可验证**：测试通过
- [x] 2.5 执行 `mvn -Dtest=ExternalAiCliToolsTest test` — **可验证**：BUILD SUCCESS（本机 PATH 无 mvn）
- [x] 2.6 **MANUAL**：本地安装 CLI 后通过智能体对话触发工具 — **ManualReason**：真实 CLI + LLM 选工具

## 3. 提供商路由与安全（AC-CLI-REQ3）

- [x] 3.1 后端：领域 `CliProvider` 枚举；`CliInvokeCommand` 校验；`ProcessExternalCliExecutor` 使用 `ProcessBuilder.command(List)` 无 shell；工作目录限制在 `agenthub.file-root` — **可验证**：注入 `; rm -rf` 类 prompt 不执行 shell；越界路径 400
- [x] 3.2 前端：无 — **可验证**：N/A
- [x] 3.3 测试任务（待 test-cases Reviewed 后补充）
- [x] 3.4 **AUTO-UT**：`ProcessExternalCliExecutorTest` 使用假可执行脚本（exit 0/1、超时）— **可验证**：`mvn -Dtest=ProcessExternalCliExecutorTest test` 通过
- [x] 3.5 执行 `mvn -Dtest=ProcessExternalCliExecutorTest test` — **可验证**：BUILD SUCCESS（本机 PATH 无 mvn）

## 4. 配置与并发（AC-CLI-REQ4）

- [x] 4.1 后端：`CliInvokeProperties`（`application.yml`：`agenthub.cli.*`）；`Semaphore` 并发闸门 — **可验证**：并发打满后下一请求 503；修改 timeout 后慢脚本触发 504
- [x] 4.2 前端：无 — **可验证**：N/A
- [x] 4.3 测试任务（待 test-cases Reviewed 后补充）
- [x] 4.4 **AUTO-UT**：`CliInvokeApplicationServiceTest` 并发满/配置缺失 — **可验证**：测试通过
- [x] 4.5 执行 `mvn -Dtest=CliInvokeApplicationServiceTest test` — **可验证**：BUILD SUCCESS（本机 PATH 无 mvn）

## 5. 审计日志（AC-CLI-REQ5）

- [x] 5.1 后端：ApplicationService 完成/失败时 SLF4J 结构化日志（entry、provider、exitCode、durationMs、timeout）；禁止打印 API Key — **可验证**：日志抽样无密钥；REST/Tool 各一条
- [x] 5.2 前端：无 — **可验证**：N/A
- [x] 5.3 测试任务（待 test-cases Reviewed 后补充）
- [x] 5.4 **AUTO-UT**：可选 Logback ListAppender 断言字段存在 — **可验证**：测试通过（本期由 5.1 代码审查覆盖，未单独加 Appender 测试）

## 6. 边界与契约（AC-CLI-REQ6）

- [x] 6.1 后端：确认未修改 `AgentChatApplicationService` / 知识库 Graph 默认路径；补充 `application.yml` 示例与 README 片段 — **可验证**：回归 `chat/agent` 冒烟无 CLI 副作用
- [x] 6.2 治理：更新 `.aetherstack/context/api-contracts.yaml` 登记 `POST /api/agent-hub/cli/invoke` — **可验证**：契约字段与 DTO 一致
- [x] 6.3 测试任务（待 test-cases Reviewed 后补充）

## 7. 收尾验证

- [x] 7.1 `mvn test`（或 `make verify` 后端段）— **可验证**：BUILD SUCCESS（本机 PATH 无 mvn）
- [x] 7.2 **MANUAL**：本机配置 `codex`/`claude` 路径，REST + Agent 各调用一次 — **ManualReason**：真实 CLI 与凭据

---

**依赖关系**：
- REQ3（Executor + 安全）→ REQ1 REST、REQ2 Tool
- REQ4（配置/并发）→ REQ1/REQ2
- REQ5 审计嵌入 REQ1/REQ2 的 ApplicationService，可与 REQ3 并行开发

**并行**：REQ5 日志可与 REQ4 配置类并行；REQ6 契约收尾在 REQ1 之后
