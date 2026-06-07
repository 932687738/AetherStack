# 平台 RAG 集成

## Knowledge Hub / 平台原生 RAG 需求说明（前提/操作/结果）
> 内置 RAG 工具，复用 knowledgehub 生产主路径（pgvector）；支持索引、检索、来源引用；禁止新增第三套 RAG 存储。
> 交付阶段：**P1**。与 `aether-knowledge/upload` 存量能力协同。

---

## ADDED Requirements
（增强存量 RAG 为平台 Tool）

<a name="req-1"></a>
### Requirement: 1. 统一 RAG 检索 Tool [P1]

<a name="openspec-req-1"></a>系统应当（SHALL）提供标准 RAG 检索 Tool，供子 Agent / ReAct 调用；底层仅使用 knowledgehub 向量存储与多库召回，不新建平行索引。

#### 场景: 子 Agent 调用知识检索
- **前提**：知识库已有 active 文档。
- **操作**：子 Agent 调用 RAG Tool 查询企业政策。
- **结果**：返回 Top-K 片段，每条含来源标识；低于阈值不返回噪声片段。

---

<a name="req-2"></a>
### Requirement: 2. 检索结果注入 Prompt [P1]

<a name="openspec-req-2"></a>系统应当（SHALL）将 RAG 检索结果格式化为「[来源: xxx] 内容」并注入子 Agent System Prompt 或工作记忆，且要求 LLM 回答时引用来源。

#### 场景: 政策问答
- **前提**：RAG 命中 3 条政策片段。
- **操作**：子 Agent 生成用户可见答案。
- **结果**：答案含可识别来源引用；与检索片段一致。

---

<a name="req-3"></a>
### Requirement: 3. 知识库管理 Tool [P1]

<a name="openspec-req-3"></a>系统应当（SHALL）提供知识库管理 Tool（新增、更新、删除文档、触发重建索引），权限受租户与角色控制；实现复用既有 upload/CRUD 能力。

#### 场景: 授权用户上传文档
- **前提**：用户具 knowledge:write 权限。
- **操作**：通过管理 Tool 提交新文档。
- **结果**：文档入库并参与后续检索；无权限用户被拒绝。

---

<a name="req-4"></a>
### Requirement: 4. 禁止第三套 RAG 路径 [P1]

<a name="openspec-req-4"></a>系统应当（SHALL）禁止新增独立于 knowledgehub 的生产 RAG 存储；agents.knowledge 存量路径须在设计中给出收敛或防腐层方案。

#### 场景: 新功能需向量检索
- **前提**：平台新增 Agent 需检索企业知识。
- **操作**：架构评审新模块数据路径。
- **结果**：仅扩展 knowledgehub；不新建 vector_store 平行表系。

---
