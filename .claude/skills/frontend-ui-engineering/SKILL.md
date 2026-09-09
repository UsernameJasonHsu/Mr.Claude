---
name: frontend-ui-engineering
description: 建置正式產品等級的 UI。適用於建置或修改面向使用者的介面。適用於建立元件、實作版面配置、管理狀態，或當輸出需要呈現正式產品的質感，而非「AI 生成感」時。
---

# 前端 UI 工程

## 概述

打造具無障礙性、效能良好、視覺精緻的正式產品等級使用者介面。目標是做出「像是頂尖公司裡懂設計的工程師寫出來的」UI —— 而不是「像 AI 生成的」。這意味著真正遵循設計系統、正確處理無障礙性、深思熟慮的互動模式，以及完全不帶那種通用的「AI 美學」。

## 適用時機

- 建置新的 UI 元件或頁面
- 修改既有的面向使用者介面
- 實作響應式版面配置
- 加入互動性或狀態管理
- 修正視覺或 UX 問題

## 元件架構

### 檔案結構

把一個元件的相關檔案放在一起：

```
src/components/
  TaskList/
    TaskList.tsx          # Component implementation
    TaskList.test.tsx     # Tests
    TaskList.stories.tsx  # Storybook stories (if using)
    use-task-list.ts      # Custom hook (if complex state)
    types.ts              # Component-specific types (if needed)
```

### 元件慣例

**組合優於設定：**

```tsx
// Good: Composable
<Card>
  <CardHeader>
    <CardTitle>Tasks</CardTitle>
  </CardHeader>
  <CardBody>
    <TaskList tasks={tasks} />
  </CardBody>
</Card>

// Avoid: Over-configured
<Card
  title="Tasks"
  headerVariant="large"
  bodyPadding="md"
  content={<TaskList tasks={tasks} />}
/>
```

**讓元件保持聚焦：**

```tsx
// Good: Does one thing
export function TaskItem({ task, onToggle, onDelete }: TaskItemProps) {
  return (
    <li className="flex items-center gap-3 p-3">
      <Checkbox checked={task.done} onChange={() => onToggle(task.id)} />
      <span className={task.done ? 'line-through text-muted' : ''}>{task.title}</span>
      <Button variant="ghost" size="sm" onClick={() => onDelete(task.id)}>
        <TrashIcon />
      </Button>
    </li>
  );
}
```

**把資料抓取與呈現分開：**

```tsx
// Container: handles data
export function TaskListContainer() {
  const { tasks, isLoading, error } = useTasks();

  if (isLoading) return <TaskListSkeleton />;
  if (error) return <ErrorState message="Failed to load tasks" retry={refetch} />;
  if (tasks.length === 0) return <EmptyState message="No tasks yet" />;

  return <TaskList tasks={tasks} />;
}

// Presentation: handles rendering
export function TaskList({ tasks }: { tasks: Task[] }) {
  return (
    <ul role="list" className="divide-y">
      {tasks.map(task => <TaskItem key={task.id} task={task} />)}
    </ul>
  );
}
```

## 狀態管理

**挑選能解決問題的最簡單做法：**

```
Local state (useState)           → Component-specific UI state
Lifted state                     → Shared between 2-3 sibling components
Context                          → Theme, auth, locale (read-heavy, write-rare)
URL state (searchParams)         → Filters, pagination, shareable UI state
Server state (React Query, SWR)  → Remote data with caching
Global store (Zustand, Redux)    → Complex client state shared app-wide
```

**避免 props 往下傳超過 3 層。** 如果你正把 props 穿過那些根本不會用到它們的元件，就該引入 context，或重新調整元件樹的結構。

## 遵循設計系統

### 避開 AI 美學

AI 生成的 UI 有一些一眼就認得出來的特徵。全部避開：

| AI 的預設 | 為什麼是問題 | 正式產品等級的做法 |
|---|---|---|
| 什麼都紫色／靛色 | 模型預設會挑視覺上「安全」的配色，結果每個 App 看起來都一樣 | 使用專案真正的配色 |
| 過多漸層 | 漸層增加視覺雜訊，而且跟多數設計系統衝突 | 平面色，或符合設計系統的細微漸層 |
| 什麼都圓角（rounded-2xl） | 圓到極致傳達的是「親切」，但無視真實設計中圓角半徑的層級關係 | 採用設計系統中一致的 border-radius |
| 通用的主視覺區塊 | 範本式的版面，跟實際內容或使用者需求毫無關聯 | 以內容為先的版面 |
| Lorem ipsum 式的文案 | 佔位文字會掩蓋真實內容才會暴露的版面問題（長度、換行、溢出） | 貼近真實的佔位內容 |
| 到處都過大的留白 | 一律給大量且相等的留白，會摧毀視覺層級，還浪費螢幕空間 | 一致的間距刻度 |
| 罐頭卡片網格 | 均勻網格是一種版面偷懶，無視資訊優先序與瀏覽動線 | 有目的性的版面 |
| 重陰影設計 | 疊加的陰影製造出與內容爭搶注意力的深度感，還會讓低階裝置渲染變慢 | 除非設計系統有指定，否則用細微陰影或不用陰影 |

### 間距與版面

使用一致的間距刻度。不要自己發明數值：

```css
/* Use the scale: 0.25rem increments (or whatever the project uses) */
/* Good */  padding: 1rem;      /* 16px */
/* Good */  gap: 0.75rem;       /* 12px */
/* Bad */   padding: 13px;      /* Not on any scale */
/* Bad */   margin-top: 2.3rem; /* Not on any scale */
```

### 字體排版

尊重字級層級：

