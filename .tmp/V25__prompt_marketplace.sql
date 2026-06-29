-- Prompt 市场 / 快捷指令 / 收藏
-- 复用 Skill 版本管理模式：tenant_id + name + version + status + UNIQUE

-- ============================================================
-- 1. prompt_templates（仿 skills 表结构）
-- ============================================================
CREATE TABLE IF NOT EXISTS prompt_templates (
    id              BIGSERIAL PRIMARY KEY,
    tenant_id       VARCHAR(64)   NOT NULL,
    name            VARCHAR(128)  NOT NULL,
    description     TEXT,
    version         INT           NOT NULL,
    status          VARCHAR(32)   NOT NULL DEFAULT 'active',
    category        VARCHAR(64)   NOT NULL,
    content         TEXT          NOT NULL,
    tags            TEXT[]        NOT NULL DEFAULT '{}',
    source          VARCHAR(32)   NOT NULL DEFAULT 'preset',
    created_by      VARCHAR(64),
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_prompt_templates_tenant_name_version UNIQUE (tenant_id, name, version),
    CONSTRAINT chk_prompt_templates_source CHECK (source IN ('preset', 'generated', 'custom'))
);

CREATE INDEX IF NOT EXISTS idx_prompt_templates_tenant_category_status
    ON prompt_templates (tenant_id, category, status);

CREATE INDEX IF NOT EXISTS idx_prompt_templates_tenant_name_status
    ON prompt_templates (tenant_id, name, status);

COMMENT ON TABLE prompt_templates IS 'Prompt 市场模板库：版本管理 + 多租户 + 分类浏览';
COMMENT ON COLUMN prompt_templates.source IS 'preset=预置, generated=AI生成, custom=用户自定义';

-- ============================================================
-- 2. quick_commands（独立表，支持乐观锁 version）
-- ============================================================
CREATE TABLE IF NOT EXISTS quick_commands (
    id              BIGSERIAL PRIMARY KEY,
    tenant_id       VARCHAR(64)   NOT NULL,
    agent_name      VARCHAR(128)  NOT NULL,
    name            VARCHAR(128)  NOT NULL,
    content         VARCHAR(4000) NOT NULL,
    icon            VARCHAR(64),
    version         INT           NOT NULL DEFAULT 1,
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_quick_commands_tenant_agent_name UNIQUE (tenant_id, agent_name, name)
);

CREATE INDEX IF NOT EXISTS idx_quick_commands_tenant_agent
    ON quick_commands (tenant_id, agent_name);

COMMENT ON TABLE quick_commands IS 'Agent 快捷指令：CRUD + 乐观锁';

-- ============================================================
-- 3. prompt_favorites
-- ============================================================
CREATE TABLE IF NOT EXISTS prompt_favorites (
    id              BIGSERIAL PRIMARY KEY,
    user_id         VARCHAR(64)   NOT NULL,
    template_id     BIGINT        NOT NULL,
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_prompt_favorites_user_template UNIQUE (user_id, template_id)
);

CREATE INDEX IF NOT EXISTS idx_prompt_favorites_user
    ON prompt_favorites (user_id);

COMMENT ON TABLE prompt_favorites IS '用户 Prompt 收藏';

-- ============================================================
-- 4. agent_registry 新增 system_prompt 列
-- ============================================================
ALTER TABLE agent_registry ADD COLUMN IF NOT EXISTS system_prompt TEXT;

COMMENT ON COLUMN agent_registry.system_prompt IS 'Agent 的 System Prompt，由 Prompt 市场选用写入';

-- ============================================================
-- 5. 预置模板种子数据（12 条）
-- ============================================================
INSERT INTO prompt_templates (tenant_id, name, description, version, status, category, content, tags, source, created_by)
VALUES
('default', 'translation-zh-en', '中文翻译为英文，保持专业术语准确', 1, 'active', '翻译',
 '请将以下中文内容翻译为英文，要求：\n1. 保持专业术语准确\n2. 语句通顺自然\n3. 保留原文格式结构\n\n待翻译内容：\n{{content}}',
 ARRAY['中文','英文','翻译'], 'preset', 'system'),

('default', 'translation-en-zh', '英文翻译为中文，保持语义完整', 1, 'active', '翻译',
 '请将以下英文内容翻译为中文，要求：\n1. 语义完整准确\n2. 符合中文表达习惯\n3. 保留原文格式结构\n\n待翻译内容：\n{{content}}',
 ARRAY['英文','中文','翻译'], 'preset', 'system'),

