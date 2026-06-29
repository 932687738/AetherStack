# Prompt Marketplace - 批量生成后端代码文件
$base = "D:\cache\workspace\ai\aether-platform\src\main\java\com\yxy\deepseek\superAgents"
$resBase = "D:\cache\workspace\ai\aether-platform\src\main\resources"

# ============================================================
# Domain Layer
# ============================================================

# PromptTemplateStatus.java
@'
package com.yxy.deepseek.superAgents.domain.prompt;

/**
 * Prompt 模板生命周期状态，参照 {@code SkillStatus}。
 */
public enum PromptTemplateStatus {
    ACTIVE,
    DEPRECATED
}
'@ | Set-Content -Encoding UTF8 "$base\domain\prompt\PromptTemplateStatus.java" -Force

# PromptTemplateRepository.java (Port)
@'
package com.yxy.deepseek.superAgents.domain.prompt;

import java.util.List;
import java.util.Optional;

/**
 * Prompt 模板仓储端口（领域层），参照 {@code SkillRepository}。
 */
public interface PromptTemplateRepository {

    List<PromptTemplateEntry> listActiveByTenant(String tenantId);

    List<PromptTemplateEntry> listActiveByCategory(String tenantId, String category);

    List<PromptTemplateEntry> searchByKeyword(String tenantId, String keyword);

    Optional<PromptTemplateEntry> findById(Long id);

    PromptTemplateEntry insertVersion(PromptTemplateEntry draft);

    int findMaxVersion(String tenantId, String name);

    void deprecateActiveVersions(String tenantId, String name);

    void updateStatus(String tenantId, String name, int version, PromptTemplateStatus status);

    List<String> listCategories(String tenantId);
}
'@ | Set-Content -Encoding UTF8 "$base\domain\prompt\PromptTemplateRepository.java" -Force

# QuickCommand.java
@'
package com.yxy.deepseek.superAgents.domain.prompt;

import java.time.Instant;

/**
 * Agent 快捷指令实体（不可变），参照 {@code SkillEntry}。
 */
public final class QuickCommand {

    private final Long id;
    private final String tenantId;
    private final String agentName;
    private final String name;
    private final String content;
    private final String icon;
    private final int version;
    private final Instant createdAt;
    private final Instant updatedAt;

