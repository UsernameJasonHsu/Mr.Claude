# Claude Code 使用方法

Claude Code 是一個在**終端機（命令列）**中運作的 AI 助理。
你只要用「打字交代任務」的方式，它就能幫你**自動化處理、整理文件、協助開發**。

---

## 一、安裝與啟動

```bash
# 安裝（需要 Node.js）
npm install -g @anthropic-ai/claude-code

# 在你的專案資料夾中啟動
cd 你的專案資料夾
claude
```

啟動後會進入對話畫面，直接打字交代任務即可。

> 💡 第一次使用會引導你登入 Anthropic 帳號。

---

## 二、基本操作

- **交代任務**：直接打字說明你要做什麼，按 Enter 送出。
- **繼續對話**：Claude 會記得前面的內容，可以邊做邊調整。
- **結束**：輸入 `/exit` 或按 `Ctrl + C` 離開。
- **常用指令**：輸入 `/help` 查看所有可用指令。

Claude 會**自己讀檔案、改檔案、執行指令**，動作前通常會先徵求你同意。

---

## 三、可以幫你做的任務

### 🤖 自動化處理

讓 Claude 幫你完成重複、繁瑣的工作：

```
把這個資料夾裡所有的 .txt 檔轉成 .csv 格式
```
```
批次把所有圖片檔名改成「日期_編號」的格式
```
```
寫一個腳本，每天自動備份 data 資料夾到雲端
```

### 📁 文件整理

```
幫我把這個資料夾的檔案，依照類型分到不同子資料夾
```
```
讀取這份長篇報告，幫我整理成一頁摘要
```
```
把這 5 個 Excel 檔案合併成一個，並移除重複資料
```

### 💻 協助開發

```
幫我看懂這個專案的架構，說明每個資料夾的用途
```
```
這段程式有 bug，幫我找出原因並修正
```
```
幫這個函式加上單元測試
```
```
把這個功能重構，讓程式更好維護
```

---

## 四、實用技巧

### ✅ 講清楚，效果更好
- **指定檔案 / 範圍**：「只改 `src/utils.py` 這個檔案」
- **說明目標**：「目的是讓載入速度變快」
- **限定做法**：「不要動到現有的測試」

### 🛠 善用內建指令
| 指令 | 用途 |
|------|------|
| `/help` | 查看所有指令 |
| `/clear` | 清空目前對話，重新開始 |
| `/init` | 讓 Claude 分析專案並建立說明文件 |
| `/exit` | 離開 |

---

## 五、讓 Claude 更懂你的專案（總覽）

你可以在專案裡放好幾種「設定與說明」，讓 Claude 表現得更貼近你的需求。
它們最大的差別在於 **何時生效**——有的每次都讀、有的需要時才用、有的要你主動觸發。

### 用比喻理解

想像你在幫 Claude 準備一位新同事的工作環境：

- **`CLAUDE.md`** = 交接筆記／工作守則 → Claude **每次**開工都會先讀一遍
- **`.claude/skills/`** = 專業技能手冊（SOP） → 遇到**特定任務**時才翻出來用
- **`.claude/commands/`** = 常用作業的快速鍵 → 你**主動喊一聲**才執行
- **`.mcp.json`** = 外接設備 → 讓它能連上 GitLab 等**外部服務**
- **`.claude/hooks/`** = 自動門 → 特定事件一發生就**自動執行**，不用人記得

### 資料夾結構

```
你的專案/
├── CLAUDE.md              ← 專案規則（每次自動讀）
├── .mcp.json             ← 外部工具連接設定（由 .mcp.json.example 複製，見第九章）
└── .claude/
    ├── settings.json      ← 權限、偏好、Hook 設定
    ├── commands/          ← 自訂 /指令（見第七章）
    │   └── weekly-report.md
    ├── skills/            ← 技能包（見第六章）
    │   └── weekly-report/
    │       └── SKILL.md
    └── hooks/             ← 自動化觸發腳本（見第十章）
        └── log-markdown-edits.ps1
```

### 對照表

| 項目 | 放哪裡 | 是什麼 | 何時生效 | 詳見 |
|------|--------|--------|----------|------|
| **CLAUDE.md** | 專案根目錄 | 專案的規則、慣例、注意事項 | **每次**對話自動讀取 | 本章 |
| **settings.json** | `.claude/` | 權限白名單、偏好設定 | **每次**自動套用 | 本章 |
| **Skill（技能）** | `.claude/skills/` | 某項特定任務的標準做法 | Claude 判斷**符合任務**時 | 第六章 |
| **Command（指令）** | `.claude/commands/` | 常用任務的捷徑 | 你打 **`/名稱`** 主動觸發 | 第七章 |
| **MCP** | `.mcp.json` | 連接外部服務（GitLab…） | 啟用連接器後 | 第九章 |
| **Hook（自動觸發）** | `.claude/hooks/` + `settings.json` | 事件發生時要跑的動作 | 特定事件**自動**執行 | 第十章 |

