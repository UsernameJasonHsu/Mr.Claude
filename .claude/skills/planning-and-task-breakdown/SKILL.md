---
name: planning-and-task-breakdown
description: 將工作拆解為有順序的任務。適用於已有規格或明確需求，需要拆解為可實作的任務時。適用於任務感覺過大難以開始、需要評估範圍，或可平行作業時。
---

# 規劃與任務拆解

## 概述

把工作分解成小而可驗證的任務，並附上明確的驗收標準。良好的任務拆解，是「能穩定完成工作的 agent」與「產出一團亂的 agent」之間的差別。每個任務都應該小到能在一次專注的工作階段內完成實作、測試與驗證。

## 適用時機

- 你已有規格，需要拆成可實作的單元
- 任務感覺太大或太模糊，不知從何下手
- 工作需要平行分給多個 agent 或多次 session
- 你需要向人說明範圍
- 實作順序不明顯

**不適用時機：** 範圍明確的單檔變更，或規格中已包含定義良好的任務。

## 規劃流程

### 步驟 1：進入 Plan Mode

在寫任何程式碼之前，先以唯讀模式運作：

- 閱讀規格與相關的程式碼區段
- 找出既有的慣例與寫法
- 盤點元件之間的相依關係
- 記下風險與未知數

**規劃期間不要寫程式碼。** 產出是一份存到 `tasks/plan.md` 的計畫文件，以及一份存到 `tasks/todo.md` 的任務清單，而不是實作。

### 步驟 2：畫出相依關係圖

盤點什麼相依於什麼：

```
Database schema
    │
    ├── API models/types
    │       │
    │       ├── API endpoints
    │       │       │
    │       │       └── Frontend API client
    │       │               │
    │       │               └── UI components
    │       │
    │       └── Validation logic
    │
    └── Seed data / migrations
```

實作順序沿著相依關係圖由下而上：先把地基做好。

### 步驟 3：垂直切分

不要先做完所有資料庫、再做完所有 API、再做完所有 UI —— 一次完成一條完整的功能路徑：

**不好（橫向切分）：**
```
Task 1: Build entire database schema
Task 2: Build all API endpoints
Task 3: Build all UI components
Task 4: Connect everything
```

**好（垂直切分）：**
```
Task 1: User can create an account (schema + API + UI for registration)
Task 2: User can log in (auth schema + API + UI for login)
Task 3: User can create a task (task schema + API + UI for creation)
Task 4: User can view task list (query + API + UI for list view)
```

每一個垂直切片都交付出可運作、可測試的功能。

### 步驟 4：撰寫任務

每個任務都遵循這個結構：

```markdown
## Task [N]: [Short descriptive title]

**Description:** One paragraph explaining what this task accomplishes.

**Acceptance criteria:**
- [ ] [Specific, testable condition]
- [ ] [Specific, testable condition]

**Verification:**
- [ ] Tests pass: `npm test -- --grep "feature-name"`
- [ ] Build succeeds: `npm run build`
- [ ] Manual check: [description of what to verify]

**Dependencies:** [Task numbers this depends on, or "None"]

**Files likely touched:**
- `src/path/to/file.ts`
- `tests/path/to/test.ts`

**Estimated scope:** [Small: 1-2 files | Medium: 3-5 files | Large: 5+ files]
```

### 步驟 5：排序並設檢查點

安排任務順序，讓它滿足：

1. 相依關係都被滿足（先把地基做好）
2. 每個任務結束時，系統都處於可運作的狀態
3. 每 2-3 個任務之後就有一個驗證檢查點
4. 高風險的任務排在前面（要失敗就早點失敗）

加上明確的檢查點：

```markdown
## Checkpoint: After Tasks 1-3
- [ ] All tests pass
- [ ] Application builds without errors
- [ ] Core user flow works end-to-end
- [ ] Review with human before proceeding
```

## 任務大小準則

