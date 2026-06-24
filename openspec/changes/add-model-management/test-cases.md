# 测试用例（add-model-management）

## 0. 测试基线来源
- Source：`AI 生成`
- OpenSpec 基线：`specs/aether-agent-model-management/spec.md` + `specs/aether-agent-orchestrator/spec.md` + `design.md`
- 外部测试基线：`无`
- 采用方式：`仅 OpenSpec`
- Status：`Draft`

---

## 1. 用例主体

# [S] aether-agent-model-management

## [S] Requirement 1：模型配置 CRUD

### [C] TC-REQ1-01 创建模型配置 - 主流程
创建 DeepSeek 模型配置，验证保存成功。
[Automation]
`AUTO-AI-UT`

[前置条件]
- 系统已启动，数据库 ai_model 表为空

#### 步骤1
调用 `POST /api/agent-hub/model`，请求体：
```json
{
  "name": "DeepSeek V3",
  "provider": "DEEPSEEK",
  "modelName": "deepseek-chat",
  "apiKey": "sk-test123",
  "baseUrl": "https://api.deepseek.com",
  "taskTypes": ["AGENT_REASONING"],
  "params": { "temperature": 0.7, "maxTokens": 4096 }
}
```

##### 预期结果
- 返回 `{"code": 0, "result": {"id": "<generated-id>"}}`
- 数据库 ai_model 表新增一条记录：name=DeepSeek V3, provider=DEEPSEEK, status=inactive, activate_flag=0

#### 可观测性断言
- 接口断言：HTTP 200, code=0, result.id 非空
- 数据库断言：ai_model 表 count=1, provider=DEEPSEEK, status=inactive

---

### [C] TC-REQ1-02 创建模型配置 - 必填字段校验
缺少 modelName 时创建失败。
[Automation]
`AUTO-AI-UT`

[前置条件]
- 系统已启动

#### 步骤1
调用 `POST /api/agent-hub/model`，请求体缺少 `modelName` 字段。

##### 预期结果
- 返回 HTTP 400，错误信息包含 "modelName is required"

#### 可观测性断言
- 接口断言：HTTP 400, message 包含 modelName

---

### [C] TC-REQ1-03 模型列表查询 - 分页与筛选
[Automation]
`AUTO-AI-UT`

[前置条件]
- 数据库存在 5 条模型配置（2 个 DEEPSEEK, 2 个 OPENAI, 1 个 OLLAMA）
- 其中 3 条 status=active, 2 条 status=inactive

#### 步骤1
调用 `GET /api/agent-hub/model/list?provider=DEEPSEEK&page=1&size=10`

##### 预期结果
- 返回 2 条记录，均为 DEEPSEEK 提供商

#### 步骤2
调用 `GET /api/agent-hub/model/list?status=active&page=1&size=10`

##### 预期结果
- 返回 3 条记录，均为 active 状态

#### 可观测性断言
- 接口断言：HTTP 200, result.total 正确, result.records.size 正确

---

### [C] TC-REQ1-04 删除模型配置 - 删除非默认模型
[Automation]
`AUTO-AI-UT`

[前置条件]
- 数据库存在一条非默认模型配置（is_default=false）

#### 步骤1
调用 `DELETE /api/agent-hub/model/{id}`

##### 预期结果
- 返回 HTTP 200, code=0
- 数据库记录 deleted=1（软删除）

#### 可观测性断言
- 数据库断言：ai_model.deleted=1

---

### [C] TC-REQ1-05 删除模型配置 - 拒绝删除默认模型
[Automation]
`AUTO-AI-UT`

[前置条件]
- 数据库存在一条默认模型配置（is_default=true）

#### 步骤1
调用 `DELETE /api/agent-hub/model/{id}`

##### 预期结果
- 返回 HTTP 409 Conflict，message="Cannot delete default model"
- 数据库记录未被删除

#### 可观测性断言
- 接口断言：HTTP 409
- 数据库断言：ai_model.deleted=0

