# OpenSpec 框架同步记录

> 最后合并：2026-05-30  
> 源项目：`D:\cache\workspace\qwmsspec`（**仅复制，不修改源**）

## 已人工合并的文件

以下文件已从 qwmsspec 框架 **理解性适配** 为 AetherStack 版本（非整文件覆盖）：

| 文件 | 来源 | 说明 |
|------|------|------|
| `openspec/config.yaml` | qwmsspec/config.yaml | 保留 AetherStack context + 完整 rules 段 |
| `openspec/references/aether-rules.md` | qwms-rules.md | 完整 0.0–8 节 + 5.1–5.10 设计约束 |
| `openspec/references/engineering-standards.md` | engineering-standards.md | 适配 Spring Boot 四层与模块映射 |
| `openspec/references/tech-stack.md` | tech-stack.md | 适配 Java17/SpringAI/React 栈 |
| `openspec/references/architecture.md` | architecture.md | AetherStack 架构（非 QWMS） |
| `openspec/references/domain-models.md` | domain-models.md | Agent/Knowledge 领域 |
| `openspec/references/glossary.md` | glossary.md | 技术+业务术语（精简） |
| `openspec/references/directory-examples.md` | directory-examples.md | aether-* 命名 |
| `openspec/references/integration-contracts.md` | integration-contracts.md | 前后端 API 契约 |
| `AGENTS.md` | qwmsspec/AGENTS.md | 可选工单 + aether-skills |

## 机械同步（robocopy 即可）

- `openspec/schemas/`（18 文件）
- `.cursor/skills/openspec-*`
- `.cursor/commands/opsx-*`

## 编码修复

- `sync-config.ps1` 使用 UTF-8 无 BOM 写入
- `CLAUDE.md` 从 `.aetherstack/templates/CLAUDE.md` 复制，避免脚本内嵌中文乱码
