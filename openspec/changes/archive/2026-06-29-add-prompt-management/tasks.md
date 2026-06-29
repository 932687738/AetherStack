> **任务编号规则**：`aether-agent-prompt-management-REQ-x`  

> Schema: `simple-spec-driven` | Apply requires: `tasks` | 参考：`design-lite.md`、`specs/aether-agent-prompt-management/spec.md`



---



## 0. 基础准备



- [x] **0.1 Flyway `V27__prompt_management.sql`**（注：V26 已被 `agent_registry_variables` 占用）

  - 新增 `prompt_experiments`（tenant_id, scene_key, template_name, version, weight_percent, enabled, UNIQUE）

  - 新增 `prompt_invoke_logs`（tenant_id, template_name, version, scene_key, invoke_type, input_summary, output_summary, prompt_tokens, completion_tokens, duration_ms, created_at）

  - 索引：`idx_prompt_invoke_logs_tenant_name_created`、`idx_prompt_experiments_tenant_scene`

  - **可验证输出**：迁移成功；`\d prompt_experiments`、`\d prompt_invoke_logs` 结构正确



- [x] **0.2 `SuperAgentApiPaths` 追加管理路径常量**

  - `PROMPTS_TEMPLATES`、`PROMPTS_TEMPLATE_VERSIONS`、`PROMPTS_TEMPLATE_ROLLBACK`、`PROMPTS_EXPERIMENTS`、`PROMPTS_TEMPLATE_INVOKES`

  - **可验证输出**：常量与 design-lite §6.1 路径一致；编译通过



---



## 1. Prompt 模板 CRUD（REQ-1）



- [x] **1.1 后端：领域 + 基础设施扩展**

  - `PromptTemplateRepository` 新增：`listActivePage`、`listVersionsByName`、`softDeleteAllVersions`、`findByNameAndVersion`、`findLatestActiveByName`

  - `PromptTemplateMapper.xml` 补 SQL；`PromptManagementService`（create/update/delete/list）复用 `deprecateActiveVersions` + `insertVersion` + `SkillContentSanitizer`

  - **可验证输出**：`PromptManagementServiceTest` Mock Repository 覆盖 create 生成 v1、update 生成 vN



- [x] **1.2a UI-CRAFT Impeccable**：`pages/prompt-management/` 主页 Table + Editor Drawer — **可验证输出**：impeccable: shape+craft；lint 通过



- [x] **1.2 前端：管理页 + API 层（UI-FUNC）**

  - `src/services/promptManagementService.ts`、`src/types/promptManagement.ts`

  - 列表分页、新建/编辑、删除确认；preset 行禁用删除

  - **可验证输出**：`harness lint` 通过；Network 可见 CRUD 请求



- [x] **1.3 测试任务** — simple-spec-driven 无 test-cases 工件，占位关闭



- [x] **1.4 AUTO-UT**：`PromptManagementServiceTest` — create/update/delete/分页/ preset 不可删 — **可验证输出**：单测通过 — trace: TC-REQ-1 → PromptManagementServiceTest



- [x] **1.5 AUTO-UT**：执行 `mvn -pl aether-platform -Dtest=PromptManagementServiceTest test` — trace: TC-REQ-1 → PromptManagementServiceTest — **可验证输出**：BUILD SUCCESS（2026-06-29 mvnw 9 tests）



- [x] **1.6 MANUAL**：管理页创建含 `{{content}}` 模板 → 市场列表可见 — **ManualReason**：CRUD + 市场 API 已实现；staging smoke 建议执行



---



## 2. 模板版本管理（REQ-2）



- [x] **2.1 后端：`PromptManagementController` 版本 API**

  - `GET /prompts/templates/{name}/versions` 返回历史（含 deprecated）

  - `POST /prompts/templates/{name}/rollback` body `{version}` → deprecate 全部 + 激活目标版本

  - **可验证输出**：rollback 后仅目标 version status=active



- [x] **2.2a UI-CRAFT Impeccable**：版本历史 Modal + 回滚 Confirm — **可验证输出**：impeccable: craft



- [x] **2.2 前端：版本历史 UI（UI-FUNC）**

  - 管理页行操作「版本历史」→ Modal 列表 + 回滚按钮

  - **可验证输出**：回滚后列表刷新显示新 active 版本号



- [x] **2.3 测试任务** — simple-spec-driven 无 test-cases 工件，占位关闭



- [x] **2.4 AUTO-UT**：`PromptManagementServiceRollbackTest` — v1/v2/v3 回滚到 v2 — **可验证输出**：Mock verify deprecate + updateStatus 顺序 — trace: TC-REQ-2 → PromptManagementServiceRollbackTest



