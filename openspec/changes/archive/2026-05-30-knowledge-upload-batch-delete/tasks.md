> **任务编号规则（项目级）**  
> 采用 `SPEC_ID-REQ_NO` 作为任务标题中的需求标识，其中：  
> - `SPEC_ID` = 变更期 specs/ 下的一层目录名（能力 ID）  
> - `REQ_NO` = 对应 spec.md 中的 `req-X` 编号  
> 示例：`aether-knowledge-upload-1` 对应 `specs/aether-knowledge-upload/spec.md#req-1`

## 1. 按所选知识库展示已上传文档列表（aether-knowledge-upload-1）

- [x] 1.1 后端（ai / knowledgehub）：实现文档列表查询链路  
  - **依赖**：无  
  - **可验证输出**：`KnowledgeDocumentRepository.findByKnowledgeBaseId` 按 `updated_at DESC` 返回文档；`KnowledgeDocumentService.listByKnowledgeBase` 校验 KB 存在；`GET /api/agent-hub/knowledge-bases/{knowledgeBaseId}/documents` 返回 `DocumentSummaryResponse[]`；KB 不存在时 400。
- [x] 1.2 前端（ai_react）：上传页展示文档列表与空状态  
  - **依赖**：1.1  
  - **可验证输出**：`knowledge.js` 新增 `listDocuments(kbId)`；`UploadDocument.jsx` 在选中 KB 后加载列表，展示文件名/分段数/时间；无文档时显示空状态；切换 KB 重新拉取并清空勾选；上传成功后自动刷新列表。
- [x] 1.3 测试任务（待 test-cases Reviewed 后补充）

## 2. 支持单条与全选多选文档（aether-knowledge-upload-2）

- [x] 2.1 后端（ai / knowledgehub）：无变更（纯前端交互）  
  - **依赖**：1.1  
  - **可验证输出**：N/A；本 Requirement 不涉及后端接口变更。
- [x] 2.2 前端（ai_react）：文档列表多选与全选  
  - **依赖**：1.2  
  - **可验证输出**：每行复选框可勾选/取消；表头全选/取消全选当前页列表；`selectedIds` 状态与 UI 同步；切换 KB 后勾选清空。
- [x] 2.3 测试任务（待 test-cases Reviewed 后补充）

## 3. 批量删除所选文档且删除前必须二次确认（aether-knowledge-upload-3）

- [x] 3.1 后端（ai / knowledgehub）：实现批量删除 Service 与 REST 端点  
  - **依赖**：1.1  
  - **可验证输出**：`KnowledgeDocumentService.batchDelete` 逐条校验 document 归属 KB，按 `deleteByDocumentId → deleteById` 清理；`POST /api/agent-hub/knowledge/documents/batch-delete` 返回 `deletedCount` / `failedDocumentIds` / `message`；`KnowledgeHubApiPaths` 与 `KnowledgeHubExceptionHandler` 已覆盖新 Controller 方法。
- [x] 3.2 前端（ai_react）：批量删除入口与二次确认  
  - **依赖**：2.2、3.1  
  - **可验证输出**：未勾选时「批量删除」按钮 disabled；点击后 `window.confirm` 文案含 `{count}`；用户取消时不调用 API；确认后调用 `batchDeleteDocuments`。
- [x] 3.3 测试任务（待 test-cases Reviewed 后补充）

## 4. 删除完成后给出结果反馈并刷新列表（aether-knowledge-upload-4）

- [x] 4.1 后端（ai / knowledgehub）：完善批量删除响应文案  
  - **依赖**：3.1  
  - **可验证输出**：全成功 / 部分失败 / 全失败三种情况 `message` 字段语义明确；`failedDocumentIds` 准确反映失败条目。
- [x] 4.2 前端（ai_react）：删除结果提示与列表刷新  
  - **依赖**：3.2  
  - **可验证输出**：全成功展示成功提示并清空勾选；部分失败展示失败数量/提示，已成功项从列表消失；全失败列表不变、勾选保留便于重试；每次删除完成后重新 `loadDocuments()`。
- [x] 4.3 测试任务（待 test-cases Reviewed 后补充）

## 5. 契约与文档同步（横切）

- [x] 5.1 治理层：同步 API 契约文档  
  - **依赖**：3.1  
  - **可验证输出**：`openspec/references/integration-contracts.md` 与 `.aetherstack/context/api-contracts.yaml` 已登记列表与批量删除两个新接口；路径与 design-lite 一致。

---

**并行建议**
- 1.1 与 3.1 可同一人串行开发（共用 `KnowledgeDocumentService`），或先完成 1.1 再 3.1
- 1.2 / 2.2 可在 1.1 联调通过后并行
- 5.1 在 3.1 合并前完成

**apply 准入**：以上 1.x～5.x 开发任务完成后即可进入实现验收；测试占位项待 `test-cases.md` Status=Reviewed 后回填 AUTO-UT / MANUAL 任务。
