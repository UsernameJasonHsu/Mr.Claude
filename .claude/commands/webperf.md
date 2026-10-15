---
description: 透過 web-performance-auditor 角色執行網頁效能稽核
---

`/webperf` 專門針對網頁應用程式。不要用在工具函式庫、CLI，或沒有瀏覽器輸出的純伺服器端程式碼上。

## 判斷模式

**深度模式（Deep mode）** —— 只要具備以下任一項就啟用：
- 一份 Lighthouse JSON 報告檔（例如 `npx lighthouse <url> --output json --output-path ./report.json`，或用 Chrome DevTools MCP CLI 執行 `npx -p chrome-devtools-mcp chrome-devtools lighthouse_audit --output-format=json`）
- 一份 PageSpeed Insights 的 JSON 回應（內含 Lighthouse + CrUX）
- 一份 CrUX API 回應（需要 `CRUX_API_KEY` 或 `GOOGLE_API_KEY`）
- 一份 DevTools 效能追蹤（trace）
- 一個可存取的網址，加上在環境中設定好的 `chrome-devtools` MCP 伺服器（agent 可直接透過 `lighthouse_audit` 與 `performance_*` 工具擷取指標）
- 在本機執行 Chrome DevTools MCP CLI（透過 `npx -p chrome-devtools-mcp chrome-devtools <tool>`，或先 `npm i -g chrome-devtools-mcp`）—— 由使用者執行像 `chrome-devtools lighthouse_audit --output-format=json` 這樣的指令，再把 JSON 輸出交給 agent

**快速模式（Quick mode）** —— 以上皆無時的預設模式。agent 會掃描原始碼中結構性的效能反模式，並將每項發現標註為 `potential impact`（潛在影響）。

## 執行稽核

啟動 `web-performance-auditor` 子代理人。明確傳給它：

- 待審查的檔案、元件或 diff
- 任何佐證檔案的路徑（Lighthouse JSON、PSI JSON、CrUX 回應、trace），或直接貼上的 JSON 內容
- 已知的目標網址或頁面名稱
- 註明你預期採用哪個模式（快速或深度），這樣若原本想跑深度模式，agent 才能指出缺了哪些輸入

子代理人會回傳一份計分卡（只填入有來源佐證的數值）、一份依重要性排序的發現清單、正面的觀察，以及主動提出的建議。

## 輸出

把完整的稽核報告回傳給使用者。不需要綜整或合併步驟 —— 這是單一角色的指令。
