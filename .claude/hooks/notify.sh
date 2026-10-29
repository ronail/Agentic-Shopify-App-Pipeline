#!/usr/bin/env bash
# Notification hook — fires when the agent sends a notification.
# Portable: PowerShell toast on Windows, osascript on macOS, notify-send on
# Linux, and a plain line everywhere else. Never blocks, never fails the turn.

set +e

INPUT=""
if [ ! -t 0 ]; then
  INPUT=$(cat 2>/dev/null)
fi

MESSAGE=""
if [ -n "$INPUT" ] && command -v jq >/dev/null 2>&1; then
  MESSAGE=$(printf '%s' "$INPUT" | jq -r '.message // .tool_input.message // empty' 2>/dev/null)
fi
if [ -z "$MESSAGE" ] && [ -n "$INPUT" ]; then
  MESSAGE=$(printf '%s' "$INPUT" | grep -oE '"message"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 \
    | sed -E 's/^"message"[[:space:]]*:[[:space:]]*"//; s/"$//')
fi
[ -n "$MESSAGE" ] || MESSAGE="Agent needs your attention"

# Cap and strip characters that break the single-quoted OS strings.
MESSAGE_SAFE=$(printf '%s' "$MESSAGE" | tr -d '\r\n' | head -c 200)
TITLE="Agentic Shopify Pipeline"

if command -v powershell.exe >/dev/null 2>&1; then
  PS_MSG=$(printf '%s' "$MESSAGE_SAFE" | sed "s/'/''/g")
  powershell.exe -NonInteractive -WindowStyle Hidden -Command "
    Add-Type -AssemblyName System.Windows.Forms
    \$notify = New-Object System.Windows.Forms.NotifyIcon
    \$notify.Icon = [System.Drawing.SystemIcons]::Information
    \$notify.BalloonTipTitle = '$TITLE'
    \$notify.BalloonTipText = '$PS_MSG'
    \$notify.Visible = \$true
    \$notify.ShowBalloonTip(5000)
    Start-Sleep -Seconds 6
    \$notify.Dispose()
  " >/dev/null 2>&1 &
elif command -v osascript >/dev/null 2>&1; then
  OS_MSG=$(printf '%s' "$MESSAGE_SAFE" | sed 's/\\/\\\\/g; s/"/\\"/g')
  osascript -e "display notification \"$OS_MSG\" with title \"$TITLE\"" >/dev/null 2>&1
elif command -v notify-send >/dev/null 2>&1; then
  notify-send "$TITLE" "$MESSAGE_SAFE" >/dev/null 2>&1
fi

echo "Notification: $MESSAGE_SAFE"
exit 0
