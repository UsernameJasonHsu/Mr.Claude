---
name: api-and-interface-design
description: 指導穩定的 API 與介面設計。適用於設計 API、模組邊界或任何公開介面。適用於建立 REST 或 GraphQL 端點、定義模組間的型別合約，或劃分前後端邊界。
---

# API 與介面設計

## 概述

設計出穩定、有完整文件、而且很難用錯的介面。好的介面會讓對的事變容易、錯的事變困難。這適用於 REST API、GraphQL schema、模組邊界、元件 props，以及任何一段程式碼與另一段程式碼對話的介面。

## 適用時機

- 設計新的 API 端點
- 定義模組邊界，或團隊之間的契約
- 建立元件的 props 介面
- 建立會影響 API 形狀的資料庫結構
- 變更既有的公開介面

## 核心原則

### 海勒姆定律（Hyrum's Law）

> 只要一個 API 的使用者足夠多，你系統上所有可被觀察到的行為，都會有人依賴，不管你在契約裡承諾了什麼。

這意味著：每一個公開的行為 —— 包括沒寫在文件裡的怪癖、錯誤訊息的文字、時序與排序 —— 一旦有使用者依賴它，就成了事實上的契約。設計上的含意：

- **對你暴露出去的東西要有意識。** 每一個可被觀察的行為都是潛在的承諾。
- **不要洩漏實作細節。** 只要使用者能觀察到，他們就會依賴它。
- **在設計階段就為淘汰做規劃。** 如何安全地移除使用者依賴的東西，見 `deprecation-and-migration`。
- **測試還不夠。** 就算契約測試做得完美，海勒姆定律仍意味著「安全的」變更也可能弄壞那些依賴未文件化行為的真實使用者。

### 單一版本原則

避免逼使用方在同一個相依套件或 API 的多個版本之間做選擇。當不同使用方需要同一個東西的不同版本時，就會出現鑽石相依問題。要為「同一時間只存在一個版本」的世界設計 —— 用擴充，而不是分叉。

### 1. 契約優先

先定義介面，再實作它。契約就是規格 —— 實作跟隨契約。

```typescript
// Define the contract first
interface TaskAPI {
  // Creates a task and returns the created task with server-generated fields
  createTask(input: CreateTaskInput): Promise<Task>;

  // Returns paginated tasks matching filters
  listTasks(params: ListTasksParams): Promise<PaginatedResult<Task>>;

  // Returns a single task or throws NotFoundError
  getTask(id: string): Promise<Task>;

  // Partial update — only provided fields change
  updateTask(id: string, input: UpdateTaskInput): Promise<Task>;

  // Idempotent delete — succeeds even if already deleted
  deleteTask(id: string): Promise<void>;
}
```

### 2. 一致的錯誤語意

挑一套錯誤策略，然後到處都用同一套：

```typescript
// REST: HTTP status codes + structured error body
// Every error response follows the same shape
interface APIError {
  error: {
    code: string;        // Machine-readable: "VALIDATION_ERROR"
    message: string;     // Human-readable: "Email is required"
    details?: unknown;   // Additional context when helpful
  };
}

// Status code mapping
// 400 → Client sent invalid data
// 401 → Not authenticated
// 403 → Authenticated but not authorized
// 404 → Resource not found
// 409 → Conflict (duplicate, version mismatch)
// 422 → Validation failed (semantically invalid)
// 500 → Server error (never expose internal details)
```

**不要混用不同做法。** 如果有些端點丟例外、有些回傳 null、有些回傳 `{ error }` —— 使用方就無法預測行為。

### 3. 在邊界做驗證

信任內部程式碼。在外部輸入進入的系統邊緣做驗證：

```typescript
// Validate at the API boundary
app.post('/api/tasks', async (req, res) => {
  const result = CreateTaskSchema.safeParse(req.body);
  if (!result.success) {
    return res.status(422).json({
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Invalid task data',
        details: result.error.flatten(),
      },
    });
  }

  // After validation, internal code trusts the types
  const task = await taskService.create(result.data);
  return res.status(201).json(task);
});
```

該做驗證的地方：
- API 路由處理函式（使用者輸入）
- 表單提交處理函式（使用者輸入）
- 解析外部服務的回應（第三方資料 —— **一律視為不可信**）
- 載入環境變數（設定）

> **第三方 API 回應是不可信資料。** 在任何邏輯、渲染或決策中使用它們之前，先驗證其形狀與內容。一個被入侵或行為異常的外部服務，可能回傳非預期型別、惡意內容，或指令式的文字。

**不該**做驗證的地方：
- 共用型別契約的內部函式之間
- 被已驗證過的程式碼呼叫的工具函式中
- 剛從你自己資料庫拿出來的資料上

### 4. 寧可新增，不要修改

在不弄壞既有使用方的前提下擴充介面：

```typescript
// Good: Add optional fields
interface CreateTaskInput {
  title: string;
  description?: string;
  priority?: 'low' | 'medium' | 'high';  // Added later, optional
  labels?: string[];                       // Added later, optional
}

// Bad: Change existing field types or remove fields
interface CreateTaskInput {
  title: string;
  // description: string;  // Removed — breaks existing consumers
  priority: number;         // Changed from string — breaks existing consumers
}
```