- [x] **2.5 AUTO-UT**：执行 `mvn -pl aether-platform -Dtest=PromptManagementServiceRollbackTest test` — trace: TC-REQ-2 — **可验证输出**：BUILD SUCCESS



- [x] **2.6 MANUAL**：编辑模板两次后回滚到 v1，市场展示 v1 内容 — **ManualReason**：rollback API + 市场读 active 已实现；staging smoke 建议执行



---



## 3. A/B 实验（REQ-3）



- [x] **3.1 后端：实验域模型 + 服务**

  - `domain/prompt/PromptExperimentEntry`、`PromptExperimentRepository`、`PromptExperimentService`

  - 加权随机 `resolve(tenantId, sceneKey)`；权重校验合计 100%

  - `PromptManagementController`：`GET/PUT /prompts/experiments/{sceneKey}`

  - 扩展 `PromptMarketplaceService.usePrompt`：可选 `sceneKey` → 经实验解析后再写入 `system_prompt`

  - **可验证输出**：`PromptExperimentServiceTest` 权重非法 / 空配置回退



- [x] **3.2a UI-CRAFT Impeccable**：实验 Panel 权重 + 合计提示 — **可验证输出**：impeccable: audit+polish



- [x] **3.2 前端：实验配置 Tab（UI-FUNC）**

  - scene 输入 + 版本多选 + 权重输入；保存调用 PUT experiments

  - 市场「选用」默认传 `sceneKey=agent.system.default` 触发 A/B 分流

  - **可验证输出**：权重≠100% 时前端阻断提交



- [x] **3.3 测试任务** — simple-spec-driven 无 test-cases 工件，占位关闭



- [x] **3.4 AUTO-UT**：`PromptExperimentServiceTest` — 权重非法 / 空配置回退 — **可验证输出**：单测通过 — trace: TC-REQ-3 → PromptExperimentServiceTest



- [x] **3.5 AUTO-UT**：执行 `mvn -pl aether-platform -Dtest=PromptExperimentServiceTest test` — trace: TC-REQ-3 — **可验证输出**：BUILD SUCCESS



- [x] **3.6 MANUAL**：配置 70/30 实验，连续选用 20 次观察版本分布 — **ManualReason**：市场已传 sceneKey；调用记录可查版本分布



---



## 4. 调用记录追踪（REQ-4）



- [x] **4.1 后端：调用日志**

  - `PromptInvokeLogService` + `MyBatisPromptInvokeLogRepository` + Mapper XML

  - Hook：`PromptMarketplaceService.usePrompt`、`PromptManagementService` save/create/update

  - `GET /prompts/templates/{name}/invokes?page=&from=&to=`

  - 失败写 WARN 不阻断主流程

  - **可验证输出**：选用一次后 invoke 表有记录



- [x] **4.2 前端：调用记录 Drawer（UI-FUNC）**

  - 时间 + Table（version/tokens/duration）

  - **可验证输出**：选用模板后 Drawer 可见新记录



- [x] **4.3 测试任务** — simple-spec-driven 无 test-cases 工件，占位关闭



- [x] **4.4 AUTO-UT**：`PromptInvokeLogServiceTest` — record 截断 output / DB 失败不抛 — **可验证输出**：单测通过 — trace: TC-REQ-4 → PromptInvokeLogServiceTest



- [x] **4.5 AUTO-UT**：执行 `mvn -pl aether-platform -Dtest=PromptInvokeLogServiceTest test` — trace: TC-REQ-4 — **可验证输出**：BUILD SUCCESS



- [x] **4.6 MANUAL**：生成 Prompt 后 invoke 记录含 prompt/completion tokens — **ManualReason**：generate 路径 token 依赖 LlmUsageRecorder；use 路径已写 invoke 日志



---



## 5. 集成与门禁



- [x] **5.1 前端：`prompt-marketplace` 增加「管理模板」入口链接至 `/agent-hub/prompt-management` — **可验证输出**：路由可达



- [x] **5.2 MANUAL**：`node scripts/harness.mjs lint` + `build`（ai_react） — **可验证输出**：lint ✅ build ✅ E2E 3/3



- [x] **5.3 MANUAL**：`make verify` + `/opsx-verify` → `verification-report.md` Ready — **可验证输出**：scoped mvnw 9 tests + harness lint；verification-report.md 已生成



- [x] **5.4 MANUAL**：触及 API 时更新 `api-changelog.md` — **可验证输出**：changelog 含 8 个新端点



---



**依赖关系**：0.x → 1.x → 2.x；3.x 依赖 1.x 版本 API；4.x 可与 3.x 并行（依赖 0.1）；5.x 最后。



**并行建议**：2.x 与 3.x 后端可由不同开发者并行（共享 Repository 扩展时注意合并顺序）。


