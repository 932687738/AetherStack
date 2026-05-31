> **任务编号规则（项目级）**  
> 采用 `SPEC_ID-REQ_NO` 作为任务标题中的需求标识。

## 1. <需求/模块名称（SPEC_ID-REQ_NO）>

- [ ] 1.1 <后端：功能实现 + 可验证输出>
- [ ] 1.2 <前端：交互/页面 + 可验证输出>（UI-CRAFT / UI-AUDIT / UI-FUNC）
- [ ] 1.2a <若 U1 且 uiCraftMode enabled：Impeccable + 可验证输出>
- [ ] 1.3 <测试标记：Automation>
- [ ] 1.4a <若 AUTO-AI-UT：先编写 L1 单测（Mock LLM）+ 可验证输出>
- [ ] 1.4 <若 AUTO-UT / AUTO-AI-UT：单测实现 + 可验证输出>
- [ ] 1.5 <若 AUTO-UT / AUTO-AI-UT：执行测试命令 + 可验证输出>
- [ ] 1.6 <若 MANUAL：人工验证 + 可验证输出>

## 2. <需求/模块名称（SPEC_ID-REQ_NO）>

- [ ] 2.1 <后端：功能实现 + 可验证输出>
- [ ] 2.2 <前端：交互/页面 + 可验证输出>
- [ ] 2.3 <测试标记：Automation（AUTO-UT / AUTO-AI-UT / MANUAL）>
- [ ] 2.4a <若 AUTO-AI-UT：先编写 L1 单测 + 可验证输出>
- [ ] 2.4 <若 AUTO-UT / AUTO-AI-UT：单测实现 + 可验证输出>
- [ ] 2.5 <若 AUTO-UT / AUTO-AI-UT：执行测试命令 + 可验证输出>
- [ ] 2.6 <若 MANUAL：人工验证 + 可验证输出>

---

**任务拆分原则（强制）**：
- 输出物导向：每个任务 = 可交付业务功能
- 粒度控制：1 个任务 ≈ 1 个 Requirement（参考 spec.md）
- 依赖最小化：标注前置任务，支持并行
- 每个任务必须包含“可验证输出”
- 必须从 `test-cases.md` 读取 `Automation` 并映射到任务
- `AUTO-UT` / `AUTO-AI-UT`：写单测、跑命令
- `uiCraftMode: enabled`：U1 须 1.2a 先于 1.2 勾选
