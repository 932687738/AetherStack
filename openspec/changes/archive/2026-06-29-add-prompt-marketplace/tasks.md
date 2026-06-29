# Prompt 市场 / 快捷指令 — 实施任务清单

> Schema: `simple-spec-driven` | Apply requires: `tasks`
> 参考：`spec.md` REQ-1～4、`design-lite.md` v2（Skill 复用方案）

---

## 任务 0：基础准备

- [x] **0.1 Flyway 迁移脚本**
  - 新增 `V25__prompt_marketplace.sql`，包含：
    - `prompt_templates` 表（仿 `V8__agent_platform_skills.sql`）：id BIGSERIAL, tenant_id, name, description, version INT, status, category, content TEXT, tags TEXT[], source VARCHAR(32), created_by, created_at, updated_at + UNIQUE(tenant_id, name, version) + INDEX(tenant_id, category, status)
    - `quick_commands` 表：id BIGSERIAL, tenant_id, agent_name, name, content VARCHAR(4000), icon, version INT, created_at, updated_at + UNIQUE(tenant_id, agent_name, name)
    - `prompt_favorites` 表：id BIGSERIAL, user_id, template_id BIGINT, created_at + UNIQUE(user_id, template_id)
    - `agent_registry` ALTER：`ADD COLUMN system_prompt TEXT`
  - **可验证输出**：迁移执行成功；`\d prompt_templates`、`\d quick_commands`、`\d prompt_favorites` 结构正确；`\d agent_registry` 可见 `system_prompt` 列

- [x] **0.2 预置模板种子数据**
  - 在 `V25` 迁移末尾 INSERT ≥10 条预置模板（分类：翻译、摘要、代码审查、写作、数据分析、客服等）
  - 每条字段：tenant_id='default', name, description, version=1, status='active', category, content, tags, source='preset', created_by='system'
  - **可验证输出**：`SELECT count(*) FROM prompt_templates WHERE source='preset'` ≥ 10

---

## 任务 1：Prompt 市场浏览与选用（REQ-1）

- [x] **1.1 后端：领域层 + 基础设施层**
  - `domain/prompt/PromptTemplateEntry.java`：final class 不可变实体（参照 `SkillEntry`）— id, tenantId, name, description, version, status, category, content, tags(List<String>), source, createdBy, createdAt, updatedAt
  - `domain/prompt/PromptTemplateStatus.java`：枚举（ACTIVE / DEPRECATED），参照 `SkillStatus`
  - `domain/prompt/PromptTemplateRepository.java`：Port 接口 — listActiveByTenant, listActiveByCategory, searchByKeyword, findById, insertVersion, findMaxVersion, updateStatus
  - `infrastructure/prompt/MyBatisPromptTemplateRepository.java`：参照 `MyBatisSkillRepository` + `TenantGuard.requireTenantId()`
  - `infrastructure/prompt/PromptTemplateMapper.java`：`@Mapper` 接口，参照 `SkillMapper`
  - `resources/mapper/superAgents/PromptTemplateMapper.xml`：resultMap constructor 注入 + `StringListTypeHandler`(tags) + `InstantTypeHandler`，参照 `SkillMapper.xml`
  - **可验证输出**：Mapper 注入成功；listActiveByTenant 返回种子数据

- [x] **1.2 后端：Application + Web 层**
  - `application/prompt/PromptMarketplaceService.java`：listActive（分类筛选 + 关键词搜索），参照 `SkillApplicationService.listActive`
  - `web/prompt/PromptMarketplaceController.java`：`GET /api/super-agents/prompts/marketplace?category=&keyword=`，参照 `SkillController`（`@RequestHeader("X-Tenant-Id")`）
  - `web/prompt/dto/PromptTemplateResponse.java`：响应 DTO
  - `SuperAgentApiPaths.java` 追加 `PROMPTS_MARKETPLACE = "/api/super-agents/prompts/marketplace"` 等常量
  - **可验证输出**：接口返回 JSON 列表，支持 category/keyword 筛选，响应 < 100ms

