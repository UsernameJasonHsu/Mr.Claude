---
name: incremental-implementation
description: 以漸進方式交付變更。適用於實作任何涉及一個以上檔案的功能或變更時。適用於即將一次寫大量程式碼，或任務感覺太大難以一步完成時。
---

# 漸進式實作

## 概述

以薄的垂直切片來建置 —— 實作一小塊、測試它、驗證它，然後再往外擴。避免一次把整個功能實作完。每一個增量都應該讓系統維持在可運作、可測試的狀態。這是讓大型功能變得可控的執行紀律。

## 適用時機

- 實作任何跨多檔案的變更
- 依任務拆解結果建置新功能
- 重構既有程式碼
- 任何你想在測試之前寫超過約 100 行的時候

**不適用時機：** 範圍本來就極小的單檔、單函式變更。

## 增量循環

```
┌──────────────────────────────────────┐
│                                      │
│   Implement ──→ Test ──→ Verify ──┐  │
│       ▲                           │  │
│       └───── Commit ◄─────────────┘  │
│              │                       │
│              ▼                       │
│          Next slice                  │
│                                      │
└──────────────────────────────────────┘
```

每一個切片都：

1. **實作**最小的一塊完整功能
2. **測試** —— 跑測試套件（若沒有測試就先寫一個）
3. **驗證** —— 確認這個切片如預期運作（測試通過、建置成功、手動確認）
4. **Commit** —— 用具描述性的訊息保存進度（原子化 commit 的指引見 `git-workflow-and-versioning`）
5. **進到下一個切片** —— 往前推進，不要從頭重來

## 切分策略

### 垂直切片（首選）

建置一條完整貫穿整個堆疊的路徑：

```
Slice 1: Create a task (DB + API + basic UI)
    → Tests pass, user can create a task via the UI

Slice 2: List tasks (query + API + UI)
    → Tests pass, user can see their tasks

Slice 3: Edit a task (update + API + UI)
    → Tests pass, user can modify tasks

Slice 4: Delete a task (delete + API + UI + confirmation)
    → Tests pass, full CRUD complete
```

每個切片都交付出可端到端運作的功能。

### 契約優先切分

當後端與前端需要平行開發時：

```
Slice 0: Define the API contract (types, interfaces, OpenAPI spec)
Slice 1a: Implement backend against the contract + API tests
Slice 1b: Implement frontend against mock data matching the contract
Slice 2: Integrate and test end-to-end
```

### 風險優先切分

先處理風險最高、最不確定的那一塊：

```
Slice 1: Prove the WebSocket connection works (highest risk)
Slice 2: Build real-time task updates on the proven connection
Slice 3: Add offline support and reconnection
```

若切片 1 失敗，你會在投入切片 2 與 3 之前就發現。

## 實作規則

### 規則 0：簡單優先

寫任何程式碼之前先問：「能行得通的最簡單做法是什麼？」

寫完之後，用這些檢查回頭審視：
- 這能用更少的行數做完嗎？
- 這些抽象值得它們帶來的複雜度嗎？
- 資深工程師看了會不會說「你怎麼不直接……」？
- 我是在為假想的未來需求而做，還是為當下的任務而做？

```
SIMPLICITY CHECK:
✗ Generic EventBus with middleware pipeline for one notification
✓ Simple function call

✗ Abstract factory pattern for two similar components
✓ Two straightforward components with shared utilities

✗ Config-driven form builder for three forms
✓ Three form components
```

三行相似的程式碼，勝過一個過早的抽象。先實作那個天真、明顯正確的版本。等正確性被測試證實之後，才做最佳化。

### 規則 0.5：範圍紀律

只碰任務需要你碰的東西。

**不要**：
- 「順手整理」你這次變更旁邊的程式碼
- 重整你並沒有要修改的檔案裡的 import
- 刪掉你並未完全理解的註解
- 因為「看起來會有用」就加上規格裡沒有的功能
- 在你只是讀過的檔案裡把語法現代化

如果你注意到任務範圍外有值得改善的地方，把它記下來 —— 不要動手修：

```
NOTICED BUT NOT TOUCHING:
- src/utils/format.ts has an unused import (unrelated to this task)
- The auth middleware could use better error messages (separate task)
→ Want me to create tasks for these?
```

### 規則 1：一次一件事

每個增量只改變一件邏輯上的事。不要把不同關注點混在一起：

**不好：** 一個 commit 同時新增了一個元件、重構了另一個既有元件，還改了建置設定。

