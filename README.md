# Claude Code 使用方法

Claude Code 是一個在**終端機（命令列）**中運作的 AI 助理。
你只要用「打字交代任務」的方式，它就能幫你**自動化處理、整理文件、協助開發**。

---

## 一、安裝與啟動

官方建議的安裝方式是「原生安裝」，之後會自動在背景更新，不用自己記得升級：

```bash
# macOS / Linux / WSL
curl -fsSL https://claude.ai/install.sh | bash
```

```powershell
# Windows PowerShell
irm https://claude.ai/install.ps1 | iex
```

> 💡 **已經有 Node.js 環境、習慣用 npm 管理工具的話**，也可以改用
> `npm install -g @anthropic-ai/claude-code`（需要 Node.js 22 以上）。
> 差別是：npm 安裝要自己跑 `npm install -g @anthropic-ai/claude-code@latest` 才會升級，
> 原生安裝則會自動更新。兩種裝出來的是同一個程式，擇一即可。

裝好後，在你的專案資料夾中啟動：

```bash
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
- **`.claude/agents/`** = 專業外援（子代理人） → 交給他**獨立處理一個角色的工作**，完成後回報結果
- **`.claude/commands/`** = 常用作業的快速鍵 → 你**主動喊一聲**才執行
- **`.mcp.json`** = 外接設備 → 讓它能連上 GitLab 等**外部服務**
- **`.claude/hooks/`** = 自動門 → 特定事件一發生就**自動執行**，不用人記得

### 資料夾結構

```
你的專案/
├── CLAUDE.md              ← 專案規則（每次自動讀）
├── .mcp.json             ← 外部工具連接設定（由 .mcp.json.example 複製，見第九章）
├── docs/                  ← 補充文件（見第十一章）
├── references/            ← 技能引用的檢查清單等參考資料（見第十一章）
└── .claude/
    ├── settings.json      ← 權限、偏好、Hook 設定
    ├── commands/          ← 自訂 /指令（見第七章）
    │   └── weekly-report.md
    ├── skills/            ← 技能包（見第六章）
    │   └── weekly-report/
    │       └── SKILL.md
    ├── agents/            ← 子代理人（見第十一章）
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
| **Agent（子代理人）** | `.claude/agents/` | 只做一件事的專業角色，獨立跑一段對話再回報 | 你指名呼叫，或指令幫你呼叫 | 第十一章 |

> 💡 `CLAUDE.md` 可以直接輸入 `/init` 讓 Claude 幫你產生。

### CLAUDE.md 不只放在專案根目錄

上面對照表寫的是最常用的位置，但 `CLAUDE.md` 其實分好幾層，**由外到內全部疊加生效**（不是後面蓋掉前面）：

| 層級 | 放哪裡 | 適用範圍 | 進版控？ |
|------|--------|----------|----------|
| 個人（跨專案） | `~/.claude/CLAUDE.md` | 你自己所有專案通用的偏好 | 否，只在你電腦上 |
| 專案（團隊共用） | 專案根目錄 `CLAUDE.md` | 這個專案所有人都要遵守的規則 | 是 |
| 個人（限這個專案） | 專案根目錄 `CLAUDE.local.md` | 只有你、只有這個專案的偏好（例如你自己的測試帳密、常用捷徑） | 否，記得加進 `.gitignore` |

三者會**一起**讀進去，不會互相取代；同一件事寫兩份還互相矛盾的話，Claude 可能隨機選一邊照做，所以盡量別讓內容打架。

> 💡 專案很大、規則很多時，可以把特定主題的規則拆到 `.claude/rules/*.md`，
> 並用檔頭 `paths:` 限定「只在改到符合條件的檔案時才載入」，比全部塞進一份 `CLAUDE.md` 更省對話空間。

### settings.json 也有好幾層，會疊加生效

`.claude/settings.json`（進版控、team 共用）之外，還有 `.claude/settings.local.json`（不進版控，只在你自己電腦生效，通常放個人化的權限或偏好）。兩者同時存在時，優先順序是：

```
命令列參數 > .claude/settings.local.json > .claude/settings.json > ~/.claude/settings.json（個人全域）
```

也就是「範圍愈小、愈個人化的設定，優先權愈高」。本專案的 `.gitignore` 已經把 `.claude/settings.local.json` 排除在外，就是為了讓每個人可以有自己的權限白名單，不會互相覆蓋、也不會不小心推上 Git。

除了 `permissions` 和 `hooks`，`settings.json` 還能設定 `model`（預設模型）、`env`（環境變數）等，有需要時再視情況加入即可。

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
3. **保留或替換技能、指令與子代理人**：`weekly-report` 可留著參考，第十一章的 `agent-skills` 範例也可整批保留或刪除，或照它們的格式改成你要的。
4. **調整權限與外部工具**：視需要修改 `.claude/settings.json` 與 `.mcp.json.example`。