- [x] **1.3 后端：收藏功能**
  - `domain/prompt/PromptFavorite.java`：值对象（userId, templateId, createdAt）
  - `domain/prompt/PromptFavoriteRepository.java`：Port 接口
  - `infrastructure/prompt/MyBatisPromptFavoriteRepository.java` + `PromptFavoriteMapper.java`
  - `resources/mapper/superAgents/PromptFavoriteMapper.xml`
  - 扩展 `PromptMarketplaceService`：toggleFavorite（幂等，响应 `{promptId, favorited}`）、listFavorites
  - `POST /api/super-agents/prompts/marketplace/favorites`（toggle）、`GET .../favorites`
  - **可验证输出**：重复收藏返回 200 不报错；收藏列表正确

- [x] **1.4 后端：选用模板到 Agent**
  - 扩展 `PromptMarketplaceService`：usePrompt(templateId, agentName) → 读取模板 content → 写入 `agent_registry.system_prompt`
  - `AgentRegistryRepository` / `AgentRegistryMapper` 新增 `updateSystemPrompt(tenantId, agentName, systemPrompt)` 方法
  - `AgentRegistryMapper.xml` 新增 UPDATE SQL
  - `POST /api/super-agents/prompts/marketplace/use`（body: `{templateId, agentName}`）
  - Agent 不存在返回 404
  - **可验证输出**：调用后 `agent_registry.system_prompt` 已更新；404 场景正确

- [x] **1.5 前端：Prompt 市场弹窗**（UI-Craft，`uiCraftMode: enabled`）— impeccable: audit+polish
  - `src/pages/prompt-marketplace/` 组件：Modal + 分类 Tab + 搜索 + 模板卡片列表
  - 卡片：名称、描述摘要、分类标签、收藏按钮、使用按钮
  - 收藏筛选 Tab：「全部」/「我的收藏」
  - **可验证输出**：分类切换正确；搜索实时筛选；点击「使用」触发 API 并关闭弹窗

- [x] **1.6 前端：API 层与 Store**
  - `src/services/promptMarketplaceService.ts`：封装 9 个端点（遵循 `frontend-umi-standards.md §3.2`：放 `services/`，禁止 `api/`）
  - `src/models/usePromptStore.ts`：Zustand store（收藏状态、搜索关键词等客户端状态）
  - 类型：`src/types/promptMarketplace.ts`（OpenAPI 尚未生成 typings，待后端 swagger 同步后迁移）
  - **可验证输出**：API 调用类型正确；store 状态更新符合预期

---

## 任务 2：快捷指令管理（REQ-2）

- [x] **2.1 后端：快捷指令 CRUD**
  - `domain/prompt/QuickCommand.java`：final class（参照 `SkillEntry`）— id, tenantId, agentName, name, content, icon, version, createdAt, updatedAt
  - `domain/prompt/QuickCommandRepository.java`：Port 接口 — findByAgentName, findById, insert, update, delete
  - `infrastructure/prompt/MyBatisQuickCommandRepository.java`：参照 `MyBatisSkillRepository` + `TenantGuard`
  - `infrastructure/prompt/QuickCommandMapper.java` + `resources/mapper/superAgents/QuickCommandMapper.xml`
  - `application/prompt/QuickCommandService.java`：CRUD 编排 + version 乐观锁冲突检测
  - `web/prompt/QuickCommandController.java`：GET/POST/PUT/DELETE `/api/super-agents/agents/{agentName}/quick-commands[/{id}]`
  - `web/prompt/dto/QuickCommandRequest.java`：请求 DTO（name, content, icon）
  - **可验证输出**：CRUD 正常；并发写入 409 冲突场景可复现

- [x] **2.2 前端：快捷指令管理面板**（UI-Craft）— impeccable: audit+polish
  - `src/pages/quick-commands/` 组件：指令列表 + 新建/编辑抽屉 + 删除确认弹窗
  - 列表按创建时间排序；编辑含名称、Prompt 内容（TextArea maxLength=4000）、图标选择
  - **可验证输出**：新建后列表更新；编辑保存后内容变更；删除后列表刷新

---

## 任务 3：快捷指令一键触发（REQ-3）

