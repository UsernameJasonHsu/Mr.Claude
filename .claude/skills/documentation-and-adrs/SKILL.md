---
name: documentation-and-adrs
description: 記錄決策與文件。適用於做出架構決策、變更公開 API、發布功能時，或需要記錄未來工程師與 agent 理解程式碼庫所需的背景資訊時。
---

# 文件與 ADR

## 概述

要記錄決策，不只是記錄程式碼。最有價值的文件記下的是*為什麼* —— 導致這個決策的背景、限制與取捨。程式碼呈現的是*做了什麼*；文件說明的是*為什麼這樣做*，以及*考慮過哪些替代方案*。對未來在這個程式碼庫中工作的人與 agent 來說，這些背景至關重要。

## 適用時機

- 做出重大架構決策
- 在幾個互相競爭的做法之間取捨
- 新增或變更公開 API
- 發布會改變面向使用者行為的功能
- 讓新成員（或 agent）熟悉專案
- 當你發現自己在反覆解釋同一件事時

**不適用時機：** 不要為顯而易見的程式碼寫文件。不要寫只是把程式碼再唸一遍的註解。不要為用完就丟的原型寫文件。

## 架構決策紀錄（ADR）

ADR 記錄的是重大技術決策背後的推理。它們是你能寫出的最高價值文件。

### 什麼時候該寫 ADR

- 選擇框架、函式庫或重要相依套件
- 設計資料模型或資料庫結構
- 選定身分驗證策略
- 決定 API 架構（REST vs. GraphQL vs. tRPC）
- 在建置工具、託管平台或基礎設施之間取捨
- 任何要反轉會很昂貴的決策

### ADR 範本

把 ADR 放在 `docs/decisions/`，並依序編號：

```markdown
# ADR-001: Use PostgreSQL for primary database

## Status
Accepted | Superseded by ADR-XXX | Deprecated

## Date
2025-01-15

## Context
We need a primary database for the task management application. Key requirements:
- Relational data model (users, tasks, teams with relationships)
- ACID transactions for task state changes
- Support for full-text search on task content
- Managed hosting available (for small team, limited ops capacity)

## Decision
Use PostgreSQL with Prisma ORM.

## Alternatives Considered

### MongoDB
- Pros: Flexible schema, easy to start with
- Cons: Our data is inherently relational; would need to manage relationships manually
- Rejected: Relational data in a document store leads to complex joins or data duplication

### SQLite
- Pros: Zero configuration, embedded, fast for reads
- Cons: Limited concurrent write support, no managed hosting for production
- Rejected: Not suitable for multi-user web application in production

### MySQL
- Pros: Mature, widely supported
- Cons: PostgreSQL has better JSON support, full-text search, and ecosystem tooling
- Rejected: PostgreSQL is the better fit for our feature requirements

## Consequences
- Prisma provides type-safe database access and migration management
- We can use PostgreSQL's full-text search instead of adding Elasticsearch
- Team needs PostgreSQL knowledge (standard skill, low risk)
- Hosting on managed service (Supabase, Neon, or RDS)
```

### ADR 的生命週期

```
PROPOSED → ACCEPTED → (SUPERSEDED or DEPRECATED)
```

- **不要刪掉舊的 ADR。** 它們記錄的是歷史背景。
- 當決策改變時，寫一份新的 ADR，引用並取代舊的那一份。

## 行內文件

### 什麼時候該寫註解

註解要寫*為什麼*，不是*做了什麼*：

```typescript
// BAD: Restates the code
// Increment counter by 1
counter += 1;

// GOOD: Explains non-obvious intent
// Rate limit uses a sliding window — reset counter at window boundary,
// not on a fixed schedule, to prevent burst attacks at window edges
if (now - windowStart > WINDOW_SIZE_MS) {
  counter = 0;
  windowStart = now;
}
```

### 什麼時候不該寫註解

```typescript
// Don't comment self-explanatory code
function calculateTotal(items: CartItem[]): number {
  return items.reduce((sum, item) => sum + item.price * item.quantity, 0);
}

// Don't leave TODO comments for things you should just do now
// TODO: add error handling  ← Just add it

// Don't leave commented-out code
// const oldImplementation = () => { ... }  ← Delete it, git has history
```

### 把已知的雷寫下來

