---
name: interview-me
description: 挖掘使用者真正想要的東西，而非他們認為自己應該想要的東西。透過一次一問的訪談方式，直到對背後真實意圖有約 95% 的把握為止。適用於需求描述不足（例如只說 "build me X" 卻沒說 "for whom" 或 "why now"）、使用者明確要求（如 "interview me"、"grill me"、"are we sure?"、"stress-test my thinking"），或發現自己在計畫、規格或程式碼出現前，正悄悄替模糊需求做假設時。
---

# 訪談我（Interview Me）

## 概述

人們開口要的東西，跟他們真正想要的東西，往往是兩回事。他們說要「一個儀表板」，是因為大家都是這樣講的，而不是因為儀表板能解決他們的問題。他們說「弄快一點」，卻沒有一個要達到的數字。

發現這個落差最便宜的時機，是在任何計畫、規格或程式碼出現之前。一旦開始建置，轉換成本就是真的，而使用者會把錯的東西自我說服成「還可以啦」。錯配就此固化。

這個技能能在落差還沒造成任何成本之前把它補起來。定義階段的其他技能都預設你已經大致知道自己要什麼：`idea-refine` 從一個構想產出變化版本、`spec-driven-development` 把需求寫下來、`doubt-driven-development` 在你擬好計畫後對它做壓力測試。interview-me 是這一切之前的那一段 —— 一次問一個問題，每個問題都附上你的最佳猜測，直到你能在使用者開口前就預測他會怎麼回答。

## 適用時機

在以下情況套用這個技能：

- 需求至少缺了其中一項：使用者是**誰**、**為什麼**要、**成功**長什麼樣、關鍵**限制**是什麼
- 需求是慣例性的而非具體的（「幫我做個 X」、「弄快一點」），而你沒辦法不靠猜就拆解那個慣例
- 你正想帶著還沒攤開來講的假設動手
- 有兩個都合理的價值互相拉扯時（簡單 vs. 彈性、成本 vs. 速度），使用者沒說他要最佳化哪一個
- 使用者明確呼叫：「訪談我」、「拷問我」、「開始之前，我們確定嗎？」、「壓力測試我的想法」

**不適用時機：**

- 需求毫無歧義且自成一體（「把這個變數改名」、「修這個錯字」）
- 使用者已明確表示速度優先於查證
- 純粹的資訊查詢（「X 是怎麼運作的？」、「這段程式碼在做什麼？」）
- 機械性操作（改名、格式化、搬檔案）
- 你已經有 ≥95% 的把握；在斷定自己沒有之前，先重讀下面的停止條件

## 載入限制

這個技能需要一位在線且會回應的使用者。**不要在非互動情境中呼叫**，例如 CI 管線、排程執行、`/loop` 或自主迴圈。如果你身處其中之一而需求描述不足，就把它標記為阻礙告訴使用者，而不是用猜的。

## 流程

### 步驟 1：提出假設，附上把握度數字

在問任何問題之前，先用**一句話**寫下你目前對使用者需求的最佳判讀，加上一個誠實的把握度數字（0-100%）：

```
HYPOTHESIS: You want a way to answer "how are we doing?" in standup, and "dashboard" was the convention that came to mind.
CONFIDENCE: ~30% — missing: who it's for, what "metrics" means in context, and what success looks like
```

這個數字會逼出誠實。如果你寫了個很高的數字，卻沒辦法真的預測使用者對你接下來三個問題的反應，那這個數字就是錯的。從你能為之辯護的把握度開始。

當把握度低於約 70% 時，在同一行補上簡短的理由 —— 還有什麼沒解決或缺漏。這能明確告訴使用者這場訪談需要挖出什麼，也避免這個數字淪為一個模糊的訊號。

### 步驟 2：一次問一個問題，每題都附上猜測

格式：

```
Q: <one focused question>
GUESS: <your hypothesis for the answer, with the reasoning that produced it>
```

等使用者回應之後，再問下一題。

**為什麼一次一題，而不是一次問一串：**

- 如果你把假設埋在清單裡，使用者就沒辦法針對它們反應
- 一次問一串會鼓勵略讀，得到表面的答案
- 第三個問題往往取決於第一題的答案；全部一次問完，等於把錯的框架先固定住
- 使用者願意認真思考的精力有限；要一次一題地花在刀口上

**為什麼要附上猜測：**

- 對一個錯的猜測做出反應，比從零想出一個答案快得多
- 它讓你公開押注在一個可能明顯出錯的假設上，逼你保持誠實
- 它會把*你的*假設攤開來，而那正是這場訪談要暴露的東西

這裡的風險是有禮貌的使用者為了配合你而同意你的猜測。緩解方式是明顯表現出「我很願意被打臉」，並偶爾故意往你預期會被反駁的方向猜。

