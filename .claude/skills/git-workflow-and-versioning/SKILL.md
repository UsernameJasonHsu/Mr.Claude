---
name: git-workflow-and-versioning
description: 建構 git 工作流程實務。適用於進行任何程式碼變更時。適用於 commit、建立分支、解決衝突，或需要組織多條並行工作流時。適用於發布版本、選擇語意化版本號（semantic version）升級方式、打標籤（tag），或撰寫變更紀錄（changelog）時。
---

# Git 工作流程與版本管理

## 概述

Git 是你的安全網。把 commit 當成存檔點、把分支當成沙盒、把歷史當成文件。當 AI agent 以極快的速度產生程式碼時，有紀律的版本控制正是讓變更保持可控、可審查、可還原的機制。

## 適用時機

永遠。每一項程式碼變更都會經過 git。

## 核心原則

### 主幹開發（建議做法）

讓 `main` 隨時都可部署。在短生命週期的功能分支上工作，並在 1-3 天內合併回去。長生命週期的開發分支是隱藏成本 —— 它們會分歧、製造合併衝突，並延後整合。DORA 的研究一再顯示，主幹開發與高績效的工程團隊高度相關。

```
main ──●──●──●──●──●──●──●──●──●──  (always deployable)
        ╲      ╱  ╲    ╱
         ●──●─╱    ●──╱    ← short-lived feature branches (1-3 days)
```

這是建議的預設做法。使用 gitflow 或長生命週期分支的團隊，可以把這些原則（原子化 commit、小變更、具描述性的訊息）套用到自己的分支模型上 —— commit 的紀律比特定的分支策略更重要。

- **開發分支是成本。** 分支每多活一天，就多累積一分合併風險。
- **發布分支是可接受的。** 當你需要在 main 繼續前進的同時穩定某個版本時。
- **功能旗標 > 長分支。** 寧可把未完成的工作藏在旗標後面部署，也不要讓它在分支上擱好幾週。

### 1. 及早 commit，經常 commit

每一個成功的增量都有自己的 commit。不要累積大量未 commit 的變更。

```
Work pattern:
  Implement slice → Test → Verify → Commit → Next slice

Not this:
  Implement everything → Hope it works → Giant commit
```

commit 就是存檔點。若下一項變更弄壞了什麼，你可以立刻還原到上一個已知可用的狀態。

### 2. 原子化 commit

每個 commit 只做一件邏輯上的事：

```
# Good: Each commit is self-contained
git log --oneline
a1b2c3d Add task creation endpoint with validation
d4e5f6g Add task creation form component
h7i8j9k Connect form to API and add loading state
m1n2o3p Add task creation tests (unit + integration)

# Bad: Everything mixed together
git log --oneline
x1y2z3a Add task feature, fix sidebar, update deps, refactor utils
```

### 3. 具描述性的訊息

commit 訊息要解釋*為什麼*，不只是*做了什麼*：

```
# Good: Explains intent
feat: add email validation to registration endpoint

Prevents invalid email formats from reaching the database.
Uses Zod schema validation at the route handler level,
consistent with existing validation patterns in auth.ts.

# Bad: Describes what's obvious from the diff
update auth.ts
```

**格式：**
```
<type>: <short description>

<optional body explaining why, not what>
```

**類型：**
- `feat` —— 新功能
- `fix` —— 修 bug
- `refactor` —— 既不修 bug 也不加功能的程式碼變更
- `test` —— 新增或更新測試
- `docs` —— 只改文件
- `chore` —— 工具、相依套件、設定

### 4. 讓不同關注點分開

不要把格式調整跟行為變更混在一起。不要把重構跟功能混在一起。每一類變更都該是獨立的 commit —— 最好也是獨立的 PR：

```
# Good: Separate concerns
git commit -m "refactor: extract validation logic to shared utility"
git commit -m "feat: add phone number validation to registration"

# Bad: Mixed concerns
git commit -m "refactor validation and add phone number field"
```

**把重構與功能開發分開。** 一次重構變更與一次功能變更是兩種不同的變更 —— 分開提交。這會讓每項變更更容易審查、更容易還原，也更容易在歷史中理解。小的整理（變數改名）可由審查者裁量是否併入功能 commit。

### 5. 控制變更大小

每個 commit／PR 以約 100 行為目標。超過約 1000 行的變更應該拆開。大型變更的拆解策略見 `code-review-and-quality`。

```
~100 lines  → Easy to review, easy to revert
~300 lines  → Acceptable for a single logical change
~1000 lines → Split into smaller changes
```

## 分支策略

### 功能分支

```
main (always deployable)
  │
  ├── feature/task-creation    ← One feature per branch
  ├── feature/user-settings    ← Parallel work
  └── fix/duplicate-tasks      ← Bug fixes
```