---

## [S] Requirement 2：模型测试与激活

### [C] TC-REQ2-01 测试模型连通性 - 成功
[Automation]
`AUTO-AI-IT`

[前置条件]
- 数据库存在一条模型配置（status=inactive）
- Mock 外部 API 返回正常响应（延迟 200ms）

#### 步骤1
调用 `POST /api/agent-hub/model/{id}/test`

##### 预期结果
- 返回 `{"success": true, "latencyMs": 200, "tokensUsed": 15, "errorMsg": null}`
- 数据库 test_passed=true, last_test_time 更新

#### 可观测性断言
- 接口断言：HTTP 200, success=true, latencyMs > 0
- 数据库断言：test_passed=true

---

### [C] TC-REQ2-02 测试模型连通性 - API Key 错误
[Automation]
`AUTO-AI-IT`

[前置条件]
- 数据库存在一条模型配置，apiKey 无效
- Mock 外部 API 返回 401 Unauthorized

#### 步骤1
调用 `POST /api/agent-hub/model/{id}/test`

##### 预期结果
- 返回 `{"success": false, "latencyMs": 0, "tokensUsed": 0, "errorMsg": "Invalid API key"}`

#### 可观测性断言
- 接口断言：HTTP 200, success=false, errorMsg 包含 "API key"

---

### [C] TC-REQ2-03 激活模型 - 测试通过后激活
[Automation]
`AUTO-AI-UT`

[前置条件]
- 数据库存在一条模型配置，test_passed=true, status=inactive

#### 步骤1
调用 `POST /api/agent-hub/model/{id}/activate`

##### 预期结果
- 返回 HTTP 200, code=0
- 数据库 status=active, activate_flag=1

#### 可观测性断言
- 数据库断言：status=active, activate_flag=1

---

### [C] TC-REQ2-04 激活模型 - 测试未通过时拒绝
[Automation]
`AUTO-AI-UT`

[前置条件]
- 数据库存在一条模型配置，test_passed=false

#### 步骤1
调用 `POST /api/agent-hub/model/{id}/activate`

##### 预期结果
- 返回 HTTP 400, message="Model must pass test before activation"
- 数据库 status 保持 inactive

#### 可观测性断言
- 接口断言：HTTP 400
- 数据库断言：status=inactive（未变化）

---

## [S] Requirement 3：默认模型与自动降级

### [C] TC-REQ3-01 设置默认模型
[Automation]
`AUTO-AI-UT`

[前置条件]
- 数据库存在两条已激活模型 A 和 B
- A 为当前默认模型（is_default=true）

#### 步骤1
调用 `POST /api/agent-hub/model/{B.id}/set-default`

##### 预期结果
- 返回 HTTP 200
- 数据库 A.is_default=false, B.is_default=true（全局唯一默认）

#### 可观测性断言
- 数据库断言：SELECT count(*) FROM ai_model WHERE is_default=true AND deleted=0 → 1

---

### [C] TC-REQ3-02 动态模型路由 - 命中已激活模型
[Automation]
`AUTO-AI-UT`

[前置条件]
- 数据库存在已激活模型：DEEPSEEK (AGENT_REASONING), OPENAI (INTENT_ROUTING)
- ModelConfigCache 已加载

#### 步骤1
调用 `ModelRouter.resolveModelName(ModelTaskType.AGENT_REASONING)`

##### 预期结果
- 返回 "deepseek-chat"

#### 可观测性断言
- 日志断言：包含 "model.route decision taskType=AGENT_REASONING model=deepseek-chat source=db"

---

### [C] TC-REQ3-03 动态模型路由 - 无配置时回退环境变量
[Automation]
`AUTO-AI-UT`

[前置条件]
- 数据库 ai_model 表为空
- 环境变量 DASHSCOPE_CHAT_MODEL=qwen-turbo

#### 步骤1
调用 `ModelRouter.resolveModelName(ModelTaskType.AGENT_REASONING)`