> 💡 `CLAUDE.md` 可以直接輸入 `/init` 讓 Claude 幫你產生。

---

## 六、動手做一個技能（Skill）

技能就是「把一件常做的任務，事先寫成說明書」，之後只要提到相關工作，Claude 就會自動照著做，不用每次重新交代。

### 步驟一：建立資料夾與檔案

在專案的 `.claude/skills/` 底下，幫技能開一個資料夾，裡面放一個 `SKILL.md`：

```
.claude/
└── skills/
    └── weekly-report/
        └── SKILL.md
```

### 步驟二：寫 SKILL.md

檔案開頭用 `---` 包住基本資訊（name、description），下面寫做法：

```markdown
---
name: weekly-report
description: 整理本週工作紀錄，產出一份週報摘要
---

# 週報產生技能

當使用者要求「產生週報」時，依照以下步驟：

1. 讀取 `logs/` 資料夾中本週的工作紀錄檔。
2. 依「已完成」「進行中」「待處理」三類分別整理。
3. 每項用一句話說明，控制在 300 字以內。
4. 最後輸出成 `reports/週報_日期.md`。
```

> 📌 **重點是 `description`**：Claude 靠這句話判斷「什麼時候該用這個技能」，所以要寫清楚用途。

### 步驟三：使用它

之後只要在對話中說：

```
幫我產生這週的週報
```

Claude 就會自動找到這個技能，照著你寫好的步驟完成——**不需要再重複解釋做法**。

> ✅ **本專案已內含這個範例可直接試跑**：`logs/` 有現成的工作紀錄，
> 只要對 Claude 說「幫我產生這週的週報」，就會在 `reports/` 產出成果。

---

## 七、進階：做成斜線指令（Slash Command）

如果某個任務你常常要用，可以把它做成 `/指令` ，打一個字就觸發，比每次打一整句更快。

### 建立方式

在 `.claude/commands/` 底下放一個 `.md` 檔，**檔名就是指令名稱**：

```
.claude/
└── commands/
    └── weekly-report.md      ← 對應指令 /weekly-report
```

檔案內容寫「你希望 Claude 做什麼」：

```markdown
---
description: 產生本週工作週報
---

讀取 logs/ 中本週的工作紀錄，依照 weekly-report 技能的做法整理，
輸出成 reports/週報_日期.md。
```

### 使用

在對話中輸入指令即可：

```
/weekly-report
```

> 💡 **技能 vs 指令的差別**：
> - **技能**是 Claude「自己判斷」該不該用（你只要描述任務）。
> - **指令**是你「主動下達」的捷徑（明確打 `/名稱` 觸發）。
>
> 本專案兩者都內含，`/weekly-report` 就是週報技能的捷徑。

---

## 八、把這個專案當範本使用

這個專案本身就是一個「可以直接搬走用」的範本。裡面的 `logs/` 是為了示範
`weekly-report` 技能而放的**假資料**（`reports/` 則是技能執行後自動產生、不進版控）。

要用在你自己的專案時，只要：

1. **清掉範例資料**：把 `logs/` 裡的示範紀錄換成你自己的內容。
2. **改寫 `CLAUDE.md`**：換成你自己專案的規則與慣例。
3. **保留或替換技能與指令**：`weekly-report` 可留著參考，或照它的格式改成你要的。
4. **調整權限與外部工具**：視需要修改 `.claude/settings.json` 與 `.mcp.json.example`。

範本可保留的結構如下，套到任何專案都適用：

```
你的專案/
├── CLAUDE.md              ← 改成你的專案規則
├── .gitignore            ← 已設定好要忽略的檔案
├── .mcp.json.example     ← 外部工具連接範本（要用時複製成 .mcp.json）
└── .claude/
    ├── settings.json      ← 權限與 Hook 設定
    ├── commands/          ← 你的 /指令
    ├── skills/            ← 你的技能
    └── hooks/             ← 你的自動化腳本
```

---

## 九、進階：連接外部工具（MCP）

前面的技能與指令都是在「本機」做事。若想讓 Claude 直接**連上外部服務**——例如查
GitLab 的 issue、開 Merge Request、讀資料庫——就要用 **MCP（外部工具連接器）**。

