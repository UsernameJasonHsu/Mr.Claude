---
name: observability-and-instrumentation
description: 為程式碼加上監測工具（instrumentation），使正式環境的行為可被觀察與診斷。適用於新增日誌（logging）、指標（metrics）、追蹤（tracing）或告警（alerting）時。適用於發布任何將在正式環境執行、且需要證據證明其正常運作的功能時。適用於收到正式環境問題回報，卻無法從既有資料判斷發生了什麼事時。
---

# 可觀測性與監測

## 概述

觀察不到的程式碼，就是營運不了的程式碼。可觀測性是指能從外部、憑程式碼吐出的遙測資料，回答「系統正在做什麼、為什麼」。監測不是上線後才補的東西 —— 它跟測試一樣，是與功能同時寫出來的。如果一個功能上線時沒有遙測，第一個使用者回報的 bug 就會變成考古，而不是一次查詢。

## 適用時機

- 建置任何將在正式環境執行的功能
- 新增服務、端點、背景工作或外部整合
- 某次正式環境事故診斷太久（「我們看不出發生了什麼事」）
- 建立或審查告警規則
- 審查一個加入 I/O、重試、佇列或跨服務呼叫的 PR

**不適用於：**
- 診斷此刻正在發生的故障 —— 請用 `debugging-and-error-recovery` 技能（可觀測性正是讓那個技能下次能更快的基礎）
- 針對已量測到的緩慢做效能剖析與最佳化 —— 請用 `performance-optimization` 技能
- 上線當天的監控檢核清單與回滾觸發條件 —— 見 `shipping-and-launch` 技能；本技能負責的是餵養它們的監測

## 流程

### 1. 加監測之前，先定義什麼叫「正常運作」

沒有問題意識的遙測就是雜訊。加任何監測之前，先寫下 on-call 工程師針對這個功能會問的 2-4 個問題：

```
FEATURE: checkout payment retry
QUESTIONS ON-CALL WILL ASK:
1. What fraction of payments succeed on first attempt vs after retry?
2. When a payment fails permanently, why? (provider error? timeout? validation?)
3. Is the payment provider slower than usual?
→ Every signal below must help answer one of these.
```

如果你說不出這些問題，就代表還沒準備好加監測 —— 你會什麼都記，卻什麼也學不到。

### 2. 為每個問題挑對訊號類型

| 訊號 | 回答什麼 | 成本特性 | 範例 |
|---|---|---|---|
| **結構化日誌** | 「這個特定案例發生了什麼事？」 | 按事件計；隨流量成長 | 帶有供應商錯誤碼的 `payment_failed` |
| **指標** | 「整體來看多常發生／多快？」 | 每條序列固定；查詢便宜 | 供應商呼叫的 p99 延遲 |
| **追蹤** | 「時間花在跨服務的哪一段？」 | 按請求計；通常會抽樣 | 一次緩慢的結帳，逐段拆解 |

原則：指標告訴你**有東西**壞了，追蹤告訴你壞在**哪裡**，日誌告訴你**為什麼**。

### 3. 結構化日誌

記事件，不要記散文。每一行日誌都是一個 JSON 物件，帶有穩定的事件名稱與機器可讀的欄位：

```typescript
// BAD: string interpolation — unqueryable, inconsistent
logger.info(`Payment ${id} failed for user ${userId} after ${n} retries`);

// GOOD: stable event name + structured fields
logger.warn({
  event: 'payment_failed',
  paymentId: id,
  provider: 'stripe',
  errorCode: err.code,
  attempt: n,
}, 'payment failed');
```

**日誌等級 —— 用法要一致：**

| 等級 | 意義 | on-call 該做什麼 |
|---|---|---|
| `error` | 不變條件被破壞；可能需要有人處理 | 調查 |
| `warn` | 功能降級但已被處理（重試成功、走了備援） | 留意趨勢 |
| `info` | 有意義的業務事件（訂單成立、工作完成） | 不用做什麼 |
| `debug` | 診斷細節 | 正式環境預設關閉 |

