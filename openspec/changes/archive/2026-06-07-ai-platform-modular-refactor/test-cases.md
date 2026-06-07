# 测试用例（standard-spec-driven）

## 0. 测试基线来源

- Source：`AI 生成`
- OpenSpec 基线：`specs/aether-platform-modular-structure/spec.md` + `design.md`
- 外部测试基线：`docs/重构方案-合并版.md` §8 验收标准
- 采用方式：`仅 OpenSpec`
- Status：`Reviewed`

## 1. 用例主体

# [S] aether-platform-modular-structure

## [S] Requirement 1：消灭知识库代码重复

### [C] TC-REQ1-01 staged 副本回滚
[用例描述]
验证 agents.knowledgehub staged 全量副本已回滚，无 Bean 重复定义风险
[Automation]
`MANUAL`
[ManualReason]
需 Git 索引与 Spring 启动上下文联合确认，无法纯单测覆盖

[前置条件]
- 执行阶段 0 回滚命令

#### 步骤1
检查 Git：`git status` 无 `agents/knowledgehub` staged 新增；启动应用无 `BeanDefinitionOverrideException`

##### 预期结果
应用正常启动；知识库相关 Bean 仅 knowledge-hub 模块注册

---

## [S] Requirement 2：Repository 依赖倒置

### [C] TC-REQ2-01 接口注入编译与 CRUD
[用例描述]
KnowledgeBaseRepository 等领域接口可被应用层注入，CRUD 行为不变
[Automation]
`AUTO-UT`

[前置条件]
- knowledge-hub domain 接口 + infrastructure MyBatis 实现就位

#### 步骤1
运行 `KnowledgeBaseRepositoryTest`（或等价）验证 save/find/delete

##### 预期结果
测试通过；应用层仅依赖 interface 类型

---

## [S] Requirement 3：Flyway 按域归属

### [C] TC-REQ3-01 全新库迁移
[用例描述]
空 PostgreSQL 实例执行 flyway migrate，脚本顺序与结果与单模块时期一致
[Automation]
`MANUAL`
[ManualReason]
需真实 PostgreSQL + Flyway 多 classpath locations 集成环境

[前置条件]
- Flyway 脚本已按 design §3.7 分配到三模块

#### 步骤1
`mvn -pl application spring-boot:run` 或 Testcontainers 触发 migrate

##### 预期结果
`flyway_schema_history` 记录完整；核心表存在且无重复 version

---

## [S] Requirement 4：横切基础模块

### [C] TC-REQ4-01 子模块独立编译
[用例描述]
common、ai-core、vector-store-api 等横切模块 `-pl` 编译通过
[Automation]
`MANUAL`
[ManualReason]
Maven 多模块编译为构建级验证

[前置条件]
- 阶段 1 各子模块 pom 就位

#### 步骤1
根目录 `mvn clean compile -pl common,ai-core,vector-store-api -am`

##### 预期结果
BUILD SUCCESS

---

## [S] Requirement 5：AI 框架与 learning 隔离

### [C] TC-REQ5-01 业务模块不依赖 learning
[用例描述]
dependency:tree 无 knowledge-hub/agent-hub/aether-platform → learning 边
[Automation]
`MANUAL`
[ManualReason]
Maven dependency:tree 构建分析

[前置条件]
- 阶段 2 完成

#### 步骤1
`mvn dependency:tree -pl knowledge-hub,agent-hub,aether-platform`

##### 预期结果
输出中无 `learning` 依赖

### [C] TC-REQ5-02 Graph 基类单点维护
[用例描述]
ai-alibaba 模块包含 AbstractKnowledgeGraphNode，knowledge-hub Graph 节点可编译注入
[Automation]
`AUTO-UT`

[前置条件]
- ai-alibaba 提取完成

#### 步骤1
Graph 配置类或节点 Bean 上下文测试加载

##### 预期结果
Graph 相关 Bean 注册成功

---

## [S] Requirement 6：三大业务域模块化

### [C] TC-REQ6-01 防腐 Port 跨域调用
[用例描述]
agent-hub 通过 KnowledgeRetrievalPort 检索，不直接依赖 knowledge-hub infrastructure
[Automation]
`AUTO-AI-UT`

[前置条件]
- agent-hub Adapter + knowledge-hub Port 实现就位

#### 步骤1
Mock Port 注入 AgentChat 或 Retriever 适配器单测

##### 预期结果
Adapter 调用 Port 方法；无 illegal cross-module import（可由 archunit 或静态检查补充）

### [C] TC-REQ6-02 知识库 E2E
[用例描述]
文档上传 + 问答 API 端到端
[Automation]
`MANUAL`
[ManualReason]
需完整 Spring 上下文 + PostgreSQL + pgvector + LLM Mock 或测试环境

[前置条件]
- knowledge-hub 模块提取完成

#### 步骤1
调用上传 API 后调用问答 API

##### 预期结果
返回结构与模块化前一致；检索命中正常

---

## [S] Requirement 7：application 启动组装

### [C] TC-REQ7-01 健康检查
[用例描述]
application 模块启动，Actuator health UP
[Automation]
`MANUAL`
[ManualReason]
全量 Spring Boot 启动集成

[前置条件]
- 阶段 4 application 模块就位

#### 步骤1
`mvn -pl application spring-boot:run` 访问 `/actuator/health`

##### 预期结果
`{"status":"UP"}`

---

## [S] Requirement 8：无功能回归验收

### [C] TC-REQ8-01 全量构建
[用例描述]
根目录 mvn clean install 通过
[Automation]
`MANUAL`
[ManualReason]
全仓库构建门禁

[前置条件]
- 全部 19 模块就位

#### 步骤1
`mvn clean install`

##### 预期结果
BUILD SUCCESS

### [C] TC-REQ8-02 核心 API 契约回归
[用例描述]
三主对话路径 + 飞书端点响应正常
[Automation]
`MANUAL`
[ManualReason]
SSE 流式与外部回调需联调环境

[前置条件]
- 应用启动；测试用 API Key 已配置

#### 步骤1
POST `/api/agent-hub/chat/agent`、`/api/agent-hub/chat/knowledge`、`/api/super-agents/chat`

##### 预期结果
HTTP 200/SSE 流正常；JSON 字段与 integration-contracts 一致

### [C] TC-REQ8-03 无环依赖
[用例描述]
dependency:tree 无环形依赖
[Automation]
`MANUAL`
[ManualReason]
Maven 构建分析

#### 步骤1
`mvn dependency:tree` 人工或脚本检查

##### 预期结果
无 A→B→A 环

### [C] TC-REQ8-04 密钥环境变量
[用例描述]
仓库无明文 API Key，环境变量可启动
[Automation]
`AUTO-UT`

[前置条件]
- application.yml 使用 `${DASHSCOPE_API_KEY}`

#### 步骤1
静态检查 + 配置加载测试（无密钥时启动失败可预期）

##### 预期结果
仓库 YAML 无真实密钥模式

### [C] TC-REQ8-05 L1 单测回归
[用例描述]
搬迁后 L1 AUTO-AI-UT 全部通过
[Automation]
`AUTO-AI-UT`

[前置条件]
- aiTddMode enabled；*Test.java 包路径已迁移

#### 步骤1
`mvn test` 或 scoped `-Dtest=*ApplicationServiceTest,*Graph*Test`

##### 预期结果
L1 相关测试 GREEN
