---
name: spec-driven-development
description: 在撰寫程式碼前先建立規格。適用於開始新專案、新功能或重大變更、且尚未有規格時。適用於需求不明確、含糊，或僅止於模糊構想時。
---

# 規格驅動開發

## 概述

在寫任何程式碼之前，先寫一份結構化的規格。規格是你與人類工程師之間共同的事實來源 —— 它定義了我們要做什麼、為什麼做，以及怎麼知道做完了。沒有規格的程式碼就是在瞎猜。

## 適用時機

- 開始一個新專案或新功能
- 需求含糊或不完整
- 這項變更會動到多個檔案或模組
- 你即將做出一個架構決策
- 這項任務實作起來會超過 30 分鐘

**不適用時機：** 單行修正、修錯字，或需求本身毫無歧義又自成一體的變更。

## 帶關卡的工作流程

規格驅動開發有四個階段。目前這個階段沒通過驗證，就不要推進到下一階段。

```
SPECIFY ──→ PLAN ──→ TASKS ──→ IMPLEMENT
   │          │        │          │
   ▼          ▼        ▼          ▼
 Human      Human    Human      Human
 reviews    reviews  reviews    reviews
```

### 階段 1：Specify（訂規格）

從高層次的願景開始。持續向人類提出釐清問題，直到需求變得具體。

**立刻把假設攤開來講。** 在寫任何規格內容之前，先列出你正在假設什麼：

```
ASSUMPTIONS I'M MAKING:
1. This is a web application (not native mobile)
2. Authentication uses session-based cookies (not JWT)
3. The database is PostgreSQL (based on existing Prisma schema)
4. We're targeting modern browsers only (no IE11)
→ Correct me now or I'll proceed with these.
```

不要默默地把模糊的需求自行補完。規格存在的唯一目的，就是在程式碼寫出來*之前*把誤解揪出來 —— 而假設正是最危險的一種誤解。

**寫一份規格文件，涵蓋以下六個核心區塊：**

1. **目標** —— 我們要做什麼、為什麼做？使用者是誰？成功長什麼樣？

2. **指令** —— 完整可執行的指令連同參數，不只是工具名稱。
   ```
   Build: npm run build
   Test: npm test -- --coverage
   Lint: npm run lint --fix
   Dev: npm run dev
   ```

3. **專案結構** —— 原始碼放哪、測試放哪、文件放哪。
   ```
   src/           → Application source code
   src/components → React components
   src/lib        → Shared utilities
   tests/         → Unit and integration tests
   e2e/           → End-to-end tests
   docs/          → Documentation
   ```

4. **程式碼風格** —— 一段真實的程式碼片段，勝過三段文字描述。包含命名慣例、格式規則，以及理想產出的範例。

5. **測試策略** —— 用什麼框架、測試放哪裡、涵蓋率期望、哪個層級的測試負責哪些面向。

6. **界線** —— 三級制：
   - **一定要做：** commit 前跑測試、遵循命名慣例、驗證輸入
   - **先問過：** 資料庫結構變更、新增相依套件、修改 CI 設定
   - **絕對不做：** commit 機密資料、修改 vendor 目錄、未經同意就移除失敗的測試

**規格範本：**

```markdown
# Spec: [Project/Feature Name]

## Objective
[What we're building and why. User stories or acceptance criteria.]

## Tech Stack
[Framework, language, key dependencies with versions]

## Commands
[Build, test, lint, dev — full commands]

## Project Structure
[Directory layout with descriptions]

## Code Style
[Example snippet + key conventions]

## Testing Strategy
[Framework, test locations, coverage requirements, test levels]

## Boundaries
- Always: [...]
- Ask first: [...]
- Never: [...]

## Success Criteria
[How we'll know this is done — specific, testable conditions]

## Open Questions
[Anything unresolved that needs human input]
```

**把指示重新框成成功標準。** 收到含糊的需求時，把它翻譯成具體的條件：

```
REQUIREMENT: "Make the dashboard faster"

REFRAMED SUCCESS CRITERIA:
- Dashboard LCP < 2.5s on 4G connection
- Initial data load completes in < 500ms
- No layout shift during load (CLS < 0.1)
→ Are these the right targets?
```

