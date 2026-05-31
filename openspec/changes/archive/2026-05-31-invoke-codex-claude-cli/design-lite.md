# design-lite：外部 AI CLI 唤起（Codex / Claude）

## 需求摘要

在 `ai` 仓库 Agent Hub 内新增受控 CLI 执行能力：调用方通过 **REST API** 或 **Agent Tool** 选择 `codex` / `claude` 提供商，传入提示内容，同步获得退出码与 stdout/stderr；须配置超时、沙箱工作目录、并发上限与审计日志。本期无前端 UI。

## 方案概述

| 层次 | 组件 | 职责 |
|------|------|------|
| 接口层 | `CliInvokeController` | `POST /api/agent-hub/cli/invoke`，校验 DTO，委托应用层 |
| 接口层 | `ExternalAiCliTools` | `@Tool` Bean，位于 `com.yxy.deepseek.agents.tool.functions`，由 `ToolRegistry` 自动发现 |
| 应用层 | `CliInvokeApplicationService` | 编排：校验 → 并发闸门 → 调用端口 → 审计 |
| 领域层 | `CliProvider`、`CliInvokeCommand`、`CliInvokeOutcome` | 枚举与不可变值对象；`ExternalCliExecutor` 端口（接口） |
| 基础设施层 | `ProcessExternalCliExecutor` | `ProcessBuilder` 启动配置路径，采集输出，超时杀进程 |

**关键决策**

- REST 与 Tool **共用** `CliInvokeApplicationService`，避免双份进程逻辑。
- CLI 参数由服务端模板组装（如 `claude -p "<escaped>"` / codex 等价），**禁止** `sh -c` 拼接用户原始 shell。
- 工作目录默认 `agenthub.file-root`（与 `FileTools` 同源配置），可选请求内相对子路径，解析后须在 root 下。
- 首期 **同步阻塞**；不在 SSE 主链路中穿插 CLI 流式输出。

## 阶段准入与失败口径

| 阶段 | 准入 | 失败口径 |
|------|------|----------|
| 参数校验 | provider ∈ {codex, claude}；prompt 非空、长度上限 | 400，无子进程 |
| 并发闸门 | 活跃进程 &lt; `agenthub.cli.max-concurrent` | 429/503「资源繁忙」 |
| 进程执行 | 可执行文件存在且可执行 | 502「提供商不可用」 |
| 超时 | 超过 `agenthub.cli.timeout-seconds` | 504 + 杀进程 + 审计 timeout=true |
| 成功 | exitCode 任意 | 200 + body 含 exitCode/stdout/stderr/durationMs |

## 代码改造分析（基于现状）

**现状（已核对）**

- Agent Hub REST 基路径：`AgentHubApiPaths.BASE` = `/api/agent-hub`（`agents/constants/web/AgentHubApiPaths.java`）。
- 本地 `@Tool` 由 `ToolRegistry` 扫描 `com.yxy.deepseek.agents` 包（`AgentHubScanConstants.TOOL_SCAN_BASE_PACKAGE`），示例：`FileTools`（`agents/tool/functions/FileTools.java`）。
- **尚无** `ProcessBuilder` / CLI 唤起实现（全仓检索无匹配）。
- Orchestrator 通过 `toolRegistry.externalToolCallbacksForPlan(plan)` 注入工具（`AgentChatService`）。

**拟新增（建议路径）**

```text
agents/
  application/CliInvokeApplicationService.java
  domain/cli/CliProvider.java
  domain/cli/CliInvokeCommand.java
  domain/cli/CliInvokeOutcome.java
  domain/cli/ExternalCliExecutor.java
  infrastructure/cli/ProcessExternalCliExecutor.java
  infrastructure/cli/CliInvokeProperties.java   # @ConfigurationProperties
  tool/functions/ExternalAiCliTools.java
  web/CliInvokeController.java
  web/dto/CliInvokeRequest.java / CliInvokeResponse.java
  constants/web/AgentHubApiPaths.java             # + CLI_INVOKE = BASE + "/cli/invoke"
```

**改造要点**

1. `CliInvokeProperties`：`codexExecutable`、`claudeExecutable`、`timeoutSeconds`、`maxConcurrent`、`maxOutputChars`。
2. `ProcessExternalCliExecutor`：列表形式传参给 `ProcessBuilder.command()`；`redirectErrorStream(false)`；UTF-8 读流；`Semaphore` 或 `AtomicInteger` 控制并发。
3. `ExternalAiCliTools`：一个或两个 `@Tool` 方法（或单方法 + provider 参数），内部构造 `CliInvokeCommand` 并调用 ApplicationService；返回给 LLM 的字符串需截断至 `maxOutputChars`。
4. `ToolRegistry`：无需改代码，新 Bean 在 `agents.tool.functions` 且含 `@Tool` 即可被发现；若需仅特定 SubAgent 可用，在 `OrchestrationPlan` 工具白名单配置中增加工具名（design 实施时在 `AgentChatService` / plan 配置处登记）。
5. `integration-contracts` / `api-contracts.yaml`：实施阶段补充 `POST /api/agent-hub/cli/invoke`。

## 影响范围

| 类型 | 范围 |
|------|------|
| 模块 | `ai` → `com.yxy.deepseek.agents`（+ 可选 `agents.constants`） |
| 接口 | 新增 REST；Agent Tool schema 增加 |
| 数据 | 无新表；审计走应用日志 |
| 依赖 | 无新 Maven 依赖（JDK `ProcessBuilder`） |
| 部署 | 主机/容器须安装 CLI + 凭据；配置可执行路径 |

## 核心场景（正常 / 边界 / 异常）

1. **正常**：REST `codex` + 合法 prompt → 200 + exitCode 0。
2. **正常**：Agent 调用 `invokeExternalAiCli`（工具名以实施为准）→ 返回截断输出供模型继续。
3. **边界**：stdout 超长 → 响应与 Tool 返回均截断并标记 `truncated=true`。
4. **边界**：exitCode ≠ 0 但进程正常结束 → 仍 200，body 带非零 exitCode（业务上视为 CLI 业务失败，非 HTTP 5xx）。
5. **异常**：provider 非法 → 400。
6. **异常**：CLI 未配置 → 502。
7. **异常**：超时 → 504，进程已终止。
8. **异常**：并发满 → 503。

## 外部系统改造点

无 OMS/ERP/EDI。外部依赖为本机 **Codex CLI**、**Claude CLI** 及各自厂商认证环境变量（由运维注入，不写死在代码）。

## 可观测性清单

| 信号 | 内容 |
|------|------|
| 应用日志 | provider、entry=REST\|TOOL、exitCode、durationMs、timeout、truncated |
| 指标（可选） | `agenthub_cli_invoke_total{provider,result}` |
| 接口返回 | 统一错误码文案（校验/不可用/超时/繁忙） |

## 数据落点清单

无持久化业务表；审计仅日志。无库存/凭证变更。

## 非功能性需求

| 项 | 口径 |
|----|------|
| 并发与幂等 | 并发由配置上限硬限制；同一 prompt 重复调用 **不** 保证幂等（CLI 副作用由厂商定义），文档注明 |
| 性能 | 默认超时建议 120s；单请求同步阻塞，不宜作为高 QPS 接口 |
| 安全 | 禁止任意 shell；沙箱目录；日志脱敏凭据 |

## 七、前端 UI 界面清单

无（`uiCraftMode: disabled`）。
