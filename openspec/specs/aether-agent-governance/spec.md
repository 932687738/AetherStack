# Skill 生命周期治理

## Agent Hub / Skill 治理 需求说明（前提/操作/结果）
> Skill 版本、灰度发布、相似度冲突检测、废弃观察期下线；Skill 评估与 A/B。
> 交付阶段：**P4**。详见 proposal `aether-agent/governance`。

---

## Requirements

<a name="req-1"></a>
### Requirement: 1. Skill 灰度发布 [P4]

<a name="openspec-req-1"></a>系统 shall 支持按租户或用户百分比配置 Skill 活跃版本，实时调整无需重启。

#### 场景: 50% 流量试用 v2
- **前提**：Skill「退款指引」v1 active，v2 灰度 50%。
- **操作**：并发多用户调用。
- **结果**：约一半走 v2；Trace 记录版本号。

---

<a name="req-2"></a>
### Requirement: 2. Skill 冲突检测 [P4]

<a name="openspec-req-2"></a>系统 shall 在新 Skill 上线前计算与已有 Skill 描述的向量相似度；超阈值写入 skill_conflicts 供人工复核。

#### 场景: 高相似新 Skill
- **前提**：新 Skill 描述与存量 Skill 余弦相似度 > 配置阈值。
- **操作**：提交上线。
- **结果**：写入 skill_conflicts；可阻断或警告发布。

---

<a name="req-3"></a>
### Requirement: 3. Skill 废弃流程 [P4]

<a name="openspec-req-3"></a>系统 shall 支持 Skill 状态 active → deprecated → observed → deleted；观察期监测调用量后安全下线。

#### 场景: 废弃 Skill 观察期
- **前提**：Skill 标记 deprecated 进入 observed。
- **操作**：观察期内仍有调用。
- **结果**：指标可见；到期无调用可 deleted；有调用则延长或通知迁移。

---

<a name="req-4"></a>
### Requirement: 4. Skill 效果评估 [P4]

<a name="openspec-req-4"></a>系统 shall 统计 Skill 完成率、平均步数与用户反馈，支持 A/B 对比报告。

#### 场景: v1 vs v2 对比
- **前提**：两版本灰度并行一周。
- **操作**：查看评估报表。
- **结果**：含完成率、平均步数、反馈分对比。

---

