---
name: deprecation-and-migration
description: 管理淘汰（deprecation）與遷移（migration）流程。適用於移除舊系統、API 或功能時。適用於將使用者從一種實作遷移至另一種時。適用於決定是否維護或淘汰既有程式碼時。
---

# 淘汰與遷移

## 概述

程式碼是負債，不是資產。每一行程式碼都有持續的維護成本 —— 要修的 bug、要更新的相依套件、要套用的安全修補，以及新進工程師的學習成本。淘汰是移除「已經不值得留」的程式碼的紀律，遷移則是安全地把使用者從舊的搬到新的的過程。

大多數工程組織很擅長把東西建出來。很少有組織擅長把東西移除掉。這個技能處理的就是這個缺口。

## 適用時機

- 用新系統、API 或函式庫取代舊的
- 收掉一個不再需要的功能
- 整併重複的實作
- 移除那種沒人維護、卻大家都在依賴的死碼
- 規劃新系統的生命週期（淘汰規劃從設計階段就開始）
- 決定要繼續維護一個老舊系統，還是投資在遷移上

## 核心原則

### 程式碼是負債

每一行程式碼都有持續成本：它需要測試、文件、安全修補、相依更新，以及任何在附近工作的人所付出的心智負擔。程式碼的價值在於它提供的功能，而不是程式碼本身。當同樣的功能可以用更少的程式碼、更低的複雜度或更好的抽象來提供時 —— 舊的就該走。

### 海勒姆定律（Hyrum's Law）讓移除變得困難

只要使用者夠多，每一個可被觀察到的行為都會有人依賴 —— 包括 bug、時序上的怪癖，以及沒寫在文件裡的副作用。這就是為什麼淘汰需要主動遷移，而不只是發個公告。當使用者依賴的行為在替代方案裡沒有被複製出來時，他們沒辦法「說換就換」。

### 淘汰規劃從設計階段就開始

在建置新東西時就要問：「三年後我們要怎麼把它移除？」以乾淨介面、功能旗標與最小暴露面設計的系統，會比那種到處洩漏實作細節的系統更容易淘汰。

## 淘汰的決策

在淘汰任何東西之前，先回答這些問題：

```
1. Does this system still provide unique value?
   → If yes, maintain it. If no, proceed.

2. How many users/consumers depend on it?
   → Quantify the migration scope.

3. Does a replacement exist?
   → If no, build the replacement first. Don't deprecate without an alternative.

4. What's the migration cost for each consumer?
   → If trivially automated, do it. If manual and high-effort, weigh against maintenance cost.

5. What's the ongoing maintenance cost of NOT deprecating?
   → Security risk, engineer time, opportunity cost of complexity.
```

## 強制淘汰 vs. 建議淘汰

| 類型 | 適用時機 | 機制 |
|------|----------|------|
| **建議式（Advisory）** | 遷移是選擇性的，舊系統仍然穩定 | 警告、文件、輕推。使用者按自己的節奏遷移。 |
| **強制式（Compulsory）** | 舊系統有安全問題、阻礙進展，或維護成本已無法承受 | 硬性期限。舊系統將在 X 日前移除。必須提供遷移工具。 |

**預設用建議式。** 只有當維護成本或風險足以正當化「強迫遷移」時，才用強制式。強制淘汰必須提供遷移工具、文件與支援 —— 你不能只是公告一個期限就了事。

## 遷移流程

### 步驟 1：先把替代方案做出來

沒有能用的替代方案就不要淘汰。替代方案必須：

- 涵蓋舊系統所有關鍵使用情境
- 有文件與遷移指南
- 已在正式環境中驗證過（不只是「理論上比較好」）

### 步驟 2：公告與撰寫文件

```markdown
## Deprecation Notice: OldService

**Status:** Deprecated as of 2025-03-01
**Replacement:** NewService (see migration guide below)
**Removal date:** Advisory — no hard deadline yet
**Reason:** OldService requires manual scaling and lacks observability.
            NewService handles both automatically.

### Migration Guide
1. Replace `import { client } from 'old-service'` with `import { client } from 'new-service'`
2. Update configuration (see examples below)
3. Run the migration verification script: `npx migrate-check`
```

### 步驟 3：漸進式遷移

一次遷移一個使用方，不要一次全部來。對每個使用方：

```
1. Identify all touchpoints with the deprecated system
2. Update to use the replacement
3. Verify behavior matches (tests, integration checks)
4. Remove references to the old system
5. Confirm no regressions
```

