# log-markdown-edits.ps1
# Hook 腳本：每當 Claude 寫入或修改 .md 檔案後，自動記一筆時間戳。
# 由 PostToolUse（Edit|Write）觸發，Claude 會把事件資訊以 JSON 從 stdin 傳入。

# 讀取 stdin 的 JSON
$raw = [Console]::In.ReadToEnd()
try {
    $data = $raw | ConvertFrom-Json
} catch {
    exit 0   # 解析失敗就安靜跳過，絕不擋住 Claude 的動作
}

$file = $data.tool_input.file_path

# 只記錄 Markdown 檔
if ($file -and $file -like '*.md') {
    $timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    $logPath   = Join-Path $env:CLAUDE_PROJECT_DIR '.claude\edit-log.txt'
    Add-Content -Path $logPath -Value "[$timestamp] Edited: $file"
}

exit 0   # 一律放行，此 hook 只負責記錄，不影響任何操作
