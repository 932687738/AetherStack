# AI 工作流与配置

AetherStack 的 AI 增强能力由 **obra Superpowers** Cursor 插件 + **`.aetherstack/`** 项目规则组成。

---

## 1. 能力矩阵

| 能力 | 组件 | 触发方式 |
|------|------|----------|
| 智能代码生成 | Harness `hev-coder` + **harness-apply** + OpenSpec apply | `/opsx-apply`（三阶段 Analyze/Code/Verify） |
| 代码审查 | obra `requesting-code-review` | 关键词：`cr`、`code review` |
| 单元测试 / TDD | obra `test-driven-development` | 关键词：单测、unit test、AUTO-UT |
| **AI 阶段化 TDD** | obra `test-driven-development` + `rules/ai-tdd.md` | OpenSpec `aiTddMode: enabled`；或 `/tdd`、`AI-TDD` |
| **前端 UI Craft** | Impeccable（`.cursor/skills/impeccable/`） | OpenSpec `uiCraftMode: enabled`；或 `/impeccable`、`UI-Craft` |
| 方案 / 计划 / 调试 | obra 插件其他 skills | brainstorming、writing-plans、systematic-debugging 等 |
| 需求追溯 | OpenSpec changes/specs | `/opsx-new`、`/opsx-sync` |
| 上下文感知 | `.aetherstack/context/` + rules | sync-config 自动加载 |
| 文档同步 | `.aetherstack/rules/documentation.md` | 「更新文档」「同步 changelog」 |
| 提交型 DDD 设计 | `.aetherstack/rules/ddd-commit-design.md` | 提交型写用例、Commit 专文 |

---

## 2. 架构

```text
obra Superpowers（Cursor 插件）     ← 通用方法论
        +
.aetherstack/                       ← 项目 rules + context
        +
OpenSpec + Harness                  ← 需求与验证
```

### 安装 obra Superpowers（Cursor）

```text
/add-plugin superpowers
```

### `.aetherstack/` 结构

```text
.aetherstack/
├── manifest.yaml
├── rules/
│   ├── core.md
│   ├── superpowers.md      # 插件集成 + 项目审查/TDD 约束
│   ├── ai-tdd.md           # AI 阶段化 TDD（OpenSpec aiTddMode 开关）
│   ├── ddd-commit-design.md
│   ├── documentation.md
│   └── ...
├── context/
├── commands/commands.yaml
└── scripts/sync-config.ps1
```

**已移除**（由 obra 插件替代）：`workflows/`、`skills-index.yaml`、`aether-skills/`。

### 同步

```powershell
make sync-config
```

---

## 3. Cursor 示例

```
用户：cr backend
AI：  invoke requesting-code-review
      遵循 rules/superpowers.md（LOCALPATH、DDD 维度）
      审查 ai 仓库
```

```
用户：为 XxxService 写单测
AI：  invoke test-driven-development
      遵循 rules/superpowers.md + harness 测试模板
```

```
用户：OpenSpec 重构 chatAgent，AI-TDD enabled
AI：  0.1 写入 .openspec.yaml → aiTddMode: enabled
      design 列出 L1 模块 → test-cases 标 AUTO-AI-UT
      apply 时 invoke test-driven-development
      遵循 ai-tdd-standards.md + ai-test-templates.md
      Mock ChatClient；Prompt 断言关键片段；Flux 用 StepVerifier
```

---

## 4. AI 阶段化 TDD（与 OpenSpec 开关联动）

### 4.1 为什么单独一套规范？

| 对比 | 常规 AUTO-UT | AI-TDD（AUTO-AI-UT） |
|------|-------------|----------------------|
| 范围 | Service 规则校验、CRUD | ChatClient 封装、Prompt、路由、Graph prep、流式编排 |
| 外部依赖 | DB/Repository Mock | **DashScope/ChatClient 必须 Mock** |
| 断言 | 返回值/异常 | Prompt **关键片段**（非整串相等）、**Flux 顺序** |
| 强制时机 | test-cases 标记 AUTO-UT | `aiTddMode: enabled` 或 auto 命中 L1 |

简单 CRUD、DTO 映射 **不强制** AI 范式，沿用常规 `AUTO-UT` 即可。

### 4.2 OpenSpec 开关（0.1 第 4 步）

变更目录 `.openspec.yaml`：

```yaml
schema: standard-spec-driven
aiTddMode: enabled   # enabled | disabled | auto
```

| 值 | 行为 |
|----|------|
| `enabled` | L1 模块必须先写 `*Test.java` 再改生产代码；tasks 中 `1.4a` 为阻断项 |
| `disabled` | 不强制 `AUTO-AI-UT` |
| `auto`（默认） | design 列出 L1 模块时等同 `enabled` |