### 步驟 3：聽出「想要」與「以為自己應該想要」的差別

最危險的答案，是使用者說出「一個深思熟慮的答案*聽起來*該有的樣子」，而不是他真正想要的東西。留意：

- 符合最佳實務套話、卻沒有具體內容的答案（「我希望它有擴展性」、「乾淨的架構」）
- 訴諸慣例的答案（「大部分 App 的做法」、「標準做法」）
- 「我大概應該……」、「我想我應該要……」、「良好的工程實務會說……」這類說法
- 把流行詞當目標 —— 當答案是「現代」、「可擴展」、「健壯」，而不是一個具體的結果

聽到這些時，該問的問題是：

> *「如果你不需要向任何人交代，你真正想要的是什麼？」*

這一個問題，往往比前面五個加起來還有用。

### 步驟 4：用使用者自己的話重述意圖

當你的把握度夠高時，把你現在認為使用者想要的東西寫回去。寫得精簡（5-8 行），盡量用他們的用語，並且排版成能讓使用者逐行確認或修正的形式：

```
Here's what I now think you want:

- Outcome:      <one line>
- User:         <one line — who benefits>
- Why now:      <one line — what changed>
- Success:      <one line — how we know it worked>
- Constraint:   <one line — the binding limit>
- Out of scope: <one line — what we're explicitly not doing>

Yes / no / refine?
```

「不在範圍內」這一行沒有商量餘地。有一半的認知落差，來自於雙方對「哪些東西*不做*」的無聲分歧。

### 步驟 5：確認 —— 要明確的「好」，不是「你覺得怎樣都行」

這道關卡要的是明確的「好」。以下**都不算**：

- 「你覺得怎樣最好就怎樣。」→ 使用者在授權，這代表他自己也沒有 95% 的把握。用兩個具體選項改成選擇題再問一次。
- 「聽起來不錯。」→ 語意含糊。追問：「有沒有想再修的地方？」沉默不等於確認。
- 「好啊，開始吧。」→ 常常是禮貌性的結束，而不是背書。同樣追問一句。
- 沉默之後接一句「好，那就開始吧」。→ 使用者是放棄訪談了，不是達成共識。停下來，問問是不是有什麼被漏掉了。

如果他們糾正你，就把修正吸收進去再重述一次。反覆直到拿到明確的「好」。

### 95% 把握度的停止點

當你能對這個問題回答「是」時，就完成了：

> *我能不能預測使用者對我接下來會問的三個問題的反應？*

若能，你們已有共同理解。停止訪談，寫出重述。若不能，就還沒完成；問下一題。

這是一個可檢驗的測試，不是憑感覺。它也有底線：如果你已經來回好幾輪，仍然無法預測，那是關於這個需求本身的資訊，而不是繼續硬磨的理由。停下來告訴使用者：「我已經問了 X 個問題，還是無法預測你的反應。有某個根本性的東西缺漏了。要不要退一步重新看？」

## 產出

這個技能的產出是一份**確認過的意圖陳述**：步驟 4 的重述，加上步驟 5 的明確「好」。那就是交付物。規格、計畫與任務清單都在下游；它們消費的正是這個技能產出的意圖。

如果使用者希望這份意圖能長期保存（跨多次 session 的專案、交接給其他協作者），可以提議把它存到 `docs/intent/[topic].md`。經確認後才存檔。

## 範例

一個簡短的前後對照。

**沒有用 `interview-me`：**

```
User:  build me a dashboard for our metrics
Agent: <starts proposing chart libraries and layouts>
```

agent 已經假設了：這是給誰用的、是哪些指標、「給我們團隊」是什麼意思、成功長什麼樣。這些都沒有人講過。每一個假設，都是日後使用者可以說「我不是這個意思」的地方。

**有用 `interview-me`：**

```
User: build me a dashboard for our metrics

Agent:
HYPOTHESIS: You want a way to answer "how are we doing?" in standup, and "dashboard" came to mind because that's the conventional answer.
CONFIDENCE: ~30% — missing: who it's for, what "metrics" are, and what success looks like

Q:     When you say "how are we doing?", who's asking — you alone, the engineering team in standup, or up the chain (e.g., your manager, an exec, a board)?
GUESS: engineering team in standup, because "we" usually scopes that way and standups are where this question gets asked. If it's for execs the metrics and the framing change a lot.

User: It's actually for me. I keep losing track of which experiments are running and what their early signal looks like.

Agent:
Updated read: not a team dashboard at all. It's a personal experiment tracker. Confidence: ~60% — still missing: what "early signal" means and what done looks like.

Q:     Is the gap that you don't know which experiments exist, or that you can't see their results in one place?
GUESS: the second one. You have a list of experiments somewhere, but their results live in five different tools, and reconciling them by hand is what you're tired of.

User: First one actually. I literally don't have a list. They're spread across different docs.

Agent: <continues>
```

