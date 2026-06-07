# 设计审查（design-review）

> **Schema**：`standard-spec-driven`  
> **审查方式**：Superpowers `brainstorming`（设计审查模式）  
> **输入**：`proposal.md`、`specs/aether-platform-modular-structure/spec.md`、`design.md` v1.0  
> **Status**: Reviewed

Status: Reviewed

## 审查基线

| 项 | 值 |
|---|---|
| Change | `ai-platform-modular-refactor` |
| design.md 版本 | v1.0（2026-06-06） |
| 审查执行 | AI + brainstorming 设计审查 |
| 审查人确认 | **已确认**（用户指示后续按流程自动推进，无需逐步询问） |

## 审查结论摘要

- **总体结论**：**通过**
- **阻塞项数量**：2（均已修订 design.md v1.0）
- **建议项数量**：4（DR-03/DR-06/DR-07 待 tasks 落地）

## 模式评估（design-review 联动）

| 开关 | 结论 |
|------|------|
| `aiTddMode: enabled` | 维持 **enabled**；L1 单测随模块搬迁同步迁移包路径 |
| `uiCraftMode: disabled` | 无 U1 界面，维持 **disabled** |

---

## 审查维度与发现

### 1. 需求与 spec 对齐

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-01 | 阻塞 | spec req-1～8 覆盖五阶段，design 须显式映射 | design §1.3 目标表 + §4.2 分阶段验证 | **已修订** |
| DR-02 | 建议 | Flyway V3～V7 为估计值 | design §3.7 标注「实施前逐脚本核对」 | **已修订** |

### 2. 架构与分层（DDD / 四层）

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-03 | 建议 | KnowledgeRetrievalPort 落点未唯一 | tasks 明确接口定义在 knowledge-hub/domain/port | 待 tasks |
| DR-04 | 阻塞 | agent-hub 禁止依赖 knowledge-hub infrastructure | design §3.4 防腐 + §3.2 依赖禁令 | **已修订** |
| DR-05 | 建议 | aether-platform 已有 11 个 Repository 接口，搬迁风险低 | 阶段 3 单独验证 MapperScan | 待 tasks |

### 3. 接口与契约

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-06 | 建议 | integration-contracts 无需变更但须 E2E 回归 | test-cases TC-REQ8-02 覆盖三主路径 | 待 test-cases |
| DR-07 | 建议 | 路径映射文档 ai/docs/modular-refactor-path-map.md | tasks 每阶段强制更新 | 待 tasks |

### 4. 非功能与可观测性

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-08 | 建议 | Bean 重复与扫描遗漏为最高运行时风险 | 阶段 0 强制 + 启动集成 MANUAL 用例 | **已修订** §7.1 |

### 5. Spring AI / 铁三角（如适用）

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-09 | 建议 | Graph 基类提取至 ai-alibaba 须保持单例 compile | 搬迁后验证 Graph Bean 非 per-request compile | 待 tasks |
| DR-10 | 建议 | L1 单测须随模块迁移 | design §4.4 列出 L1 范围 | **已修订** |

### 6. 风险、假设与备选方案

| ID | 严重度 | 发现 | 建议 / 处置 | design 修订 |
|----|--------|------|-------------|-------------|
| DR-11 | 建议 | 9 周工期较长，可并行度有限 | tasks 按阶段 gate，阶段内子模块可并行 | 待 tasks |

## 阻塞项清单（须清零后方可进入 test-cases / tasks）

- [x] DR-01：spec 与 design 阶段映射 — **已修订**
- [x] DR-04：跨域依赖禁令 — **已修订**

## design.md 修订记录

| 章节 | 修订摘要 | 对应 DR |
|------|----------|---------|
| §1.3 / §4.2 | 五阶段目标与验证点 | DR-01 |
| §3.2 / §3.4 | 依赖禁令与防腐 Port | DR-04 |
| §3.7 | Flyway 估计值免责声明 | DR-02 |
| §4.4 | L1 AI-TDD 范围 | DR-10 |
| §7.1 | Bean 冲突可观测性 | DR-08 |

## 用户确认

- [x] 审查结论已阅读，同意进入 test-cases / tasks 阶段（用户授权自动推进）