**關聯 ID 是必要的。** 在系統邊界產生（或接受）一個 request ID，並附到每一行日誌、每一個 span 與每一次對外呼叫上。沒有它，你無法從交錯的日誌中還原出單一請求：

```typescript
// Express: child logger per request, ID propagated downstream
app.use((req, res, next) => {
  req.id = req.headers['x-request-id'] ?? crypto.randomUUID();
  req.log = logger.child({ requestId: req.id });
  res.setHeader('x-request-id', req.id);
  next();
});
```

**絕不記錄機密資料、token、密碼或完整個資。** 這是來自 `security-and-hardening` 技能的硬性規則 —— 遙測管線是典型的資料外洩途徑。用允許清單挑欄位；不要把整個 request body 記下來。

### 4. 指標

對請求驅動的服務，在每個端點與每個外部相依上監測 **RED**：**R**ate（每秒請求數）、**E**rrors（失敗率）、**D**uration（延遲直方圖，不是平均值）。對資源（佇列、連線池、主機）則用 **USE**：**U**tilization（使用率）、**S**aturation（飽和度）、**E**rrors（錯誤）。

跟追蹤一樣，不綁定廠商的做法是使用 OpenTelemetry 的 metrics API（與步驟 5 同一套 SDK 與情境）。下面的範例用的是 Prometheus 的 `prom-client` —— 那只是常見的後端選擇之一，不是唯一；無論用哪一種，RED／USE 與基數（cardinality）規則都完全相同。

```typescript
import { Histogram } from 'prom-client';

const httpDuration = new Histogram({
  name: 'http_request_duration_seconds',
  help: 'HTTP request duration',
  labelNames: ['method', 'route', 'status_class'],  // '2xx', not '200'
  buckets: [0.05, 0.1, 0.25, 0.5, 1, 2.5, 5],
});
```

**基數是主要的失敗模式。** 每一種標籤組合都是一條獨立的時間序列。標籤必須來自小而固定的集合（路由樣板、狀態類別、供應商名稱）。絕不要拿使用者 ID、原始 URL、錯誤訊息或其他沒有上限的值當標籤 —— 那些該放在日誌與追蹤裡。

```
OK as label:    route="/api/tasks/:id"   status_class="5xx"   provider="stripe"
NEVER a label:  user_id, email, request_id, full URL, error message text
```

永遠不要只看平均值，永遠要看百分位數：平均值會掩蓋掉那 1% 體驗極差的使用者。用直方圖，然後讀 p50／p95／p99。

### 5. 分散式追蹤

用 OpenTelemetry —— 它是不綁定廠商的標準，而且自動監測幾乎不用寫程式就能涵蓋 HTTP、gRPC 與常見的資料庫用戶端：

```typescript
// tracing.ts — must be imported before anything else
import { NodeSDK } from '@opentelemetry/sdk-node';
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';

const sdk = new NodeSDK({
  serviceName: 'checkout-service',
  instrumentations: [getNodeAutoInstrumentations()],
});
sdk.start();
```

只在有意義的內部工作單元（例如 `applyDiscounts`、`chargeProvider`）周圍手動加 span，並附上 on-call 會用來過濾的屬性。要在每一個非同步邊界傳遞情境 —— HTTP 標頭、佇列訊息中繼資料 —— 否則追蹤會在那個斷點斷掉。預設以低比例做頭部抽樣（head-based sampling）；若你的後端支援尾部抽樣，就把錯誤全部保留。

### 6. 告警

針對**使用者感受得到的症狀**告警，而不是針對成因：

```
SYMPTOM (page-worthy):           CAUSE (dashboard, not a page):
error rate > 1% for 5 min        CPU at 85%
p99 latency > 2s                 one pod restarted
queue age > 10 min               disk at 70%
```

以成因為基礎的告警，會在什麼事都沒有時響起，卻漏掉你沒預料到的故障。以症狀為基礎的告警，恰好在使用者受影響時響起，不管成因是什麼。

你建立的每一條告警都要遵守：

