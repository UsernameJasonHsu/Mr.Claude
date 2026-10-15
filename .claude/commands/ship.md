---
description: 以平行分派給多位專家角色的方式跑完上線前檢核清單，再綜整出「可上線／不可上線」的決策
---

呼叫 shipping-and-launch 技能。

`/ship` 是一個**分派型協調器（fan-out orchestrator）**。它會針對目前的變更，平行執行三個專家角色，再把它們的報告合併成單一的「可上線／不可上線」決策，並附上回滾計畫。這些角色各自獨立運作 —— 沒有共用狀態、沒有先後順序 —— 這正是平行執行在此既安全又有效的原因。

## 階段 A —— 平行分派

使用 Agent 工具同時啟動三個子代理人。**三個 Agent 工具呼叫要放在同一則回覆中發出，才會平行執行** —— 拆成連續呼叫就失去這個指令的意義了。

在 Claude Code 中，每次呼叫都要傳入與該角色 `name` 欄位相符的 `subagent_type`：

1. **`code-reviewer`** —— 針對已暫存的變更或近期 commit，執行五面向審查（正確性、可讀性、架構、安全性、效能）。輸出標準審查範本。
2. **`security-auditor`** —— 執行漏洞掃描與威脅建模。檢查 OWASP Top 10、機密資料處理、身分驗證／授權、相依套件的 CVE。輸出標準稽核報告。
3. **`test-engineer`** —— 分析此次變更的測試涵蓋率。找出正常路徑、邊界情境、錯誤路徑與並行情境上的缺口。輸出標準涵蓋率分析。

若所在環境沒有 Agent 工具，就依序執行各角色的系統提示，並把它們的輸出當成平行回傳的結果來處理 —— 合併階段依然適用。

限制（來自 Claude Code 的子代理人模型）：
- 子代理人不能再啟動其他子代理人 —— 不要讓某個角色轉包給另一個角色。
- 每個子代理人都有自己獨立的情境視窗，只會把報告回傳給這個主 session。
- 如果你需要的是彼此能對話的隊友、而不只是各自回報，請改用 Claude Code Agent Teams，並把這些角色當成隊友類型引用（見 `references/orchestration-patterns.md`）。

**角色解析。** 這些角色已經放在本專案的 `.claude/agents/`，要客製化就直接改那些檔案，`/ship` 會自動採用。若使用者層級的 `~/.claude/agents/` 也有同名定義，請先查閱 Claude Code 現行的範圍優先序規則，確認哪一份會勝出，再決定要不要倚賴它。

## 階段 B —— 在主情境中合併

三份報告都回來之後，由主代理人（而非任何子角色）綜整：

1. **程式碼品質** —— 彙整 `code-reviewer` 提出的「嚴重／重要」發現，以及任何失敗的測試、lint 或建置輸出。排除審查者之間重複的項目。
2. **安全性** —— 把 `security-auditor` 任何「嚴重／高風險」的發現提升為上線阻斷項。並與 `code-reviewer` 的安全性面向交叉比對。
3. **效能** —— 取自 `code-reviewer` 的效能面向；適用時再交叉檢查 Core Web Vitals。
4. **無障礙性** —— 驗證鍵盤操作、螢幕閱讀器支援、對比度（這項不在三個角色的職掌內 —— 在這裡直接處理，或呼叫無障礙檢核清單）。
5. **基礎設施** —— 環境變數、資料遷移、監控、功能旗標。直接驗證。
6. **文件** —— README、ADR、變更紀錄。直接驗證。

## 階段 C —— 決策與回滾

產出單一份輸出：

```markdown
## Ship Decision: GO | NO-GO

### Blockers (must fix before ship)
- [Source persona: Critical finding + file:line]

### Recommended fixes (should fix before ship)
- [Source persona: Important finding + file:line]

### Acknowledged risks (shipping anyway)
- [Risk + mitigation]

### Rollback plan
- Trigger conditions: [what signals would prompt rollback]
- Rollback procedure: [exact steps]
- Recovery time objective: [target]

### Specialist reports (full)
- [code-reviewer report]
- [security-auditor report]
- [test-engineer report]
```

## 規則

1. 階段 A 的三個角色一律平行執行 —— 絕不依序執行。
2. 角色之間不互相呼叫。由主代理人在階段 B 合併。
3. 任何 GO 決策之前，回滾計畫都是必要的。
4. 只要有任一角色回報「嚴重」等級的發現，預設判定就是 NO-GO，除非使用者明確接受該風險。
5. **只有以下條件全部成立時，才可略過分派：** 變更動到的檔案不超過 2 個、diff 少於 50 行，而且沒有碰到身分驗證、金流、資料存取或設定／環境變數。否則一律預設走分派流程。`/ship` 是為了要上正式環境的變更而設計 —— 只要影響範圍不算小，即使 diff 看起來很短，還是要跑平行審查。
