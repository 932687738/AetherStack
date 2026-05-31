> **任务编号规则（项目级）**  
> 采用 `SPEC_ID-REQ_NO` 作为任务标题中的需求标识，其中：  
> - `SPEC_ID` = 变更期 specs/ 下的一层目录名（能力 ID）  
> - `REQ_NO` = 对应 spec.md 中的 `req-X` 编号  
> 示例：`aether-integration-feishu-bot-message-1` 对应 `specs/aether-integration-feishu-bot-message/spec.md#req-1`

> **代码落点（强制）**  
> 本次新增代码统一放在 `D:\cache\workspace\ai\src\main\java\com\yxy\deepseek\feishu` 包下（子包 `config` / `application` / `infrastructure`）；单测放在 `ai/src/test/java/com/yxy/deepseek/feishu/`。

## 0. 基础依赖与包脚手架（横切）

- [ ] 0.1 后端（ai）：引入飞书 SDK 并创建 `feishu` 包结构  
  - **依赖**：无  
  - **可验证输出**：`pom.xml` 新增 `com.larksuite.oapi:oapi-sdk`（Maven Central 最新稳定版）；目录存在 `feishu/config`、`feishu/application`、`feishu/infrastructure`；`mvn -q -DskipTests compile` 通过。

## 1. 飞书应用凭证通过外部配置注入（aether-integration-feishu-bot-message-1）

- [ ] 1.1 后端（ai / feishu）：实现配置属性与条件装配  
  - **依赖**：0.1  
  - **可验证输出**：`FeishuProperties`（`prefix=feishu`，含 `enabled`/`appId`/`appSecret`/`isCredentialsPresent()`）；`FeishuIntegrationConfig` 启用 `@ConfigurationProperties`；`application-knowledge.yml` 追加占位项 `${FEISHU_ENABLED:false}` / `${FEISHU_APP_ID:}` / `${FEISHU_APP_SECRET:}`，**不含真实 Secret**；`enabled=false` 时不注册长连接 Bean。
- [ ] 1.2 前端（ai_react）：无变更  
  - **依赖**：无  
  - **可验证输出**：N/A。
- [ ] 1.3 测试任务（待 test-cases Reviewed 后补充）
- [ ] 1.4 单测：`FeishuPropertiesTest`（AUTO-UT）  
  - **依赖**：1.1  
  - **可验证输出**：覆盖凭证完整/缺失、`enabled=false` 等判定；`mvn -Dtest=FeishuPropertiesTest test` 通过。
- [ ] 1.5 执行测试命令（AUTO-UT）  
  - **依赖**：1.4  
  - **可验证输出**：`mvn -Dtest=FeishuPropertiesTest test` 退出码 0。
- [ ] 1.6 人工验证（MANUAL）：凭证缺失与开关关闭  
  - **依赖**：1.1  
  - **可验证输出**：`feishu.enabled=false` 启动无飞书 ERROR；`enabled=true` 且 Secret 为空时 WARN「credentials missing」且应用正常 Running。

## 2. 应用启动时建立飞书长连接（aether-integration-feishu-bot-message-2）

- [ ] 2.1 后端（ai / feishu）：实现长连接生命周期  
  - **依赖**：1.1  
  - **可验证输出**：`FeishuLongConnectionLifecycle`（`ApplicationRunner` + `DisposableBean`）在凭证完整时构建 `EventDispatcher.newBuilder("", "")` 与 `Client.Builder(appId, appSecret).eventHandler(...).build()` 并 `start()`；启动成功日志 `feishu long connection started appId=...`；`start()` 异常 catch 后 ERROR 且不阻断 Spring Boot；`@PreDestroy` 调用 `client.stop()`（以 SDK API 为准）。
- [ ] 2.2 前端（ai_react）：无变更  
  - **依赖**：无  
  - **可验证输出**：N/A。
- [ ] 2.3 测试任务（待 test-cases Reviewed 后补充）
- [ ] 2.4 单测：长连接条件装配（AUTO-UT，可选）  
  - **依赖**：2.1  
  - **可验证输出**：`@SpringBootTest` 或切片测试验证 `feishu.enabled=false` 时不创建 `FeishuLongConnectionLifecycle` Bean；或 Mock `Client` 验证 `start()` 失败时不抛到主线程。
- [ ] 2.5 执行测试命令（AUTO-UT）  
  - **依赖**：2.4（若跳过 2.4 则标注 N/A）  
  - **可验证输出**：对应 `mvn -Dtest=... test` 通过或记录「2.4 跳过」。
- [ ] 2.6 人工验证（MANUAL）：飞书后台长连接联调  
  - **依赖**：2.1、1.1  
  - **可验证输出**：本地设置 `FEISHU_ENABLED=true` 与有效凭证后启动；飞书开发者后台事件订阅选择「长连接」并保存 `im.message.receive_v1`；日志出现连接成功；断网后恢复可再次收消息（UC-01/UC-07）。

## 3. 长连接断线后自动重连（aether-integration-feishu-bot-message-3）

