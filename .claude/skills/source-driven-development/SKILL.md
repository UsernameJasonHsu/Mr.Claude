---
name: source-driven-development
description: 讓每個實作決策都以官方文件為依據。適用於希望取得有權威來源引用、不含過時模式的程式碼時。適用於使用任何框架或函式庫開發、且正確性至關重要時。
---

# 來源驅動開發

## 概述

每一個框架相關的程式碼決策，都必須有官方文件作後盾。不要憑記憶實作 —— 要查證、標明出處，讓使用者看得到你的來源。訓練資料會過時、API 會被淘汰、最佳實務會演進。這個技能確保使用者拿到的程式碼值得信任，因為每個寫法都能追溯到一個他們可以自行查核的權威來源。

## 適用時機

- 使用者想要一份符合該框架當前最佳實務的程式碼
- 正在寫樣板、起始程式碼，或會被複製到整個專案的慣用寫法
- 使用者明確要求「有文件依據」、「經過查證」或「正確」的實作
- 實作那些框架建議做法很關鍵的功能（表單、路由、資料抓取、狀態管理、身分驗證）
- 審查或改善使用框架特定寫法的程式碼
- 任何你正打算憑記憶寫框架相關程式碼的時候

**不適用時機：**

- 正確性不取決於特定版本（重新命名變數、修錯字、搬移檔案）
- 在所有版本下行為都相同的純邏輯（迴圈、條件判斷、資料結構）
- 使用者明確表示速度優先於查證（「先快點做出來就好」）

## 流程

```
DETECT ──→ FETCH ──→ IMPLEMENT ──→ CITE
  │          │           │            │
  ▼          ▼           ▼            ▼
 What       Get the    Follow the   Show your
 stack?     relevant   documented   sources
            docs       patterns
```

### 步驟 1：辨識技術堆疊與版本

閱讀專案的相依檔案，找出確切版本：

```
package.json    → Node/React/Vue/Angular/Svelte
composer.json   → PHP/Symfony/Laravel
requirements.txt / pyproject.toml → Python/Django/Flask
go.mod          → Go
Cargo.toml      → Rust
Gemfile         → Ruby/Rails
```

明確說出你找到什麼：

```
STACK DETECTED:
- React 19.1.0 (from package.json)
- Vite 6.2.0
- Tailwind CSS 4.0.3
→ Fetching official docs for the relevant patterns.
```

若版本缺漏或模稜兩可，**去問使用者**。不要用猜的 —— 版本決定了哪種寫法才是對的。

### 步驟 2：抓取官方文件

抓取你正在實作的那項功能所對應的文件頁面。不是首頁，也不是整份文件 —— 是相關的那一頁。

**來源權威階層（依權威性排序）：**

| 優先序 | 來源 | 範例 |
|--------|------|------|
| 1 | 官方文件 | react.dev、docs.djangoproject.com、symfony.com/doc |
| 2 | 官方部落格／變更紀錄 | react.dev/blog、nextjs.org/blog |
| 3 | 網頁標準參考 | MDN、web.dev、html.spec.whatwg.org |
| 4 | 瀏覽器／執行環境相容性 | caniuse.com、node.green |

**不具權威性 —— 絕不當成主要來源引用：**

- Stack Overflow 的回答
- 部落格文章或教學（就算很紅也一樣）
- AI 生成的文件或摘要
- 你自己的訓練資料（這正是重點所在 —— 去查證它）

**抓取時要精準：**

```
BAD:  Fetch the React homepage
GOOD: Fetch react.dev/reference/react/useActionState

BAD:  Search "django authentication best practices"
GOOD: Fetch docs.djangoproject.com/en/6.0/topics/auth/
```

抓取之後，萃取出關鍵寫法，並記下任何淘汰警告或遷移指引。

當官方來源彼此矛盾時（例如遷移指南與 API 參考文件說法不一致），把這個落差告訴使用者，並針對偵測到的版本實際驗證哪一種寫法真的可行。

### 步驟 3：依照文件的寫法實作

寫出與文件所示相符的程式碼：