- 從 `main`（或團隊的預設分支）開分支
- 讓分支保持短命（1-3 天內合併）—— 長生命週期的分支是隱藏成本
- 合併後刪除分支
- 未完成的功能，優先用功能旗標而不是長生命週期分支

### 分支命名

```
feature/<short-description>   → feature/task-creation
fix/<short-description>       → fix/duplicate-tasks
chore/<short-description>     → chore/update-deps
refactor/<short-description>  → refactor/auth-module
```

## 使用 worktree

要讓多個 AI agent 平行作業，可以用 git worktree 同時跑多個分支：

```bash
# Create a worktree for a feature branch
git worktree add ../project-feature-a feature/task-creation
git worktree add ../project-feature-b feature/user-settings

# Each worktree is a separate directory with its own branch
# Agents can work in parallel without interfering
ls ../
  project/              ← main branch
  project-feature-a/    ← task-creation branch
  project-feature-b/    ← user-settings branch

# When done, merge and clean up
git worktree remove ../project-feature-a
```

好處：
- 多個 agent 可以同時處理不同功能
- 不需要切換分支（每個目錄都有自己的分支）
- 若某個實驗失敗，刪掉那個 worktree 就好 —— 什麼都不會丟
- 在明確合併之前，變更彼此隔離

## 存檔點模式

```
Agent starts work
    │
    ├── Makes a change
    │   ├── Test passes? → Commit → Continue
    │   └── Test fails? → Revert to last commit → Investigate
    │
    ├── Makes another change
    │   ├── Test passes? → Commit → Continue
    │   └── Test fails? → Revert to last commit → Investigate
    │
    └── Feature complete → All commits form a clean history
```

這個模式代表你損失的工作永遠不會超過一個增量。若 agent 跑偏了，`git reset --hard HEAD` 就能把你帶回上一個成功的狀態。

## 變更摘要

在任何修改之後，提供一份結構化的摘要。這會讓審查更容易、記錄你的範圍紀律，也能揭露非預期的變更：

```
CHANGES MADE:
- src/routes/tasks.ts: Added validation middleware to POST endpoint
- src/lib/validation.ts: Added TaskCreateSchema using Zod

THINGS I DIDN'T TOUCH (intentionally):
- src/routes/auth.ts: Has similar validation gap but out of scope
- src/middleware/error.ts: Error format could be improved (separate task)

POTENTIAL CONCERNS:
- The Zod schema is strict — rejects extra fields. Confirm this is desired.
- Added zod as a dependency (72KB gzipped) — already in package.json
```

這個模式能及早抓出錯誤的假設，也給審查者一張清楚的變更地圖。「沒有動到的東西」那一段尤其重要 —— 它顯示你有守住範圍紀律，沒有跑去做沒人要求的翻修。

## Commit 前的衛生檢查

每次 commit 之前：

```bash
# 1. Check what you're about to commit
git diff --staged

# 2. Ensure no secrets
git diff --staged | grep -i "password\|secret\|api_key\|token"

# 3. Run tests
npm test

# 4. Run linting
npm run lint

# 5. Run type checking
npx tsc --noEmit
```

用 git hook 把它自動化：

```json
// package.json (using lint-staged + husky)
{
  "lint-staged": {
    "*.{ts,tsx}": ["eslint --fix", "prettier --write"],
    "*.{json,md}": ["prettier --write"]
  }
}
```

## 處理產生出來的檔案

- **只有在專案預期會有時，才 commit 產生出來的檔案**（例如 `package-lock.json`、Prisma 遷移檔）
- **不要 commit** 建置輸出（`dist/`、`.next/`）、環境檔（`.env`），或 IDE 設定（除非是共用的，否則不要 commit `.vscode/settings.json`）
- **要有 `.gitignore`**，涵蓋：`node_modules/`、`dist/`、`.env`、`.env.local`、`*.pem`

## 用 Git 除錯

```bash
# Find which commit introduced a bug
git bisect start
git bisect bad HEAD
git bisect good <known-good-commit>
# Git checkouts midpoints; run your test at each to narrow down

# View what changed recently
git log --oneline -20
git diff HEAD~5..HEAD -- src/

# Find who last changed a specific line
git blame src/services/task.ts

# Search commit messages for a keyword
git log --grep="validation" --oneline
```

## 發布與版本管理

commit 是*你*用來追蹤變更的方式；而**版本**是你的*使用方*用來追蹤變更的方式。一旦有任何其他東西依賴你的程式碼 —— 另一個團隊、一個已發布的套件、一個已部署的用戶端 ——「main 上的最新版」就不再足以回答「我現在跑的是什麼、升級安全嗎？」。版本號與變更紀錄，就是回答這個問題的契約。

### 語意化版本

任何有使用方的東西，都以 `MAJOR.MINOR.PATCH` 標示版本，並讓數字承載意義：

