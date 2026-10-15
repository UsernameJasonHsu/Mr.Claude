---
name: using-agent-skills
description: 探索並呼叫 agent skills。適用於開始新 session，或需要判斷目前任務該套用哪個 skill 時。這是統管所有其他 skill 如何被探索與呼叫的 meta-skill。
---

# 使用 Agent Skills

## 概述

Agent Skills 是一組依開發階段整理的工程流程技能。每個技能都封裝了一套資深工程師會遵循的具體流程。這個 meta-skill 幫你為當下的任務找出並套用對的技能。

## 技能索引

任務進來時，先判斷它屬於哪個開發階段，再套用對應的技能：

```
Task arrives
    │
    ├── Don't know what you want yet? ──────→ interview-me
    ├── Have a rough concept, need variants? → idea-refine
    ├── New project/feature/change? ──→ spec-driven-development
    ├── Have a spec, need tasks? ──────→ planning-and-task-breakdown
    ├── Implementing code? ────────────→ incremental-implementation
    │   ├── UI work? ─────────────────→ frontend-ui-engineering
    │   ├── API work? ────────────────→ api-and-interface-design
    │   ├── Need better context? ─────→ context-engineering
    │   ├── Need doc-verified code? ───→ source-driven-development
    │   └── Stakes high / unfamiliar code? ──→ doubt-driven-development
    ├── Writing/running tests? ────────→ test-driven-development
    │   └── Browser-based? ───────────→ browser-testing-with-devtools
    ├── Something broke? ──────────────→ debugging-and-error-recovery
    ├── Reviewing code? ───────────────→ code-review-and-quality
    │   ├── Too complex? ─────────────→ code-simplification
    │   ├── Security concerns? ───────→ security-and-hardening
    │   └── Performance concerns? ────→ performance-optimization
    ├── Committing/branching? ─────────→ git-workflow-and-versioning
    ├── CI/CD pipeline work? ──────────→ ci-cd-and-automation
    ├── Deprecating/migrating? ────────→ deprecation-and-migration
    ├── Writing docs/ADRs? ───────────→ documentation-and-adrs
    ├── Adding logs/metrics/alerts? ───→ observability-and-instrumentation
    └── Deploying/launching? ─────────→ shipping-and-launch
```

## 核心運作行為

以下行為在任何時候、套用任何技能時都成立。沒有商量餘地。

### 1. 把假設攤開來講

在實作任何不算瑣碎的東西之前，明確講出你的假設：

```
ASSUMPTIONS I'M MAKING:
1. [assumption about requirements]
2. [assumption about architecture]
3. [assumption about scope]
→ Correct me now or I'll proceed with these.
```

不要默默地把模糊的需求自行補完。最常見的失敗模式，就是做了錯誤的假設卻沒人檢查就一路做下去。及早把不確定講出來 —— 那比事後重做便宜得多。

### 2. 主動處理自己的困惑

當你遇到前後不一致、需求互相衝突，或規格不明確時：

1. **停下來。** 不要靠猜的繼續做。
2. 指名困惑到底在哪裡。
3. 把取捨攤開，或提出釐清問題。
4. 等問題解決再繼續。

**不好：** 默默挑一種解讀，然後祈禱自己猜對。
**好：** 「規格裡寫的是 X，但既有程式碼是 Y。哪一個優先？」

### 3. 該反駁就反駁

你不是應聲蟲。當某個做法有明顯問題時：

- 直接指出問題
- 說明具體的壞處（能量化就量化 —— 說「這會增加約 200ms 延遲」，而不是「這可能會比較慢」）
- 提出替代方案
- 若對方在充分了解資訊後仍決定推翻，就接受他的決定

一味迎合是一種失敗模式。「當然沒問題！」然後去實作一個爛主意，對誰都沒好處。誠實的技術異議，比虛假的同意有價值得多。

### 4. 堅持簡單

你的天性會傾向把事情複雜化。要主動抵抗它。

在完成任何實作之前，先問：
- 這能用更少的行數做完嗎？
- 這些抽象值得它們帶來的複雜度嗎？
- 資深工程師看了會不會說「你怎麼不直接……」？

如果你寫了 1000 行，但 100 行就夠，那就是失敗。優先選擇無聊、顯而易見的解法。耍聰明的代價很高。

### 5. 嚴守範圍紀律

只碰你被要求碰的東西。

**不要**：
- 刪掉你看不懂的註解
- 「順手整理」與任務無關的程式碼
- 順帶重構相鄰的系統
- 未經明確同意就刪掉看似沒用到的程式碼
- 因為「看起來會有用」就加上規格裡沒有的功能

你的工作是外科手術般的精準，不是沒人要求的翻修。

### 6. 要驗證，不要假設

每個技能都包含驗證步驟。驗證通過之前，任務都不算完成。「看起來沒問題」永遠不夠 —— 必須有證據（通過的測試、建置輸出、執行期資料）。

