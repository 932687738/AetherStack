# Prompt 市场 / 快捷指令 — 技术方案（简版）v2

## 一、需求摘要

为 AetherStack 平台新增三项能力：
1. **Prompt 市场**：按场景分类的预置 Prompt 模板库（**复用 Skill 版本管理模式**），用户可浏览、搜索、收藏并一键选用到 Agent
2. **快捷指令**：Agent 级预置命令（独立表 + **复用 Skill DDD 分层模式**），CRUD + 对话面板一键触发
3. **AI 辅助生成 Prompt**：用户输入描述 → LLM 生成结构化 Prompt 模板

对应 spec：`specs/aether-agent-prompt-marketplace/spec.md` REQ-1 ～ REQ-4。

---

## 二、方案概述

### 2.1 技术选型（复用 Skill 基础设施）

| 能力 | 技术组件 | 复用 Skill 资产 | 理由 |
|------|---------|----------------|------|
| Prompt 市场模板 | **新建 `prompt_templates` 表**（仿 `skills` 表结构：tenant_id + name + version + status + category） | 表结构参照 `V8__agent_platform_skills.sql`；DDD 四层参照 `SkillEntry`/`SkillRepository`/`MyBatisSkillRepository` | 模板需要版本管理、多租户、状态（active/deprecated）；与 Skill 同构但业务概念不同，独立表更清晰 |
| 快捷指令 | **新建 `quick_commands` 独立表**（非 JSONB；含 id/agent_name/name/content/version） | DDD 分层参照 `SkillEntry` 模式；MyBatis resultMap 参照 `SkillMapper.xml` | 独立表支持乐观锁 `version`（解决 DR-03）；复用 Skill 的 Port/Repository/Mapper 模式 |
| 收藏 | `prompt_favorites` 表（user_id + template_id） | 参照 `SkillMenuCacheService` 做缓存 | 用户维度持久化 |
| AI 生成 | 复用 `ChatClient` + `SuperAgentPromptService`（classpath 模板加载）+ `PlatformPromptTemplateRenderer`（注入防护） | `SuperAgentPromptService.load()` 加载生成器 Prompt 模板；`PlatformPromptTemplateRenderer` 渲染 | 单次问答，豁免 CompiledGraph/ReactAgent（解决 DR-09） |
| 选用模板 | `agent_registry` 表新增 `system_prompt TEXT` 列 | 复用 `AgentRegistryRepository` | 解决 DR-01/DR-07：`appId` = `agent_registry.name`，模板写入 `system_prompt` 字段 |

### 2.2 模块归属

新增代码落在 **`aether-platform`** 模块，与 Skill 同包域：

```text
com.yxy.deepseek.superAgents
  ├── domain.prompt/          ← PromptTemplateEntry / QuickCommand / PromptFavorite + Repository Port
  ├── infrastructure.prompt/  ← MyBatisPromptTemplateRepository / PromptTemplateMapper
  │                            MyBatisQuickCommandRepository / QuickCommandMapper
  │                            MyBatisPromptFavoriteRepository / PromptFavoriteMapper
  ├── application.prompt/     ← PromptMarketplaceService / QuickCommandService / PromptGenerateService
  └── web.prompt/             ← PromptMarketplaceController / QuickCommandController + DTO
```

**复用现有 Skill 资产（不修改）**：
- `SkillContentSanitizer`：内容消毒（防 Prompt 注入）
- `SkillMenuCacheService`：缓存模式参考
- `SuperAgentPromptService`：classpath 模板加载（AI 生成器的 Prompt 模板）
- `PlatformPromptTemplateRenderer`：`{{key}}` 渲染 + 注入防护
- `TenantGuard`：多租户身份校验
- `StringListTypeHandler` / `InstantTypeHandler`：MyBatis TypeHandler 复用
- `SuperAgentApiPaths`：路径常量追加

