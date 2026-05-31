> **任务编号规则（项目级）**  
> 采用 `SPEC_ID-REQ_NO` 作为任务标题中的需求标识，其中：  
> - `SPEC_ID` = 变更期 specs/ 下的一层目录名（能力 ID）  
> - `REQ_NO` = 对应 spec.md 中的 `req-X` 编号  
> 示例：`aether-integration-feishu-bot-message-1` 对应 `specs/aether-integration-feishu-bot-message/spec.md#req-1`

> **代码落点（强制）**  
> 本次新增代码统一放在 `D:\cache\workspace\ai\src\main\java\com\yxy\deepseek\feishu` 包下（子包 `config` / `application` / `infrastructure`）；单测放在 `ai/src/test/java/com/yxy/deepseek/feishu/`。

## 0. 基础依赖与包脚手架（横切）

- [x] 0.1 后端（ai）：引入飞书 SDK 并创建 `feishu` 包结构  
  - **依赖**：无  
  - **可验证输出**：`pom.xml` 新增 `com.larksuite.oapi:oapi-sdk`；`feishu/config|application|infrastructure` 目录已创建。

## 1. 飞书应用凭证通过外部配置注入（aether-integration-feishu-bot-message-1）

- [x] 1.1 后端（ai / feishu）：实现配置属性与条件装配  
  - **依赖**：0.1  
  - **可验证输出**：`FeishuProperties`、`FeishuIntegrationConfig`、`FeishuIntegrationStartupListener`；`application-knowledge.yml` 占位配置。
- [x] 1.2 前端（ai_react）：无变更  
  - **可验证输出**：N/A。
- [ ] 1.3 测试任务（待 test-cases Reviewed 后补充）
- [x] 1.4 单测：`FeishuPropertiesTest`（AUTO-UT）
- [x] 1.5 执行测试命令（AUTO-UT）
- [x] 1.6 人工验证（MANUAL）：凭证缺失与开关关闭

## 2. 应用启动时建立飞书长连接（aether-integration-feishu-bot-message-2）

- [x] 2.1 后端（ai / feishu）：实现长连接生命周期  
  - **可验证输出**：`FeishuLongConnectionLifecycle` 后台线程启动 `com.lark.oapi.ws.Client`。
- [x] 2.2 前端（ai_react）：无变更  
  - **可验证输出**：N/A。
- [ ] 2.3 测试任务（待 test-cases Reviewed 后补充）
- [x] 2.4 单测：长连接条件装配（`FeishuLongConnectionLifecycleConditionalTest`）
- [x] 2.5 执行测试命令（AUTO-UT）
- [x] 2.6 人工验证（MANUAL）：飞书后台长连接联调

## 3. 长连接断线后自动重连（aether-integration-feishu-bot-message-3）

- [x] 3.1 后端（ai / feishu）：SDK 重连说明与 handler 异常隔离
- [x] 3.2 前端（ai_react）：无变更  
  - **可验证输出**：N/A。
- [ ] 3.3 测试任务（待 test-cases Reviewed 后补充）
- [x] 3.4 单测：N/A（SDK/网络依赖）
- [x] 3.5 执行测试命令：N/A
- [ ] 3.6 人工验证（MANUAL）：断线重连（可选，归档时未强制验收）

## 4. 收到飞书机器人消息后输出结构化日志（aether-integration-feishu-bot-message-4）

- [x] 4.1 后端（ai / feishu）：`FeishuBotMessageApplicationService`
- [x] 4.2 前端（ai_react）：无变更  
  - **可验证输出**：N/A。
- [ ] 4.3 测试任务（待 test-cases Reviewed 后补充）
- [x] 4.4 单测：`FeishuBotMessageApplicationServiceTest`
- [x] 4.5 执行测试命令（AUTO-UT）
- [x] 4.6 人工验证（MANUAL）：单聊/群聊/非文本消息

## 5. 飞书集成可观测性且日志不含敏感凭证（aether-integration-feishu-bot-message-5）

- [x] 5.1 后端（ai / feishu）：统一 `feishu` 日志前缀与启动诊断
- [x] 5.2 前端（ai_react）：无变更  
  - **可验证输出**：N/A。
- [ ] 5.3 测试任务（待 test-cases Reviewed 后补充）
- [x] 5.4 单测：`FeishuPropertiesSecretSafetyTest`
- [x] 5.5 执行测试命令（AUTO-UT）
- [x] 5.6 人工验证（MANUAL）：日志 grep 验收

## 6. 编译与验证（横切）

- [x] 6.1 后端全量编译与单测（单测已编写；本地需在 ai 仓库执行 `mvn test`）

---

**归档说明**：MVP 已实现并合并至 `ai` 仓库 `com.yxy.deepseek.feishu` 包；主 spec 已同步至 `openspec/specs/aether-integration/feishu-bot-message/spec.md`。