##### 预期结果
- 返回 "qwen-turbo"（环境变量兜底）

#### 可观测性断言
- 日志断言：包含 "source=default-env"

---

### [C] TC-REQ3-04 自动降级 - 主模型超时后降级到默认模型
[Automation]
`AUTO-AI-IT`

[前置条件]
- 数据库存在两个已激活模型：A（默认，正常）和 B（非默认，Mock 超时）
- B 绑定 AGENT_REASONING 任务类型

#### 步骤1
调用 `ModelRouter.completionPort(AGENT_REASONING)` 获取 ChatClient
#### 步骤2
使用该 ChatClient 调用 LLM（Mock 超时）

##### 预期结果
- 第一次调用失败（超时）
- 自动降级到默认模型 A
- 第二次调用成功，返回正常响应

#### 可观测性断言
- 日志断言：包含 "model.route fallback from=B to=A reason=timeout"
- 指标断言：aether.model.route.fallback{from="B",to="A"} 计数 +1

---

### [C] TC-REQ3-05 自动降级 - 全部模型不可用时返回明确错误
[Automation]
`AUTO-AI-IT`

[前置条件]
- 数据库存在两个已激活模型，均 Mock 为不可用

#### 步骤1
调用 LLM 完成请求

##### 预期结果
- 抛出 `ModelUnavailableException`
- 返回 HTTP 503, message="All models unavailable"

#### 可观测性断言
- 接口断言：HTTP 503
- 日志断言：包含 "All models unavailable"

---

## [S] Requirement 4：提供商适配

### [C] TC-REQ4-01 获取支持的提供商列表
[Automation]
`AUTO-AI-UT`

[前置条件]
- 系统已启动

#### 步骤1
调用 `GET /api/agent-hub/model/providers`

##### 预期结果
- 返回 5 种内置提供商：DEEPSEEK, OPENAI, DASHSCOPE, OLLAMA, CUSTOM
- 每个提供商包含 name, displayName, defaultBaseUrl

#### 可观测性断言
- 接口断言：HTTP 200, result.size=5

---

### [C] TC-REQ4-02 自定义 OpenAI 兼容提供商
[Automation]
`AUTO-AI-IT`

[前置条件]
- 创建模型配置：provider=CUSTOM, baseUrl=http://localhost:11434/v1（Ollama 本地）

#### 步骤1
调用 `POST /api/agent-hub/model/{id}/test`

##### 预期结果
- 通过 OpenAI 兼容协议调用本地 Ollama，测试成功

#### 可观测性断言
- 接口断言：HTTP 200, success=true

---

# [S] aether-agent-orchestrator（MODIFIED）

## [S] Requirement 1：模型路由动态化

### [C] TC-ORCH-01 缓存刷新 - 配置变更后路由生效
[Automation]
`AUTO-AI-UT`

[前置条件]
- 初始状态：数据库无模型配置，路由回退到环境变量
- 管理员新增并激活一个模型

#### 步骤1
调用 `POST /api/agent-hub/model/{id}/activate`
#### 步骤2
调用 `ModelRouter.resolveModelName(AGENT_REASONING)`

##### 预期结果
- 返回新激活模型的 modelName（不再回退环境变量）

#### 可观测性断言
- 日志断言：包含 "ModelConfigCache refreshed"

---

## 2. 测试覆盖矩阵

| Requirement | 用例数 | AUTO-AI-UT | AUTO-AI-IT | MANUAL |
|-------------|--------|------------|------------|--------|
| REQ1: CRUD | 5 | 5 | 0 | 0 |
| REQ2: 测试与激活 | 4 | 2 | 2 | 0 |
| REQ3: 默认与降级 | 5 | 2 | 3 | 0 |
| REQ4: 提供商适配 | 2 | 1 | 1 | 0 |
| ORCH: 路由动态化 | 1 | 1 | 0 | 0 |
| **合计** | **17** | **11** | **6** | **0** |
