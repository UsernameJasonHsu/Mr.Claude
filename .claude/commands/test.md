---
description: 執行 TDD 流程 —— 先寫失敗的測試、再實作、然後驗證。修 bug 時使用 Prove-It 模式。
---

呼叫 test-driven-development 技能。

新功能的做法：
1. 寫出描述預期行為的測試（此時應該要**失敗**）
2. 實作程式碼讓測試通過
3. 在測試維持綠燈的前提下重構

修正 bug 的做法（Prove-It 模式）：
1. 寫一個能重現該 bug 的測試（必須**失敗**）
2. 確認測試確實失敗
3. 實作修正
4. 確認測試通過
5. 執行完整測試套件，檢查有沒有造成回歸

若問題與瀏覽器有關，另外呼叫 browser-testing-with-devtools，用 Chrome DevTools MCP 驗證。