- 使用文件裡的 API 簽章，不要憑記憶
- 若文件示範了新的做法，就用新的做法
- 若文件已淘汰某種寫法，就不要用被淘汰的版本
- 若文件沒有涵蓋某件事，就標記為「未經查證」

**當文件與專案既有程式碼衝突時：**

```
CONFLICT DETECTED:
The existing codebase uses useState for form loading state,
but React 19 docs recommend useActionState for this pattern.
(Source: react.dev/reference/react/useActionState)

Options:
A) Use the modern pattern (useActionState) — consistent with current docs
B) Match existing code (useState) — consistent with codebase
→ Which approach do you prefer?
```

把衝突攤開來講。不要默默挑一個。

### 步驟 4：標明你的來源

每個框架特定的寫法都要附上出處。使用者必須有辦法查核每一項決策。

**寫在程式碼註解裡：**

```typescript
// React 19 form handling with useActionState
// Source: https://react.dev/reference/react/useActionState#usage
const [state, formAction, isPending] = useActionState(submitOrder, initialState);
```

**寫在對話裡：**

```
I'm using useActionState instead of manual useState for the
form submission state. React 19 replaced the manual
isPending/setIsPending pattern with this hook.

Source: https://react.dev/blog/2024/12/05/react-19#actions
"useTransition now supports async functions [...] to handle
pending states automatically"
```

**引用規則：**

- 用完整網址，不要縮網址
- 盡量使用帶錨點的深層連結（例如用 `/useActionState#usage` 而不是 `/useActionState`）—— 文件改版時，錨點比上層頁面更禁得起考驗
- 當某個決策不那麼顯而易見時，把支持它的段落引述出來
- 建議使用平台功能時，附上瀏覽器／執行環境的支援度資料
- 若你找不到某個寫法的文件，就明講：

```
UNVERIFIED: I could not find official documentation for this
pattern. This is based on training data and may be outdated.
Verify before using in production.
```

誠實說出哪些你沒能查證，比虛假的自信有價值得多。

## 常見的自我合理化

| 自我合理化 | 現實 |
|---|---|
| 「這個 API 我很有把握」 | 把握不是證據。訓練資料裡有一堆看起來正確、但在現行版本上會壞掉的過時寫法。去查證。 |
| 「抓文件很浪費 token」 | 幻想出一個 API 浪費得更多。使用者除錯一小時，才發現函式簽章早就變了。抓一次文件，省下好幾小時的重做。 |
| 「文件裡不會有我要的東西」 | 如果文件沒有涵蓋，那本身就是有價值的資訊 —— 這個寫法可能根本不是官方推薦的。 |
| 「我加註一句『可能已過時』就好」 | 免責聲明沒有幫助。要嘛查證並附上出處，要嘛清楚標記為未經查證。含糊其辭是最糟的選項。 |
| 「這是簡單的任務，不用查」 | 用錯寫法的簡單任務會變成範本。使用者會把你那個已被淘汰的表單處理器複製到十個元件裡，才發現原來有現代做法。 |

## 警訊

- 沒查該版本的文件，就寫框架相關的程式碼
- 談到某個 API 時用「我相信」、「我認為」，而不是引用來源
- 實作了某個寫法，卻不知道它適用於哪個版本
- 引用 Stack Overflow 或部落格文章，而不是官方文件
- 因為訓練資料裡有，就使用已被淘汰的 API
- 實作前沒有讀 `package.json` 或相依檔案
- 交付的程式碼中，框架相關的決策沒有附上來源
- 只需要一頁時卻把整個文件網站抓下來

## 驗證

以來源驅動開發完成實作之後：

- [ ] 已從相依檔案辨識出框架與函式庫版本
- [ ] 已針對框架相關寫法抓取官方文件
- [ ] 所有來源都是官方文件，不是部落格文章或訓練資料
- [ ] 程式碼遵循該版本文件所示的寫法
- [ ] 非瑣碎的決策都附有完整網址的來源引用
- [ ] 沒有使用被淘汰的 API（已對照遷移指南確認）
- [ ] 文件與既有程式碼之間的衝突都已告知使用者
- [ ] 任何無法查證的部分都已明確標記為未經查證
