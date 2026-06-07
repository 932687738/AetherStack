# MCP 安全接入

## Integration / MCP 安全 需求说明（前提/操作/结果）
> MCP 协议优先接入外部服务；强制认证、传输加密、能力声明校验；与平台权限模型衔接。
> 交付阶段：**P2**（基础认证 **P2**，完整合规 **P3**）。详见 proposal `aether-integration/mcp-security`。

---

## Requirements

<a name="req-1"></a>
### Requirement: 1. MCP 连接认证 [P2]

<a name="openspec-req-1"></a>系统 shall 要求所有 MCP Server 连接配置认证凭据（非硬编码）；未认证连接拒绝建立。

#### 场景: 无凭据 MCP 配置
- **前提**：管理员提交空 API Key 的 MCP 端点。
- **操作**：保存并尝试连接。
- **结果**：配置校验失败或连接拒绝；日志不含密钥明文。

---

<a name="req-2"></a>
### Requirement: 2. 能力声明校验 [P2]

<a name="openspec-req-2"></a>系统 shall 在注册 MCP Tool 时校验 Server 声明的能力与平台允许列表一致；未知高危能力需审批。

#### 场景: MCP 暴露文件写能力
- **前提**：MCP Server 声明 write_file 能力。
- **操作**：注册至平台。
- **结果**：标记高危；默认不暴露给 Agent 直至审批通过。

---

<a name="req-3"></a>
### Requirement: 3. 传输加密 [P3]

<a name="openspec-req-3"></a>系统 shall 生产环境 MCP 连接使用 TLS；禁止明文传输凭据与业务数据。

#### 场景: HTTP 非 TLS MCP
- **前提**：配置 http:// 明文 MCP URL（非 localhost）。
- **操作**：启动校验。
- **结果**：警告或拒绝；文档说明 localhost 开发例外。

---

<a name="req-4"></a>
### Requirement: 4. MCP Tool 权限绑定 [P2]

<a name="openspec-req-4"></a>系统 shall 使 MCP 衍生的 Tool 继承平台权限模型；调用前校验租户与用户角色。

#### 场景: 无权限用户调用 MCP Tool
- **前提**：用户无 mcp:payment 权限。
- **操作**：Agent 尝试调用支付类 MCP Tool。
- **结果**：调用被阻断；ToolResult 权限错误。

---

