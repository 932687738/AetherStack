# Metrics 采集规范

## 采集方式

融合两种采集方式，互补覆盖：

| 方式 | 来源 | 特点 |
|------|------|------|
| Hook 回调 | V2 onSubAgentStart/End | 结构化、可靠、与 Claude Code Hooks 集成 |
| METRIC 标记 | V3 零侵入 HTML 注释 | 轻量、自包含、Agent 输出中嵌入 |

## Hook 回调机制

通过 Claude Code 的 Hooks 配置实现阶段级 metrics 采集。

### 阶段映射

| Harness 阶段 | Metrics Phase | Hook 事件 |
|-------------|---------------|----------|
| 目录索引 | requirement | Start hook |
| 沟通计划 | techDesign | PostToolUse (Agent) |
| 执行计划 | coding | PostToolUse (Agent) |
| 验证计划 | review | PostToolUse (Bash: mvn) |
| 完成计划 | complete | Stop hook |
| 文档归档 | archive | Stop hook |

### Hook 配置

在 `settings.json` 中配置：

```json
{
  "hooks": {
    "Start": [{
      "hooks": [{
        "type": "command",
        "command": "powershell -ExecutionPolicy Bypass -File \"$HOME/.claude/hooks/harness-metrics-start.ps1\" 2>$null; exit 0"
      }]
    }],
    "PreToolUse": [{
      "matcher": "AskUserQuestion",
      "hooks": [{
        "type": "command",
        "command": "powershell -ExecutionPolicy Bypass -File \"$HOME/.claude/hooks/harness-metrics.ps1\" -EventType \"askUser\" 2>$null; exit 0"
      }]
    }],
    "PostToolUse": [{
      "matcher": "Bash|Read|Write|Edit|Grep|Glob",
      "hooks": [{
        "type": "command",
        "command": "powershell -ExecutionPolicy Bypass -File \"$HOME/.claude/hooks/harness-metrics.ps1\" -EventType \"$TOOL_NAME\" 2>$null; exit 0"
      }]
    }],
    "Stop": [{
      "hooks": [{
        "type": "command",
        "command": "powershell -ExecutionPolicy Bypass -File \"$HOME/.claude/hooks/harness-metrics-stop.ps1\" -Status \"success\" 2>$null; exit 0"
      }]
    }]
  }
}
```

### 采集数据

| 字段 | 说明 |
|------|------|
| session_id | 会话唯一标识 |
| start_time / end_time | 起止时间 |
| phase | 当前阶段（requirement/techDesign/coding/review/complete/archive） |
| tool_calls | 工具调用次数（按类型分） |
| interactions | 交互轮数 |
| files_changed | 变更文件数 |
| issues_found | 发现问题数（Linter/编译/测试） |
| loop_count | 验证循环次数 |

## METRIC 标记规范

在 hev-* Agent 输出中嵌入 HTML 注释格式的 metrics 标记：

```markdown
<!-- METRIC:PHASE:techDesign:START -->
... 技术分析内容 ...
<!-- METRIC:PHASE:techDesign:END -->

<!-- METRIC:PHASE:coding:START -->
... 编码内容 ...
<!-- METRIC:PHASE:coding:END -->

<!-- METRIC:PHASE:review:START -->
... 验证内容 ...
<!-- METRIC:ISSUE:CRITICAL:2 -->
<!-- METRIC:ISSUE:HIGH:3 -->
<!-- METRIC:PHASE:review:END -->

<!-- METRIC:FIX:LOOP_EXCEEDED -->
```

### 解析规则

1. Hook 脚本扫描 Agent 输出中的 METRIC 标记
2. 提取 PHASE 和 ISSUE 数据
3. 汇总到 metrics 报告

## 输出

### 阶段5（完成）时的 Metrics 摘要

```markdown
## Metrics 摘要

| 指标 | 值 |
|------|-----|
| 总耗时 | 12m 30s |
| 工具调用 | Read:15, Edit:8, Grep:12, Bash:6 |
| 交互轮数 | 8 |
| 变更文件 | 5 |
| 验证循环 | 2/3 |
| 问题发现 | CRITICAL:1, HIGH:3 |
| 问题修复 | CRITICAL:1, HIGH:3 |
```

### 归档时的 Metrics 数据

metrics 数据随 summary 一起归档到 `docs/archive/{task-key}/{task-key}-summary.md` 的 Metrics 部分。