才問到第二題，agent 就發現真正的需求根本不是「一個儀表板」，而是「一份清單」。不同的產物、不同的範圍、不同的工作量。做儀表板會是錯的。

## 與其他技能的關係

- **`idea-refine`**：在下游。若確認後的意圖是「我想要 X，但不知道範圍該怎麼抓」，就交棒給 `idea-refine`，針對已明確化的意圖產出變化版本。
- **`spec-driven-development`**：在下游。若確認後的意圖已經具體（「我要為 Y 類使用者做 X，成功標準是 Z」），就交棒給 `spec-driven-development` 把它寫下來。
- **`planning-and-task-breakdown`**：在這個技能的下游第二站（規格之後）。
- **`doubt-driven-development`**：在時間軸的另一端。interview-me 是決策前的意圖萃取；doubt-driven 是決策後的產物審查。兩者都在捕捉偏離，但發生在不同時刻。
- **`source-driven-development`**：正交關係。interview-me 釐清使用者想要什麼；SDD 查證框架事實。兩者不衝突。

## 常見的自我合理化

| 自我合理化 | 現實 |
|---|---|
| 「需求已經夠清楚了」 | 如果你此刻沒辦法用一句話寫出使用者想要的結果，那需求就不夠清楚。在下判斷前先跑步驟 1。 |
| 「問太多問題是在浪費他們的時間」 | 4-6 個精準問題浪費的時間很少。做錯東西浪費的時間極大，而且成本是使用者在承擔。 |
| 「我邊做邊搞清楚就好」 | 程式碼寫出來之後的轉換成本，是現在的 10 倍。在實作期間才發現，那叫重做。 |
| 「他們說『你覺得怎樣都行』，那我就自己決定」 | 「你覺得怎樣都行」是授權，不是決定。用兩個具體選項當選擇題再問一次。 |
| 「我應該給他們幾個選項挑」 | 選項適用於使用者已經知道自己要什麼、正在權衡取捨的時候。他們現在還不知道自己要什麼。列選項是在擴大搜尋範圍；提問才是在收斂。 |
| 「附上我的猜測會不會在誘導他們？」 | 誘導正是重點。做出反應比從零想快。風險是一味附和，不是誘導；緩解方式是明顯表現出你很願意被打臉。 |
| 「聊夠了，我懂了」 | 檢驗一下：你能預測他們對接下來三個問題的反應嗎？不能，就代表你還沒懂。 |
| 「使用者說好了，那就完成了」 | 如果那個「好」是在一段含糊的重述、或一句開放式的「聽起來不錯」之後出現的，那個「好」是空的。具體地重述一次，再確認一次。 |

## 警訊

- 一則訊息裡塞三個以上的問題：那是批次發問，不是訪談
- 沒有附上你的假設就問問題：那是問卷調查，不是押注
- 把「你覺得怎樣最好就怎樣」當成最終答案接受
- 在使用者明確確認你的重述之前，就產出規格、計畫或任務清單
- 問題框成「什麼是最佳實務？」，而不是「你真正想要什麼？」
- 使用者給出彰顯專業感的答案（「可擴展」、「乾淨」、「現代」），你卻沒有追問那是不是他真正想要的
- 來回三輪以上，你的把握度卻沒有明顯上升：你問錯問題了，退一步重新框定
- 把握度低於約 70% 卻沒附理由：使用者不知道缺什麼，就沒辦法幫你補上
- 在使用者確認之前就把意圖文件存檔（存檔這個動作本身，就暗示了一個使用者並未給出的「好」）
- 重述時漏掉「不在範圍內」那一行（對非目標的無聲分歧，佔了認知落差的一半）

## 驗證

套用 interview-me 之後：

- [ ] 第一輪就講出了明確的假設，並附上把握度數字
- [ ] 每個低於約 70% 的把握度數字，都附上了一行理由（還有什麼沒解決或缺漏）
- [ ] 問題是一次一題問的，每題都附上 agent 的猜測
- [ ] 當使用者給出彰顯專業感或訴諸慣例的答案時，至少追問過一次「如果你不必向誰交代，你真正想要什麼？」
- [ ] 有把一份具體的重述（結果／使用者／為什麼是現在／成功／限制／不在範圍內）寫回給使用者
- [ ] 使用者用明確的「好」確認了重述（不是「你覺得怎樣都行」、不是「聽起來不錯」、也不是沉默）
- [ ] 在停止的那一刻，agent 能預測自己接下來會問的三個問題會得到什麼反應
- [ ] 任何交棒給下游技能（`idea-refine`、`spec-driven-development`）的動作，都是以確認過的意圖為基礎，而不是以最初那個描述不足的需求為基礎