### 2.3 API 设计

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/super-agents/prompts/marketplace` | 市场模板列表（`category`、`keyword` 筛选） |
| POST | `/api/super-agents/prompts/marketplace/favorites` | 收藏/取消收藏（toggle，响应 `{promptId, favorited}`） |
| GET | `/api/super-agents/prompts/marketplace/favorites` | 我的收藏列表 |
| POST | `/api/super-agents/prompts/marketplace/use` | 选用模板（body: `{templateId, agentName}`）→ 写入 `agent_registry.system_prompt` |
| GET | `/api/super-agents/agents/{agentName}/quick-commands` | Agent 快捷指令列表 |
| POST | `/api/super-agents/agents/{agentName}/quick-commands` | 创建快捷指令 |
| PUT | `/api/super-agents/agents/{agentName}/quick-commands/{id}` | 更新快捷指令 |
| DELETE | `/api/super-agents/agents/{agentName}/quick-commands/{id}` | 删除快捷指令 |
| POST | `/api/super-agents/prompts/generate` | AI 生成 Prompt（SSE 流式） |

**SSE 契约（`POST /prompts/generate`，解决 DR-05）**：
- 事件类型：`type=token`（文本分片，与 `integration-contracts.md` §4 对齐）
- 流结束：服务端关闭 SSE 连接
- 流内错误：`type=progress` event `{status:"error", message:"生成失败，请稍后重试"}`，随后关闭连接
- 超时：503 + `Retry-After` Header

### 2.4 Spring AI 设计（解决 DR-09）

| 维度 | 选型 | 理由 |
|------|------|------|
| 编排 | **单次 `ChatClient`**（豁免 CompiledGraph/ReactAgent） | REQ-4 为单次问答，无多步编排、无工具调用 |
| Prompt 模板 | 外置 `resources/prompts/super-agents/prompt-generator.st`（StringTemplate 格式） | 遵循 `spring-ai-core-standards.md`：Prompt 放 `resources/prompts/`；复用 `SuperAgentPromptService.load()` |
| 异常降级 | 503 `SERVICE_UNAVAILABLE` + 友好文案「生成失败，请稍后重试」 | 已覆盖（§五 异常场景 7） |
| 密钥 | 沿用 `DASHSCOPE_API_KEY` 环境变量 | 不引入新密钥 |
| 可观测 | Micrometer `prompt.tokens` / `completion.tokens` / `llm.duration.ms` + `traceId` | 遵循 `spring-ai-core-standards.md` |

---

## 三、代码改造分析

### 3.1 后端（aether-platform 模块）

**新增文件（目标位置，参照 Skill DDD 模式）**：

| 文件 | 层 | 复用参照 |
|------|---|---------|
| `domain/prompt/PromptTemplateEntry.java` | domain | 参照 `SkillEntry`（final class，tenantId/name/version/status/category/content） |
| `domain/prompt/PromptTemplateStatus.java` | domain | 参照 `SkillStatus`（ACTIVE/DEPRECATED） |
| `domain/prompt/PromptTemplateRepository.java` | domain | 参照 `SkillRepository`（Port 接口） |
| `domain/prompt/QuickCommand.java` | domain | 参照 `SkillEntry`（final class，agentName/name/content/version） |
| `domain/prompt/QuickCommandRepository.java` | domain | Port 接口 |
| `domain/prompt/PromptFavorite.java` | domain | 值对象（userId + templateId） |
| `domain/prompt/PromptFavoriteRepository.java` | domain | Port 接口 |
| `infrastructure/prompt/MyBatisPromptTemplateRepository.java` | infrastructure | 参照 `MyBatisSkillRepository` + `TenantGuard` |
| `infrastructure/prompt/PromptTemplateMapper.java` | infrastructure | 参照 `SkillMapper`（@Mapper） |
| `infrastructure/prompt/MyBatisQuickCommandRepository.java` | infrastructure | 参照 `MyBatisSkillRepository` |
| `infrastructure/prompt/QuickCommandMapper.java` | infrastructure | 参照 `SkillMapper` |
| `infrastructure/prompt/MyBatisPromptFavoriteRepository.java` | infrastructure | |
| `infrastructure/prompt/PromptFavoriteMapper.java` | infrastructure | |
| `application/prompt/PromptMarketplaceService.java` | application | 参照 `SkillApplicationService`（listActive + 缓存 + TenantGuard） |
| `application/prompt/QuickCommandService.java` | application | CRUD 编排 + 乐观锁冲突检测 |
| `application/prompt/PromptGenerateService.java` | application | 调用 `ChatClient` + `SuperAgentPromptService` + `PlatformPromptTemplateRenderer` |
| `web/prompt/PromptMarketplaceController.java` | web | 参照 `SkillController`（@RestController + TenantId Header） |
| `web/prompt/QuickCommandController.java` | web | 参照 `SkillController` |
| `web/prompt/dto/PromptTemplateResponse.java` | web/dto | 参照 `SkillItemResponse` |
| `web/prompt/dto/QuickCommandRequest.java` | web/dto | |
| `web/prompt/dto/UsePromptRequest.java` | web/dto | `{templateId, agentName}` |
| `resources/prompts/super-agents/prompt-generator.st` | resources | AI 生成器 System Prompt 模板 |
| `resources/mapper/superAgents/PromptTemplateMapper.xml` | resources | 参照 `SkillMapper.xml`（resultMap + constructor 注入） |
| `resources/mapper/superAgents/QuickCommandMapper.xml` | resources | 参照 `SkillMapper.xml` |
| `resources/mapper/superAgents/PromptFavoriteMapper.xml` | resources | |

**现有文件改造**：

| 文件 | 改造内容 |
|------|---------|
| `SuperAgentApiPaths.java` | 追加 `PROMPTS_MARKETPLACE`、`QUICK_COMMANDS` 等路径常量 |
| `AgentRegistryRepository` / `AgentRegistryMapper` | 新增 `updateSystemPrompt(tenantId, agentName, systemPrompt)` 方法 |
| `AgentRegistryMapper.xml` | 新增 update SQL |
| Flyway `V25__prompt_marketplace.sql` | 新建 `prompt_templates`、`quick_commands`、`prompt_favorites` 表；`agent_registry` 加 `system_prompt TEXT` 列 |

### 3.2 前端（ai_react，解决 DR-10/DR-11）

| 文件 | 说明 |
|------|------|
| `src/pages/PromptMarketplace/` | 市场弹窗/抽屉组件 |
| `src/pages/QuickCommands/` | 快捷指令管理面板 |
| `src/services/promptMarketplace.ts` | API 调用层（遵循 `frontend-umi-standards.md §3.2`：放 `services/`，禁止 `api/`） |
| `src/models/usePromptStore.ts` | Zustand store（遵循 §4.1：放 `models/`，导出 hook） |

**API 类型**：从 `src/openapi/typings.d.ts` 引用，禁止手写类型。  
**状态管理边界**：marketplace 列表等静态数据用 Umi `useRequest` 缓存；收藏状态、当前选中模板等客户端状态走 Zustand。

---

## 四、影响范围

| 维度 | 影响 |
|------|------|
| 模块 | `aether-platform`（后端新增）；`ai_react`（前端新增页面） |
| 接口 | 新增 9 个 REST 端点（见 §2.3），不修改现有接口 |
| 数据 | 新增 3 张表（`prompt_templates`、`quick_commands`、`prompt_favorites`）；`agent_registry` 新增 `system_prompt` 列 |
| 现有改造 | `SuperAgentApiPaths` 追加常量；`AgentRegistryRepository`/`Mapper` 新增 updateSystemPrompt 方法 |
| 外部依赖 | 无（AI 生成复用现有 ChatClient + DashScope） |
| 多租户 | 所有新表含 `tenant_id` 列；Controller 使用 `X-Tenant-Id` Header + `TenantGuard` |

---

## 五、核心场景

### 正常场景
1. 用户打开 Prompt 市场 → 分类列表加载 → 选择模板 → 点击「使用」→ 模板 content 写入 `agent_registry.system_prompt`（agentName 标识目标 Agent）
2. 用户在 Agent 配置页创建快捷指令 → 对话界面面板展示 → 点击触发 → SSE 流式响应
3. 用户输入描述 → AI 通过 `ChatClient` 生成 Prompt（System Prompt 模板加载自 `prompt-generator.st`）→ 预览编辑 → 保存为自定义模板（写入 `prompt_templates` 表，status=ACTIVE，version=1）

### 边界场景
4. 市场模板为空 → 返回空列表 + 友好提示
5. 快捷指令超过合理数量（>50 条/Agent）→ 前端分页展示
6. AI 生成 Prompt 返回超长内容 → `PlatformPromptTemplateRenderer` 截断（8000 字符上限）+ 提示用户精简描述

### 异常场景
7. LLM 调用超时（AI 生成）→ SSE `progress` error event → 关闭连接 → 前端展示「生成失败，请稍后重试」
8. 选用模板时目标 Agent 不存在（`agent_registry` 无记录）→ 返回 404 `NOT_FOUND`
9. 快捷指令并发写入冲突 → 乐观锁（`version` 字段）返回 409 `CONFLICT`

---

## 六、可观测性清单（解决 DR-08）

| 观测点 | 内容 |
|--------|------|
| 接口响应 | 所有端点携带 `traceId`；错误响应统一 `{code, message, traceId}` 结构 |
| 日志事件 | `PROMPT_MARKETPLACE_USE`（用户选用模板）；`QUICK_COMMAND_CREATE/DELETE`；`PROMPT_GENERATE`（AI 生成请求/耗时/模型） |
| Micrometer | AI 生成接口记录 `prompt.tokens`、`completion.tokens`、`llm.duration.ms`（遵循 `spring-ai-core-standards.md`） |
| 数据库 | `prompt_favorites` 记录收藏；`prompt_templates` 记录用户生成模板；`quick_commands` 记录快捷指令 |

---

## 七、数据落点清单

| 数据 | 存储位置 | 验证口径 |
|------|---------|---------|
| 市场模板 | `prompt_templates` 表（tenant_id, name, version, status, category, description, content, tags） | name + version 唯一约束；参照 Skill 的 `uq_skills_tenant_name_version` |
| 快捷指令 | `quick_commands` 表（id, tenant_id, agent_name, name, content, icon, version） | agent_name + name 唯一约束；version 乐观锁 |
| 用户收藏 | `prompt_favorites` 表（user_id, template_id, created_at） | UNIQUE(user_id, template_id) 防重复 |
| Agent System Prompt | `agent_registry.system_prompt` TEXT 列 | 选用模板时写入，Agent 对话时读取 |
| AI 生成模板 | 保存时写入 `prompt_templates` 表（source='generated'） | 与预置模板同表，通过 source 字段区分 |

---

## 八、非功能性需求

| 维度 | 验收口径 |
|------|---------|
| 幂等性 | 收藏接口以 `user_id + template_id` 幂等；重复收藏返回 200 不报错 |
| 并发 | 快捷指令写入带乐观锁 `version`（独立表，解决 DR-03）；冲突返回 409 |
| 性能 | 市场列表查询 < 100ms（参照 `SkillMenuCacheService` 缓存）；AI 生成首 token < 3s |
| 容量 | prompt_templates < 500 条/租户；快捷指令 < 200 条/Agent |
| 安全 | 所有用户输入经 `SkillContentSanitizer` + `PlatformPromptTemplateRenderer` 消毒（防 Prompt 注入） |

---

## 九、前端 UI 界面清单（UI-Craft `uiCraftMode: enabled`）

| 界面 | 组件 | 说明 |
|------|------|------|
| Prompt 市场弹窗 | Modal / Drawer | 分类 Tab + 搜索栏 + 模板卡片列表 + 收藏筛选 |
| 模板详情 | Card | 名称、描述、内容预览、使用/收藏按钮 |
| 快捷指令管理 | Settings Panel | 指令列表 + 新建/编辑表单 + 删除确认 |
| 对话快捷面板 | Toolbar / Dropdown | 对话输入框旁的快捷按钮组 |
| AI 生成 Prompt | Inline Form | 描述输入框 + 生成按钮 + SSE 流式预览区 + 编辑区 + 保存按钮 |

---

## 十、假设与风险（解决 DR-12）

| 假设 | 失效风险 | 降级策略 | 验证方式 |
|------|---------|---------|---------|
| 预置模板 ≤500 条，随版本发布更新 | 模板量过大导致查询变慢 | 引入分页 + `SkillMenuCacheService` 缓存模式 | 上线前 count 验证 |
| `prompt_templates` 表与 `skills` 表同构，复用 DDD 模式 | Skill 重构时可能影响 prompt | 两个模块独立包，仅共享 TypeHandler 等基础设施 | Code Review 确认无交叉 import |
| `agent_registry.system_prompt` 字段足够存储 Prompt 模板 | 超长 Prompt（>64KB） | TEXT 类型上限足够（PostgreSQL TEXT 无硬上限）；前端限制 8000 字符 | 前端 maxLength 校验 |
| AI 生成质量依赖 LLM 能力 | 生成结果不可用 | 用户可手动编辑后保存；生成失败不影响其他功能 | E2E 测试覆盖生成 + 编辑流程 |
| 快捷指令 content 长度 ≤4000 字符 | 超长指令 | 前端 TextArea maxLength 限制 | 后端 VARCHAR(4000) 约束 |
