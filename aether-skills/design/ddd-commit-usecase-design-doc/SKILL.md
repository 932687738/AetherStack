---
name: ddd-commit-usecase-design-doc
description: >-
  为「提交类」写用例（单次确认后持久化）编写 DDD 目标设计文档的通用流程：三阶段流水线（事前加载→内存装配→统一落库）、InputContext 与聚合根隔离、落库阶段事务、聚合 composeFrom 与 Part 协作、子实体/值对象划分、时序图与伪代码、与主设计文档及 API 契约同步；并含 GWMS 落地补充（异常码与 inbound_exception_message、PersistenceExecutor + 单类落库实现桥接仓储、校验顺序、自调用与事务）。在用户提及 commit 提交 DDD、聚合设计专文、事前加载内存落库、仓储事务边界、*-Commit-ddd、或直接上架 commit 工程约定时使用。
---

# 提交型写用例 — DDD 设计文档（通用工作流）

本技能描述**与具体业务无关**的文档结构与建模约定，适用于任意领域的「一次提交、单事务落库（或等价一致性边界）」型接口。业务专有表名、外部系统、库存/凭证等细节应在**具体变更的 `design.md` / 专文**中展开，**不**写入本技能正文。

## 1. 前置

1. **对齐契约**：对外 HTTP/JSON、错误码、幂等等以 **OpenSpec / API 清单 / 主 `design.md`** 为准；DDD 专文**不**擅自改写接口契约。
2. **准一来源**：若专文与主设计并存，在专文首声明**唯一维护路径**；源码树内避免双份长文（可保留占位链到专文）。
3. **实现路径**：按项目约定读取 **`LOCALPATH.md`** 或等价工程路径说明（若有）。

## 2. 设计立场（对照表）

用一张表写清与「边调现网大方法边落库」等旧模式的切割，通用维度示例：

| 维度 | 典型目标 |
|------|----------|
| 编排 | 不复用「整段业务入口」黑盒；吸收规则与字段语义，在本用例内显式编排 |
| 状态 | 中间过程仅在内存；持久化层只接收**聚合终态** |
| 外部副作用 | 需一次完成的副作用（如批量 RPC、账务提交）在阶段 C **按主设计顺序**集中调用，避免同一请求内多次等价提交 |

（业务-specific 行删去；由具体专文填写。）

## 3. 分层草图

用 text 树列出：**adapter → application（用例）→ domain（Command、LoadBundle、Aggregate、policies、领域服务）→ infrastructure（只读 Facade、Repository、Mapper）**。

**依赖方向**：领域不依赖框架与具体 DAO；基础设施不直接调用「替代整段旧链路」的遗留大入口（若项目有此约束）。

## 4. 三阶段流水线

| 阶段 | 名称 | 通用要点 |
|------|------|----------|
| **A** | 事前加载 | 只读；产出 **LoadBundle**（或等价快照）；不写业务结果表 |
| **B** | 内存装配 | **无**独立 `*Factory` 类；**聚合根**提供唯一入口（如 `composeFrom(command, bundle)`）；**`*Part`** 为构图协作单元 |
| **C** | 统一落库 | **写事务**建议在 **`Repository.saveFinalState(aggregate, hints)`（或项目约定命名）** 上开启；内部顺序对齐主设计中的落库/副作用清单 |

### 4.1 三类对象（与聚合隔离）

- **InputContext**：入参快照、解析后的租户/仓等、**LoadBundle**；**不**持有聚合根字段。
- **Aggregate**：领域终态；**不**混入传输层/安全上下文字段。
- **PersistHints**（可选）：从 InputContext 派生的横切薄片，供阶段 C 日志、审计、路由等；**不**复制聚合内领域事实的第二真相源。

### 4.2 聚合内四类建模

- **聚合根**
- **子实体**（将持久化的头/行意图）
- **值对象**（合并结果、维度键、意图快照等）
- **`*Part`**：仅协作构图，**不**映射到表；宜包私有或私有方法族

### 4.3 事务边界（常见约定）

- **用例方法**（如 `execute` / `commit`）：**不**标类级 `@Transactional`（若采用「仅落库事务」策略）。
- **仓储落库方法**：**唯一**声明读写事务的位置；注意 **自调用** 导致事务失效。

## 5. 溯源表

「遗留类/方法 → 吸收的规则或语义 → 在本方案中的落点（聚合子对象 / 仓储 / 领域服务）」；强调 **复用规则不复用整段调用**。

## 6. 伪代码骨架

1. 构建 `InputContext` → 预检 → 阶段 A 加载 → **`Aggregate.composeFrom`** → `PersistHints.from` → **`repository.saveFinalState(aggregate, hints)`**。
2. `@Transactional` 标在**落库实现**（若采用 §4.3）。
3. 异常与文案：遵循**项目约定**（如统一业务异常 + 消息资源 + 多语言流程）；可交叉引用 **`qwms-skills/gwms-i18n-workflow/SKILL.md`**（若项目为 GWMS/QWMS）。

## 7. 时序图套件（建议四幅）

