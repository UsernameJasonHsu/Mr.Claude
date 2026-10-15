---
name: code-simplification
description: 簡化程式碼以提升清晰度。適用於在不改變行為的前提下重構程式碼以提升可讀性。適用於程式碼雖可運作，但比應有的難以閱讀、維護或擴充時。適用於審查已累積不必要複雜度的程式碼時。
---

# 程式碼簡化

> 靈感來自 [Claude Code Simplifier plugin](https://github.com/anthropics/claude-plugins-official/blob/main/plugins/code-simplifier/agents/code-simplifier.md)。此處改寫為不綁定特定模型、以流程為主的技能，適用於任何 AI 編碼 agent。

## 概述

在完整保留原有行為的前提下，降低複雜度來簡化程式碼。目標不是行數變少 —— 而是讓程式碼更容易閱讀、理解、修改與除錯。每一項簡化都必須通過一個簡單的測試：「一位新進團隊成員看懂它，會比看懂原版更快嗎？」

## 適用時機

- 功能已經可以運作、測試也通過，但實作感覺比該有的還笨重
- 程式碼審查中被指出可讀性或複雜度問題時
- 遇到巢狀過深的邏輯、過長的函式，或不清楚的命名
- 重構那些在時間壓力下寫出來的程式碼
- 整併散落在多個檔案中的相關邏輯
- 合併變更後產生了重複或不一致

**不適用時機：**

- 程式碼已經乾淨可讀 —— 不要為了簡化而簡化
- 你還沒搞懂這段程式碼在做什麼 —— 先理解，再簡化
- 這段程式碼對效能很關鍵，而「比較簡單」的版本會明顯變慢
- 你正打算整個重寫這個模組 —— 簡化即將被丟掉的程式碼是白費力氣

## 五項原則

### 1. 完整保留行為

不要改變程式碼「做了什麼」—— 只改變它「怎麼表達」。所有輸入、輸出、副作用、錯誤行為與邊界情境都必須維持一模一樣。若你不確定某項簡化能否保留行為，就不要做。

```
ASK BEFORE EVERY CHANGE:
→ Does this produce the same output for every input?
→ Does this maintain the same error behavior?
→ Does this preserve the same side effects and ordering?
→ Do all existing tests still pass without modification?
```

### 2. 遵循專案慣例

簡化的意思是讓程式碼更貼合程式碼庫，而不是把外來的偏好強加上去。簡化之前：

```
1. Read CLAUDE.md / project conventions
2. Study how neighboring code handles similar patterns
3. Match the project's style for:
   - Import ordering and module system
   - Function declaration style
   - Naming conventions
   - Error handling patterns
   - Type annotation depth
```

破壞專案一致性的簡化不是簡化 —— 那叫瞎攪和。

### 3. 清楚勝過聰明

當精簡的版本需要讀者停下來想一下才解得開時，明確的程式碼就勝過精簡的程式碼。

```typescript
// UNCLEAR: Dense ternary chain
const label = isNew ? 'New' : isUpdated ? 'Updated' : isArchived ? 'Archived' : 'Active';

// CLEAR: Readable mapping
function getStatusLabel(item: Item): string {
  if (item.isNew) return 'New';
  if (item.isUpdated) return 'Updated';
  if (item.isArchived) return 'Archived';
  return 'Active';
}
```

```typescript
// UNCLEAR: Chained reduces with inline logic
const result = items.reduce((acc, item) => ({
  ...acc,
  [item.id]: { ...acc[item.id], count: (acc[item.id]?.count ?? 0) + 1 }
}), {});

// CLEAR: Named intermediate step
const countById = new Map<string, number>();
for (const item of items) {
  countById.set(item.id, (countById.get(item.id) ?? 0) + 1);
}
```

### 4. 拿捏分寸

簡化有一種失敗模式：過度簡化。留意這些陷阱：

- **內聯得太積極** —— 移除一個「替某個概念取了名字」的輔助函式，反而讓呼叫端更難讀
- **把不相關的邏輯合併** —— 兩個簡單的函式併成一個複雜的函式，並不叫簡單
- **移除「不必要的」抽象** —— 有些抽象的存在是為了擴充性或可測試性，不是因為複雜
- **為行數而最佳化** —— 行數少不是目標；容易理解才是

### 5. 範圍限於有變動的部分

預設只簡化近期修改過的程式碼。除非明確被要求擴大範圍，否則不要順手重構無關的程式碼。沒有範圍的簡化會讓 diff 變得吵雜，還可能造成非預期的回歸。

## 簡化流程

### 步驟 1：動手之前先理解（切斯特頓的柵欄）

在改動或移除任何東西之前，先搞懂它為什麼存在。這就是切斯特頓的柵欄：若你看到路上有一道柵欄卻不知道它為什麼在那，不要拆掉它。先弄懂原因，再判斷那個原因是否仍然成立。

```
BEFORE SIMPLIFYING, ANSWER:
- What is this code's responsibility?
- What calls it? What does it call?
- What are the edge cases and error paths?
- Are there tests that define the expected behavior?
- Why might it have been written this way? (Performance? Platform constraint? Historical reason?)
- Check git blame: what was the original context for this code?
```

若你回答不出這些，就代表你還沒準備好簡化。先讀更多情境。

### 步驟 2：找出可簡化之處

掃描這些寫法 —— 每一個都是具體的訊號，不是模糊的直覺：

**結構性複雜度：**

| 寫法 | 訊號 | 簡化方式 |
|------|------|----------|
| 巢狀過深（3 層以上） | 控制流程難以追蹤 | 把條件抽成防衛式回傳或輔助函式 |
| 函式過長（50 行以上） | 職責不只一項 | 拆成職責明確、名稱具描述性的函式 |
| 巢狀三元運算子 | 需要在腦中壓堆疊才解得開 | 改用 if/else 串接、switch，或查表物件 |
| 布林參數旗標 | `doThing(true, false, true)` | 改用選項物件，或拆成不同函式 |
| 重複的條件判斷 | 同一個 `if` 檢查散落多處 | 抽成一個命名良好的判定函式 |

**命名與可讀性：**

| 寫法 | 訊號 | 簡化方式 |
|------|------|----------|
| 籠統的命名 | `data`、`result`、`temp`、`val`、`item` | 改成能描述內容的名稱：`userProfile`、`validationErrors` |
| 縮寫的命名 | `usr`、`cfg`、`btn`、`evt` | 用完整單字，除非該縮寫是通用的（`id`、`url`、`api`） |
| 誤導性的命名 | 名為 `get` 的函式卻會改動狀態 | 改成反映實際行為的名稱 |
| 解釋「做了什麼」的註解 | `count++` 上面寫 `// increment counter` | 刪掉註解 —— 程式碼本身已經夠清楚 |
| 解釋「為什麼」的註解 | `// Retry because the API is flaky under load` | 保留 —— 它們承載了程式碼表達不出的意圖 |

**冗餘：**

| 寫法 | 訊號 | 簡化方式 |
|------|------|----------|
| 重複的邏輯 | 同樣的 5 行以上出現在多處 | 抽成共用函式 |
| 死碼 | 到不了的分支、沒用到的變數、註解掉的區塊 | 移除（確認它真的是死碼之後） |
| 沒必要的抽象 | 沒有增加任何價值的包裝層 | 把包裝內聯，直接呼叫底層函式 |
| 過度設計的模式 | 工廠的工廠、只有一種策略的策略模式 | 換成簡單直接的做法 |
| 多餘的型別斷言 | 對已經被推導出型別的東西再做轉型 | 移除該斷言 |

### 步驟 3：漸進式套用變更

一次做一項簡化。每改一項就跑一次測試。**重構的變更要跟功能或修 bug 的變更分開提交。** 一個既重構又加功能的 PR，其實是兩個 PR —— 把它們拆開。

```
FOR EACH SIMPLIFICATION:
1. Make the change
2. Run the test suite
3. If tests pass → commit (or continue to next simplification)
4. If tests fail → revert and reconsider
```

避免把多項簡化打包成一次未經測試的變更。若有東西壞了，你得知道是哪一項簡化造成的。

**500 行原則：** 若一次重構會動到超過 500 行，就投資在自動化上（codemod、sed 腳本、AST 轉換），而不是手動修改。在那個規模下手動編輯既容易出錯，審查起來也很折磨人。

### 步驟 4：驗證結果

所有簡化都完成後，退一步整體評估：

```
COMPARE BEFORE AND AFTER:
- Is the simplified version genuinely easier to understand?
- Did you introduce any new patterns inconsistent with the codebase?
- Is the diff clean and reviewable?
- Would a teammate approve this change?
```

若「簡化後」的版本反而更難理解或更難審查，就還原。不是每次簡化嘗試都會成功。

## 各語言的指引

### TypeScript／JavaScript

```typescript
// SIMPLIFY: Unnecessary async wrapper
// Before
async function getUser(id: string): Promise<User> {
  return await userService.findById(id);
}
// After
function getUser(id: string): Promise<User> {
  return userService.findById(id);
}

// SIMPLIFY: Verbose conditional assignment
// Before
let displayName: string;
if (user.nickname) {
  displayName = user.nickname;
} else {
  displayName = user.fullName;
}
// After
const displayName = user.nickname || user.fullName;

// SIMPLIFY: Manual array building
// Before
const activeUsers: User[] = [];
for (const user of users) {
  if (user.isActive) {
    activeUsers.push(user);
  }
}
// After
const activeUsers = users.filter((user) => user.isActive);

// SIMPLIFY: Redundant boolean return
// Before
function isValid(input: string): boolean {
  if (input.length > 0 && input.length < 100) {
    return true;
  }
  return false;
}
// After
function isValid(input: string): boolean {
  return input.length > 0 && input.length < 100;
}
```

### Python

```python
# SIMPLIFY: Verbose dictionary building
# Before
result = {}
for item in items:
    result[item.id] = item.name
# After
result = {item.id: item.name for item in items}

# SIMPLIFY: Nested conditionals with early return
# Before
def process(data):
    if data is not None:
        if data.is_valid():
            if data.has_permission():
                return do_work(data)
            else:
                raise PermissionError("No permission")
        else:
            raise ValueError("Invalid data")
    else:
        raise TypeError("Data is None")
# After
def process(data):
    if data is None:
        raise TypeError("Data is None")
    if not data.is_valid():
        raise ValueError("Invalid data")
    if not data.has_permission():
        raise PermissionError("No permission")
    return do_work(data)
```

### React／JSX

```tsx
// SIMPLIFY: Verbose conditional rendering
// Before
function UserBadge({ user }: Props) {
  if (user.isAdmin) {
    return <Badge variant="admin">Admin</Badge>;
  } else {
    return <Badge variant="default">User</Badge>;
  }
}
// After
function UserBadge({ user }: Props) {
  const variant = user.isAdmin ? 'admin' : 'default';
  const label = user.isAdmin ? 'Admin' : 'User';
  return <Badge variant={variant}>{label}</Badge>;
}

// SIMPLIFY: Prop drilling through intermediate components
// Before — consider whether context or composition solves this better.
// This is a judgment call — flag it, don't auto-refactor.
```

## 常見的自我合理化

| 自我合理化 | 現實 |
|---|---|
| 「它能跑，不用去動它」 | 難讀但能跑的程式碼，壞掉時也會很難修。現在簡化，能省下未來每一次變更的時間。 |
| 「行數越少一定越簡單」 | 一行的巢狀三元運算子，並不比五行的 if/else 簡單。簡單指的是理解速度，不是行數。 |
| 「順手把這段無關的也簡化一下好了」 | 沒有範圍的簡化會製造吵雜的 diff，還可能讓你本來不打算動的程式碼出現回歸。保持聚焦。 |
| 「型別讓它自我說明了」 | 型別說明的是結構，不是意圖。一個命名良好的函式解釋*為什麼*的能力，勝過型別簽章解釋*是什麼*。 |
| 「這個抽象以後可能有用」 | 不要保留推測性的抽象。現在沒用到，它就是沒有價值的複雜度。移除它，需要時再加回來。 |
| 「原作者一定有他的理由」 | 也許吧。查一下 git blame —— 套用切斯特頓的柵欄。但累積下來的複雜度往往沒有理由；它只是壓力下反覆迭代留下的殘渣。 |
| 「我加這個功能時順便重構」 | 把重構跟功能開發分開。混在一起的變更更難審查、更難還原，也更難在歷史中理解。 |

## 警訊

- 需要改測試才能通過的簡化（你八成改到行為了）
- 「簡化後」的程式碼比原版更長、更難懂
- 為了符合自己的偏好而改名，而不是為了符合專案慣例
- 因為「這樣程式碼比較乾淨」就移除錯誤處理
- 簡化你並未完全理解的程式碼
- 把很多項簡化打包成一個又大又難審查的 commit
- 未經要求就重構當前任務範圍之外的程式碼

## 驗證

完成一輪簡化之後：

- [ ] 所有既有測試都不需修改即可通過
- [ ] 建置成功且沒有新的警告
- [ ] Linter／formatter 通過（沒有風格上的退步）
- [ ] 每一項簡化都是可審查的漸進變更
- [ ] diff 乾淨 —— 沒有混進無關的變更
- [ ] 簡化後的程式碼遵循專案慣例（已對照 CLAUDE.md 或同等文件確認）
- [ ] 沒有移除或削弱任何錯誤處理
- [ ] 沒有留下死碼（未使用的 import、到不了的分支）
- [ ] 團隊成員或審查 agent 會認可這項變更是淨改善