| 大小 | 檔案數 | 範圍 | 範例 |
|------|--------|------|------|
| **XS** | 1 | 單一函式或設定變更 | 加一條驗證規則 |
| **S** | 1-2 | 一個元件或端點 | 新增一個 API 端點 |
| **M** | 3-5 | 一個功能切片 | 使用者註冊流程 |
| **L** | 5-8 | 跨多元件的功能 | 含篩選與分頁的搜尋 |
| **XL** | 8+ | **太大了 —— 再往下拆** | — |

若任務是 L 以上，就該拆成更小的任務。agent 在 S 與 M 大小的任務上表現最好。

**什麼時候該再往下拆：**
- 一次專注的工作階段做不完（大約需要 agent 工作 2 小時以上）
- 你沒辦法用 3 個以內的項目符號描述驗收標準
- 它動到兩個以上互相獨立的子系統（例如身分驗證與帳務）
- 你發現自己在任務標題裡寫了「以及」（這是兩個任務的徵兆）

## 輸出檔案

- **計畫文件：** 把實作計畫存到 `tasks/plan.md`。
- **任務清單：** 把檢核清單形式的任務清單存到 `tasks/todo.md`。

若 `tasks/` 目錄不存在就建立它。這些路徑是 `/build` 指令與其他下游工具預期的慣例。

## 計畫文件範本

```markdown
# Implementation Plan: [Feature/Project Name]

## Overview
[One paragraph summary of what we're building]

## Architecture Decisions
- [Key decision 1 and rationale]
- [Key decision 2 and rationale]

## Task List

### Phase 1: Foundation
- [ ] Task 1: ...
- [ ] Task 2: ...

### Checkpoint: Foundation
- [ ] Tests pass, builds clean

### Phase 2: Core Features
- [ ] Task 3: ...
- [ ] Task 4: ...

### Checkpoint: Core Features
- [ ] End-to-end flow works

### Phase 3: Polish
- [ ] Task 5: ...
- [ ] Task 6: ...

### Checkpoint: Complete
- [ ] All acceptance criteria met
- [ ] Ready for review

## Risks and Mitigations
| Risk | Impact | Mitigation |
|------|--------|------------|
| [Risk] | [High/Med/Low] | [Strategy] |

## Open Questions
- [Question needing human input]
```

## 平行化的機會

當有多個 agent 或多個 session 可用時：

- **可安全平行：** 互相獨立的功能切片、替已實作功能補測試、文件撰寫
- **必須依序進行：** 資料庫遷移、共用狀態的變更、相依鏈
- **需要協調：** 共用同一份 API 契約的功能（先定好契約，再平行化）

## 常見的自我合理化

| 自我合理化 | 現實 |
|---|---|
| 「我邊做邊想就好」 | 這正是你最後會得到一團亂與大量重做的原因。10 分鐘的規劃能省下好幾小時。 |
| 「這些任務很明顯」 | 還是寫下來。明確列出的任務會暴露隱藏的相依關係與被遺忘的邊界情境。 |
| 「規劃是額外開銷」 | 規劃就是任務本身。沒有計畫的實作只是在打字。 |
| 「我全部都記得住」 | 情境視窗是有限的。寫下來的計畫能撐過 session 的邊界與情境壓縮。 |

## 警訊

- 沒有書面任務清單就開始實作
- 任務只寫「實作這個功能」，沒有驗收標準
- 計畫中沒有驗證步驟
- 所有任務都是 XL 大小
- 任務之間沒有檢查點
- 沒有考慮相依順序

## 驗證

開始實作之前，確認：

- [ ] 每個任務都有驗收標準
- [ ] 每個任務都有驗證步驟
- [ ] 任務相依關係都已辨識並正確排序
- [ ] 沒有任務動到超過約 5 個檔案
- [ ] 各主要階段之間都有檢查點
- [ ] 人類已審閱並核准計畫

## 延伸閱讀

驗收標準是逐任務的，回答的是「我們做的是對的東西嗎？」。它們架在專案層級的「完成的定義」之上 —— 那是每個任務都得先跨過、才算完成的固定門檻。見 `references/definition-of-done.md`。
