# 前端常见错误清单

本文档整理前端开发中常见错误及修复方案，按严重级别分类。

---

## 高优先级问题（影响生产环境）

### 1. Hooks 规则违反

**问题**：在条件语句、循环或嵌套函数中调用 Hooks

**错误做法**：
```tsx
if (condition) {
  const [value, setValue] = useState(0); // 违反规则
}
```

**正确做法**：Hooks 必须在组件顶层调用，条件逻辑放在 Hook 内部

### 2. XSS 攻击

**问题**：直接渲染用户输入的 HTML

**错误做法**：
- React: `dangerouslySetInnerHTML={{ __html: userInput }}`
- Vue: `v-html="userInput"`

**正确做法**：
- 使用文本渲染 `{{ userInput }}` / `{userInput}`
- 如需渲染 HTML，必须经过 DOMPurify 等库消毒

### 3. 状态管理错误

**React**：
- 直接 mutate state：`state.value = x` → 应使用 `setState({ ...state, value: x })`
- useState 引用类型未创建新引用：`setArr(arr.push(x))` → `setArr([...arr, x])`

**Vue**：
- 解构 reactive 对象丢失响应性：`const { name } = reactive(...)` → 使用 `toRefs`
- 直接修改 props：`props.value = x` → 使用 emit

### 4. 内存泄漏

**问题**：组件卸载后仍执行异步操作、定时器未清理

**正确做法**：
```tsx
useEffect(() => {
  const controller = new AbortController();
  fetchData(controller.signal);
  return () => controller.abort(); // 清理
}, []);
```

### 5. 竞态条件

**问题**：多个异步请求返回顺序不确定，导致显示旧数据

**正确做法**：
- 使用请求取消（AbortController）
- 使用递增 ID 忽略过期响应
- 使用 React Query / SWR 等库自动处理

---

## 中优先级问题（影响可维护性）

### 6. any 类型滥用

**问题**：使用 `any` 绕过类型检查

**正确做法**：
- 使用 `unknown` + 类型守卫
- 定义具体 interface
- 使用泛型

### 7. 重渲染性能问题

**常见原因**：
- useEffect 依赖数组不正确，导致无限循环
- 对象/数组在渲染中重新创建：`style={{ color: 'red' }}`
- 父组件 re-render 导致所有子组件 re-render
- 缺少 `useMemo` / `useCallback` / `memo`

**解决方案**：
- 稳定引用：提取到组件外部或使用 useMemo
- React.memo 包裹纯展示组件
- 列表使用 key 标识

### 8. useEffect 过度使用

**问题**：在 useEffect 中做太多事，或用 useEffect 同步状态

**正确做法**：
- 派生状态用 useMemo，不用 useEffect + setState
- 事件处理用事件回调，不用 useEffect 监听
- 数据获取用 React Query / SWR

### 9. 闭包陷阱

**问题**：useEffect/useCallback 中引用的变量是旧值

**正确做法**：
- 使用 useRef 保存最新值
- 确保依赖数组完整
- 使用函数式更新 `setCount(c => c + 1)`

### 10. 列表渲染缺少 key

**问题**：使用 index 作为 key，导致列表更新异常

**正确做法**：使用唯一标识符（id）作为 key

---

## 低优先级问题（完善性）

### 11. console.log 残留

**问题**：提交时忘记移除调试日志

**解决方案**：ESLint 规则禁止 console，使用构建时自动移除

### 12. CSS 优先级冲突

**问题**：全局样式覆盖组件样式

**解决方案**：
- 使用 CSS Modules / scoped
- 避免标签选择器
- BEM 命名规范

### 13. 硬编码字符串

**问题**：文案、URL、配置直接写在代码中

**解决方案**：
- 文案使用 i18n
- URL 和配置使用环境变量
- 魔法值提取为常量

### 14. 组件文件过大

**问题**：单文件超过 300 行

**解决方案**：
- 拆分子组件
- 提取自定义 Hook
- 拆分工具函数

---

## 修复优先级判断

| 优先级 | 判断标准 | 示例 |
|--------|----------|------|
| **CRITICAL** | 安全漏洞、数据丢失、生产崩溃 | XSS、内存泄漏、状态串号 |
| **HIGH** | 性能严重退化、功能异常 | 无限重渲染、竞态条件、状态管理错误 |
| **SUGGESTION** | 代码风格、优化机会 | console残留、硬编码、文件过大 |
