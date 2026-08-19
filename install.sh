#!/usr/bin/env bash
# install.sh — 將 hermes-codex-orchestration skill 安裝到目標平台
# 用法: ./install.sh   (偵測 $HERMES_HOME 或 ~/.hermes)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/SKILL.md"

# 解析 HERMES_HOME（支援多 profile 環境）
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
DEST_DIR="$HERMES_HOME/skills/autonomous-ai-agents/hermes-codex-orchestration"
DEST="$DEST_DIR/SKILL.md"

if [ ! -f "$SRC" ]; then
  echo "❌ 找不到 $SRC（請確認 install.sh 與 SKILL.md 同目錄）" >&2
  exit 1
fi

mkdir -p "$DEST_DIR"
cp "$SRC" "$DEST"
echo "✅ 已安裝: $DEST"
echo "   （重新開啟 Hermes session 後生效）"
