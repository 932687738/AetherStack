> **任务编号规则（项目级）**  
> 采用 `SPEC_ID-REQ_NO` 作为任务标题中的需求标识，其中：  
> - `SPEC_ID` = 变更期 specs/ 下的一层目录名（能力 ID）  
> - `REQ_NO` = 对应 spec.md 中的 `req-X` 编号  
> 示例：`gwms-outbound-pda-scan-ship-1` 对应 `specs/gwms-outbound-pda-scan-ship/spec.md#req-1`

## 1. <需求/模块名称（SPEC_ID-REQ_NO）>

- [ ] 1.1 <后端：功能实现 + 可验证输出>
- [ ] 1.2 <前端：交互/页面 + 可验证输出>（标注 UI-CRAFT / UI-AUDIT / UI-FUNC）
- [ ] 1.2a <若 UI-CRAFT/UI-AUDIT 且 uiCraftMode enabled：Impeccable shape/craft 或 audit→polish + impeccable: <命令链> + 可验证输出>
- [ ] 1.3 <测试标记：Automation（AUTO-UT / AUTO-AI-UT / MANUAL）>
- [ ] 1.4a <若 AUTO-AI-UT（AI-TDD）：**先**编写 L1 模块单测（Mock LLM）+ 可验证输出（`*Test.java`）>
- [ ] 1.4 <若 AUTO-UT / AUTO-AI-UT：根据 test-cases 完成单测 + 可验证输出>
- [ ] 1.5 <若 AUTO-UT / AUTO-AI-UT：执行 `mvn -Dtest=XxxTest test` + trace: TC-REQx-yy → XxxTest#method + 可验证输出>
- [ ] 1.6 <若 MANUAL：人工验证 + 可验证输出>

## 2. <需求/模块名称（SPEC_ID-REQ_NO）>

- [ ] 2.1 <后端：功能实现 + 可验证输出>
- [ ] 2.2 <前端：交互/页面 + 可验证输出>（标注 UI 类型）
- [ ] 2.2a <若 UI-CRAFT/UI-AUDIT：Impeccable 任务 + 可验证输出>
- [ ] 2.3 <测试标记：Automation（AUTO-UT / AUTO-AI-UT / MANUAL）>
- [ ] 2.4a <若 AUTO-AI-UT：先编写 L1 单测 + 可验证输出>
- [ ] 2.4 <若 AUTO-UT / AUTO-AI-UT：单测实现 + 可验证输出>
- [ ] 2.5 <若 AUTO-UT / AUTO-AI-UT：执行测试命令 + 可验证输出>
- [ ] 2.6 <若 MANUAL：人工验证 + 可验证输出>

---

**任务拆分原则（强制）**：
- 输出物导向：每个任务 = 可交付业务功能
- 粒度控制：1 个任务 ≈ 1 个 Requirement（参考 spec.md，不是 design.md）
- 依赖最小化：标注前置任务，支持并行
- 每个任务必须包含“可验证输出”
- 必须从 `test-cases.md` 读取每条 `[C]` 的 `Automation` 标记并映射到任务
- 对 `AUTO-UT` / `AUTO-AI-UT` 任务，从 test-cases 读用例，写单测，跑命令
- `aiTddMode: enabled` 时 L1 实现任务依赖 1.4a/1.4 单测任务完成
- `uiCraftMode: enabled` 时 U1 前端依赖 1.2a Impeccable 完成；UI-FUNC 除外