| 图 | 内容 |
|----|------|
| 全景 | InputContext / Aggregate / PersistHints；写事务仅在进入仓储落库 |
| 预检 + 阶段 A | 只填充 InputContext |
| 阶段 B | `composeFrom` + 子对象/领域服务；无独立 Factory |
| 阶段 C | 映射与插入顺序按主设计 → 副作用按主设计顺序 |

**维护约定**：事务边界、阶段划分或装配方式变更时，**同步更新**全部图与伪代码。

## 8. 类职责表

按 adapter / application / port / domain / infrastructure 分列；事务职责与 §4.3 一致。

## 9. 与主设计同步

在主 `design.md` 用短句 + 链接指向专文；避免两处长期双写冲突。

## 10. 通用检查清单

- [ ] 三阶段清晰；阶段 B **无**平行 Factory 类
- [ ] InputContext / Aggregate / PersistHints 分离
- [ ] 写事务位置与项目策略一致（常见：仅落库方法）
- [ ] 子实体 / 值对象 / `*Part` 已说明；Mapper **不**映射 `*Part`
- [ ] 时序图与伪代码一致
- [ ] 异常与文案符合项目规范
- [ ] 与主 `design.md`、API 契约、落库顺序一致

## 11. GWMS / QWMS 落地补充（提交型用例通用，与具体表名无关的可复用约定）

以下摘自无单直接上架等「commit + 三阶段」类需求的**工程化共性**，便于新需求对齐；业务表、Manager 名仍以各变更 `design.md` / 专文为准。

### 11.1 异常与多语言（与专文 §13 一致）

- **枚举码**：领域或 inbound 包下集中定义 `*ExceptionCode` 字符串常量（如 `ERR_IB_*_COMMIT_*`），**禁止**在业务代码里把英文/中文句子作为唯一用户可见提示。
- **`BizException`**：`new BizException(codeConstant, arg0, arg1, …)`，`codeConstant` 与 **properties 中的 key** 一致。
- **资源文件**：GWMS 入库相关通常落在 `gwms-web/.../inbound_exception_message.properties` 及 `inbound_exception_message_zh_CN.properties` 等；新增 key 时 **多 bundle 同步**（至少默认 + `zh_CN`，其余 locale 可用英文占位避免缺 key）。详细流程见 **`qwms-skills/gwms-i18n-workflow/SKILL.md`**。
- **与 import / preview 对齐**：同一业务域的「导入预览」与「commit」应 **共用同一批 key**（或同一前缀族），避免双轨文案。

### 11.2 过渡期「编排桥接」仓储

- 目标形态是 **`RepositoryImpl#saveFinalState(aggregate, hints)`** 内按 Mapper 写 PO → `stockCore.submit` → 反馈 → 日志。
- **过渡**：可在 `@Transactional` 的 `saveFinalState` 内先 `AggregatePersistenceMapper#persistFromAggregate`（预检或骨架 INSERT），再委托 **单事务落库类**（如 `DirectPutawayCommitUnifiedPersistence#executePersistSteps`）。**仍保持「仅落库边界 Bean 声明写事务」**，领域聚合已预先 `composeFrom` 用于不变量与后续迁移；目标为落库类**仅 DAO/Manager**，组装上收聚合。
- **注意**：桥接阶段 **落库实现类** 与 **阶段 A `LoadFacade`** 可能对 **EA 包装、良品 SKU 状态、库位校验** 存在重复逻辑，评审或修改一处时须 **对照另一处**，必要时抽私有共享方法或工具类（仍以不破坏现网行为为前提）。

### 11.3 校验与加载顺序（建议固定）

1. **VO 层校验**（静态工具或入口首行）：必填、数量、扫描=实际、行上库位二选一。
2. **预检**：解析 `whId`（入参优先，否则安全上下文）、可选 **CIC 快照**（供审计或后续落库使用）。
3. **阶段 A**：`LoadFacade#load` → `LoadBundle`；再跑 **Bundle 级校验**（行上 sku / 库位均能由快照解析，与 import-preview 口径一致）。
4. **阶段 B**：`Aggregate.composeFrom`（领域内 **无 IO**）。
5. **阶段 C**：`Repository#saveFinalState`（**唯一** `@Transactional` 写边界）。

### 11.4 `@Transactional` 与自调用

- 落库实现类若再拆 `private` 方法写库，须通过 **接口代理 / self 注入** 调用带事务的方法，避免 **自调用导致事务不生效**（见本技能 §4.3）。
- **GWMS 实践**：可将写事务声明在独立 Bean（如 `DirectPutawayCommitPersistenceExecutor#executeSaveFinalState`），`RepositoryImpl#saveFinalState` 仅委托，便于同事务内先调 `AggregatePersistenceMapper` 再调 `DirectPutawayCommitUnifiedPersistence`；Mapper 全量落地后再收缩或删除该类。

### 11.5 文档与契约

- HTTP 形状以 **OpenSpec / `*-controller-api.json` / 主 `design.md`** 为准；DDD 专文（如 `*-Commit-ddd.md`）变更事务边界或阶段划分时，**同步** §2.1、时序图与伪代码（本技能 §7、§10）。

## 输出要求

使用本技能完成设计或评审后，在回复末尾追加：`Skills: ddd-commit-usecase-design-doc`