1. **它必須可付諸行動。** 如果反應是「不用理它，它會自己好」，那就把這條告警刪掉。
2. **它要連到一份處理手冊（runbook）** —— 哪怕只有三行：這代表什麼、第一個該跑的查詢、升級管道。
3. **它的門檻與持續時間要有依據**，來自 SLO 或歷史資料，而不是憑感覺猜的。
4. 只用兩種嚴重度：**呼叫（page）**（影響使用者，立刻處理）與**開單（ticket）**（功能降級，本週處理）。第三層只會變成雜訊，訓練大家對所有告警視而不見。

### 7. 驗證遙測本身

監測也是程式碼，一樣可能寫錯。在宣告完工之前，觸發那些路徑，實際看看輸出：

- 在測試環境強制製造一個錯誤 → 用 `requestId` 在日誌中找到它，確認欄位是結構化的（不是 `[object Object]`）
- 送測試流量 → 確認指標序列有出現，標籤符合預期、數值合理
- 在追蹤介面中跨服務追一個請求 → 沒有斷掉的 span
- 每條新告警都實際觸發一次（暫時調低門檻）→ 確認它有送到正確的頻道，而且處理手冊的連結有效

## 常見的自我合理化

| 自我合理化 | 現實 |
|---|---|
| 「等它能跑了再加日誌」 | 「等一下」會變成「等第一次事故之後」，而那是發現自己什麼都看不到的最昂貴時刻。邊做邊加監測。 |
| 「日誌越多 = 可觀測性越高」 | 沒有結構的雜訊只會讓事故處理更慢，而不是更快。三個可查詢的事件，勝過三百行散文。 |
| 「現在先用 console.log 就好」 | 沒有結構的輸出無法過濾、無法關聯、也無法拿來告警。用結構化 logger 只多花五分鐘，而且只花這一次。 |
| 「出事的時候看儀表板就好」 | 沒有先定義問題就做出來的儀表板，什麼都給你看，就是沒有答案。從 on-call 的問題出發。 |
| 「重要的都先告警，之後再調」 | 一個吵鬧的呼叫器，會訓練大家忽略它。「之後再調」永遠不會發生；被漏掉的那次真警報則會發生。 |
| 「用使用者 ID 當指標標籤比較好除錯」 | 它也會讓你的指標後端垮掉。高基數的查詢屬於日誌與追蹤。 |
| 「我們只有兩個服務，追蹤太超過了」 | 兩個服務就已經會產生日誌回答不了的跨服務延遲問題。自動監測讓成本低到微不足道。 |

## 警訊

- 一個含有重試、佇列或外部呼叫的功能 PR，卻沒有任何新增的遙測
- 日誌用字串內插拼出來，而不是用結構化欄位
- 沒有關聯／請求 ID —— 每行日誌都是孤兒
- 指標的標籤是使用者 ID、原始 URL 或錯誤訊息文字（基數炸彈）
- 延遲只用平均值追蹤，沒有百分位數
- 每天都在響、被人按掉卻沒有任何行動的告警
- 對成因（CPU、記憶體）告警並呼叫真人，面向使用者的錯誤率卻沒人監控
- 日誌中出現機密資料、token 或完整的 request body
- 證明正式環境功能健康的唯一依據，是「在我電腦上可以跑」

## 驗證

替一個功能加完監測後，確認：

- [ ] 這個功能的 on-call 問題已寫下來，而且每個訊號都對應到其中一個
- [ ] 所有日誌輸出都是結構化的（JSON），有穩定的事件名稱，每行都帶關聯 ID
- [ ] 任何一行日誌都沒有機密資料、token 或未遮蔽的個資（抽查實際輸出）
- [ ] 每個新端點與每個外部相依都有 RED 指標，且標籤集合有上限
- [ ] 延遲是直方圖；p95／p99 可查詢
- [ ] 單一請求可在追蹤介面中端到端追完，沒有斷掉的 span
- [ ] 每條新告警都以症狀為基礎、有處理手冊連結，且已測試觸發過一次
- [ ] 在測試環境誘發一次故障，僅憑遙測就能定位，不必去讀原始碼

想看這份清單的一頁式版本（含上線前的監測關卡），見 `references/observability-checklist.md`。