```typescript
/**
 * IMPORTANT: This function must be called before the first render.
 * If called after hydration, it causes a flash of unstyled content
 * because the theme context isn't available during SSR.
 *
 * See ADR-003 for the full design rationale.
 */
export function initializeTheme(theme: Theme): void {
  // ...
}
```

## API 文件

針對公開 API（REST、GraphQL、函式庫介面）：

### 與型別寫在一起（TypeScript 的首選做法）

```typescript
/**
 * Creates a new task.
 *
 * @param input - Task creation data (title required, description optional)
 * @returns The created task with server-generated ID and timestamps
 * @throws {ValidationError} If title is empty or exceeds 200 characters
 * @throws {AuthenticationError} If the user is not authenticated
 *
 * @example
 * const task = await createTask({ title: 'Buy groceries' });
 * console.log(task.id); // "task_abc123"
 */
export async function createTask(input: CreateTaskInput): Promise<Task> {
  // ...
}
```

### REST API 使用 OpenAPI／Swagger

```yaml
paths:
  /api/tasks:
    post:
      summary: Create a task
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateTaskInput'
      responses:
        '201':
          description: Task created
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Task'
        '422':
          description: Validation error
```

## README 的結構

每個專案都該有一份 README，涵蓋：

```markdown
# Project Name

One-paragraph description of what this project does.

## Quick Start
1. Clone the repo
2. Install dependencies: `npm install`
3. Set up environment: `cp .env.example .env`
4. Run the dev server: `npm run dev`

## Commands
| Command | Description |
|---------|-------------|
| `npm run dev` | Start development server |
| `npm test` | Run tests |
| `npm run build` | Production build |
| `npm run lint` | Run linter |

## Architecture
Brief overview of the project structure and key design decisions.
Link to ADRs for details.

## Contributing
How to contribute, coding standards, PR process.
```

## 維護變更紀錄

針對已發布的功能：

```markdown
# Changelog

## [1.2.0] - 2025-01-20
### Added
- Task sharing: users can share tasks with team members (#123)
- Email notifications for task assignments (#124)

### Fixed
- Duplicate tasks appearing when rapidly clicking create button (#125)

### Changed
- Task list now loads 50 items per page (was 20) for better UX (#126)
```

## 給 agent 看的文件

針對 AI agent 的情境，有幾點特別考量：

- **CLAUDE.md／規則檔** —— 把專案慣例寫下來，讓 agent 遵循
- **規格檔** —— 保持規格更新，agent 才會做出對的東西
- **ADR** —— 幫 agent 理解過去的決策為什麼那樣下（避免重新決定一次）
- **行內的雷** —— 避免 agent 踩進已知的陷阱

## 常見的自我合理化

| 自我合理化 | 現實 |
|---|---|
| 「程式碼會自己說明」 | 程式碼呈現的是「做了什麼」。它不會告訴你為什麼、否決了哪些替代方案，或有哪些限制。 |
| 「等 API 穩定了再寫文件」 | 你把它寫成文件之後，API 反而會更快穩定。文件是設計的第一道測試。 |
| 「沒人看文件」 | agent 會看。未來的工程師會看。三個月後的你自己也會看。 |
| 「ADR 是額外開銷」 | 花 10 分鐘寫一份 ADR，能省下半年後就同一個決策爭論兩小時。 |
| 「註解會過時」 | 寫*為什麼*的註解很穩定。寫*做了什麼*的註解才會過時 —— 這正是你只該寫前者的原因。 |

## 警訊

- 架構決策沒有任何書面理由
- 公開 API 沒有文件也沒有型別
- README 沒說明怎麼把專案跑起來
- 用註解掉的程式碼代替刪除
- TODO 註解已經放了好幾週
- 專案有重大架構選擇，卻沒有任何 ADR
- 文件只是把程式碼再唸一遍，而不是說明意圖

## 驗證

寫完文件之後：

- [ ] 所有重大架構決策都有 ADR
- [ ] README 涵蓋快速上手、指令與架構概觀
- [ ] API 函式都有參數與回傳型別的說明
- [ ] 已知的雷都在關鍵處以行內註解記錄
- [ ] 沒有殘留註解掉的程式碼
- [ ] 規則檔（CLAUDE.md 等）內容是最新且準確的