**流失原則（The Churn Rule）：** 如果被淘汰的基礎設施是你擁有的，那麼遷移使用者就是你的責任 —— 或者提供不需要遷移的向後相容更新。不要公告完淘汰，就把使用者丟在那裡自己想辦法。

### 步驟 4：移除舊系統

只有在所有使用方都完成遷移之後：

```
1. Verify zero active usage (metrics, logs, dependency analysis)
2. Remove the code
3. Remove associated tests, documentation, and configuration
4. Remove the deprecation notices
5. Celebrate — removing code is an achievement
```

## 遷移模式

### 絞殺者模式（Strangler Pattern）

讓新舊系統並行運作。把流量逐步從舊的導到新的。當舊系統承接 0% 流量時，就移除它。

```
Phase 1: New system handles 0%, old handles 100%
Phase 2: New system handles 10% (canary)
Phase 3: New system handles 50%
Phase 4: New system handles 100%, old system idle
Phase 5: Remove old system
```

### 轉接器模式（Adapter Pattern）

做一個轉接器，把舊介面的呼叫轉譯到新的實作。使用方繼續用舊介面，你則在後端進行遷移。

```typescript
// Adapter: old interface, new implementation
class LegacyTaskService implements OldTaskAPI {
  constructor(private newService: NewTaskService) {}

  // Old method signature, delegates to new implementation
  getTask(id: number): OldTask {
    const task = this.newService.findById(String(id));
    return this.toOldFormat(task);
  }
}
```

### 功能旗標遷移

用功能旗標把使用方一個一個從舊系統切換到新系統：

```typescript
function getTaskService(userId: string): TaskService {
  if (featureFlags.isEnabled('new-task-service', { userId })) {
    return new NewTaskService();
  }
  return new LegacyTaskService();
}
```

## 殭屍程式碼

殭屍程式碼是指沒人擁有、卻大家都在依賴的程式碼。它沒有被積極維護、沒有明確的負責人，還會不斷累積安全漏洞與相容性問題。徵兆：

- 6 個月以上沒有 commit，卻仍有活躍的使用方
- 沒有指定的維護者或團隊
- 有失敗的測試但沒人修
- 有已知漏洞的相依套件卻沒人更新
- 文件中引用的系統早就不存在了

**該怎麼做：** 要嘛指派一位負責人並好好維護，要嘛帶著具體的遷移計畫把它淘汰。殭屍程式碼不能一直懸在那裡 —— 不是得到投入，就是被移除。

## 常見的自我合理化

| 自我合理化 | 現實 |
|---|---|
| 「它還能跑啊，幹嘛移除？」 | 沒人維護但還能跑的程式碼，會不斷累積安全債與複雜度。維護成本會悄悄成長。 |
| 「說不定以後有人會用到」 | 如果以後真的需要，再重建就好。為了「以防萬一」而留著沒人用的程式碼，成本比重建還高。 |
| 「遷移太貴了」 | 拿遷移成本跟未來 2-3 年的持續維護成本比較。長期來看，遷移通常比較便宜。 |
| 「等新系統做完再來淘汰它」 | 淘汰規劃從設計階段就開始。等新系統做完，你早就有新的優先事項了。現在就規劃。 |
| 「使用者會自己遷移」 | 他們不會。提供工具、文件與誘因 —— 或者你自己做遷移（流失原則）。 |
| 「兩套系統可以一直並存」 | 兩套系統做同一件事，等於維護、測試、文件與教育訓練成本全部加倍。 |

## 警訊

- 被淘汰的系統沒有可用的替代方案
- 淘汰公告沒有附上遷移工具或文件
- 「軟性」淘汰以建議狀態掛了好幾年，毫無進展
- 沒有負責人、卻有活躍使用方的殭屍程式碼
- 在已被淘汰的系統上新增功能（該把心力投在替代方案上）
- 沒有量測目前使用量就進行淘汰
- 沒有確認已無活躍使用方就移除程式碼

## 驗證

完成一次淘汰之後：

- [ ] 替代方案已在正式環境驗證過，並涵蓋所有關鍵使用情境
- [ ] 有遷移指南，附具體步驟與範例
- [ ] 所有活躍使用方都已完成遷移（以指標／日誌確認）
- [ ] 舊程式碼、測試、文件與設定都已完全移除
- [ ] 程式碼庫中不再有任何指向被淘汰系統的引用
- [ ] 淘汰公告已移除（它們已經完成任務）
