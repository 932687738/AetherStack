# AetherStack 文档同步 Skill

## 触发

用户要求更新文档、同步 CHANGELOG、或代码变更后需维护文档时。

## 步骤

1. 识别变更范围（backend / frontend / openspec / 根文档）
2. 按 `.aetherstack/rules/documentation.md` 更新对应文件
3. 若 API 变更，更新 `.aetherstack/context/api-contracts.yaml`
4. 运行 `make sync-config`（若改了 .aetherstack/）

## 输出

列出已更新文件路径。
