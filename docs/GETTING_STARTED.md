# 新人快速上手（Getting Started）

从 clone 到看到第一个页面的完整流程。**前后端在独立仓库开发，不在 AetherStack 目录内。**

---

## Step 0：准备三个目录

| 仓库 | 路径 | 作用 |
|------|------|------|
| AetherStack | `D:\cache\workspace\AetherStack` | 规范 + Superpower |
| ai | `D:\cache\workspace\ai` | 后端真源 |
| ai_react | `D:\cache\workspace\ai_react` | 前端真源 |

路径可在 `.aetherstack/context/repos.yaml` 修改。

---

## Step 1：AetherStack 同步 AI 配置

```powershell
cd D:\cache\workspace\AetherStack
make sync-config
```

阅读 [AGENTS.md](../AGENTS.md)、[docs/REPOS.md](REPOS.md)。

---

## Step 2：选择工作模式

### 模式 A — 仅规范/文档（无需启动任何服务）

在 **AetherStack** 编辑 `openspec/`、`.aetherstack/` 即可。

### 模式 B — 全栈开发（在关联仓库启动）

---

## Step 3：启动数据库（在 ai 仓库）

```powershell
cd D:\cache\workspace\ai
docker compose up -d
```

---

## Step 4：启动后端（ai 仓库）

```powershell
cd D:\cache\workspace\ai
$env:DASHSCOPE_API_KEY = "sk-xxx"
$env:POSTGRES_JDBC_URL = "jdbc:postgresql://127.0.0.1:5432/agenthub"
$env:POSTGRES_USERNAME = "postgres"
$env:POSTGRES_PASSWORD = "secret"
mvn spring-boot:run
```

验证：http://localhost:8080/actuator/health

---

## Step 5：启动前端（ai_react 仓库）

```powershell
cd D:\cache\workspace\ai_react
npm install
npm run dev
```

打开：http://localhost:5173

---

## Step 6：提交前验证

在 AetherStack 根目录：

```powershell
make verify
```

会在关联的 ai / ai_react 路径执行 `mvn test` 与 `npm lint/build`。

---

## 常见问题

| 问题 | 解决 |
|------|------|
| 找不到 backend | 检查 `LOCALPATH.md` 与 ai 仓库路径 |
| 前端连不上 API | 确认 ai 已启动，ai_react `.env` 代理指向 `:8080` |
| OpenSpec 与代码分离 | 规范在 AetherStack，实现在 ai/ai_react |

---

## 下一步

- [docs/SUPERpower.md](SUPERpower.md)
- [D:\cache\workspace\ai\README.md](file:///D:/cache/workspace/ai/README.md)（后端）
- [D:\cache\workspace\ai_react\README.md](file:///D:/cache/workspace/ai_react/README.md)（前端）
