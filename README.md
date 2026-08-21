# hermes-codex-pi

**Coding Hermes orchestrates, Codex/pi codes, Hermes verifies.**

一個可移植的 [Hermes Agent](https://hermes-agent.nousresearch.com) skill，定義「Hermes 編排 + Codex/pi 寫碼 + Hermes 驗證」的完整協同工作流：規劃拆解、測試先行（TDD gate）、agent prompt 撰寫、5 層驗證（L1–L5）、並行 sub-agent、合併追蹤。

## 內容

| 章節 | 說明 |
|---|---|
| Phase 1 — 規劃 | 理解需求、拆解任務、定義驗收、準備 baseline |
| Phase 1.5 — 計劃呈現 Gate | 計劃與執行必須不同回合，等使用者明確批准 |
| Phase 1.6 — 測試先行（TDD gate） | 任何 coding 前先完成測試碼並確認 RED |
| Phase 2 — Agent Prompt | 角色、範圍邊界、read-first、自我測試前置 |
| Phase 3 — 啟動 Codex | 背景 + PTY + notify_on_complete |
| Phase 3.5 — 啟動 pi | pi CLI 非互動批次、provider/model/thinking 指定 |
| Phase 4 — 驗證 | 5 層驗證（L1 品質 / L2 範圍 / L3 測試 / L4 語意 / L5 回歸） |
| Phase 5 — 合併 + 追蹤 | 驗證全 PASS 才合併，更新 baseline |
| 並行 Sub-agent 模式 | 大 Step 拆 2–4 個 worktree、共享檔案合併覆蓋防護 |
| 多 Agent 任務分配原則 | 依責任邊界拆、單檔單一 owner、測試早於實作 |
| Agent 生命週期監控 | 卡死偵測、完成自動收集、全員整合檢查、EOR/ESR 記錄 |
| Model Capacity 處理 | gpt-5.6-luna exit 1 接手流程、Fallback 模型鏈、重試上限 |

## 支援的執行 Agent

| Agent | 啟動方式 | 通道 | 協議文件 |
|---|---|---|---|
| Codex CLI | `codex exec ...`（背景 + PTY） | OpenAI（gpt-5.6-luna + xhigh） | `templates/AGENT-CODEX.md` |
| pi (pi-coding-agent) | `pi -p ...`（非互動批次） | ollama 本機 / openai-codex OAuth | `templates/AGENT-PI.md` |

兩者共用同一套協作規則：TDD gate、SELF-TEST 交付前置、UNVERIFIED 標記、L1–L5 驗證、退回迴圈。

## 安裝（移植到其他平台）

### 方式 A — 手動複製（最通用）

```bash
# Linux / macOS / WSL
mkdir -p ~/.hermes/skills/autonomous-ai-agents/hermes-codex-pi
cp SKILL.md ~/.hermes/skills/autonomous-ai-agents/hermes-codex-pi/SKILL.md

# 若 HERMES_HOME 有覆寫（多 profile 環境）
# mkdir -p "$HERMES_HOME/skills/autonomous-ai-agents/hermes-codex-pi"
# cp SKILL.md "$HERMES_HOME/skills/autonomous-ai-agents/hermes-codex-pi/SKILL.md"
```

### 方式 B：使用 install.sh

```bash
./install.sh
```

install.sh 會自動偵測 `$HERMES_HOME`（未設定則用 `~/.hermes`），建立 `autonomous-ai-agents/hermes-codex-pi/` 並複製 SKILL.md。

### 方式 C：匯入本 repo 為 skill source（ClawHub 風格）

```bash
hermes skills install https://raw.githubusercontent.com/jimmywangpro-gif/hermes-codex-pi/main/SKILL.md --name hermes-codex-pi --yes
```

> 安裝後需**新開 session** 才會載入（skill loader 於 session 啟動時初始化）。

## 專案母版（AGENT-HERMES.md / AGENT-CODEX.md / AGENT-PI.md）

本 repo 的 `templates/` 內附**協作協議母版**，用於在目標平台的專案內建立協作規範：

| 檔案 | 對象 | 內容 |
|---|---|---|
| `templates/AGENT-HERMES.md` | Hermes | 角色分工、13 步執行流程、5 層驗證（L1–L5）、no-idle、清理 worktree |
| `templates/AGENT-CODEX.md` | Codex CLI | 8 條絕對規則（範圍邊界、read-first、TDD gate、SELF-TEST 交付前置、commit 格式） |
| `templates/AGENT-PI.md` | pi CLI | 8 條絕對規則、呼叫格式（provider/model/thinking）、session 管理、交付報告 |

**SKILL.md 與母版的關係：**
- `SKILL.md` — 操作手冊，Hermes 讀：什麼時候做什麼、怎麼驗證、怎麼處理 failure。
- `AGENT-*.md` — 專案規範，Hermes 與執行者（Codex/pi）都讀（Codex 透過 prompt 或專案根目錄的 `AGENT-CODEX.md`；pi 透過 `--append-system-prompt AGENT-PI.md`）。

### 使用方式（在目標專案建立母版）

```bash
# 在目標專案根目錄執行（以 repo 內 templates/ 為來源）
cp templates/AGENT-HERMES.md .
cp templates/AGENT-CODEX.md .
cp templates/AGENT-PI.md .

# 或：在專案根目錄執行 install.sh --agents
/path/to/hermes-codex-pi/install.sh --agents
```

> **重要**：`templates/` 是**母版**。建議每個專案複製後**依專案修改**（如加 Docker/.NET 規範、多 subagent 規範），不要直接改共享母版——每個專案的 `AGENT-*.md` 是專案專屬版本。

> 若目標平台已有專案 symlink 指向共享母版，沿用該專案既有方式即可，不必重複建立。

## 前置需求

- [Hermes Agent](https://hermes-agent.nousresearch.com)（安裝於目標平台）
- Codex CLI 可用：`codex --version`
- pi CLI 可用：`pi --version`（`@earendil-works/pi-coding-agent`，npm 全域安裝）
- GitHub CLI 已認證：`gh auth status`（用於 repo 操作）
- git 工作目錄乾淨（`git status`）
- 測試環境（venv / dotnet / 等）

## 使用方式

在 Hermes session 中，執行任何 coding 專案（新專案、功能、修 bug）時，工作流會自動載入本 skill。核心循環：

```
Hermes (編排) ──規劃/拆解/定義驗收──▶ Codex / pi (寫碼)
                                      │  完整實作 + 交付前自我測試
                                      ▼
Hermes (L1-L5 驗證) ◀──交付── 完成
```

## 授權

MIT License — 詳見 [LICENSE](LICENSE)。
