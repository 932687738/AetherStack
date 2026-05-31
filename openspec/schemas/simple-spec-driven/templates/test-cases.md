# 测试用例（simple-spec-driven）

## 0. 测试基线来源（按需）
- Source：`测试同学提供` / `AI 生成`（必填，标识用例来源）
- OpenSpec 基线：`specs/.../spec.md` + `design-lite.md`
- 外部测试基线：`无` / `<路径>`（仅在用户提供外部测试稿时填写）
- 采用方式：`仅 OpenSpec` / `以外部测试稿为主并合并 OpenSpec` / `冲突项待确认`
- Status：`Draft`（测试同学 review 并确认后改为 `Reviewed`）

## 1. 用例主体（可导入格式，必填）

# [S] 顶级模块名称
## [S] 子模块名称

### [C] 用例名称（新增用例示例）
[用例描述]
[这里填写用例描述]
[Automation]
`AUTO-UT` / `AUTO-AI-UT` / `AUTO-AI-IT` / `MANUAL`（必填；AI-TDD 开启时 L1 用 `AUTO-AI-UT`）
[ManualReason]
`仅当 Automation=MANUAL 时必填；写明不可下沉单测的具体原因`

[前置条件]
- [条件1]
- [条件2]

#### 步骤1
[步骤]

##### 预期结果
[预期结果]

### [C] 用例名称（边界或异常示例）
[用例描述]
[这里填写边界、异常、取消、非法或回归场景描述]
[Automation]
`AUTO-UT` / `AUTO-AI-UT` / `AUTO-AI-IT` / `MANUAL`（必填；AI-TDD 开启时 L1 用 `AUTO-AI-UT`）
[ManualReason]
`仅当 Automation=MANUAL 时必填；写明不可下沉单测的具体原因`

[前置条件]
- [条件]

#### 步骤1
[步骤]

##### 预期结果
[预期结果]

### [C] 用例名称（回归或扩展示例，按需）
[用例描述]
[当需求涉及筛选、导出、多端、上下游或性能时，补充回归或扩展场景]
[Automation]
`AUTO-UT` / `AUTO-AI-UT` / `AUTO-AI-IT` / `MANUAL`（必填；AI-TDD 开启时 L1 用 `AUTO-AI-UT`）
[ManualReason]
`仅当 Automation=MANUAL 时必填；写明不可下沉单测的具体原因`

[前置条件]
- [条件]

#### 步骤1
[步骤]

##### 预期结果
[预期结果]