- [ ] 3.1 后端（ai / feishu）：确认 SDK 重连行为并补充可观测日志  
  - **依赖**：2.1  
  - **可验证输出**：文档或代码注释说明重连由 `oapi-sdk` 内置；若 SDK 暴露连接状态回调则挂钩并输出 `feishu connection disconnected` / `reconnected` 类日志；handler 内异常不导致进程退出。
- [ ] 3.2 前端（ai_react）：无变更  
  - **依赖**：无  
  - **可验证输出**：N/A。
- [ ] 3.3 测试任务（待 test-cases Reviewed 后补充）
- [ ] 3.4 单测：无（重连依赖 SDK 与网络，AUTO-UT 不适用）  
  - **依赖**：3.1  
  - **可验证输出**：N/A，见 3.6 MANUAL。
- [ ] 3.5 执行测试命令  
  - **依赖**：3.4  
  - **可验证输出**：N/A。
- [ ] 3.6 人工验证（MANUAL）：断线重连  
  - **依赖**：2.6  
  - **可验证输出**：运行中短暂断网或重启飞书侧连接；观察断线/重连日志；恢复后发送消息仍可收到日志（UC-03 场景）。

## 4. 收到飞书机器人消息后输出结构化日志（aether-integration-feishu-bot-message-4）

- [ ] 4.1 后端（ai / feishu）：实现消息日志应用服务  
  - **依赖**：2.1  
  - **可验证输出**：`FeishuBotMessageApplicationService.logIncomingMessage(P2MessageReceiveV1)` 输出字段 `eventType`、`messageId`、`senderId`、`chatId`、`msgType`、`textPreview`（文本截断 500 字符）；非 text 类型不抛异常；**不**调用 Agent Hub / LLM / 回复 API。
- [ ] 4.2 前端（ai_react）：无变更  
  - **依赖**：无  
  - **可验证输出**：N/A。
- [ ] 4.3 测试任务（待 test-cases Reviewed 后补充）
- [ ] 4.4 单测：`FeishuBotMessageApplicationServiceTest`（AUTO-UT）  
  - **依赖**：4.1  
  - **可验证输出**：Mock/构造 `P2MessageReceiveV1` 覆盖 text / 非 text / 群聊字段解析；`mvn -Dtest=FeishuBotMessageApplicationServiceTest test` 通过。
- [ ] 4.5 执行测试命令（AUTO-UT）  
  - **依赖**：4.4  
  - **可验证输出**：`mvn -Dtest=FeishuBotMessageApplicationServiceTest test` 退出码 0。
- [ ] 4.6 人工验证（MANUAL）：单聊/群聊/非文本消息  
  - **依赖**：2.6、4.1  
  - **可验证输出**：私聊文本、群 @ 文本、图片各发一条；日志字段符合 UC-02/03/04；无自动回复。

## 5. 飞书集成可观测性且日志不含敏感凭证（aether-integration-feishu-bot-message-5）

- [ ] 5.1 后端（ai / feishu）：统一日志规范与安全审查  
  - **依赖**：2.1、4.1  
  - **可验证输出**：飞书相关日志使用稳定前缀/关键字（如 `feishu`）；全链路不打印 `appSecret`；异常栈不包含 Secret；MVP 确认无消息转发至 `agents` 包。
- [ ] 5.2 前端（ai_react）：无变更  
  - **依赖**：无  
  - **可验证输出**：N/A。
- [ ] 5.3 测试任务（待 test-cases Reviewed 后补充）
- [ ] 5.4 单测：日志不含 Secret（AUTO-UT，可选）  
  - **依赖**：5.1  
  - **可验证输出**：断言 `FeishuProperties.toString()` 或日志 appender 输出不含 secret 明文（若实现 `@ToString.Exclude` 等）。
- [ ] 5.5 执行测试命令（AUTO-UT）  
  - **依赖**：5.4（若跳过则 N/A）  
  - **可验证输出**：对应 test 通过或 N/A。
- [ ] 5.6 人工验证（MANUAL）：日志 grep 验收  
  - **依赖**：5.1、4.6  
  - **可验证输出**：grep 应用日志无 `app-secret` / Secret 明文；生命周期与消息日志均可检索（UC-08）。

## 6. 编译与验证（横切）

- [ ] 6.1 后端全量编译与单测  
  - **依赖**：1.4、4.4（及已实现的 2.4/5.4）  
  - **可验证输出**：`mvn -Dtest=FeishuPropertiesTest,FeishuBotMessageApplicationServiceTest test` 通过；或 `mvn test` 无回归失败。

---

**并行建议**
- 0.1 → 1.1 → 2.1 → 4.1 串行为主路径
- 1.4 可与 2.1 并行（Properties 单测不依赖 Client）
- 4.4 在 4.1 完成后即可编写
- 2.6 / 3.6 / 4.6 / 5.6 为 MANUAL，需飞书后台与有效凭证，可合并一次联调会话

**apply 准入**：0.1～6.1 开发任务完成后即可进入实现；测试占位项 1.3/2.3/3.3/4.3/5.3 待 `test-cases.md` Status=Reviewed 后回填（本变更 `aiTddMode: disabled`，无 AUTO-AI-UT）。