各技能的驗證是局部檢查。無論當下套用哪個技能、對*每一項*變更都適用的專案層級標準，是「完成的定義（Definition of Done）」：測試通過、沒有回歸、行為在執行期得到驗證、文件已更新。見 `references/definition-of-done.md`。它是各任務驗收標準的補充，而不是取代。

## 要避免的失敗模式

以下是看起來很有生產力、實際上卻在製造問題的細微錯誤：

1. 做了錯誤的假設卻不查證
2. 沒有處理自己的困惑 —— 迷路了還硬往前衝
3. 注意到不一致卻不講出來
4. 對不明顯的決策不攤開取捨
5. 對有明顯問題的做法一味附和（「當然沒問題！」）
6. 把程式碼與 API 搞得過度複雜
7. 修改與任務無關的程式碼或註解
8. 移除自己並未完全理解的東西
9. 因為「這很明顯」就沒有規格直接開做
10. 因為「看起來沒問題」就跳過驗證

## 技能使用規則

1. **動工之前，先看有沒有適用的技能。** 技能封裝的是能預防常見錯誤的流程。

2. **技能是工作流程，不是建議。** 按順序執行步驟。不要跳過驗證步驟。

3. **可以同時適用多個技能。** 實作一個功能可能會依序用到 `idea-refine` → `spec-driven-development` → `planning-and-task-breakdown` → `incremental-implementation` → `test-driven-development` → `code-review-and-quality` → `code-simplification` → `shipping-and-launch`。

4. **拿不定主意時，就從規格開始。** 若任務不算瑣碎、又沒有規格，就先從 `spec-driven-development` 開始。

## 生命週期順序

一個完整功能的典型技能順序是：

```
1.  interview-me                → Extract what the user actually wants
2.  idea-refine                 → Refine vague ideas
3.  spec-driven-development     → Define what we're building
4.  planning-and-task-breakdown → Break into verifiable chunks
5.  context-engineering         → Load the right context
6.  source-driven-development   → Verify against official docs
7.  incremental-implementation  → Build slice by slice
8.  observability-and-instrumentation → Instrument as you build (runs parallel with 7-9, not after)
9.  doubt-driven-development    → Cross-examine non-trivial decisions in-flight
10. test-driven-development     → Prove each slice works
11. code-review-and-quality     → Review before merge
12. code-simplification         → Reduce unnecessary complexity while preserving behavior
13. git-workflow-and-versioning → Clean commit history
14. documentation-and-adrs      → Document decisions
15. deprecation-and-migration   → Retire old systems and move users safely when needed
16. shipping-and-launch         → Deploy safely
```

不是每個任務都需要用到每個技能。修一個 bug 可能只需要：`debugging-and-error-recovery` → `test-driven-development` → `code-review-and-quality`。

## 快速對照表

| 階段 | 技能 | 一句話摘要 |
|------|------|-----------|
| 定義 | interview-me | 在計畫、規格或程式碼出現之前，挖出使用者真正想要什麼 |
| 定義 | idea-refine | 透過結構化的發散與收斂思考淬鍊構想 |
| 定義 | spec-driven-development | 先有需求與驗收標準，才有程式碼 |
| 規劃 | planning-and-task-breakdown | 拆解成小而可驗證的任務 |
| 建置 | incremental-implementation | 薄的垂直切片，每一片驗證過再往外擴 |
| 建置 | source-driven-development | 實作前先對照官方文件驗證 |
| 建置 | doubt-driven-development | 對每個非瑣碎決策施以全新情境的對抗式審查 |
| 建置 | context-engineering | 在對的時機給對的情境 |
| 建置 | frontend-ui-engineering | 具無障礙性的正式產品等級 UI |
| 建置 | api-and-interface-design | 契約清晰的穩定介面 |
| 驗證 | test-driven-development | 先寫會失敗的測試，再讓它通過 |
| 驗證 | browser-testing-with-devtools | 用 Chrome DevTools MCP 做執行期驗證 |
| 驗證 | debugging-and-error-recovery | 重現 → 定位 → 修正 → 加上防護 |
| 審查 | code-review-and-quality | 附帶品質關卡的五面向審查 |
| 審查 | code-simplification | 保留行為，同時削掉不必要的複雜度 |
| 審查 | security-and-hardening | OWASP 防範、輸入驗證、最小權限 |
| 審查 | performance-optimization | 先量測，只最佳化真正重要的部分 |
| 交付 | git-workflow-and-versioning | 原子化的 commit、乾淨的歷史 |
| 交付 | ci-cd-and-automation | 每次變更都自動跑品質關卡 |
| 交付 | deprecation-and-migration | 安全地移除舊系統並遷移使用者 |
| 交付 | documentation-and-adrs | 記錄「為什麼」，不只是「做了什麼」 |
| 交付 | observability-and-instrumentation | 結構化日誌、RED 指標、追蹤、以症狀為基礎的告警 |
| 交付 | shipping-and-launch | 上線前檢核清單、監控、回滾計畫 |
