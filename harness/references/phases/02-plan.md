# 阶段2：沟通计划 / 任务拆分

## 目标

与用户沟通需求，将大需求拆分为可独立执行的子计划，每个子计划有明确的文档输出和验证标准。

## 流程

```
用户提出需求
    ↓
1. 理解需求：结合 AGENTS.md 和 INDEX.md 理解项目结构
    ↓
2. 评估复杂度：单一功能 or 需要拆分
    ↓
3. 拆分子计划（如需要）
    ↓
4. 在 PLANS.md 注册所有子计划
    ↓
5. 为每个子计划生成 design-doc + exec-plan
    ↓
6. 与用户确认拆分方案
    ↓
进入阶段3（执行第一个子计划）
```

## 任务拆分原则

### 约束

- 单个子计划变更文件数 ≤ 15
- 单个子计划预估交互数 ≤ 5
- 每个子计划必须有独立的验证标准
- 每个子计划完成后可独立提交

### 拆分策略

| 需求类型 | 拆分策略 | 示例 |
|---------|---------|------|
| 单一 CRUD | 不拆分，作为一个子计划 | "增加用户管理模块" |
| 多实体 CRUD | 按实体拆分 | "用户+角色+权限" → 3个子计划 |
| 新功能模块 | 按层次拆分：数据层→业务层→接口层 | "支付模块" → 3个子计划 |
| 重构 | 按模块拆分 | "重构认证系统" → auth模块 + session模块 |
| 跨模块功能 | 按接口拆分：先定义接口→各模块独立实现 | "添加审计日志" → 接口定义 + 各模块接入 |
| Bug 修复 | 不拆分，直接作为一个子计划 | "修复登录超时问题" |

### 拆分检查清单

拆分完成后，验证每个子计划：
- [ ] 变更范围清晰（文件列表可预判）
- [ ] 验证标准明确（Linter/编译/测试 通过）
- [ ] 与其他子计划的依赖关系已声明
- [ ] 可独立提交到 git

## PLANS.md 注册

### 状态流转

```
Planned → In Progress → Verifying → Completed
              ↓              ↓
           Blocked        Blocked
```

### PLANS.md 格式

层级化格式，按任务分段：

```markdown
## 进行中

### 📋 {task-key} - {任务名称}

> 状态: In Progress | 创建: yyyy-MM-dd | 优先级: P0

**任务概述**：<!-- 一段话描述目标和范围 -->

| # | 子计划 | 状态 | 依赖 | 技术方案 | 执行计划 |
|---|--------|------|------|---------|---------|
| sp1 | | Planned | — | [方案](plans/{task-key}/sp1-xxx.md) | [计划](plans/{task-key}/sp1-xxx-exec.md) |
| sp2 | | Planned | sp1 | [方案](plans/{task-key}/sp2-xxx.md) | [计划](plans/{task-key}/sp2-xxx-exec.md) |

---

## 待启动

### 📋 {task-key} - {任务名称}

> 状态: Planned | 创建: yyyy-MM-dd | 优先级: P1

| # | 子计划 | 状态 | 依赖 | 技术方案 | 执行计划 |
|---|--------|------|------|---------|---------|
| sp1 | | Planned | — | [方案](plans/{task-key}/sp1-xxx.md) | [计划](plans/{task-key}/sp1-xxx-exec.md) |

---

## 已完成

| 任务 | 完成日期 | SP数 | 归档 |
|------|---------|------|------|
| {task-key} | yyyy-MM-dd | 3 | [archive/{task-key}/](archive/{task-key}/) |

## Spike/POC

| # | 验证项 | 任务 | SP | 状态 | 结论 |
|---|--------|------|-----|------|------|
| 1 | _示例：JPA VECTOR 写入限制_ | {task-key} | sp1 | Pending | — |
```

### 任务文件夹创建

拆分确认后，为每个任务创建文件夹：

```bash
# 多子计划任务
mkdir -p docs/plans/{task-key}
# 生成文件：
#   docs/plans/{task-key}/{task-key}.md            # 任务汇总
#   docs/plans/{task-key}/sp1-{name}.md             # 子计划1 技术方案
#   docs/plans/{task-key}/sp1-{name}-exec.md        # 子计划1 执行计划
#   docs/plans/{task-key}/sp2-{name}.md             # 子计划2 技术方案
#   docs/plans/{task-key}/sp2-{name}-exec.md        # 子计划2 执行计划
```

**小任务合并规则**：若任务仅有 1 个 SP 且无复杂依赖，可将 task summary + design + exec-plan 合并为单文件：
```
docs/plans/fix-login-bug/fix-login-bug.md    # 合并文档
```

**task-key 命名**灵活支持：
- Issue key：`FD-409828`
- 语义名：`user-mgmt`
- 混合：`FD-409828-refund-flow`

## 技术方案文档（design-doc）

每个子计划必须生成技术方案文档，模板见 `references/templates/design-doc-template.md`。

核心内容：
1. **需求分析**：功能点列表、边界条件
2. **技术选型**：方案对比（如需要）
3. **接口设计**：API 端点、数据模型
4. **实现方案**：条件-接口映射表、变更文件清单
5. **风险评估**：潜在问题和应对

## 执行计划文档（exec-plan）

每个子计划必须生成执行计划文档，模板见 `references/templates/exec-plan-template.md`。

核心内容：
1. **前置条件**：依赖的其他子计划/模块
2. **任务拆解**：步骤 → 变更文件 → 预估交互
3. **验证标准**：Linter/编译/测试/人工审查项
4. **文档更新清单**：完成后需更新的索引文件

### Spike/POC 注册（MUST）

技术验证项 MUST 在执行前注册到 PLANS.md：

1. 识别需要验证的技术风险点
2. 在 PLANS.md 对应 SP 行新增 `Spike` 列，记录验证项
3. 或在 PLANS.md 末尾新增 `## Spike/POC` 段：
   ```markdown
   ## Spike/POC

   | # | 验证项 | SP | 状态 | 结论 |
   |---|--------|-----|------|------|
   | 1 | JPA VECTOR 写入限制 | SP6 | Done | 需 Native UPDATE |
   ```
4. 执行 Spike 后 MUST 回填结论

### Phase 2 退出验证清单（MUST 全部 ✅）

退出 Phase 2 前，MUST 逐项确认：

- [ ] PLANS.md 已注册所有任务和 SP（含 status、依赖、链接）
- [ ] 每个任务文件夹已创建（`docs/plans/{task-key}/`）
- [ ] 每个任务有任务汇总文档（`{task-key}.md`）
- [ ] 每个 SP 有独立 design-doc（路径正确、内容非空）
- [ ] 每个 SP 有独立 exec-plan（含任务拆解表、验证标准）
- [ ] Spike/POC 已注册（如有技术验证项）
- [ ] 核心接口已在 design-doc 中声明（含全限定名）
- [ ] 前置条件已列出并标记验证状态

⚠️ 任何一项未完成 → MUST NOT 进入 Phase 3。

## 异常处理

| 情况 | 处理 |
|------|------|
| 需求不明确 | AskUserQuestion 补充细节 |
| 拆分方案有争议 | 提供多种拆分方案让用户选择 |
| 依赖关系复杂 | 按拓扑排序确定执行顺序，阻塞项标记为 Blocked |
| 单个子计划过于复杂 | 继续拆分，直到满足约束 |
