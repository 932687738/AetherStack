# 前端代码规范

本文档定义前端项目（React/Vue/TypeScript）的通用代码规范。

---

## 命名规范

| 类型 | 规范 | 示例 |
|------|------|------|
| 组件文件名 | PascalCase | `UserProfile.tsx`、`OrderList.vue` |
| 工具/Hook 文件名 | camelCase | `useAuth.ts`、`formatDate.ts` |
| 样式文件名 | kebab-case 或同组件名 | `user-profile.module.css`、`OrderList.scss` |
| 变量/函数 | camelCase，有语义 | `userName`、`handleSubmit` |
| 常量 | SCREAMING_SNAKE_CASE | `MAX_RETRY_COUNT`、`API_BASE_URL` |
| 类型/接口 | PascalCase | `UserInfo`、`OrderStatus` |
| 枚举 | PascalCase | `enum OrderStatus { Pending, Completed }` |

---

## React 规范

### 函数组件 + Hooks

```tsx
interface UserCardProps {
  userId: string;
  onFollow: (id: string) => void;
}

const UserCard: React.FC<UserCardProps> = ({ userId, onFollow }) => {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchUser = async () => {
      setLoading(true);
      try {
        const data = await getUser(userId);
        setUser(data);
      } finally {
        setLoading(false);
      }
    };
    fetchUser();
  }, [userId]);

  if (loading) return <Skeleton />;
  if (!user) return null;

  return (
    <div onClick={() => onFollow(user.id)}>
      {user.name}
    </div>
  );
};
```

**要点**：
- 使用函数组件，不用 class 组件
- Hooks 调用顺序固定，不在条件/循环中调用
- useEffect 依赖数组完整，不遗漏
- 组件拆分：单文件不超过 200 行

### 自定义 Hook

```ts
function useUser(userId: string) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    let cancelled = false;
    getUser(userId)
      .then(data => { if (!cancelled) setUser(data); })
      .catch(err => { if (!cancelled) setError(err); })
      .finally(() => { if (!cancelled) setLoading(false); });

    return () => { cancelled = true; };
  }, [userId]);

  return { user, loading, error };
}
```

---

## Vue 规范

### `<script setup>` 规范

```vue
<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';

interface Props {
  userId: string;
}

const props = defineProps<Props>();
const emit = defineEmits<{
  follow: [id: string];
}>();

const user = ref<User | null>(null);
const loading = ref(true);

const displayName = computed(() => user.value?.name ?? '未知用户');

onMounted(async () => {
  loading.value = true;
  try {
    user.value = await getUser(props.userId);
  } finally {
    loading.value = false;
  }
});
</script>
```

**要点**：
- 使用 `<script setup>` 语法
- 使用 TypeScript，定义 Props 和 Emits 接口
- ref/reactive 不要解构（丢失响应性）
- computed 用于派生状态

---

## 状态管理

### 就近原则

| 状态范围 | 管理方式 |
|---------|---------|
| 组件内部 | `useState` / `ref` |
| 父子共享 | Props + Callbacks |
| 跨层级共享 | Context / Provide-Inject |
| 全局共享 | Zustand / Pinia / Redux |

**原则**：
- 不过早引入全局状态库
- 状态就近管理，提升不要超过必要层级
- 避免将 UI 状态（loading、modal visible）放入全局 store

---

## 异步处理

```ts
// 使用 async/await，不使用裸 .then 链
async function handleSubmit() {
  setLoading(true);
  try {
    const result = await createOrder(formData);
    message.success('创建成功');
    navigate(`/orders/${result.id}`);
  } catch (error) {
    if (error instanceof BusinessError) {
      message.error(error.message);
    } else {
      message.error('系统繁忙');
    }
  } finally {
    setLoading(false);
  }
}
```

---

## 样式规范

| 方案 | 说明 |
|------|------|
| CSS Modules | `import styles from './x.module.css'`，默认推荐 |
| Scoped CSS | Vue 单文件组件 `<style scoped>` |
| Tailwind | 原子化 CSS，项目已引入时使用 |
| CSS-in-JS | 仅在主题系统需要时使用 |

**原则**：
- 不使用全局 CSS，避免样式冲突
- 不使用 `!important`
- 颜色、间距使用设计系统变量

---

## TypeScript 规范

```ts
// 优先使用 interface 定义对象类型
interface UserInfo {
  id: string;
  name: string;
  role: 'admin' | 'user';
}

// 使用 type 定义联合类型、工具类型
type ApiResponse<T> = {
  code: number;
  data: T;
  message: string;
};

// 禁止 any，使用 unknown 替代
function parseJSON(str: string): unknown {
  return JSON.parse(str);
}

// 使用类型守卫收窄
function isUser(data: unknown): data is UserInfo {
  return typeof data === 'object' && data !== null && 'id' in data;
}
```

---

## 组件设计原则

1. **单一职责**：一个组件只做一件事
2. **Props 向下，Events 向上**：数据流单向
3. **组合优于继承**：使用 Hook/Composable 复用逻辑
4. **受控 vs 非受控**：优先受控组件
5. **错误边界**：关键区域使用 ErrorBoundary / onErrorCaptured

---

## API 调用规范

```ts
// 统一封装请求
const api = {
  getUser: (id: string) => request.get<UserInfo>(`/api/users/${id}`),
  createUser: (data: CreateUserDTO) => request.post<UserInfo>('/api/users', data),
};

// 在 Hook/Composable 中调用，不在组件中直接写 fetch
function useUser(id: string) {
  return useQuery({
    queryKey: ['user', id],
    queryFn: () => api.getUser(id),
  });
}
```
