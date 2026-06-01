---
description: Spring AI 知识库(RAG)开发规范 - 文档处理、向量存储、检索策略、与Agent集成
globs: "**/*.java,**/*.yml,**/*.yaml,**/*.properties,**/*.sql,**/*.md"
alwaysApply: true
---

# Spring AI 知识库（RAG）开发规范

> **适用范围**：关联仓库 **ai** 中 `knowledgehub/**` 及 Agent Hub 内知识库检索 `@Tool` 相关 Java、YAML、SQL。  
> **配套**：`openspec/references/spring-ai-rag-standards.md`、`.aetherstack/rules/backend-ai.md`、`.aetherstack/rules/spring-ai-core.md`、`.aetherstack/rules/spring-ai-multi-agent.md`、`.aetherstack/rules/spring-ai-react-graph.md`（铁三角）  
> **生产主路径**：`knowledgehub` 表结构 + CompiledGraph；**禁止**新增第三套 RAG 存储。

## 一、知识库架构原则

- **多库分层**：按业务域或数据类型划分独立知识库（订单 FAQ、产品手册等），禁止所有文档混入单一索引。
- **索引即服务**：每个知识库须有明确名称、描述、嵌入模型标识，经配置中心 / `application-knowledge.yml` 管理；**禁止**硬编码集合名或索引名。
- **文档溯源**：入库文档须保留原始来源（文件路径、URL、数据库 ID）与时间戳，写入向量元数据。
- **增量更新**：须支持增量写入、更新、删除；**禁止**以全量重建作为日常更新手段（初始化除外）。

## 二、文档处理规范（强制）

1. **分段策略**
   - 使用 `DocumentSplitter` 分段，默认 **800~1200 字符**，重叠 **100~200 字符**。
   - 代码类文档用语言感知分割器（如 `CodeSplitter`）；表格密集型文档须保留表格上下文。
   - 每段须追加元数据：`doc_title`、`section`、`domain`。

2. **嵌入模型**
   - 中文知识库须使用支持中文的嵌入模型（本项目默认 DashScope；亦可 `bge-large-zh-v1.5` 等）。
   - 模型名称与维度须在 `application-knowledge.yml` 声明；**禁止**代码写死。

3. **元数据最小集**
   - `source`：原始路径或 URL
   - `updated_at`：ISO 时间戳
   - `doc_type`：`FAQ` / `PRODUCT_MANUAL` / `POLICY` / `CODE_API` 等
   - `status`：`active` / `deprecated`（废弃文档检索时默认排除）

4. **清洗流水线**
   - 顺序：去噪 → Markdown 标准化 → PII 脱敏 → 分段。
   - 封装为 `DocumentTransformer`，便于复用与单测。

## 三、向量存储配置规范

- **选型**：生产推荐 **Pgvector**（本项目主选）；Redis Stack / Milvus 可经 OpenSpec 论证。**禁止**内存型向量存储作持久知识库。
- **连接**：经 `spring.ai.vectorstore` 前缀注入；**禁止**硬编码连接信息。
- **索引**：向量索引 `IVF_FLAT` 或 **HNSW**；元数据过滤字段（`domain`、`doc_type`、`status`）须建索引。
- **多租户**：每租户独立命名空间/分区，检索时带租户过滤。

## 四、检索策略规范

1. **相似度阈值**：默认须设阈值（如 **0.7** 或项目配置的 0~100 分制换算）；低于阈值不返回。阈值可配置，各 Agent 可独立覆盖。
2. **Top-K**：单次检索 **≤10**；注入 LLM 通常 **3~5**；与 Tool 动态注入结合时 **≤3**。
3. **元数据过滤**：按意图 / Agent 领域过滤（如 `doc_type=FAQ` 且 `domain=order`）；Tool 描述须体现，API 显式传入。
4. **重排序**：政策问答、法律条款等重要场景须用 reranker（如 `bge-reranker-v2-m3`），最终 Top 3 注入。

## 五、知识库与智能体集成

- 检索封装为标准 `@Tool`；description 须含：知识库名称、适用场景、反例、返回摘要或全文说明（并遵循 `spring-ai-multi-agent.md` 四段式）。
- **工具知识库**：向量动态选 Tool 时，工具描述须预处理分段，独立索引，受本规范约束。
- **返回格式**：传给 LLM 前统一为 `[来源: {source}] {content}`，并要求 LLM 引用来源。

## 六、监控与可观测性

须记录：查询文本（脱敏）、检索耗时、返回数量、最高/最低相似度、是否命中阈值过滤。

空结果或低分（如 <0.6）须告警并采样入 Badcase 表。暴露 Micrometer 指标：`rag_search_duration_seconds`、`rag_results_count`、`rag_score_avg`。

## 七、测试与验收

- 每知识库至少 **20 条**问答对，评估 Top-3 命中率、MRR。
- 文档更新后触发回归，检索质量下降 **≤5%**。
- 新增 Agent 须同步更新关联知识库测试用例。

## 八、安全与合规

- 入库前 PII 清洗；无法清洗的标记 `contains_pii=true` 并在检索后过滤或提示。
- 检索须与用户/租户权限对齐。
- **禁止**用户输入直接拼接 SQL；须参数绑定或 ORM 安全查询。

## 九、代码风格

- 组件统一放在 `knowledgehub/**`（domain / application / graph / infrastructure）。
- 类与方法注释说明所属知识库、文档类型、分段参数。
- PII 清洗代码标注 `// PII清洗`。

## 十、验证与 OpenSpec

- 本地：`make verify`；RAG `@Tool` 可选 `.aetherstack/scripts/check-spring-ai-rag.ps1`。
- OpenSpec design 涉及 RAG 时须引用 `spring-ai-rag-standards.md`，并说明 `knowledge_base`、`score_threshold`、topK、rerank。
- 代码审查（`cr backend`）触及 knowledgehub / RAG `@Tool` 时须核对 §二~§六。