- [x] **3.1 前端：对话面板快捷按钮组**（UI-Craft）— impeccable: audit+polish
  - 对话界面输入框旁新增快捷指令工具栏
  - 当前 Agent 有指令时展示按钮组；无指令时隐藏
  - 点击按钮 → 将指令 content 作为用户消息发送到 SSE 对话流
  - **可验证输出**：有指令时工具栏显示；点击触发后 SSE 响应正常

---

## 任务 4：AI 辅助生成 Prompt（REQ-4）

- [x] **4.1 后端：AI 生成 Prompt 接口**
  - `resources/prompts/super-agents/prompt-generator.st`：StringTemplate 格式的 System Prompt 模板
  - `application/prompt/PromptGenerateService.java`：
    - 模板加载：`SuperAgentPromptService.load("super-agents/prompt-generator.st")`
    - 用户输入消毒：`PlatformPromptTemplateRenderer.sanitizeUserInput()`
    - LLM 调用：单次 `ChatClient` 流式输出（豁免 CompiledGraph/ReactAgent）
    - 可观测：Micrometer `prompt.tokens` / `completion.tokens` / `llm.duration.ms`（待后续迭代补指标）
  - `POST /api/super-agents/prompts/generate`（SSE）
  - SSE 契约：`type=token`（文本分片）+ 关闭连接表示流结束 + `type=progress` error event + 503 超时
  - **可验证输出**：SSE 流式返回结构化 Prompt；超时 503；首 token < 3s

- [x] **4.2 后端：保存生成结果为自定义模板**
  - 扩展 `PromptGenerateService` 或 `PromptMarketplaceService`：saveGenerated(content, name, tenantId) → 写入 `prompt_templates`（source='generated', version=1, status='active'）
  - `POST /api/super-agents/prompts/marketplace/save-generated`
  - **可验证输出**：保存后 `prompt_templates` 表有 source='generated' 记录；市场列表可查到

- [x] **4.3 前端：AI 生成 Prompt 表单**（UI-Craft）— impeccable: audit+polish
  - 市场弹窗内「AI 生成」Tab：描述输入框 + 生成按钮 + SSE 流式预览区 + 编辑区 + 保存按钮
  - 生成中 loading；失败友好提示
  - 保存后模板加入「我的模板」列表
  - **可验证输出**：流式输出正常；可编辑；保存后列表可查

---

## 任务 5：测试

- [x] **5.1 测试任务**
  - 后端单测：`MyBatisPromptTemplateRepositoryTest`、`PromptMarketplaceServiceTest`、`QuickCommandServiceTest`
  - 幂等/并发场景：收藏幂等、快捷指令乐观锁
  - AI 生成：`PromptGenerateServiceTest`（mock ChatClient）
  - **可验证输出**：`mvn -Dtest=PromptMarketplaceServiceTest,QuickCommandServiceTest,MyBatisPromptTemplateRepositoryTest,PromptGenerateServiceTest test -pl aether-platform` BUILD SUCCESS

---

## 任务 6：集成与收尾

- [x] **6.1 API 文档与契约更新**
  - 更新 `openspec/references/integration-contracts.md`：新增 9+1 个端点白名单
  - 更新 `.aetherstack/context/api-contracts.yaml`：追加路径
  - 更新 `openspec/references/api-changelog.md`：Added 条目
  - **可验证输出**：三处文档均已更新；`/v3/api-docs` 运行时可见新端点

- [x] **6.2 多租户强制过滤验证**
  - 确认所有读写接口遵循 `X-Tenant-Id` + `TenantGuard` 过滤
  - **可验证输出**：`MyBatisPromptTemplateRepositoryTest` + `TenantGuardTest` 覆盖 tenant 传递与空 tenant 拒绝

---

## 依赖关系

```text
0.1（迁移+种子）──┬──> 1.1（领域+基础设施）──> 1.2（Application+Web）──> 1.3（收藏）──> 1.5（前端弹窗）
                   │                                                         └──> 1.4（选用模板）──┘
                   ├──> 2.1（快捷指令CRUD）──> 2.2（前端管理面板）──> 3.1（对话面板触发）
                   └──> 4.1（AI生成）──> 4.2（保存模板）──> 4.3（前端生成表单）
1.6（API层+Store）──> 1.5 / 2.2 / 3.1 / 4.3
6.1 / 6.2 可与 1～4 并行
```
