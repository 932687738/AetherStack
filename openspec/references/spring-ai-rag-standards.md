# Spring AI 知识库（RAG）规范（AetherStack）

> **适用范围**：关联仓库 **ai** 中 Knowledge Hub（`knowledgehub/**`）、Agent Hub 内知识库检索 `@Tool`、向量入库与检索相关设计与实现。  
> **配套**：`engineering-standards.md` §4.4、`.aetherstack/rules/spring-ai-rag.md`、`.aetherstack/rules/backend-ai.md`、`.aetherstack/rules/spring-ai-multi-agent.md`、`spring-ai-core-standards.md`、`domain-models.md`

---

## 1. 架构原则

| 原则 | 要求 |
|------|------|
| 多库分层 | 按业务域/数据类型独立知识库；禁止单索引混放全部文档 |
| 索引即服务 | 名称、描述、嵌入模型经 `application-knowledge.yml` / 配置中心；禁止硬编码表名、集合名 |
| 文档溯源 | 向量元数据保留 `source`、时间戳、文档 ID |
| 增量更新 | 支持增删改；禁止日常全量重建（初始化除外） |
| 单一生产路径 | 以 **knowledgehub** 表 + `knowledge_chunks.embedding` 为准；禁止新增第三套 RAG 存储（见 `backend-design-guide.md` §2.2） |

与 `backend-ai.md` 的关系：入库/问答编排优先 **CompiledGraph** + DomainService；本规范约束 **文档处理、向量契约、检索策略、Agent 集成与可观测性**。

---

## 2. 文档处理规范（强制）

### 2.1 分段策略

| 项 | 默认值 |
|----|--------|
| 分块大小 | 800~1200 字符 |
| 重叠 | 100~200 字符 |
| 实现 | Spring AI `DocumentSplitter`；代码类用语言感知分割器 |
| 元数据 | 每段追加 `doc_title`、`section`、`domain` |

复杂分段策略（去重、选库、语言检测）放在 **DomainService**，Graph 节点仅编排（见 `engineering-standards.md` §1）。

### 2.2 嵌入模型

- 中文知识库须使用支持中文的嵌入模型。
- **本项目默认**：DashScope embedding（维度见 `application-knowledge.yml`，当前工程基线 **1024**）。
- 切换模型（如 `text-embedding-3-small`、`bge-large-zh-v1.5`）须同步：配置声明、表/索引维度、HNSW 重建评估。

### 2.3 元数据最小集

每个 `Document` / chunk 须携带：

| 字段 | 说明 |
|------|------|
| `source` | 文件路径、URL 或 DB ID |
| `updated_at` | ISO-8601 |
| `doc_type` | `FAQ` / `PRODUCT_MANUAL` / `POLICY` / `CODE_API` 等 |
| `status` | `active` / `deprecated`（检索默认排除 deprecated） |
| `contains_pii` | 可选；无法脱敏时 `true`，检索后过滤或提示 |

### 2.4 清洗流水线

顺序：**去噪 → Markdown 标准化 → PII 脱敏 → 分段**。

- 实现为 `DocumentTransformer`（可组合多个 Transformer）。
- PII 清洗代码须标注 `// PII清洗`；须有单测（`AUTO-UT` / 触及 Graph prep 时 `AUTO-AI-UT`）。

---

## 3. 向量存储配置

| 项 | 要求 |
|----|------|
| 生产选型 | **Pgvector**（PostgreSQL 16 + pgvector，Flyway 迁移） |
| 配置前缀 | `spring.ai.vectorstore.*`；连接信息环境变量注入 |
| 索引 | HNSW 或 IVF_FLAT；元数据过滤字段建索引 |
| 禁止 | 内存 VectorStore 作持久知识库；agents 旧 VectorStore 新能力扩展（收敛至 knowledgehub） |
| 多租户 | 命名空间/分区 + 检索租户过滤 |

**配置示例**（片段，占位符不得提交真实密钥）：

```yaml
spring:
  ai:
    vectorstore:
      pgvector:
        host: ${VECTOR_DB_HOST}
        port: 5432
        database: knowledge_base
        table: knowledge_chunks
        dimensions: 1024
        index-type: HNSW
    embedding:
      api-key: ${DASHSCOPE_API_KEY}
      model: text-embedding-v3
```

---

## 4. 检索策略

### 4.1 相似度阈值

- 默认须设阈值，低于阈值的结果不注入 LLM。
- 阈值作为配置项；会话级阈值见存量能力 `KnowledgeRetrievalThresholdConfig`（0~100 分制），新需求与之对齐或说明差异。
- 各 Agent / Tool 可独立覆盖。

### 4.2 Top-K

| 场景 | 上限 |
|------|------|
| 向量检索 API | ≤10 |
| 注入 LLM 上下文 | 通常 3~5 |
| Tool 动态注入 + RAG | ≤3 |

### 4.3 元数据过滤

- 检索前按 `doc_type`、`domain`、`status`、租户等过滤。
- Agent `@Tool` 描述须说明过滤维度；调用检索 API 时显式传参。

### 4.4 重排序（Re-Rank）

