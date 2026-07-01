# log-markdown-edits.ps1
# Hook script: append a timestamp whenever Claude writes/edits a .md file.
# Triggered by PostToolUse (Edit|Write). Claude passes the event as JSON on stdin.
#
# NOTE: comments are ASCII-only on purpose. A .ps1 saved as UTF-8 without BOM
# is misread by Windows PowerShell 5.1 (Big5/ANSI codepage) if it contains
# non-ASCII characters, which breaks the script. Keep this file ASCII-safe.

# Read the JSON payload from stdin
$raw = [Console]::In.ReadToEnd()
try {
    $data = $raw | ConvertFrom-Json
} catch {
    exit 0   # parse failed: stay silent, never block Claude's action
}

$file = $data.tool_input.file_path

# Only log Markdown files
if ($file -and $file -like '*.md') {
    $timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    $logPath   = Join-Path $env:CLAUDE_PROJECT_DIR '.claude\edit-log.txt'
    Add-Content -Path $logPath -Value "[$timestamp] Edited: $file"
}

exit 0   # logging only: always allow, never affect the operation