### 4.3 模块分层

| 层级 | 示例 | AI-TDD enabled 时 |
|------|------|-------------------|
| **L1** | `AgentChatService`、`AgentPromptService`、路由 DomainService、Graph prep 节点 | **强制 TDD** |
| **L2** | 多路 RAG、Graph 检索链 | 推荐 `AUTO-AI-IT` 集成测试 |
| **L3** | Repository、DTO、简单 CRUD | 常规 `AUTO-UT`，可放宽 |

### 4.4 测试范式要点（/tdd 阶段）

1. **Mock AI 外部依赖**：禁止单测调用真实 DashScope
2. **Prompt 验证**：`contains` / `doesNotContain` 关键片段，禁止完整字符串 `assertEquals`
3. **流式响应**：`StepVerifier` 验证 `Flux<String>`；Controller 可用 `WebTestClient`
4. **先测后码**：`AUTO-AI-UT` 任务未完成不得勾选 L1 实现任务

### 4.5 流程串联

```text
OpenSpec 0.1（aiTddMode）
    → design（L1 模块清单）
    → test-cases（AUTO-AI-UT / AUTO-AI-IT）
    → tasks（1.4a 先写单测）
    → apply（invoke test-driven-development）
```

非 OpenSpec：对话中说 `/tdd` 或 `AI-TDD` 即走同一套规范。

### 4.6 文档索引

| 文档 | 说明 |
|------|------|
| [openspec/references/ai-tdd-standards.md](../openspec/references/ai-tdd-standards.md) | 完整规范 |
| [.aetherstack/rules/ai-tdd.md](../.aetherstack/rules/ai-tdd.md) | 规则源（sync → `aether-ai-tdd.mdc`） |
| [harness/adapters/java-maven/ai-test-templates.md](../harness/adapters/java-maven/ai-test-templates.md) | 代码模板 |
| [openspec/references/tech-stack.md](../openspec/references/tech-stack.md) | 测试策略摘要 |

---

## 5. 前端 UI Craft（Impeccable + OpenSpec 开关）

### 5.1 与 Superpowers / AI-TDD 的区别

| 维度 | AI-TDD | UI-Craft |
|------|--------|----------|
| 仓库 | **ai** 后端 | **ai_react** 前端 |
| 工具 | Superpowers TDD | **Impeccable** skill |
| 关注点 | 逻辑正确性、Mock LLM | 视觉、交互、无障碍、craft |
| 开关 | `aiTddMode` | `uiCraftMode` |

二者在 OpenSpec 0.1 **独立选择**，可组合（全栈新功能常两者 `enabled` 或 `auto`）。

### 5.2 开关（0.1 第 5 步）

```yaml
uiCraftMode: enabled   # enabled | disabled | auto
```

| 值 | 行为 |
|----|------|
| `enabled` | U1 界面（UI-CRAFT/UI-AUDIT）必须 Impeccable |
| `disabled` | 前端 lint/build 即可 |
| `auto` | design 含 U1 界面清单时等同 `enabled` |

### 5.3 U1 / U3 分层

- **U1**：页面、组件、布局改版 → `shape`/`craft` 或 `audit`→`polish`
- **U3**：`api/*`、SSE 解析、无视觉变更 → **跳过** Impeccable

### 5.4 示例

```
用户：OpenSpec 改版聊天侧边栏，uiCraftMode enabled
AI：  design 含「前端 UI 界面清单」
      tasks：1.2a Impeccable craft → 1.2 实现
      读 impeccable/SKILL.md → shape → craft → polish
      ai_react：npm run lint && npm run build
```

---

## 6. Codex / Claude Code

无插件市场；读取 `.aetherstack/rules/superpowers.md`、`.aetherstack/rules/ai-tdd.md`、`.aetherstack/rules/ui-craft.md` 及 GitHub 上 obra skill 正文；Impeccable 见 `.cursor/skills/impeccable/`。

---

## 7. 相关文档

- [AGENTS.md](../AGENTS.md)
- [.aetherstack/rules/superpowers.md](../.aetherstack/rules/superpowers.md)
- [.aetherstack/rules/ai-tdd.md](../.aetherstack/rules/ai-tdd.md)
- [openspec/references/ai-tdd-standards.md](../openspec/references/ai-tdd-standards.md)
- [.aetherstack/rules/ui-craft.md](../.aetherstack/rules/ui-craft.md)
- [openspec/references/ui-craft-standards.md](../openspec/references/ui-craft-standards.md)
- [obra Superpowers 安装](https://obra-superpowers.mintlify.app/installation/cursor)