政策、法律、合规类场景 **必须** 使用 reranker（如 `bge-reranker-v2-m3`）对初检结果二次排序，取 Top 3 注入。

design 须说明：是否 rerank、模型、失败降级策略。

---

## 5. 与智能体集成

### 5.1 知识库 `@Tool`

检索须封装为 `@Tool`，description **同时满足**：

1. `spring-ai-multi-agent-standards.md` 四段式（功能、典型问法、反例、前提）
2. 指明 **知识库名称**、返回摘要还是全文

**示例**：

```java
@Tool(description = """
从订单 FAQ 知识库检索答案。
适用场景：“如何取消订单”、“退款多久到账”。
不适用：查询实时物流（需调用物流 API）。
返回最相关的 3 条 FAQ 摘要。
""")
public String searchOrderFAQ(String query) { ... }
```

### 5.2 工具知识库

向量检索动态选择 Tool 时，工具描述库为独立索引，描述文本须预处理分段，受 §2、§3 约束。

### 5.3 返回格式化

注入 LLM 前统一模板：

```text
[来源: {source}] {content}
```

系统 prompt 或后处理须要求模型在回答中引用来源。

---

## 6. 监控与可观测性

每次检索须记录（结构化日志 + 可选 Micrometer）：

| 字段 | 说明 |
|------|------|
| 查询文本 | 脱敏后 |
| 耗时 | ms |
| 返回数量 | count |
| 分数 | max / min |
| 阈值过滤 | 是否触发 |

**Badcase**：空结果或低分（如 `<0.6`）采样入库，供调优。

**指标名**：`rag_search_duration_seconds`、`rag_results_count`、`rag_score_avg`。

---

## 7. 测试与验收

| 要求 | 标准 |
|------|------|
| 检索质量集 | 每知识库 ≥20 条问答对 |
| 指标 | Top-3 命中率、MRR |
| 回归 | 文档更新后自动化回归；质量下降 ≤5% |
| Agent 联动 | 新增 Agent 同步更新关联 KB 测试用例 |

OpenSpec tasks 建议：

- `AUTO-UT` / `AUTO-AI-UT`：分段、元数据、阈值过滤、格式化逻辑单测
- `AUTO-AI-IT`：多路召回 + rerank 集成测试（Mock 向量/嵌入）
- `MANUAL`：真实嵌入 + 端到端问答质量抽检

---

## 8. 安全与合规

- 入库前 PII 清洗；`contains_pii=true` 的文档检索后过滤或显式提示。
- 检索权限与租户隔离；A 租户不得检索 B 租户文档。
- **禁止**将用户输入拼接到 SQL；使用参数绑定 / Repository 安全查询。

---

## 9. OpenSpec design 必填项

涉及 RAG 入库、检索、Agent 集成的 design.md 须包含：

| 项 | 内容 |
|----|------|
| 知识库清单 | 名称、domain、doc_type、嵌入模型 |
| 分段参数 | 块大小、重叠、特殊文档策略 |
| 存储 | 表/索引、维度、是否多租户 |
| 检索 | `knowledge_base`、`score_threshold`、topK、元数据过滤、rerank |
| Graph 边界 | 哪些步骤在 Graph 节点 vs DomainService |
| 与多 Agent 关系 | RAG `@Tool` 清单、是否动态注入 |

delta spec 可增加字段：`knowledge_base`、`score_threshold`、`top_k`、`doc_type_filter`。

---

## 10. Harness 与本地验证

治理仓执行：

```powershell
.aetherstack/scripts/check-spring-ai-rag.ps1
.aetherstack/scripts/check-spring-ai-rag.ps1 -Strict
```

`make verify` 在后端测试通过后可执行（非 `-Strict` 为警告）。

检查项（静态，针对 `knowledgehub/**` 内 RAG 相关 `@Tool`）：

- `description` 非空且含知识库/FAQ/RAG 类指称
- 含「适用」与「不适用」类表述（与多 Agent 规范一致）
- 含返回说明（摘要/条数/全文）

---

## 11. 与 React/Graph、多 Agent 铁三角

| 规范 | 衔接 |
|------|------|
| `spring-ai-react-graph-standards.md` | Graph/RAG 节点：阈值、Top-K、`[来源]` 格式；节点禁止 `web.dto` |
| `spring-ai-multi-agent-standards.md` | RAG `@Tool` 四段式与 ≤5 动态注入 |

---

## 12. 参考索引

| 文档 | 用途 |
|------|------|
| `.aetherstack/rules/spring-ai-rag.md` | Cursor / Codex 规则源 |
| `.aetherstack/rules/backend-ai.md` | CompiledGraph 选型与 Graph 禁令 |
| `openspec/references/backend-design-guide.md` | 三套 RAG 收敛与演进 |
| `openspec/references/spring-ai-multi-agent-standards.md` | `@Tool` 四段式与动态注入 |
| `openspec/references/spring-ai-react-graph-standards.md` | ReactAgent / CompiledGraph 编排 |
| `openspec/references/ai-tdd-standards.md` | Graph prep / 检索 L1 单测 |
| `openspec/references/domain-models.md` | Knowledge Hub 领域边界 |
| `harness/adapters/java-maven/verify-commands.md` | 验证步骤 |