**好：** 三個獨立的 commit —— 每項變更一個。

### 規則 2：保持可編譯

每個增量之後，專案都必須能建置，既有測試都必須通過。不要在切片之間把程式碼庫留在壞掉的狀態。

### 規則 3：未完成的功能用功能旗標包起來

如果某個功能還沒準備好給使用者，但你需要合併增量：

```typescript
// Feature flag for work-in-progress
const ENABLE_TASK_SHARING = process.env.FEATURE_TASK_SHARING === 'true';

if (ENABLE_TASK_SHARING) {
  // New sharing UI
}
```

這讓你可以把小增量合併進主分支，又不會暴露未完成的工作。

### 規則 4：安全的預設值

新程式碼的預設行為應該是安全、保守的：

```typescript
// Safe: disabled by default, opt-in
export function createTask(data: TaskInput, options?: { notify?: boolean }) {
  const shouldNotify = options?.notify ?? false;
  // ...
}
```

### 規則 5：對回滾友善

每個增量都應該能被獨立還原：

- 新增性質的變更（新檔案、新函式）很容易還原
- 對既有程式碼的修改應該最小化並聚焦
- 資料庫遷移應該有對應的回滾遷移
- 避免在同一個 commit 裡先刪掉某個東西又替換掉它 —— 把它們分開

## 與 agent 協作

在指示 agent 做漸進式實作時：

```
"Let's implement Task 3 from the plan.

Start with just the database schema change and the API endpoint.
Don't touch the UI yet — we'll do that in the next increment.

After implementing, run `npm test` and `npm run build` to verify
nothing is broken."
```

明確講出每個增量的範圍內是什麼、範圍外**不是**什麼。

## 增量檢核清單

每個增量之後，驗證：

- [ ] 這項變更只做一件事，而且做完整
- [ ] 所有既有測試仍然通過（`npm test`）
- [ ] 建置成功（`npm run build`）
- [ ] 型別檢查通過（`npx tsc --noEmit`）
- [ ] Lint 通過（`npm run lint`）
- [ ] 新功能如預期運作
- [ ] 變更已用具描述性的訊息 commit

**注意：** 在可能影響某項檢查的變更之後，就跑那個驗證指令。成功跑過之後，除非程式碼有變動，否則不要重複跑同一個指令 —— 對沒改動過的程式碼重跑，不會提供任何新資訊。

## 常見的自我合理化

| 自我合理化 | 現實 |
|---|---|
| 「我最後再一次全部測」 | bug 會疊加。切片 1 的 bug 會讓切片 2-5 全錯。每個切片都測。 |
| 「一次做完比較快」 | 在出事之前*感覺*比較快；出事之後，你會找不出 500 行改動裡是哪一行造成的。 |
| 「這些變更太小，不值得分開 commit」 | 小 commit 不花錢。大 commit 會藏 bug，還讓回滾變得痛苦。 |
| 「功能旗標我之後再加」 | 若功能還沒完成，它就不該對使用者可見。現在就加旗標。 |
| 「這個重構很小，順便一起放進來吧」 | 重構跟功能混在一起，會讓兩者都更難審查、更難除錯。分開。 |
| 「讓我再跑一次建置指令確認一下」 | 成功跑過之後，除非程式碼有變動，否則重複同一個指令什麼也不會多告訴你。要在後續編輯之後再跑，而不是為了求心安。 |

## 警訊

- 寫超過 100 行程式碼卻沒跑過測試
- 一個增量裡塞了多項互不相關的變更
- 「順便快快加上這個」的範圍膨脹
- 為了求快而跳過測試／驗證步驟
- 增量之間建置或測試是壞的
- 大量未 commit 的變更不斷累積
- 在第三個使用情境真正要求之前就先做抽象
- 「反正我都在這裡了」而動到任務範圍外的檔案
- 為一次性的操作新建工具檔案
- 中間沒有任何程式碼變動，卻連續跑兩次同一個建置／測試指令

## 驗證

一個任務的所有增量都完成之後：

- [ ] 每個增量都各自測試過並 commit
- [ ] 完整測試套件通過
- [ ] 建置乾淨
- [ ] 功能如規格所述能端到端運作
- [ ] 沒有殘留未 commit 的變更

## 延伸閱讀

逐增量的驗證是局部檢查。在宣告任務完成之前，把專案層級的「完成的定義」當成最後一道關卡套用一次 —— 那是不論什麼任務、每個增量都得跨過的固定門檻。見 `references/definition-of-done.md`。