('default', 'summary-concise', '精简摘要，提取核心要点', 1, 'active', '摘要',
 '请对以下内容进行精简摘要，要求：\n1. 提取不超过5个核心要点\n2. 每个要点用一句话概括\n3. 保留关键数据和结论\n\n原文：\n{{content}}',
 ARRAY['摘要','精简','要点'], 'preset', 'system'),

('default', 'code-review', '代码审查，关注质量与安全', 1, 'active', '代码审查',
 '请审查以下代码，从以下维度给出建议：\n1. 代码质量（命名、结构、可读性）\n2. 潜在 Bug 和边界情况\n3. 安全漏洞\n4. 性能优化建议\n\n代码：\n```\n{{content}}\n```',
 ARRAY['代码','审查','安全','质量'], 'preset', 'system'),

('default', 'writing-polish', '文章润色，提升表达质量', 1, 'active', '写作',
 '请对以下文章进行润色，要求：\n1. 提升语言表达的流畅度和专业性\n2. 修正语法和拼写错误\n3. 保持原文核心意思不变\n4. 给出修改说明\n\n原文：\n{{content}}',
 ARRAY['写作','润色','优化'], 'preset', 'system'),

('default', 'data-analysis', '数据分析报告生成', 1, 'active', '数据分析',
 '请根据以下数据生成分析报告，包含：\n1. 数据概览与趋势分析\n2. 关键指标解读\n3. 异常值识别与说明\n4. 结论与建议\n\n数据：\n{{content}}',
 ARRAY['数据','分析','报告'], 'preset', 'system'),

('default', 'customer-service', '客服回复模板，专业友好', 1, 'active', '客服',
 '你是一位专业的客服代表。请根据用户的咨询内容，给出专业、友好的回复：\n1. 先确认理解用户问题\n2. 给出明确解答或操作指引\n3. 提供后续支持渠道\n4. 语气亲切专业\n\n用户咨询：\n{{content}}',
 ARRAY['客服','回复','专业'], 'preset', 'system'),

('default', 'email-draft', '商务邮件撰写', 1, 'active', '写作',
 '请根据以下要点撰写一封商务邮件：\n1. 主题明确、简洁\n2. 正文条理清晰\n3. 语气正式得体\n4. 包含适当的开头和结尾\n\n要点：\n{{content}}',
 ARRAY['邮件','商务','撰写'], 'preset', 'system'),

('default', 'sql-generator', '自然语言转 SQL 查询', 1, 'active', '代码审查',
 '根据以下需求生成 SQL 查询语句：\n1. 使用标准 SQL 语法\n2. 包含必要的 JOIN 和 WHERE 条件\n3. 添加适当的索引建议\n4. 给出查询优化说明\n\n需求描述：\n{{content}}',
 ARRAY['SQL','查询','生成'], 'preset', 'system'),

('default', 'meeting-notes', '会议纪要整理', 1, 'active', '写作',
 '请将以下会议内容整理为结构化纪要：\n1. 会议主题与时间\n2. 参会人员\n3. 讨论要点（按议题分组）\n4. 决议事项与负责人\n5. 后续行动项（含截止日期）\n\n会议内容：\n{{content}}',
 ARRAY['会议','纪要','整理'], 'preset', 'system'),

('default', 'api-doc', 'API 接口文档生成', 1, 'active', '代码审查',
 '请根据以下接口信息生成标准 API 文档：\n1. 接口概述\n2. 请求方法与路径\n3. 请求参数（含类型、必填、说明）\n4. 响应格式（含示例）\n5. 错误码说明\n6. 调用示例\n\n接口信息：\n{{content}}',
 ARRAY['API','文档','接口'], 'preset', 'system'),

('default', 'brainstorm', '头脑风暴助手，发散思维', 1, 'active', '写作',
 '针对以下主题进行头脑风暴：\n1. 列出至少10个创意方案\n2. 每个方案简述优缺点\n3. 按可行性排序\n4. 推荐最佳方案并说明理由\n\n主题：\n{{content}}',
 ARRAY['头脑风暴','创意','发散'], 'preset', 'system')
ON CONFLICT (tenant_id, name, version) DO NOTHING;
