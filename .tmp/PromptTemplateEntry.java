package com.yxy.deepseek.superAgents.domain.prompt;

import java.time.Instant;
import java.util.List;

/**
 * Prompt 模板聚合（单版本一行），参照 {@code SkillEntry}。
 */
public final class PromptTemplateEntry {

    private final Long id;
    private final String tenantId;
    private final String name;
    private final String description;
    private final int version;
    private final PromptTemplateStatus status;
    private final String category;
    private final String content;
    private final List<String> tags;
    private final String source;
    private final String createdBy;
    private final Instant createdAt;
    private final Instant updatedAt;

    public PromptTemplateEntry(
            Long id,
            String tenantId,
            String name,
            String description,
            Integer version,
            PromptTemplateStatus status,
            String category,
            String content,
            List<String> tags,
            String source,
            String createdBy,
            Instant createdAt,
            Instant updatedAt) {
        this.id = id;
        this.tenantId = tenantId;
        this.name = name;
        this.description = description;
        this.version = version == null ? 0 : version;
        this.status = status;
        this.category = category;
        this.content = content;
        this.tags = tags == null ? List.of() : List.copyOf(tags);
        this.source = source;
        this.createdBy = createdBy;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    public Long getId() { return id; }
    public String getTenantId() { return tenantId; }
    public String getName() { return name; }
    public String getDescription() { return description; }
    public int getVersion() { return version; }
    public PromptTemplateStatus getStatus() { return status; }
    public String getCategory() { return category; }
    public String getContent() { return content; }
    public List<String> getTags() { return tags; }
    public String getSource() { return source; }
    public String getCreatedBy() { return createdBy; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
}
