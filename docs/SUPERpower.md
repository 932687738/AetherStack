# AI 工作流与配置

AetherStack 的 AI 增强能力由 **obra Superpowers** Cursor 插件 + **`.aetherstack/`** 项目规则组成。

---

## 1. 能力矩阵

| 能力 | 组件 | 触发方式 |
|------|------|----------|
| 智能代码生成 | Harness `hev-coder` + OpenSpec apply | `/opsx-apply`、Harness 执行阶段 |
| 代码审查 | obra `requesting-code-review` | 关键词：`cr`、`code review` |
| 单元测试 / TDD | obra `test-driven-development` | 关键词：单测、unit test、AUTO-UT |
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

---

## 4. Codex / Claude Code

无插件市场；读取 `.aetherstack/rules/superpowers.md` 及 GitHub 上 obra skill 正文，叠加项目 rules。

---

## 5. 相关文档

- [AGENTS.md](../AGENTS.md)
- [.aetherstack/rules/superpowers.md](../.aetherstack/rules/superpowers.md)
- [obra Superpowers 安装](https://obra-superpowers.mintlify.app/installation/cursor)