這樣你就能朝著一個明確目標反覆嘗試、修正、解決問題，而不是在猜「更快」到底是什麼意思。

### 階段 2：Plan（訂計畫）

拿著通過驗證的規格，產生一份技術實作計畫：

1. 找出主要元件與它們之間的相依關係
2. 決定實作順序（什麼必須先做）
3. 記下風險與緩解策略
4. 分辨哪些可以平行進行、哪些必須依序進行
5. 在各階段之間定義驗證檢查點

> 這些步驟背後的相依關係圖繪製與垂直切分細節，請依循 `planning-and-task-breakdown`，它才是權威來源。上面的條列只是輕量摘要；若兩者出現分歧，以 `planning-and-task-breakdown` 為準。
>
> **輸出慣例：** 依照 `/plan` 指令的慣例，把計畫存到 `tasks/plan.md`，任務清單存到 `tasks/todo.md`。若 `tasks/` 不存在就建立它。下游指令（`/build` 等）預期會用到這些路徑。

計畫要能被審閱：人類應該能讀完之後說「對，方向沒錯」或「不對，把 X 改掉」。

### 階段 3：Tasks（拆任務）

把計畫拆成一個個獨立、可實作的任務：

- 每個任務都應該能在一次專注的工作階段內完成
- 每個任務都有明確的驗收標準
- 每個任務都包含一個驗證步驟（測試、建置、手動確認）
- 任務依相依關係排序，而不是依主觀的重要性
- 任何任務都不應該需要改動超過約 5 個檔案

> 完整的任務大小拿捏與相依排序做法，請依循 `planning-and-task-breakdown`，它才是權威來源。下面的範本只是行內的輕量版；若兩者出現分歧，以 `planning-and-task-breakdown` 為準。

**任務範本：**
```markdown
- [ ] Task: [Description]
  - Acceptance: [What must be true when done]
  - Verify: [How to confirm — test command, build, manual check]
  - Files: [Which files will be touched]
```

### 階段 4：Implement（實作）

依循 `.claude/skills/incremental-implementation/SKILL.md`（`incremental-implementation`）與 `.claude/skills/test-driven-development/SKILL.md`（`test-driven-development`），一次執行一個任務。用 `.claude/skills/context-engineering/SKILL.md`（`context-engineering`）在每一步載入對應的規格段落與原始碼檔案，而不是把整份規格一次灌給 agent。

## 讓規格保持存活

規格是活的文件，不是一次性的產物：

- **決策改變時就更新** —— 若你發現資料模型需要調整，先更新規格，再動手實作。
- **範圍改變時就更新** —— 功能的增減都應反映在規格上。
- **把規格納入版控** —— 規格應該跟程式碼一起放在版本控制中。
- **在 PR 中引用規格** —— 每個 PR 都連回它所實作的那一段規格。

## 常見的自我合理化

| 自我合理化 | 現實 |
|---|---|
| 「這很簡單，不用寫規格」 | 簡單的任務不需要*長*規格，但仍然需要驗收標準。兩行的規格也是規格。 |
| 「我寫完程式碼再補規格」 | 那叫文件，不叫規格。規格的價值在於逼你在寫程式*之前*把事情想清楚。 |
| 「寫規格會拖慢我們」 | 花 15 分鐘寫規格，能省下好幾小時的重做。花 15 分鐘走瀑布，勝過花 15 小時除錯。 |
| 「反正需求本來就會變」 | 這正是規格是活文件的原因。一份過時的規格，仍然比沒有規格好。 |
| 「使用者自己知道要什麼」 | 就算需求講得很清楚，裡面仍有隱含的假設。規格能把那些假設攤開來。 |

## 警訊

- 沒有任何書面需求就開始寫程式
- 還沒釐清「完成」是什麼意思，就問「我可以直接開始做嗎？」
- 實作了規格或任務清單中沒提到的功能
- 做了架構決策卻沒有記錄下來
- 因為「要做什麼很明顯」就跳過規格

## 驗證

進入實作之前，確認：

- [ ] 規格涵蓋了全部六個核心區塊
- [ ] 人類已審閱並核准規格
- [ ] 成功標準具體且可測試
- [ ] 界線（一定要做／先問過／絕對不做）已定義
- [ ] 規格已存成儲存庫中的檔案
