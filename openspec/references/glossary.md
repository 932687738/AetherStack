# Terminology Glossary (AetherStack)

本文件包含 AetherStack 项目使用的技术术语与核心业务术语。编写规范、命名字段或沟通语义时应引用此处标准用语。

## 技术术语

### 数据对象

- **DTO (Data Transfer Object)** - 层间数据传输对象，如 `knowledgehub.dto`
- **Record** - Java record，用于不可变领域对象（如 `KnowledgeBase`）
- **VO** - 前端展示对象（本项目 frontend 多为 plain object）

### DDD 术语

- **Bounded Context（限界上下文）** - Agent Hub、Knowledge Hub 等
- **Aggregate Root（聚合根）** - 如 KnowledgeBase
- **Repository（仓储）** - 如 `KnowledgeChunkRepository`
- **Application Service（应用服务）** - 用例编排，如 `DocumentUploadService`
- **Domain Event（领域事件）** - Hook 发布的前/后/异常事件

### AI / 工程术语

- **Agent Hub** - 多智能体统一编排入口
- **SubAgent** - 子智能体，处理特定意图
- **Orchestrator** - 意图路由与对话编排
- **RAG** - Retrieval-Augmented Generation，检索增强生成
- **SSE** - Server-Sent Events，流式响应协议
- **pgvector** - PostgreSQL 向量扩展
- **HNSW** - 向量近似最近邻索引算法
- **MCP** - Model Context Protocol，工具/上下文协议
- **OpenSpec** - 规范驱动开发流程
- **obra Superpowers** - Cursor 插件（TDD、代码审查等通用工作流）；项目约束在 `.aetherstack/rules/`
- **Harness** - 六阶段 AI 工程实践框架

### 前后端术语

- **Nebula Desk** - 前端产品名（包名 `aetherstack-frontend`）
- **DashScope** - 默认 LLM/Embedding 提供商（阿里云）
- **Agent Hub API** - 前缀 `/api/agent-hub/*`

## 业务术语

| 中文 | 英文 | 说明 |
|------|------|------|
| 知识库 | Knowledge Base | 文档与向量集合的容器 |
| 知识文档 | Knowledge Document | 上传的文件及其元数据 |
| 知识分段 | Knowledge Chunk | 文档切片及 embedding |
| 知识库模式 | Knowledge Chat Mode | 基于 RAG 的对话 |
| 智能体模式 | Agent Chat Mode | SubAgent 路由对话 |
| 需求开发模式 | Requirement Dev Mode | 项目经理式需求编排 |
| 流式对话 | Streaming Chat | SSE 逐 token 返回 |
| 长期记忆 | Long-term Memory | 跨会话持久化记忆 |
| 会话记忆 | Session Memory | 当前会话上下文 |

## OpenSpec 术语

| 术语 | 说明 |
|------|------|
| change | 进行中变更目录 `openspec/changes/` |
| spec | 已归档真相 `openspec/specs/` |
| delta | 变更相对现状的 ADDED/MODIFIED 段落 |
| schema | 工作流定义（standard/simple/bugfix） |
| apply | 按 tasks 进入实现阶段 |
| AUTO-UT | 可自动化单元测试的用例标记 |
| AUTO-AI-UT | AI 核心模块单元测试（AI-TDD 开启时强制，Mock LLM） |
| AUTO-AI-IT | 复杂 RAG/Graph 集成测试（推荐） |
| aiTddMode | OpenSpec 变更 AI-TDD 开关：enabled / disabled / auto |
| uiCraftMode | OpenSpec 变更 UI-Craft 开关（Impeccable）：enabled / disabled / auto |
| UI-CRAFT / UI-FUNC | 前端任务类型：可见 UI 改版 vs 纯 API 逻辑 |
| MANUAL | 需人工验证的用例标记 |
