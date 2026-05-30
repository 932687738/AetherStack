# 阶段3：执行计划

## 目标

按执行计划编码实现，通过多 Agent 协作确保代码质量。

## 前置条件门控（MUST）

进入执行阶段前，MUST 逐项验证：

- [ ] 每个 SP 在 PLANS.md 中已注册（含 status 列）
- [ ] 每个 SP 对应的 design-doc 存在且非空（`docs/plans/{task-key}/sp{n}-{name}.md`）
- [ ] 每个 SP 对应的 exec-plan 存在且含任务拆解表（`docs/plans/{task-key}/sp{n}-{name}-exec.md`）
- [ ] 前置 SP 状态为 Completed（若当前 SP 有依赖）

⚠️ 任何一项不满足 → MUST 回退到 Phase 2 补充，不得跳过。

## Agent 分发守卫（MUST）

执行引擎 MUST 按以下逻辑分发：

1. 读取 `harness.config.yaml` → `agents` 配置
2. 若任一 agent 的 `enabled: true`：
   - MUST 使用 `subagent_type` 对应的 hev-* Agent 执行
   - 主 Agent 仅做编排，MUST NOT 直接编写业务代码
3. 若所有 agent 的 `enabled: false` 或未配置：
   - 主 Agent 直接执行（Mode B）
4. 每个步骤执行前 MUST 打印分发决策：
   `[Agent-Dispatch] Step={stepId} → Agent={agentType} | Mode={A/B} | Reason={config状态}`

## 前置条件

- 阶段2 已完成：exec-plan 已生成并经用户确认
- PLANS.md 当前子计划状态为 Planned
- 依赖的前置子计划已 Completed

## 流程

```
1. 读取 exec-plan
    ↓
2. 更新 PLANS.md 状态为 In Progress
    ↓
3. 选择执行引擎
    ↓
4. 按步骤执行编码
    ↓
5. 进入阶段4（验证）
```

## 执行引擎

### 配置驱动调度

**读取 `harness.config.yaml` 中 `agents` 配置，确定调度目标。**

### 模式A：Agent 模式（config.agents 中有 enabled=true 的 Agent）

如果 config.agents.analyzer.enabled = true，调度 hev-analyzer：
```
Harness 阶段3
    ↓ 传入 exec-plan 的核心接口和场景类型
hev-analyzer 执行
    ↓ 接口验证 + 条件-接口映射
    ↓ 输出验证结果和映射表
```

如果 config.agents.coder.enabled = true，调度 hev-coder：
```
Harness 阶段3
    ↓ 传入 exec-plan 的任务拆解和技术方案摘要
hev-coder 执行
    ↓ 依赖预检查 + 编码 + 熵预防
    ↓ 输出变更文件清单
```

**验证由阶段4 的 hev-verifier 负责，不在执行阶段做验证。**

**关键**：hev-* Agent 负责 单个子计划的 分析→编码 小循环，Harness 负责 计划拆分→调度→验证→归档 的大循环。

### 模式B：内置工具执行

如果 config.agents 未配置或全部 disabled，使用内置工具直接执行：

1. 读取 exec-plan 中的步骤
2. 按步骤顺序：
   - 使用 Read/Grep 理解现有代码
   - 使用 Edit/Write 修改代码
   - 使用 Bash 执行构建命令
3. 每步完成后检查变更是否符合预期
4. 所有步骤完成后进入阶段4

## 执行过程中的约束

1. **只改 exec-plan 声明的文件**：不做计划外的变更
2. **每步验证**：完成一步后检查编译是否通过
3. **代码规范**：遵循 DESIGN.md 中的编码标准
4. **不自动提交**：代码变更在阶段5由用户确认后才提交
5. **不跳过步骤**：按 exec-plan 中的步骤顺序执行

## 执行日志

执行过程中记录：

```
[子计划 P1] Step 1/5: 创建 Entity 类
  → 变更: src/main/java/com/example/User.java (+85行)
  → 验证: mvn compile 通过

[子计划 P1] Step 2/5: 创建 Repository 接口
  → 变更: src/main/java/com/example/UserRepository.java (+12行)
  → 验证: mvn compile 通过
```

## 异常处理

| 情况 | 处理 |
|------|------|
| 编译失败 | 检查错误，修复后重试（≤2次），仍失败则暂停升级用户 |
| 接口不存在 | 标记为待确认，不猜测方法签名，升级用户 |
| 依赖缺失 | 检查 pom.xml/build.gradle，添加缺失依赖 |
| exec-plan 步骤需调整 | 更新 exec-plan 文档，继续执行 |
