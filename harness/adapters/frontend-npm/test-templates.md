# 前端单元测试模板与策略

## 测试策略

- **优先级**：Hook/工具函数 单元测试 > 组件测试 > E2E 测试
- **Mock 策略**：Mock API 调用和外部依赖，测试业务逻辑
- **命名规范**：`方法名_场景_预期结果`（如 `handleSubmit_whenInvalid_showError`）

## 测试工具选择

| 框架 | 单测工具 | 组件测试工具 |
|------|---------|-------------|
| React | Vitest + React Testing Library | renderHook, render + screen |
| Vue | Vitest + Vue Test Utils | mount, shallowMount |

---

## Hook 测试模板（React）

```tsx
import { renderHook, waitFor } from '@testing-library/react';
import { useUser } from './useUser';

// Mock API
vi.mock('../api/user', () => ({
  getUser: vi.fn(),
}));

import { getUser } from '../api/user';

describe('useUser', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  test('should fetch user data successfully', async () => {
    // Given
    const mockUser = { id: '1', name: '张三', role: 'admin' };
    vi.mocked(getUser).mockResolvedValue(mockUser);

    // When
    const { result } = renderHook(() => useUser('1'));

    // Then - loading state
    expect(result.current.loading).toBe(true);

    // Then - success state
    await waitFor(() => {
      expect(result.current.loading).toBe(false);
    });
    expect(result.current.user).toEqual(mockUser);
    expect(result.current.error).toBeNull();
  });

  test('should handle fetch error', async () => {
    // Given
    vi.mocked(getUser).mockRejectedValue(new Error('Network Error'));

    // When
    const { result } = renderHook(() => useUser('1'));

    // Then
    await waitFor(() => {
      expect(result.current.loading).toBe(false);
    });
    expect(result.current.user).toBeNull();
    expect(result.current.error).toBeInstanceOf(Error);
  });
});
```

---

## 组件测试模板（React）

```tsx
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { OrderForm } from './OrderForm';

describe('OrderForm', () => {
  const mockOnSubmit = vi.fn();

  beforeEach(() => {
    vi.clearAllMocks();
  });

  test('should submit valid form data', async () => {
    // Given
    render(<OrderForm onSubmit={mockOnSubmit} />);

    // When
    await userEvent.type(screen.getByLabelText('订单名称'), '测试订单');
    await userEvent.click(screen.getByRole('button', { name: '提交' }));

    // Then
    await waitFor(() => {
      expect(mockOnSubmit).toHaveBeenCalledWith({
        name: '测试订单',
      });
    });
  });

  test('should show error for empty required field', async () => {
    // Given
    render(<OrderForm onSubmit={mockOnSubmit} />);

    // When
    await userEvent.click(screen.getByRole('button', { name: '提交' }));

    // Then
    expect(screen.getByText('请输入订单名称')).toBeInTheDocument();
    expect(mockOnSubmit).not.toHaveBeenCalled();
  });
});
```

---

## 组件测试模板（Vue）

```tsx
import { mount } from '@vue/test-utils';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import OrderForm from './OrderForm.vue';

describe('OrderForm', () => {
  const mockOnSubmit = vi.fn();

  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('should submit valid form data', async () => {
    // Given
    const wrapper = mount(OrderForm, {
      props: { onSubmit: mockOnSubmit },
    });

    // When
    await wrapper.find('input[name="name"]').setValue('测试订单');
    await wrapper.find('button[type="submit"]').trigger('click');

    // Then
    expect(mockOnSubmit).toHaveBeenCalledWith({ name: '测试订单' });
  });

  it('should show error for empty required field', async () => {
    // Given
    const wrapper = mount(OrderForm, {
      props: { onSubmit: mockOnSubmit },
    });

    // When
    await wrapper.find('button[type="submit"]').trigger('click');

    // Then
    expect(wrapper.text()).toContain('请输入订单名称');
    expect(mockOnSubmit).not.toHaveBeenCalled();
  });
});
```

---

## Mock 常见外部依赖

| 依赖 | Mock 方式 |
|------|---------|
| API 调用 | `vi.mock('../api/xxx')` + `mockResolvedValue` |
| Router | `vi.mock('react-router-dom')` / `vi.mock('vue-router')` |
| Context/Store | 包裹 Provider 或 `vi.mock('../store')` |
| localStorage | `vi.stubGlobal('localStorage', ...)` |
| 定时器 | `vi.useFakeTimers()` + `vi.advanceTimersByTime()` |
| fetch/axios | `vi.mock('../api/client')` |

---

## 测试文件位置

```
src/
├── hooks/
│   ├── useUser.ts
│   └── __tests__/
│       └── useUser.test.ts
├── components/
│   ├── OrderForm/
│   │   ├── OrderForm.tsx
│   │   └── __tests__/
│   │       └── OrderForm.test.tsx
│   └── ...
├── utils/
│   ├── format.ts
│   └── __tests__/
│       └── format.test.ts
```

---

## verifier Agent 写单测的步骤

1. 读取 coder Agent 变更的组件/Hook/工具函数
2. 识别导出的函数和组件 Props
3. 为每个函数编写 2-3 个测试用例（正常路径 + 边界 + 异常）
4. 创建测试文件到同目录 `__tests__/` 下
5. 运行 `npx vitest run <test-file>` 验证