### 用比喻理解

MCP 就像幫 Claude「插上外接設備」：插上 GitLab，它就能操作 GitLab；插上資料庫，
它就能查資料。你只要在設定檔裡告訴它「要連哪個服務、用什麼帳號」。

### 設定方式

本專案附了一份範本 `.mcp.json.example`，照三步驟即可啟用：

**① 複製成正式設定檔**
```bash
cp .mcp.json.example .mcp.json
```

**② 設定檔長這樣**（金鑰用 `${變數}` 代入，不直接寫在檔案裡）
```json
{
  "mcpServers": {
    "gitlab": {
      "type": "http",
      "url": "https://gitlab-srcit.ieiworld.com/api/v4/mcp",
      "headers": { "Authorization": "Bearer ${GITLAB_TOKEN}" }
    }
  }
}
```

**③ 把 token 放進環境變數**（不要寫進設定檔）
```bash
# Windows PowerShell
$env:GITLAB_TOKEN = "你的存取權杖"

# Mac / Linux
export GITLAB_TOKEN="你的存取權杖"
```

設定好後，在 Claude 對話中輸入 `/mcp` 就能看到、啟用這個連接器，接著就能說：

```
幫我看 GitLab 上指派給我的 issue，整理成清單
```

### 也可以用指令快速新增

不想手動編輯 JSON，可用 CLI：
```bash
claude mcp add --scope project --transport http gitlab https://gitlab-srcit.ieiworld.com/api/v4/mcp
claude mcp list        # 查看已設定的連接器
```

### ⚠️ 安全提醒

- **金鑰絕不寫進設定檔或推上 Git**：一律用 `${變數}` 代入，實際值放環境變數。
- 本專案的 `.gitignore` 已忽略 `.env`，請把 token 放這類檔案或系統環境變數。
- `.mcp.json` 可以進版控（分享給團隊），但裡面只該有設定、沒有機密。

---

## 十、進階：自動化觸發（Hooks）

前面的技能、指令都要「Claude 決定用」或「你主動喊」才會動。**Hook 不一樣——
只要某個事件發生，它就一定會自動執行**，是由 Claude Code 這個程式保證跑的，
不依賴 Claude 或你記得。

### 用比喻理解

Hook 就像**自動門**：有人走近（事件發生）就自動打開（執行動作），不用有人去按。

### 能做什麼（常見用途）

| 觸發時機 | 典型用途 |
|----------|----------|
| 改完檔案後 | 自動跑格式化 / lint，程式碼隨時保持整潔 |
| 執行指令前 | 攔截危險操作（例如偵測到 `rm -rf` 就擋下） |
| 每次送出訊息時 | 自動附上專案資訊、目前分支等背景 |
| 任務結束時 | 發通知提醒你「跑完了」 |

### 本專案內含的範例

本專案附了一個安全的示範：**每當 Claude 改完 `.md` 檔，就自動記一筆時間戳**。

它由兩部分組成：

**① 腳本** `.claude/hooks/log-markdown-edits.ps1`
從事件資訊取出檔名，若是 `.md` 就把時間與檔名寫進 `.claude/edit-log.txt`。

**② 在 `settings.json` 註冊**（告訴 Claude「什麼事件、跑哪個腳本」）
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"${CLAUDE_PROJECT_DIR}/.claude/hooks/log-markdown-edits.ps1\""
          }
        ]
      }
    ]
  }
}
```

- **`PostToolUse`**：事件名稱，代表「工具執行完之後」。
- **`matcher`**：要攔哪些工具，這裡是改檔用的 `Edit` 和 `Write`（大小寫要一致）。
- **`command`**：實際要跑的指令。

設定好後，試著請 Claude 改任何一個 `.md` 檔，`.claude/edit-log.txt` 就會自動多一行紀錄。
（此範例只記錄、不影響任何操作，所以很安全。）

> 💡 這個範例腳本是 **PowerShell（Windows）** 寫的。Mac / Linux 團隊可改寫成
> `.sh` 腳本，或把 `command` 換成對應的指令。

---

## 十一、使用小提醒

- 🔍 **會犯錯**：重要的修改記得自己再檢查一次。
- 🔒 **注意權限**：Claude 執行指令前會詢問，看清楚再同意。
- 💾 **善用版本控制**：在 Git 專案中使用，改壞了也能還原。
- 🔄 **多試幾次**：換個說法交代任務，常能得到更好的結果。

---

*交代任務前先講清楚目標，Claude 就能幫你省下大量時間 🎉*