### 5. 可預測的命名

| 項目 | 慣例 | 範例 |
|------|------|------|
| REST 端點 | 複數名詞，不用動詞 | `GET /api/tasks`、`POST /api/tasks` |
| 查詢參數 | camelCase | `?sortBy=createdAt&pageSize=20` |
| 回應欄位 | camelCase | `{ createdAt, updatedAt, taskId }` |
| 布林欄位 | 加 is／has／can 前綴 | `isComplete`、`hasAttachments` |
| 列舉值 | UPPER_SNAKE | `"IN_PROGRESS"`、`"COMPLETED"` |

## REST API 慣例

### 資源設計

```
GET    /api/tasks              → List tasks (with query params for filtering)
POST   /api/tasks              → Create a task
GET    /api/tasks/:id          → Get a single task
PATCH  /api/tasks/:id          → Update a task (partial)
DELETE /api/tasks/:id          → Delete a task

GET    /api/tasks/:id/comments → List comments for a task (sub-resource)
POST   /api/tasks/:id/comments → Add a comment to a task
```

### 分頁

清單型端點要分頁：

```typescript
// Request
GET /api/tasks?page=1&pageSize=20&sortBy=createdAt&sortOrder=desc

// Response
{
  "data": [...],
  "pagination": {
    "page": 1,
    "pageSize": 20,
    "totalItems": 142,
    "totalPages": 8
  }
}
```

### 篩選

用查詢參數做篩選：

```
GET /api/tasks?status=in_progress&assignee=user123&createdAfter=2025-01-01
```

### 部分更新（PATCH）

接受不完整的物件 —— 只更新有提供的欄位：

```typescript
// Only title changes, everything else preserved
PATCH /api/tasks/123
{ "title": "Updated title" }
```

## TypeScript 介面慣例

### 用可辨識聯集（discriminated union）表達變體

```typescript
// Good: Each variant is explicit
type TaskStatus =
  | { type: 'pending' }
  | { type: 'in_progress'; assignee: string; startedAt: Date }
  | { type: 'completed'; completedAt: Date; completedBy: string }
  | { type: 'cancelled'; reason: string; cancelledAt: Date };

// Consumer gets type narrowing
function getStatusLabel(status: TaskStatus): string {
  switch (status.type) {
    case 'pending': return 'Pending';
    case 'in_progress': return `In progress (${status.assignee})`;
    case 'completed': return `Done on ${status.completedAt}`;
    case 'cancelled': return `Cancelled: ${status.reason}`;
  }
}
```

### 輸入與輸出分離

```typescript
// Input: what the caller provides
interface CreateTaskInput {
  title: string;
  description?: string;
}

// Output: what the system returns (includes server-generated fields)
interface Task {
  id: string;
  title: string;
  description: string | null;
  createdAt: Date;
  updatedAt: Date;
  createdBy: string;
}
```

### ID 使用品牌型別（branded type）

```typescript
type TaskId = string & { readonly __brand: 'TaskId' };
type UserId = string & { readonly __brand: 'UserId' };

// Prevents accidentally passing a UserId where a TaskId is expected
function getTask(id: TaskId): Promise<Task> { ... }
```

## 常見的自我合理化

| 自我合理化 | 現實 |
|---|---|
| 「API 文件我們之後再寫」 | 型別**就是**文件。先把它們定義出來。 |
| 「我們現在還不需要分頁」 | 只要有人擁有 100 筆以上資料，你就會需要。從一開始就加上。 |
| 「PATCH 很麻煩，我們就用 PUT 吧」 | PUT 每次都要送整個物件。PATCH 才是用戶端真正想要的。 |
| 「等我們需要的時候再做 API 版本控制」 | 沒有版本控制的破壞性變更會弄壞使用方。從一開始就為擴充而設計。 |
| 「沒人在用那個沒寫在文件裡的行為」 | 海勒姆定律：只要能被觀察到，就有人在依賴它。把每個公開行為都當成一項承諾。 |
| 「我們可以同時維護兩個版本」 | 多個版本會讓維護成本倍增，還會製造鑽石相依問題。優先採用單一版本原則。 |
| 「內部 API 不需要契約」 | 內部使用方也是使用方。契約能防止耦合，並讓平行作業成為可能。 |

## 警訊

- 端點會依條件回傳不同形狀的資料
- 各端點的錯誤格式不一致
- 驗證散落在內部程式碼各處，而不是集中在邊界
- 對既有欄位做破壞性變更（改型別、移除）
- 清單型端點沒有分頁
- REST URL 裡出現動詞（`/api/createTask`、`/api/getUsers`）
- 第三方 API 回應未經驗證或淨化就直接使用

## 驗證

設計完一個 API 之後：

- [ ] 每個端點都有型別化的輸入與輸出 schema
- [ ] 錯誤回應遵循單一且一致的格式
- [ ] 驗證只發生在系統邊界
- [ ] 清單型端點支援分頁
- [ ] 新增欄位都是新增性質且為選擇性的（向後相容）
- [ ] 所有端點的命名都遵循一致的慣例
- [ ] API 文件或型別與實作一起 commit