範本可保留的結構如下，套到任何專案都適用：

```
你的專案/
├── CLAUDE.md              ← 改成你的專案規則
├── .gitignore            ← 已設定好要忽略的檔案
├── .mcp.json.example     ← 外部工具連接範本（要用時複製成 .mcp.json）
├── docs/                  ← 補充文件（可留可刪，見第十一章）
├── references/            ← 技能引用的參考資料（可留可刪，見第十一章）
└── .claude/
    ├── settings.json      ← 權限與 Hook 設定
    ├── commands/          ← 你的 /指令
    ├── skills/            ← 你的技能
    ├── agents/            ← 你的子代理人（見第十一章）
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

### 兩種連接方式：http 與 stdio

`.mcp.json.example` 裡其實放了兩組範例，對應 MCP 的兩種連接方式：

- **`type: "http"`**：像上面的 `gitlab`，連到一個「已經架好、隨時在跑」的**遠端服務**。
- **`type: "stdio"`**：像範本裡的 `filesystem-example`，Claude 自己在背景**啟動一個本機小程式**來當外接設備，用 `command` / `args` 指定要怎麼啟動它。

```json
{
  "filesystem-example": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-filesystem", "${CLAUDE_PROJECT_DIR}"]
  }
}
```

這個 `filesystem-example` 本身用途不大——Claude Code 內建的讀寫檔工具已經能做同樣的事——放在範本裡純粹是示範 `stdio` 這種連接方式長什麼樣子。真的要用時，把它換成你要接的本機工具（例如某個資料庫的 MCP server）即可。

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

> ⚠️ **腳本註解刻意寫成英文**：`.ps1` 若存成「UTF-8 無 BOM」又含中文，
> Windows PowerShell 5.1 會用 Big5 碼頁誤讀而導致整支腳本失效。寫成純英文
> （ASCII）就能避開這個陷阱，在 PowerShell 5.1 與 7 都能正常執行。

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

### 不是只有 PostToolUse

`PostToolUse`（工具跑完之後）只是眾多事件之一，常用的還有：

| 事件 | 觸發時機 | 適合做什麼 |
|------|----------|------------|
| `PreToolUse` | 工具**執行前** | 檢查參數、**擋下**危險操作（回傳「不允許」，該次操作就真的不會執行） |
| `PostToolUse` | 工具執行**成功後** | 本專案範例：記錄、自動格式化 |
| `UserPromptSubmit` | 你送出訊息、Claude 還沒開始處理前 | 自動附加背景資訊（例如目前分支） |
| `SessionStart` / `SessionEnd` | 對話開始／結束時 | 初始化環境、寫入工作紀錄 |
| `Stop` | Claude 這輪回覆完畢時 | 發通知提醒「跑完了」 |

`PreToolUse` 跟本專案的範例（`PostToolUse`）差在：`PostToolUse` 只能事後補做點事，`PreToolUse` 可以**真的擋下**該次操作——例如公司規定不准用 `rm -rf`，就能寫一個 `PreToolUse` Hook 偵測到就回傳拒絕。設定方式跟本專案範例一樣，只是把 `"PostToolUse"` 換成對應的事件名稱。

---

## 十一、進階：子代理人（Agent）與外部技能包

### 什麼是 Agent（子代理人）

前面的 Skill 是「Claude 自己邊做邊翻的 SOP」，Agent 則更像**找一位專業外援**：
把一件事整個交給他，他在自己獨立的對話裡處理完，只把**結論**回報給你，
不會佔用主對話的內容。適合「需要專注單一角色觀點」的工作，例如程式碼審查、資安稽核。

### 建立方式

在 `.claude/agents/` 底下放一個 `.md` 檔，**檔名就是子代理人名稱**：

```
.claude/
└── agents/
    └── code-reviewer.md
```

檔案開頭一樣用 `---` 包住 `name`、`description`，下面寫這個角色的行為準則、
輸出格式：

```markdown
---
name: code-reviewer
description: 資深程式碼審查員，從正確性、可讀性、架構、安全性與效能五個面向評估變更。
---

# Senior Code Reviewer