```
h1 → Page title (one per page)
h2 → Section title
h3 → Subsection title
body → Default text
small → Secondary/helper text
```

不要跳過標題層級。不要把標題樣式用在非標題的內容上。

### 色彩

- 使用語意化的色彩 token：`text-primary`、`bg-surface`、`border-default` —— 而不是原始的十六進位色碼
- 確保足夠的對比度（一般文字 4.5:1、大字 3:1）
- 不要只靠顏色傳達資訊（同時也用圖示、文字或圖樣）

## 無障礙性（WCAG 2.1 AA）

每個元件都必須符合這些標準：

### 鍵盤操作

```tsx
// Every interactive element must be keyboard accessible
<button onClick={handleClick}>Click me</button>        // ✓ Focusable by default
<div onClick={handleClick}>Click me</div>               // ✗ Not focusable
<div role="button" tabIndex={0} onClick={handleClick}    // ✓ But prefer <button>
     onKeyDown={e => {
       if (e.key === 'Enter') handleClick();
       if (e.key === ' ') e.preventDefault();
     }}
     onKeyUp={e => {
       if (e.key === ' ') handleClick();
     }}>
  Click me
</div>
```

### ARIA 標籤

```tsx
// Label interactive elements that lack visible text
<button aria-label="Close dialog"><XIcon /></button>

// Label form inputs
<label htmlFor="email">Email</label>
<input id="email" type="email" />

// Or use aria-label when no visible label exists
<input aria-label="Search tasks" type="search" />
```

### 焦點管理

```tsx
// Move focus when content changes
function Dialog({ isOpen, onClose }: DialogProps) {
  const closeRef = useRef<HTMLButtonElement>(null);

  useEffect(() => {
    if (isOpen) closeRef.current?.focus();
  }, [isOpen]);

  // Trap focus inside dialog when open
  return (
    <dialog open={isOpen}>
      <button ref={closeRef} onClick={onClose}>Close</button>
      {/* dialog content */}
    </dialog>
  );
}
```

### 有意義的空狀態與錯誤狀態

```tsx
// Don't show blank screens
function TaskList({ tasks }: { tasks: Task[] }) {
  if (tasks.length === 0) {
    return (
      <div role="status" className="text-center py-12">
        <TasksEmptyIcon className="mx-auto h-12 w-12 text-muted" />
        <h3 className="mt-2 text-sm font-medium">No tasks</h3>
        <p className="mt-1 text-sm text-muted">Get started by creating a new task.</p>
        <Button className="mt-4" onClick={onCreateTask}>Create Task</Button>
      </div>
    );
  }

  return <ul role="list">...</ul>;
}
```

## 響應式設計

以行動裝置優先設計，再往外擴：

```tsx
// Tailwind: mobile-first responsive
<div className="
  grid grid-cols-1      /* Mobile: single column */
  sm:grid-cols-2        /* Small: 2 columns */
  lg:grid-cols-3        /* Large: 3 columns */
  gap-4
">
```

在這些斷點測試：320px、768px、1024px、1440px。

## 載入與轉場

```tsx
// Skeleton loading (not spinners for content)
function TaskListSkeleton() {
  return (
    <div className="space-y-3" aria-busy="true" aria-label="Loading tasks">
      {Array.from({ length: 3 }).map((_, i) => (
        <div key={i} className="h-12 bg-muted animate-pulse rounded" />
      ))}
    </div>
  );
}

// Optimistic updates for perceived speed
function useToggleTask() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: toggleTask,
    onMutate: async (taskId) => {
      await queryClient.cancelQueries({ queryKey: ['tasks'] });
      const previous = queryClient.getQueryData(['tasks']);

      queryClient.setQueryData(['tasks'], (old: Task[]) =>
        old.map(t => t.id === taskId ? { ...t, done: !t.done } : t)
      );

      return { previous };
    },
    onError: (_err, _taskId, context) => {
      queryClient.setQueryData(['tasks'], context?.previous);
    },
  });
}
```

## 延伸閱讀

詳細的無障礙性要求與測試工具，見 `references/accessibility-checklist.md`。

## 常見的自我合理化

| 自我合理化 | 現實 |
|---|---|
| 「無障礙性是有做更好的加分項」 | 在許多司法管轄區它是法律要求，也是工程品質標準。 |
| 「我們之後再做響應式」 | 事後補上響應式設計，難度是一開始就做的 3 倍。 |
| 「設計還沒定案，所以我先不做樣式」 | 用設計系統的預設值。沒有樣式的 UI 會給審查者留下「壞掉了」的第一印象。 |
| 「這只是原型」 | 原型會變成正式程式碼。把地基打對。 |
| 「AI 美學現在先這樣也行」 | 它傳達的是低品質。從一開始就用專案真正的設計系統。 |

## 警訊

- 元件超過 200 行（把它拆開）
- 使用行內樣式或隨意的像素值
- 缺少錯誤狀態、載入狀態或空狀態
- 沒有測試過鍵盤操作
- 只用顏色來表示狀態（紅／綠卻沒有文字或圖示）
- 通用的「AI 感」（紫色漸層、過大的卡片、罐頭版面）

## 驗證

做完 UI 之後：

- [ ] 元件渲染時沒有主控台錯誤
- [ ] 所有可互動元素都能用鍵盤操作（用 Tab 走一遍整頁）
- [ ] 螢幕閱讀器能傳達頁面的內容與結構
- [ ] 響應式：在 320px、768px、1024px、1440px 都正常
- [ ] 載入、錯誤與空狀態都有處理
- [ ] 遵循專案的設計系統（間距、色彩、字體排版）
- [ ] 開發工具或 axe-core 沒有無障礙性警告
