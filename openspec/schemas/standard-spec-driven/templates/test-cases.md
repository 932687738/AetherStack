# 测试用例（standard-spec-driven）

> 用例主体需遵循 `[S]` / `[C]` Markdown 导入规则；以下模板用于约束结构与覆盖深度。

## 0. 测试基线来源（按需）
- Source：`测试同学提供` / `AI 生成`（必填，标识用例来源）
- OpenSpec 基线：`specs/.../spec.md` + `design.md`
- 外部测试基线：`无` / `<路径>`（仅在用户提供外部测试稿时填写）
- 采用方式：`仅 OpenSpec` / `以外部测试稿为主并合并 OpenSpec` / `冲突项待确认`
- Status：`Draft`（测试同学 review 并确认后改为 `Reviewed`）

## 1. 用例主体（可导入格式，必填）

# [S] 模块A
## [S] Requirement 1：名称

### [C] TC-REQ1-01 主流程
[用例描述]
[描述主流程]
[Automation]
`AUTO-UT` / `MANUAL`（必填，默认 `MANUAL`）
[ManualReason]
`仅当 Automation=MANUAL 时必填；写明不可下沉单测的具体原因`

[前置条件]
- [条件1]
- [条件2]

#### 步骤1
[步骤]

##### 预期结果
[预期结果]

#### 可观测性断言
- 接口断言：[接口/返回码/关键字段]
- 数据库断言：[表/字段变化]

### [C] TC-REQ1-02 边界或异常
[用例描述]
[描述失败或边界]
[Automation]
`AUTO-UT` / `MANUAL`（必填，默认 `MANUAL`）
[ManualReason]
`仅当 Automation=MANUAL 时必填；写明不可下沉单测的具体原因`

[前置条件]
- [条件]

#### 步骤1
[步骤]

##### 预期结果
[预期结果]

#### 可观测性断言
- 任务中心断言：[任务状态/明细]
- 日志断言：[日志事件/关键字段]

### [C] TC-REQ1-03 回归或数据校验
[用例描述]
[描述后续链路、回归或数据落点]
[Automation]
`AUTO-UT` / `MANUAL`（必填，默认 `MANUAL`）
[ManualReason]
`仅当 Automation=MANUAL 时必填；写明不可下沉单测的具体原因`

[前置条件]
- [条件]

#### 步骤1
[步骤]

##### 预期结果
[预期结果]

#### 可观测性断言
- 库存断言：[库存/凭证/状态回写]
- 外部反馈断言：[回调/消息/下游数据]