    public QuickCommand(Long id, String tenantId, String agentName, String name,
                        String content, String icon, Integer version,
                        Instant createdAt, Instant updatedAt) {
        this.id = id;
        this.tenantId = tenantId;
        this.agentName = agentName;
        this.name = name;
        this.content = content;
        this.icon = icon;
        this.version = version == null ? 1 : version;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    public Long getId() { return id; }
    public String getTenantId() { return tenantId; }
    public String getAgentName() { return agentName; }
    public String getName() { return name; }
    public String getContent() { return content; }
    public String getIcon() { return icon; }
    public int getVersion() { return version; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
}
'@ | Set-Content -Encoding UTF8 "$base\domain\prompt\QuickCommand.java" -Force

# QuickCommandRepository.java (Port)
@'
package com.yxy.deepseek.superAgents.domain.prompt;

import java.util.List;
import java.util.Optional;

/**
 * 快捷指令仓储端口（领域层）。
 */
public interface QuickCommandRepository {

    List<QuickCommand> findByAgentName(String tenantId, String agentName);

    Optional<QuickCommand> findById(Long id);

    QuickCommand insert(QuickCommand command);

    /** 乐观锁更新：version 不匹配时返回空。 */
    Optional<QuickCommand> update(QuickCommand command);

    void delete(Long id);
}
'@ | Set-Content -Encoding UTF8 "$base\domain\prompt\QuickCommandRepository.java" -Force

# PromptFavorite.java
@'
package com.yxy.deepseek.superAgents.domain.prompt;

import java.time.Instant;

/**
 * Prompt 收藏值对象。
 */
public final class PromptFavorite {

    private final Long id;
    private final String userId;
    private final Long templateId;
    private final Instant createdAt;

    public PromptFavorite(Long id, String userId, Long templateId, Instant createdAt) {
        this.id = id;
        this.userId = userId;
        this.templateId = templateId;
        this.createdAt = createdAt;
    }

    public Long getId() { return id; }
    public String getUserId() { return userId; }
    public Long getTemplateId() { return templateId; }
    public Instant getCreatedAt() { return createdAt; }
}
'@ | Set-Content -Encoding UTF8 "$base\domain\prompt\PromptFavorite.java" -Force

# PromptFavoriteRepository.java (Port)
@'
package com.yxy.deepseek.superAgents.domain.prompt;

import java.util.List;

/**
 * Prompt 收藏仓储端口（领域层）。
 */
public interface PromptFavoriteRepository {

    /** 幂等 toggle：存在则删除返回 false，不存在则插入返回 true。 */
    boolean toggle(String userId, Long templateId);

    List<PromptFavorite> listByUser(String userId);

    boolean isFavorite(String userId, Long templateId);
}
'@ | Set-Content -Encoding UTF8 "$base\domain\prompt\PromptFavoriteRepository.java" -Force

Write-Host "Domain layer done."

# ============================================================
# Infrastructure Layer - Mappers
# ============================================================

# PromptTemplateMapper.java
@'
package com.yxy.deepseek.superAgents.infrastructure.prompt;

import com.yxy.deepseek.superAgents.domain.prompt.PromptTemplateEntry;
import com.yxy.deepseek.superAgents.domain.prompt.PromptTemplateStatus;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface PromptTemplateMapper {

    int insert(PromptTemplateEntry entry);

    PromptTemplateEntry findById(@Param("id") Long id);

    List<PromptTemplateEntry> listActiveByTenant(@Param("tenantId") String tenantId);

    List<PromptTemplateEntry> listActiveByCategory(@Param("tenantId") String tenantId,
                                                    @Param("category") String category);

    List<PromptTemplateEntry> searchByKeyword(@Param("tenantId") String tenantId,
                                               @Param("keyword") String keyword);

    Integer findMaxVersion(@Param("tenantId") String tenantId, @Param("name") String name);

    int deprecateActiveVersions(@Param("tenantId") String tenantId, @Param("name") String name);

    int updateStatus(@Param("tenantId") String tenantId, @Param("name") String name,
                     @Param("version") int version, @Param("status") PromptTemplateStatus status);

    List<String> listCategories(@Param("tenantId") String tenantId);
}
'@ | Set-Content -Encoding UTF8 "$base\infrastructure\prompt\PromptTemplateMapper.java" -Force

# QuickCommandMapper.java
@'
package com.yxy.deepseek.superAgents.infrastructure.prompt;

import com.yxy.deepseek.superAgents.domain.prompt.QuickCommand;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface QuickCommandMapper {

    List<QuickCommand> findByAgentName(@Param("tenantId") String tenantId,
                                        @Param("agentName") String agentName);

    QuickCommand findById(@Param("id") Long id);

    int insert(QuickCommand command);

    /** 乐观锁更新：WHERE version = #{version}，返回受影响行数。 */
    int updateWithVersion(QuickCommand command);

    int deleteById(@Param("id") Long id);
}
'@ | Set-Content -Encoding UTF8 "$base\infrastructure\prompt\QuickCommandMapper.java" -Force

# PromptFavoriteMapper.java
@'
package com.yxy.deepseek.superAgents.infrastructure.prompt;

import com.yxy.deepseek.superAgents.domain.prompt.PromptFavorite;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface PromptFavoriteMapper {

    int insert(@Param("userId") String userId, @Param("templateId") Long templateId);

    int deleteByUserAndTemplate(@Param("userId") String userId, @Param("templateId") Long templateId);

    List<PromptFavorite> listByUser(@Param("userId") String userId);

    int countByUserAndTemplate(@Param("userId") String userId, @Param("templateId") Long templateId);
}
'@ | Set-Content -Encoding UTF8 "$base\infrastructure\prompt\PromptFavoriteMapper.java" -Force

Write-Host "Mapper interfaces done."

# ============================================================
# Infrastructure Layer - Repository Implementations
# ============================================================

# MyBatisPromptTemplateRepository.java
@'
package com.yxy.deepseek.superAgents.infrastructure.prompt;

import com.yxy.deepseek.superAgents.application.tenant.TenantGuard;
import com.yxy.deepseek.superAgents.domain.prompt.PromptTemplateEntry;
import com.yxy.deepseek.superAgents.domain.prompt.PromptTemplateRepository;
import com.yxy.deepseek.superAgents.domain.prompt.PromptTemplateStatus;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public class MyBatisPromptTemplateRepository implements PromptTemplateRepository {

    @Autowired
    private PromptTemplateMapper mapper;

    @Override
    public List<PromptTemplateEntry> listActiveByTenant(String tenantId) {
        return mapper.listActiveByTenant(TenantGuard.resolveTenantId(tenantId));
    }

    @Override
    public List<PromptTemplateEntry> listActiveByCategory(String tenantId, String category) {
        return mapper.listActiveByCategory(TenantGuard.resolveTenantId(tenantId), category);
    }

    @Override
    public List<PromptTemplateEntry> searchByKeyword(String tenantId, String keyword) {
        return mapper.searchByKeyword(TenantGuard.resolveTenantId(tenantId), keyword);
    }

    @Override
    public Optional<PromptTemplateEntry> findById(Long id) {
        return Optional.ofNullable(mapper.findById(id));
    }

    @Override
    public PromptTemplateEntry insertVersion(PromptTemplateEntry draft) {
        String tenantId = TenantGuard.requireTenantId(draft.getTenantId());
        mapper.insert(draft);
        return mapper.findById(draft.getId());
    }

    @Override
    public int findMaxVersion(String tenantId, String name) {
        Integer max = mapper.findMaxVersion(TenantGuard.resolveTenantId(tenantId), name);
        return max == null ? 0 : max;
    }

    @Override
    public void deprecateActiveVersions(String tenantId, String name) {
        mapper.deprecateActiveVersions(TenantGuard.resolveTenantId(tenantId), name);
    }

    @Override
    public void updateStatus(String tenantId, String name, int version, PromptTemplateStatus status) {
        mapper.updateStatus(TenantGuard.resolveTenantId(tenantId), name, version, status);
    }

    @Override
    public List<String> listCategories(String tenantId) {
        return mapper.listCategories(TenantGuard.resolveTenantId(tenantId));
    }
}
'@ | Set-Content -Encoding UTF8 "$base\infrastructure\prompt\MyBatisPromptTemplateRepository.java" -Force

# MyBatisQuickCommandRepository.java
@'
package com.yxy.deepseek.superAgents.infrastructure.prompt;

import com.yxy.deepseek.superAgents.application.tenant.TenantGuard;
import com.yxy.deepseek.superAgents.domain.prompt.QuickCommand;
import com.yxy.deepseek.superAgents.domain.prompt.QuickCommandRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public class MyBatisQuickCommandRepository implements QuickCommandRepository {

    @Autowired
    private QuickCommandMapper mapper;

    @Override
    public List<QuickCommand> findByAgentName(String tenantId, String agentName) {
        return mapper.findByAgentName(TenantGuard.resolveTenantId(tenantId), agentName);
    }

    @Override
    public Optional<QuickCommand> findById(Long id) {
        return Optional.ofNullable(mapper.findById(id));
    }

    @Override
    public QuickCommand insert(QuickCommand command) {
        TenantGuard.requireTenantId(command.getTenantId());
        mapper.insert(command);
        return mapper.findById(command.getId());
    }

    @Override
    public Optional<QuickCommand> update(QuickCommand command) {
        int rows = mapper.updateWithVersion(command);
        if (rows == 0) {
            return Optional.empty();
        }
        return Optional.ofNullable(mapper.findById(command.getId()));
    }

    @Override
    public void delete(Long id) {
        mapper.deleteById(id);
    }
}
'@ | Set-Content -Encoding UTF8 "$base\infrastructure\prompt\MyBatisQuickCommandRepository.java" -Force

# MyBatisPromptFavoriteRepository.java
@'
package com.yxy.deepseek.superAgents.infrastructure.prompt;

import com.yxy.deepseek.superAgents.domain.prompt.PromptFavorite;
import com.yxy.deepseek.superAgents.domain.prompt.PromptFavoriteRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public class MyBatisPromptFavoriteRepository implements PromptFavoriteRepository {

    @Autowired
    private PromptFavoriteMapper mapper;

    @Override
    public boolean toggle(String userId, Long templateId) {
        int existing = mapper.countByUserAndTemplate(userId, templateId);
        if (existing > 0) {
            mapper.deleteByUserAndTemplate(userId, templateId);
            return false;
        }
        mapper.insert(userId, templateId);
        return true;
    }

    @Override
    public List<PromptFavorite> listByUser(String userId) {
        return mapper.listByUser(userId);
    }

    @Override
    public boolean isFavorite(String userId, Long templateId) {
        return mapper.countByUserAndTemplate(userId, templateId) > 0;
    }
}
'@ | Set-Content -Encoding UTF8 "$base\infrastructure\prompt\MyBatisPromptFavoriteRepository.java" -Force

Write-Host "Repository implementations done."

# ============================================================
# Application Layer
# ============================================================

# PromptMarketplaceService.java
@'
package com.yxy.deepseek.superAgents.application.prompt;

import com.yxy.deepseek.superAgents.application.tenant.TenantGuard;
import com.yxy.deepseek.superAgents.domain.prompt.PromptTemplateEntry;
import com.yxy.deepseek.superAgents.domain.prompt.PromptTemplateRepository;
import com.yxy.deepseek.superAgents.domain.prompt.PromptFavoriteRepository;
import com.yxy.deepseek.superAgents.domain.registry.AgentRegistryRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.NoSuchElementException;

@Service
public class PromptMarketplaceService {

    @Autowired
    private PromptTemplateRepository templateRepository;

    @Autowired
    private PromptFavoriteRepository favoriteRepository;

    @Autowired
    private AgentRegistryRepository agentRegistryRepository;

    public List<PromptTemplateEntry> listActive(String tenantId) {
        return templateRepository.listActiveByTenant(TenantGuard.resolveTenantId(tenantId));
    }

    public List<PromptTemplateEntry> listByCategory(String tenantId, String category) {
        if (category == null || category.isBlank()) {
            return listActive(tenantId);
        }
        return templateRepository.listActiveByCategory(TenantGuard.resolveTenantId(tenantId), category);
    }

    public List<PromptTemplateEntry> search(String tenantId, String keyword) {
        if (keyword == null || keyword.isBlank()) {
            return listActive(tenantId);
        }
        return templateRepository.searchByKeyword(TenantGuard.resolveTenantId(tenantId), keyword);
    }

    public List<String> listCategories(String tenantId) {
        return templateRepository.listCategories(TenantGuard.resolveTenantId(tenantId));
    }

    public boolean toggleFavorite(String userId, Long templateId) {
        return favoriteRepository.toggle(userId, templateId);
    }

    public List<PromptFavorite> listFavorites(String userId) {
        return favoriteRepository.listByUser(userId);
    }

    /**
     * 选用模板：读取模板 content，写入 agent_registry.system_prompt。
     */
    public void usePrompt(String tenantId, Long templateId, String agentName) {
        String tid = TenantGuard.resolveTenantId(tenantId);
        PromptTemplateEntry template = templateRepository.findById(templateId)
                .orElseThrow(() -> new NoSuchElementException("Template not found: " + templateId));
        agentRegistryRepository.findByTenantAndName(tid, agentName)
                .orElseThrow(() -> new NoSuchElementException("Agent not found: " + agentName));
        agentRegistryRepository.updateSystemPrompt(tid, agentName, template.getContent());
    }
}
'@ | Set-Content -Encoding UTF8 "$base\application\prompt\PromptMarketplaceService.java" -Force

# QuickCommandService.java
@'
package com.yxy.deepseek.superAgents.application.prompt;

import com.yxy.deepseek.superAgents.application.tenant.TenantGuard;
import com.yxy.deepseek.superAgents.domain.prompt.QuickCommand;
import com.yxy.deepseek.superAgents.domain.prompt.QuickCommandRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.NoSuchElementException;

@Service
public class QuickCommandService {

    @Autowired
    private QuickCommandRepository repository;

    public List<QuickCommand> listByAgent(String tenantId, String agentName) {
        return repository.findByAgentName(TenantGuard.resolveTenantId(tenantId), agentName);
    }

    public QuickCommand create(String tenantId, String agentName, String name,
                                String content, String icon) {
        String tid = TenantGuard.requireTenantId(tenantId);
        QuickCommand cmd = new QuickCommand(null, tid, agentName, name, content, icon, 1, null, null);
        return repository.insert(cmd);
    }

    public QuickCommand update(Long id, String content, String name, String icon, int expectedVersion) {
        QuickCommand existing = repository.findById(id)
                .orElseThrow(() -> new NoSuchElementException("QuickCommand not found: " + id));
        QuickCommand updated = new QuickCommand(
                existing.getId(), existing.getTenantId(), existing.getAgentName(),
                name != null ? name : existing.getName(),
                content != null ? content : existing.getContent(),
                icon != null ? icon : existing.getIcon(),
                expectedVersion,
                existing.getCreatedAt(), existing.getUpdatedAt());
        return repository.update(updated)
                .orElseThrow(() -> new org.springframework.dao.OptimisticLockingFailureServiceException(
                        "Version conflict for QuickCommand " + id));
    }

    public void delete(Long id) {
        repository.delete(id);
    }
}
'@ | Set-Content -Encoding UTF8 "$base\application\prompt\QuickCommandService.java" -Force

Write-Host "Application layer done."

# ============================================================
# Web Layer - DTOs
# ============================================================

# PromptTemplateResponse.java
@'
package com.yxy.deepseek.superAgents.web.prompt.dto;

import com.yxy.deepseek.superAgents.domain.prompt.PromptTemplateEntry;
import java.util.List;

public record PromptTemplateResponse(
        Long id,
        String name,
        String description,
        int version,
        String status,
        String category,
        String content,
        List<String> tags,
        String source) {

    public static PromptTemplateResponse from(PromptTemplateEntry e) {
        return new PromptTemplateResponse(
                e.getId(), e.getName(), e.getDescription(), e.getVersion(),
                e.getStatus().name().toLowerCase(), e.getCategory(),
                e.getContent(), e.getTags(), e.getSource());
    }
}
'@ | Set-Content -Encoding UTF8 "$base\web\prompt\dto\PromptTemplateResponse.java" -Force

# QuickCommandRequest.java
@'
package com.yxy.deepseek.superAgents.web.prompt.dto;

public record QuickCommandRequest(String name, String content, String icon) {
}
'@ | Set-Content -Encoding UTF8 "$base\web\prompt\dto\QuickCommandRequest.java" -Force

# UsePromptRequest.java
@'
package com.yxy.deepseek.superAgents.web.prompt.dto;

public record UsePromptRequest(Long templateId, String agentName) {
}
'@ | Set-Content -Encoding UTF8 "$base\web\prompt\dto\UsePromptRequest.java" -Force

# FavoriteRequest.java
@'
package com.yxy.deepseek.superAgents.web.prompt.dto;

public record FavoriteRequest(Long templateId) {
}
'@ | Set-Content -Encoding UTF8 "$base\web\prompt\dto\FavoriteRequest.java" -Force

# PromptGenerateRequest.java
@'
package com.yxy.deepseek.superAgents.web.prompt.dto;

public record PromptGenerateRequest(String description) {
}
'@ | Set-Content -Encoding UTF8 "$base\web\prompt\dto\PromptGenerateRequest.java" -Force

Write-Host "DTOs done."

Write-Host "All Java files generated successfully!"
