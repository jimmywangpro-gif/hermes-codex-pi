#!/usr/bin/env bash
# install.sh — 將 hermes-codex-pi skill 安裝到目標平台
# 用法:
#   ./install.sh              安裝 skill（偵測 $HERMES_HOME 或 ~/.hermes）
#   ./install.sh --agents     同時複製 AGENT-HERMES.md / AGENT-CODEX.md / AGENT-PI.md 到目前目錄（專案母版）
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/SKILL.md"

# 解析 HERMES_HOME（支援多 profile 環境）
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
DEST_DIR="$HERMES_HOME/skills/autonomous-ai-agents/hermes-codex-pi"
DEST="$DEST_DIR/SKILL.md"

if [ ! -f "$SRC" ]; then
  echo "❌ 找不到 $SRC（請確認 install.sh 與 SKILL.md 同目錄）" >&2
  exit 1
fi

mkdir -p "$DEST_DIR"
cp "$SRC" "$DEST"
echo "✅ 已安裝: $DEST"
echo "   （重新開啟 Hermes session 後生效）"

# --agents：複製專案母版到目前目錄
if [ "${1:-}" = "--agents" ]; then
  TARGET="${2:-$(pwd)}"
  if [ ! -f "$SCRIPT_DIR/templates/AGENT-HERMES.md" ] || [ ! -f "$SCRIPT_DIR/templates/AGENT-CODEX.md" ] || [ ! -f "$SCRIPT_DIR/templates/AGENT-PI.md" ]; then
    echo "❌ 找不到 templates/AGENT-*.md（本 repo 需含 templates/）" >&2
    exit 1
  fi
  cp "$SCRIPT_DIR/templates/AGENT-HERMES.md" "$TARGET/AGENT-HERMES.md"
  cp "$SCRIPT_DIR/templates/AGENT-CODEX.md" "$TARGET/AGENT-CODEX.md"
  cp "$SCRIPT_DIR/templates/AGENT-PI.md" "$TARGET/AGENT-PI.md"
  echo "✅ 專案母版已建立: $TARGET/AGENT-HERMES.md, $TARGET/AGENT-CODEX.md, $TARGET/AGENT-PI.md"
  echo "   建議依專案修改（加 Docker/.NET/多 subagent 規範），不要直接改共享母版。"
fi