```
  MAJOR  breaking change — consumers must change their code to upgrade
  MINOR  new functionality, backward-compatible — safe to upgrade
  PATCH  bug fix, backward-compatible — safe to upgrade
```

這個數字是一項承諾，所以要讓程式碼與它相符。一個改變了使用方所依賴行為的「patch」，是偽裝過的重大變更（海勒姆定律 —— 見 `api-and-interface-design` 技能）。當你不確定某項變更是否具破壞性時，就假設它是；一次意外的 major，遠比一個被弄壞的使用方便宜得多。

### 替發布打標籤，並讓標籤成為事實來源

發布是歷史上一個不可變的點，不是一個會移動的分支。替它打標籤，讓它永遠能被重現：

```bash
git tag -a v1.4.0 -m "Release 1.4.0"
git push origin v1.4.0
```

從標籤推導出版本，而不是在散落各處的檔案裡手動編輯，這樣產出物、標籤與變更紀錄就永遠不會彼此矛盾。

### 寫一份給人看的變更紀錄

變更紀錄不是 `git log`。它是經過策劃、面向使用方的答案，回答「改了什麼、我需要在意嗎？」—— 依 `Added / Changed / Fixed / Deprecated / Removed / Security` 分組，最新的在最上面，每一條都圍繞著對使用者的影響來寫，而不是內部機制。

```markdown
## [1.4.0] - 2025-06-12
### Added
- Bulk task import via CSV
### Fixed
- Timezone drift in recurring task due dates
### Deprecated
- `GET /v1/tasks/all` — use the paginated `GET /v1/tasks` (removal in 2.0)
```

在做出該變更的同一次變更中就寫下對應的條目，趁影響還鮮明時 —— 而不是在發布時靠 commit 考古重建出來。破壞性變更要附上遷移說明與淘汰緩衝期（依循 `deprecation-and-migration` 技能）；實際把版本推出去是 `shipping-and-launch` 技能的職責 —— 本節談的是餵養它的版本契約。

## 常見的自我合理化

| 自我合理化 | 現實 |
|---|---|
| 「等功能做完我再 commit」 | 一個巨大的 commit 無法審查、無法除錯、也無法還原。每個切片都 commit。 |
| 「訊息不重要」 | 訊息就是文件。未來的你（與未來的 agent）需要理解改了什麼、為什麼改。 |
| 「我之後再把它們 squash 起來」 | squash 會摧毀開發的敘事。從一開始就寫出乾淨的漸進 commit。 |
| 「分支是額外開銷」 | 短命的分支是免費的，還能防止衝突的工作撞在一起。有問題的是長生命週期的分支 —— 1-3 天內合併掉。 |
| 「這個變更我之後再拆」 | 大型變更更難審查、部署風險更高、也更難還原。提交前就拆，不是提交後。 |
| 「我不需要 .gitignore」 | 直到含有正式環境機密的 `.env` 被 commit 進去為止。立刻把它設起來。 |
| 「只是個小修正，patch 加一就好」 | 檢查使用方能觀察到什麼。他們所依賴的行為變了，就是 major，不管 diff 多小。 |
| 「變更紀錄就是 commit log 啊」 | commit 是給你自己看的；變更紀錄是給使用方看的，並依影響策劃過。從原始 commit 自動產生，只會把重點埋掉。 |
| 「變更紀錄等發布時再寫」 | 到那時候，影響只能憑記憶重建，而且會漏掉一半。跟著變更一起寫下條目。 |

## 警訊

- 大量未 commit 的變更不斷累積
- commit 訊息像「fix」、「update」、「misc」
- 格式調整跟行為變更混在一起
- 專案裡沒有 `.gitignore`
- 把 `node_modules/`、`.env` 或建置產物 commit 進去
- 長生命週期的分支與 main 嚴重分歧
- 對共用分支做 force push
- 破壞性變更卻只升了 minor 或 patch 版號
- 發布沒有打標籤，或版本號被手動編輯到與標籤不同步
- 面向使用者的發布沒有變更紀錄條目，或變更紀錄只是把 commit 訊息倒進去

## 驗證

每個 commit：

- [ ] commit 只做一件邏輯上的事
- [ ] 訊息解釋了為什麼，並遵循類型慣例
- [ ] commit 前測試通過
- [ ] diff 中沒有機密資料
- [ ] 沒有把純格式變更跟行為變更混在一起
- [ ] `.gitignore` 涵蓋了標準的排除項目

每次發布（任何有使用方的東西）：

- [ ] 版號的升級方式與變更相符：破壞性 → major、新增性 → minor、修正 → patch
- [ ] 發布有打標籤，而且版本是從標籤推導出來的，沒有被手動編輯到不同步
- [ ] 變更紀錄中，這個版本有一則經過策劃、依影響分組、人看得懂的條目