你是一位資深工程師，負責審查程式碼異動……
```

之後可以直接跟 Claude 說「幫我用 code-reviewer 這個角色審查這次修改」，
或讓 Claude 依 `description` 自行判斷該不該叫這個角色出來。

> 💡 **不想手動寫檔案**：對 Claude 說 `/agents`，可以用互動介面建立、編輯、刪除子代理人，效果跟手動寫 `.md` 檔一樣，只是不用自己排版 YAML。
>
> 💡 **`name`、`description` 之外還有其他欄位**：例如 `model`（指定這個角色用哪個模型，例如簡單任務可以指定較便宜的模型）、`tools`（限制這個角色能用哪些工具，例如唯讀審查用的角色可以不給 `Edit`/`Write`）。不寫的話就沿用預設值，本專案的範例都沒特別指定。

### 本專案內含的範例：agent-skills 技能包

本專案的 `.claude/agents/`、`.claude/skills/`、`.claude/commands/` 內，
除了自製的 `weekly-report` 範例，還收錄了開源專案
**[addyosmani/agent-skills](https://github.com/addyosmani/agent-skills)**
提供的一整套「軟體開發生命週期」技能包，方便直接體驗 Agent／Skill／Command
三者如何搭配運作。授權為 MIT License，原始授權條款與所複製的上游版本（commit SHA）
存放於 [`docs/agent-skills-LICENSE.txt`](docs/agent-skills-LICENSE.txt)。

### 為什麼是「複製」進來，不是「安裝」Plugin

`addyosmani/agent-skills` 原本是以 **Claude Code Plugin** 的形式發布——Plugin
是可以裝在使用者層級、跨專案共用的擴充套件，靠一份 `.claude-plugin/plugin.json`
manifest 告訴 Claude Code「agent 放這裡、skill 放那裡」，資料夾不一定要在 `.claude/`
底下，而且會用 `外掛名稱:資源名稱` 的命名空間避免撞名。

但本專案的定位是「clone 下來就能直接照著跑的教學範本」，不希望還要另外叫使用者
去裝一個外部 Plugin 才看得到範例，所以選擇把檔案**直接複製**進本專案固定的
`.claude/agents/`、`.claude/skills/`、`.claude/commands/`——一般專案（非 Plugin）
只有這幾個固定路徑會被 Claude Code 自動偵測，沒有 manifest 可以指定其他位置。

| | 複製進專案（本專案的做法） | 安裝 Plugin |
|---|---|---|
| 檔案放哪 | 固定路徑：`.claude/agents/`、`.claude/skills/`、`.claude/commands/` | manifest 說了算，可以在 repo 任何位置 |
| 使用門檻 | clone 下來就能用，不用額外安裝 | 要先 `/plugin marketplace add`、`/plugin install` |
| 命名空間 | 沒有，直接用原本的名稱 | 有，例如 `agent-skills:code-reviewer`，避免撞名 |
| 跟上游同步 | 不會自動同步，是某個時間點的快照 | 隨市集更新，重新 install 就跟上 |

兩者互不衝突：你可以像現在這樣把範例複製進專案學習、直接改著玩；之後若想在
**其他**專案也用同一套技能，改成 `/plugin install agent-skills@<市集>` 安裝會更省事，
不用每個專案都複製一份。

| 內容 | 數量 | 放在哪裡 |
|------|------|----------|
| Agent（子代理人／角色） | 4 個 | `.claude/agents/` |
| Skill（技能） | 24 個 | `.claude/skills/` |
| Command（指令） | 8 個 | `.claude/commands/` |
| 參考資料（檢查清單等） | 7 份 | `references/` |
| 補充文件 | 2 份 | `docs/` |

**4 個角色（Agent）**：

| 角色 | 定位 | 適合場景 |
|------|------|----------|
| `code-reviewer` | 資深工程師 | 合併前的完整程式碼審查 |
| `security-auditor` | 資安工程師 | 弱點偵測、OWASP 風格稽核 |
| `test-engineer` | QA 工程師 | 測試策略、涵蓋率分析 |
| `web-performance-auditor` | 網頁效能工程師 | Core Web Vitals、載入效能稽核 |

**8 個指令**，對應軟體開發從「定義」到「上線」的各階段：

| 階段 | 指令 | 說明 |
|------|------|------|
| 定義需求 | `/spec` | 先寫規格再寫程式 |
| 拆解任務 | `/plan` | 拆成小而可驗證的任務 |
| 漸進實作 | `/build` | 一次做一個任務；加 `auto` 可一次跑完整份計畫 |
| 驗證 | `/test` | TDD：先寫失敗測試，再實作 |
| 審查 | `/review` | 五個面向的程式碼審查 |
| 簡化 | `/code-simplify` | 在不改變行為下降低複雜度 |
| 效能稽核 | `/webperf` | 網頁效能專項稽核 |
| 上線前檢查 | `/ship` | 平行叫出多個角色會診，綜合成「可不可以上線」的結論 |

24 個 Skill 涵蓋需求訪談、規格撰寫、除錯、CI/CD、安全性強化、文件撰寫等情境，
會依你當下在做的事自動判斷要不要套用；不確定該用哪個時，可以先看
`.claude/skills/using-agent-skills/SKILL.md`，這是統整其他 23 個技能的「總索引」。

> 💡 **想拿掉這批範例**：直接刪除 `.claude/agents/`、`.claude/skills/` 裡對應的資料夾、
> `.claude/commands/` 裡的 8 個 `.md`，以及 `docs/agent-skills-LICENSE.txt`、`docs/agents.md`、
> `references/` 即可，彼此互不依賴 `weekly-report` 範例。
>
> 📌 **內容刻意保留英文**：這批檔案的內文（角色設定、技能步驟、指令說明）維持原文英文，
> 方便日後對照上游 [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) 更新、直接比對差異；
> 只有 `description`（Claude 判斷何時套用的依據）翻成繁中，其餘不算違反本專案「文件一律繁中」的慣例。
>
> ⚠️ **`idea-refine` 技能需要 bash**：`.claude/skills/idea-refine/scripts/idea-refine.sh` 是
> shell 腳本，在 Windows 上要透過 Git Bash 或 WSL 執行，PowerShell 無法直接跑。

---

## 十二、進階：Plan Mode、復原（Rewind）與自動記憶

這三個是 Claude Code 內建、不用另外設定就能用的功能，跟前面「注意權限」「善用版本控制」的精神一致，建議養成習慣。

### Plan Mode：先看計畫，再動手改

按 `Shift+Tab` 可以切換模式，切到 **Plan Mode** 後，Claude 只會**讀程式、探索、提出做法**，不會真的改檔案或執行指令；等你看過計畫、覺得可行再核准，它才會真的動手。

適合用在「範圍較大、有點風險、想先確認方向」的任務，例如：

```
（先按 Shift+Tab 切到 Plan Mode）
把整個結帳流程改成支援多幣別
```

比起「先改下去、改壞了再復原」，Plan Mode 讓你在**動手前**就能喊停或調整方向。

### 復原：改壞了怎麼辦

除了「注意權限」「善用版本控制」，Claude Code 自己也有後悔藥：

- **連按兩下 `Esc`**，或輸入 `/rewind`：把對話內容和程式碼改動，一起復原到之前的某個時間點。
- 按一下 `Esc`：如果發現 Claude 正往錯的方向做，可以立刻打斷，不用等它做完。

這個復原是 Claude Code 自己管理的檢查點，跟 `git` 是兩件事、可以搭配使用：手邊的改動用 `/rewind` 復原，已經 commit 的版本再靠 `git` 控管。

### 自動記憶（Auto Memory）：Claude 自己會抄筆記

`CLAUDE.md`（見第五章）是**你寫給 Claude 看**的規則；Auto Memory 則是 **Claude 自己觀察對話、寫給自己看**的筆記——例如你糾正過的做法、專案的建置指令、除錯時發現的眉角，下次對話會自動記得，不用你再交代一次。

筆記存在 `~/.claude/projects/<專案>/memory/`，預設是開啟的。想看 Claude 記了什麼，輸入 `/memory` 即可瀏覽、編輯或刪除——內容都是純文字檔，看不順眼可以直接改。

| | CLAUDE.md | Auto Memory |
|---|---|---|
| 誰寫的 | 你 | Claude |
| 寫什麼 | 規則、慣例（本專案這份 `CLAUDE.md` 就是） | Claude 自己觀察到的做法、偏好 |
| 進版控？ | 通常會（團隊共用） | 不會（存在你電腦，個人專屬） |

### 其他值得知道的功能

以下功能本專案沒有深入示範，但值得知道有這回事，需要時再查官方文件（[docs.claude.com](https://docs.claude.com)）：

- **Output Styles**（`/config` 設定）：切換 Claude 回答的風格，例如偏教學導向的 Explanatory 風格。
- **狀態列（`/statusline`）**：自訂終端機下方狀態列要顯示什麼資訊（目前分支、對話用量等）。
- **IDE 擴充套件**：VS Code、JetBrains 都有 Claude Code 的擴充套件，不只能在終端機用。
- **Headless 模式（`claude -p`）**：不進互動畫面、直接跑一次性任務，適合寫進自動化腳本。
- **GitHub Actions**：讓 Claude Code 在 CI 流程裡自動跑（例如 PR 開啟時自動審查）。

---

## 十三、使用小提醒

- 🔍 **會犯錯**：重要的修改記得自己再檢查一次。
- 🔒 **注意權限**：Claude 執行指令前會詢問，看清楚再同意。
- 💾 **善用版本控制**：在 Git 專案中使用，改壞了也能還原。
- 🔄 **多試幾次**：換個說法交代任務，常能得到更好的結果。

---

*交代任務前先講清楚目標，Claude 就能幫你省下大量時間 🎉*
