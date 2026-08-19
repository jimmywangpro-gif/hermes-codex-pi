# hermes-codex-orchestration

**Coding Hermes orchestrates, Codex codes, Hermes verifies.**

一個可移植的 [Hermes Agent](https://hermes-agent.nousresearch.com) skill，定義「Hermes 編排 + Codex 寫碼 + Hermes 驗證」的完整協同工作流：規劃拆解、測試先行（TDD gate）、Codex prompt 撰寫、5 層驗證（L1–L5）、並行 sub-agent、合併追蹤。

## 內容

| 章節 | 說明 |
|---|---|
| Phase 1 — 規劃 | 理解需求、拆解任務、定義驗收、準備 baseline |
| Phase 1.5 — 計劃呈現 Gate | 計劃與執行必須不同回合，等使用者明確批准 |
| Phase 1.6 — 測試先行（TDD gate） | 任何 coding 前先完成測試碼並確認 RED |
| Phase 2 — Codex Prompt | 角色、範圍邊界、read-first、自我測試前置 |
| Phase 3 — 啟動 Codex | 背景 + PTY + notify_on_complete |
| Phase 4 — 驗證 | 5 層驗證（L1 品質 / L2 範圍 / L3 測試 / L4 語意 / L5 回歸） |
| Phase 5 — 合併 + 追蹤 | 驗證全 PASS 才合併，更新 baseline |
| 並行 Sub-agent 模式 | 大 Step 拆 2–4 個 worktree、共享檔案合併覆蓋防護 |
| 多 Agent 任務分配原則 | 依責任邊界拆、單檔單一 owner、測試早於實作 |
| Agent 生命週期監控 | 卡死偵測、完成自動收集、全員整合檢查、EOR/ESR 記錄 |
| Model Capacity 處理 | gpt-5.6-luna exit 1 接手流程、Fallback 模型鏈、重試上限 |

## 安裝（移植到其他平台）

### 方式 A — 手動複製（最通用）

```bash
# Linux / macOS / WSL
mkdir -p ~/.hermes/skills/autonomous-ai-agents/hermes-codex-orchestration
cp SKILL.md ~/.hermes/skills/autonomous-ai-agents/hermes-codex-orchestration/SKILL.md

# 若 HERMES_HOME 有覆寫（多 profile 環境）
# mkdir -p "$HERMES_HOME/skills/autonomous-ai-agents/hermes-codex-orchestration"
# cp SKILL.md "$HERMES_HOME/skills/autonomous-ai-agents/hermes-codex-orchestration/SKILL.md"
```

### 方式 B：使用 install.sh

```bash
./install.sh
```

install.sh 會自動偵測 `$HERMES_HOME`（未設定則用 `~/.hermes`），建立 `autonomous-ai-agents/hermes-codex-orchestration/` 並複製 SKILL.md。

### 方式 C：匯入本 repo 為 skill source（ClawHub 風格）

若你的 Hermes 支援從 GitHub 安裝 skill：

```bash
hermes skills install https://raw.githubusercontent.com/jimmywangpro-gif/hermes-codex-orchestration/main/SKILL.md --name hermes-codex-orchestration --yes
```

> 安裝後需**新開 session** 才會載入（skill loader 於 session 啟動時初始化）。

## 前置需求

- [Hermes Agent](https://hermes-agent.nousresearch.com)（安裝於目標平台）
- Codex CLI 可用：`codex --version`
- GitHub CLI 已認證：`gh auth status`（用於 repo 操作）
- git 工作目錄乾淨（`git status`）
- 測試環境（venv / dotnet / 等）

## 使用方式

在 Hermes session 中，執行任何 coding 專案（新專案、功能、修 bug）時，工作流會自動載入本 skill。核心循環：

```
Hermes (編排) ──規劃/拆解/定義驗收──▶ Codex (寫碼)
                                      │  完整實作 + 交付前自我測試
                                      ▼
Hermes (L1-L5 驗證) ◀──交付── 完成
```

## 授權

MIT License — 詳見 [LICENSE](LICENSE)。
