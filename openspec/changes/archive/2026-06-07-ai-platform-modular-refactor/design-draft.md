# ai-platform Maven 多模块重构 - 整体方案

## 一、核心问题

**要解决什么问题**：单模块 Maven 项目无法按业务域独立演进，知识库代码三份并存有 Bean 冲突风险，多 AI 框架与基础设施缺乏抽象层，Flyway/配置/依赖边界模糊。

**技术挑战**：
- 724 个 Java 文件搬迁须保持 Git 历史与零功能回归
- Spring Bean 全量扫描跨 19 个 JAR 须无遗漏、无重复
- Graph 节点、MyBatis Mapper、Flyway 脚本物理位置变更但执行语义不变
- `agents.knowledge` 与 `knowledgehub` 防腐边界须在搬迁前收敛

---

## 二、整体思路

**分五阶段渐进提取**：先收敛债务 → 横切基础 → AI 框架 → 业务域 → 启动组装。每阶段 `mvn clean compile` 门禁，业务域阶段最高风险单独预留 3 周。

**业务场景**：
- 新增向量库（Milvus）→ 新建 `vector-store-milvus` 实现 `vector-store-api`，业务零改动
- 新增机器人（钉钉）→ 新建 `bot-dingtalk` 实现 `bot-api`
- 新增 AI 框架 → 新建模块实现 `ai-core` 端口

**技术实现思路**：
- 父 POM `ai-platform` 统一 BOM 版本；仅 `application` 启用 Spring Boot Plugin
- 包名保留 `com.yxy.deepseek.*`，仅 Maven 模块边界变化
- 跨域：`KnowledgeRetrievalPort` / `KnowledgeAdminPort` 防腐；禁止 agent-hub import knowledge-hub infrastructure
- `learning` 模块 `@Profile("demo")` 或 POM 隔离，生产 classpath 不引入

---

## 三、技术选型

| 功能场景 | 技术组件 | 使用理由 |
|---------|---------|---------|
| 多模块构建 | Maven 父子 POM + `<modules>` | 与现有 Maven 工具链一致，IDE 支持成熟 |
| AI 抽象层 | 自研 `ai-core` 端口接口 | 框架无关，对齐 DDD 依赖倒置 |
| Graph 编排基类 | `ai-alibaba`（CompiledGraph） | 生产主路径已在 knowledgehub/aether-platform |
| 向量存储 | `vector-store-api` + `vector-store-pgvector` | 生产已用 pgvector HNSW 1024 维 |
| 持久化 | `platform-persistence` + 各域 Flyway | 共享 DataSource，脚本按域归属 |
| 启动 | `application` 单入口 | 明确部署单元，配置 `spring.config.import` 聚合 |

不涉及 MQ 新增；Redis/Caffeine 保留在 `nosql` 模块按 `aether.platform.cache.type` 条件装配。

---

## 四、影响范围

### 系统间影响
- 前端 **ai_react**：无影响（契约不变）
- 飞书 / MCP 外部集成：端点路径不变，仅内部模块边界调整

### 模块改动
- **ai 全仓库**：`pom.xml` 重构 + 源码 `git mv` 至 19 子模块
- **AetherStack 治理仓**：OpenSpec 工件 + 可选 `ARCHITECTURE.md` 同步

### 接口变更
- **无新增/修改对外 REST/SSE 接口**（非 BREAKING）
- 内部：新增 Maven 模块间 Java 接口依赖（防腐 Port）

---

## 五、数据设计

### 数据模型关系
- **无表结构变更**；仅 Flyway 脚本**文件位置**按域迁移
- 实体关系与聚合不变（KnowledgeBase、PlatformAgent 等）

### 表结构要点
```sql
-- 无新增/修改表 DDL
-- Flyway 脚本物理迁移：
--   platform-persistence: V1~V2（共享基础表）
--   knowledge-hub:      V3~V7（知识库域）
--   aether-platform:    V8~V16（平台治理域）
```

---

## 六、约束与风险

### 技术约束
- 性能：模块化不引入额外网络 hop，运行时仍为单进程多 JAR classpath
- 业务：包名不重命名，降低 import 修改量
- 技术：每阶段编译门禁；`git mv` 保留历史

### 风险点

| 风险 | 应对措施 |
|------|---------|
| Bean 重复定义（knowledge 三份） | 阶段 0 强制收敛 staged 副本 |
| Graph 节点扫描失败 | `scanBasePackages` 全包扫描 + 启动集成测试 |
| Flyway 重复/漏执行 | 脚本内容不变，仅路径；聚合 locations 单测验证 |
| 环形 Maven 依赖 | 每阶段 `dependency:tree`；业务域 → learning 禁止 |
| L1 单测路径变更 | `aiTddMode: enabled`，搬迁后同步 `*Test.java` 包路径 |

---

## 七、待 AI 细化

- [x] 19 子模块清单与依赖拓扑（见 design.md §三）
- [x] 分阶段迁移清单与旧路径→新路径映射规则
- [x] 防腐 Port 接口落点与 Adapter 职责
- [x] Flyway 归属表与 `spring.flyway.locations` 配置
- [x] 验收命令与 E2E 端点清单
- [x] tasks 分阶段可勾选任务
