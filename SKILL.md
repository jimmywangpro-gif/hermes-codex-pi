---
name: hermes-codex-pi
description: Coding Hermes orchestrates Codex/pi codes Hermes verifies.
version: 1.0.0
author: Hermes
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [coding, codex, pi, orchestration, review, verification]
    related_skills: [codex, karpathy-coding-standards]
---

# Hermes 編排 + Codex/pi 寫碼 + Hermes 驗證 工作流

## When to Use

- 使用者說「任何 coding 項目由 Hermes orchestrated、交付 Codex/pi coding、完成後 Hermes review/test/驗證」
- 開始任何實作型 coding 任務，且 Codex 或 pi CLI 可用
- 需要將實作委派給執行者（Codex 預設；pi 為替代）並確保品質

## 用途

任何 coding 專案（新專案、功能、修 bug）的通用協同模式：

```
Hermes (編排) ──規劃/拆解/定義驗收──▶ coding sub-agent（Codex 預設 / pi 替代）
                                      │  完整實作（src + config + tests + docs）＋ 自我測試
                                      ▼
              codex review ◀──findings──▶ pi coding（迭代至共識，Hermes 裁判）
                                      ▼
Hermes (review/test/驗證 L1-L5) ◀──交付── 完成 → merge
```

- **Hermes**：編排（規劃、拆解任務、撰寫 sub-agent prompt、啟動、監控）＋裁判與最終驗證（findings 查證、品質閘門、L1-L5、合併、追蹤）。不寫 src（Model Capacity 接手除外）。
- **Codex CLI / pi（coding sub-agent）**：**實作工程師**，負責實際程式碼實作（src、config、測試、docs as scoped 完整交付），交付前必先自我測試；無法執行時標記 UNVERIFIED，不得宣稱通過。角色權威定義：母版 `AGENT-CODEX.md` §1 / `AGENT-PI.md`；prompt 要求見 Phase 2。
- **Review 迴圈角色**（Phase 4）：pi coding ↔ codex review（read-only）迭代至共識；Hermes 是裁判不是修理工。

本 skill 與母版 `AGENT-HERMES.md` / `AGENT-CODEX.md` / `AGENT-PI.md` 定義**一致**：執行者寫全部 code、交付前自我測試、Hermes 編排＋L1-L5 驗證。專案有母版時以母版為準。`codex` skill 的 multi-stream 分流模式（Hermes 寫 src、Codex 只寫 tests）是補測試／技術債的特例（`references/multi-stream-collaboration.md`），**不是**母版定義、也不是本 skill 模式。

## 前置準備

1. 確認執行者 CLI 可用：Codex `codex --version`；pi `pi --version`；gh 已認證（`gh auth status`）
2. 載入 `codex` skill（autonomous-ai-agents/codex）取得 Codex 啟動細節；pi 啟動細節見本 skill Phase 3.5
3. 確認專案 git 狀態乾淨（`git status`）
4. 確認 test 執行環境（venv / dotnet / 等）


## 工作流

### Phase 0 — 模型選擇 Gate ★強制（skill 觸發時）

**Skill 一經觸發，先詢問使用者本次執行者模型，不得自行預設。**

1. 以 `clarify` 詢問本次 Codex/pi 使用的模型，候選至少含：
   - Codex `gpt-5.6-luna` + `xhigh`（原預設建議）
   - Codex ollama 本機通道（如 `glm-5.2:cloud`）
   - pi + ollama（如 `glm-5.2:cloud` / `deepseek-v4-flash:0731-cloud`）
   - 其他（自由指定 provider / model / reasoning）
2. 使用者未明確選擇前，⛔ 不得撰寫執行者 prompt、不得 spawn 任何 agent。
3. 選擇結果記入 Phase 1.5 計劃呈現內容與 EOR 執行記錄（`docs/exec/<task-id>.md`）。

> 理由：模型與 reasoning 等級直接影響品質與成本，雲端模型 capacity 也變動頻繁；由使用者當場指定，避免 skill 記載的預設值漂移或過時。

### Phase 1 — Hermes 規劃（編排）

1. **理解需求** — 確認目標、範圍、驗收標準。有歧義先問，不要猜。
2. **拆解任務** — 切成可獨立交付的單元（每單元有明確產出與驗證方式）。
3. **定義驗收標準** — 具體、可測（回傳值、狀態變化、錯誤路徑、閾值、無洩漏）。
4. **準備 baseline** — 記錄目前測試通過數/品質閘門結果，作為回歸基準。

### Phase 1.5 — 計劃呈現 Gate ★強制

**計劃與執行必須不同回合：**

1. 拆解完成後，把計劃（任務清單、agent 分配、驗收、預估）**呈現給使用者確認**。
2. ⛔ **STOP** — 呈現計劃的回合不得同時 spawn 或寫 prompt。
3. 等使用者明確批准（「繼續」/ 👍 / 指定調整）後，才進入 Phase 2。

> 這與使用者「先不實作」的偏好一致：計劃是承諾，執行是之後的事，兩者不得混在同一回合。

### Phase 1.6 — 測試先行（TDD gate）★強制

**開始任何 coding 前，必須先完成測試碼。** 這是不可跳過的硬閘門。

1. **定義測試案例** — 根據 Phase 1 的驗收標準，寫出具體測試案例（涵蓋正常路徑、邊界、錯誤路徑）。
2. **確認 RED** — 測試碼必須先跑出 **FAIL（RED）**，證明測試有效、目標行為尚未實作。
3. **才開始實作** — Codex prompt 中包含已完成的測試碼作為規格，要求 Codex 實作至測試全綠（GREEN）。

> 測試碼可由 Hermes 撰寫，或由 Codex 在第一趟只寫測試（確認 RED）、第二趟才實作。不論誰寫，**測試碼必須先於實作碼存在且確認 RED**。

### Phase 2 — 撰寫 coding sub-agent 委派 Prompt（Codex 預設 / pi 替代）

**Prompt 的本質：對一個 coding sub-agent 的完整任務委派書**——sub-agent 收到後獨立實作、自我測試、交付，中途不與使用者對話。模型與 reasoning 依 **Phase 0 使用者選定**，不使用本 skill 範例中的模型值。

每個 coding sub-agent prompt 必須包含：
- **角色**：「你是 coding sub-agent（實作工程師），負責完整實作 <任務>；你不規劃專案、不決定驗收標準、不做最終驗證——這些由 Hermes 裁定」
- **範圍邊界**：明確說哪些檔案可改、哪些不可動
- **read-first**：先讀現有程式碼確認實際屬性/型別/命名，再動手
- **具體任務**：backlog item / 明確功能，非模糊目標
- **驗收標準**：具體斷言期望（回傳值、狀態、錯誤處理、閾值）
- **測試命令**：含絕對路徑的測試指令，讓執行者能自我驗證
- **SELF-TEST 交付前置**：「交付前必須先執行測試指令並確認通過；無法執行時標記 UNVERIFIED，不得宣稱通過」
- **commit 格式**：確保可追溯（pi 交付為檔案變更 + 回報，commit 可由 Hermes 執行）

> 若專案有 `AGENT-CODEX.md` 或 `AGENT-PI.md`，直接套用其 prompt 模板並填寫具體任務內容。

### Phase 3 — 啟動 Codex

```
terminal(background=true, pty=true, workdir=<專案路徑>, notify_on_complete=true)
```
- 用背景 + pty 啟動 Codex
- `notify_on_complete=true` 讓 Hermes 在 Codex 完成時收到通知
- 記錄 session_id

### Phase 3.5 — 啟動 pi（替代執行者）

當使用者指定或 Codex 不可用時，改用 pi（earendil-works pi-coding-agent）：

```
pi -p --provider ollama --model <model-id> --thinking xhigh \
   --session-dir /path/to/worktree/.pi-sessions \
   --append-system-prompt /path/to/AGENT-PI.md \
   "<prompt>"
```

- **非互動批次**：`-p` 處理 prompt 後即退出（已實測可用）
- **模型**：`--provider ollama`（本機）或 `openai-codex`（雲端 OAuth）；`--model` 明確指定
- **規範注入**：`--append-system-prompt AGENT-PI.md` 讓 pi 讀取協作協議
- **session 管理**：`--session-dir` 指向 worktree 專屬目錄，避免跨專案 session 污染；或 `--no-session` 一次性執行
- **交付要求**：與 Codex 相同 — SELF-TEST 前置、UNVERIFIED 標記、L1-L5 驗證流程不變

### Phase 4 — 驗證（Hermes review/test/驗證）★核心

Codex 交付後，**不得直接接受**。先確認 **Codex 已自我測試**：

- 交付是否回報自我測試指令 + 結果？
- Codex 若標記 UNVERIFIED（無法跑測試）→ Hermes 於 L3 代跑，不把 Codex 的「完成」當證明。

然後執行 **5 層驗證**（L1 品質閘門 → L2 範圍檢查 → L3 測試品質 → L4 語意符合 → L5 回歸）。

> **權威來源**：`codex` skill 的 `references/codex-deliverable-verification.md` — 含每層具體命令、退回迴圈規則、失敗模式對策表。本 skill 不重複；以下僅列出編排層獨有的注意事項。

**L4-E2E（真實環境驗證）— Node 單元測試的盲區補丁（2026-09-05 stock 實證）★**：

單元測試全綠 ≠ 真實環境正常。兩類缺陷 Node 測試結構性抓不到，前端/圖表類交付必須以真實瀏覽器 E2E（如 Chrome CDP headless）作為 L4 硬閘門：

1. **WebIDL receiver 陷阱**：全域 `setTimeout/clearTimeout` 抽進物件屬性未 bind → 瀏覽器丟 `TypeError: Illegal invocation`，Node 的 setTimeout 對 receiver 寬容故測不到。預防：DI fallback 建構處一律 `.bind(globalThis)`，禁止提升到 module 頂層 bind。
2. **圖表/第三方庫內部斷言**：如 lightweight-charts `setData` 要求 time 嚴格遞增唯一——tick 級時間戳映射到秒後同秒兩點即炸內部斷言（訊息如 `Value is null` 不直指原因）。預防：任何資料餵入 vendored 套件前，以最小樣本驗 API 契約；映射序列先去重（同秒 last-wins）。

E2E 最低標：Chrome `--headless=new --remote-debugging-port=<port>` + CDP 監聽 `Runtime.exceptionThrown` / `Log.entryAdded` / `Network.responseReceived`，斷言 console/runtime/network **零錯誤**＋核心互動（渲染、選取、切換主題、儲存）逐項 PASS。腳本模式存 stock 專案 /tmp/stock-cdp-e2e.mjs 可複用。

**Review 迭代迴圈（2026-09-05 老大指示）★**：

1. 執行者（pi/codex）交付後，**必須先送 codex review**（開獨立 tab，v2 輪起），Hermes 不得在 codex review 之前就自行驗證結案。
2. **coding（pi）與 review（codex）需不斷迭代直到達成共識**：codex findings → pi 修復 → codex 複審 → 重複，直到 codex 無新增 findings 且 **VERDICT: PASS**；Hermes 跑 L1-L5 全綠即共識成立。
3. **不設固定 review 輪數上限**：pi↔codex 持續修復／複審直到達成共識；不得因「已跑兩輪」就在仍有有效 finding 時結案。若雙方對同一 finding 產生無法以測試或原始碼證據消解的實質分歧，才把雙方證據呈交老大裁決。
4. Hermes 在迴圈中的職責：分派 findings 給 pi 修復（Hermes 只在 pi 失敗/卡死時接手）、代跑被 sandbox 擋住的測試、驗證 findings 是否屬實（防 codex 誤報——誤報時帶證據回 codex 對質而非盲目修）、最終 L1-L5 + E2E。
5. 踩坑記錄：v1 輪曾跳過 codex review 直接 Hermes 驗證結案（被老大指正）；v2 輪起此為硬閘門，且迭代主體是 pi↔codex，Hermes 是裁判不是修理工。
6. **一修一審 1:1**（2026-09-05 老大指正「為什麼沒 codex 驗證」）：每輪修復後立即送 codex 複審，不合併輪次。codex usage limit / capacity 中斷時切 ollama 通道補審（見 Model Capacity 節），**不**以「Hermes 已另行驗證」抵免 codex 複審；Hermes 的 L4-E2E 是獨立補強證據（codex read-only sandbox 跑不了瀏覽器/server），不取代靜態複審。

**編排層額外要求**：
- **TDD gate 回顧** — L3 時確認 Phase 1.5 的測試碼已被實作覆蓋為 GREEN，不是事後補寫的測試
- **退回迴圈**：L1-L4 任一 FAIL → 帶具體 gap list 退回 Codex 修 → 從 L1 重跑。L5 FAIL → Hermes 決定 revert 或修。

### Phase 5 — 合併 + 追蹤

1. 驗證全 PASS → merge / commit
2. 更新任務追蹤：狀態、測試數、品質閘門、agent 歸屬
3. 更新 baseline 追蹤表

## 並行 Sub-agent 模式（大 Step 拆解）

當一個 Step 太大（如前後端 + API 同時開發），拆成 2–4 個**各自完整實作**的 Codex sub-agent，每個跑在獨立 worktree：

```
main (clean baseline)
  ├── worktree A  ──  Codex 實作模組 A（src + tests）
  ├── worktree B  ──  Codex 實作模組 B（src + tests）
  └── worktree C  ──  Codex 實作模組 C（src + tests）
```

### 啟動流程

1. **拆解** — 依關注面切分（如後端 API / 前端看板 / 前端報表），每個 sub-agent 有獨立 src 範圍 + 驗收。
2. **建立 worktree** — `git worktree add -b feat/stepN-a /tmp/stepN-a main`，每個分支獨立。
3. **同步 src** — worktree 從 main 建立；若 main 有後續 commit，啟動前先 `git checkout main -- src/`。
4. **並行啟動 Codex** — 每個 worktree 一個 `terminal(background=true, pty=true, workdir=/tmp/stepN-x)`。
5. **不閒置** — Hermes 利用等待時間更新文件、確認下游依賴、清理分支、預備下一步。
6. **逐個驗證** — 每個 Codex 退出後跑 L1–L4，通過後依序合併。
7. **合併順序** — 先合併無共享檔案的分支；有共享檔案的分支最後合併，合併後立即檢查覆蓋。

### 啟動方式二選一：terminal 模式 / Herdr 模式

**A. terminal 模式（無 Herdr 環境時）** — 上列第 4 步用 `terminal(background=true, pty=true, workdir=<worktree>)`，定期 poll 輸出監控。

**B. Herdr 模式（預設拓撲：每個 sub-agent 開新 tab；使用者要求以 Herdr 框架啟動時）** — 套用 `herdr` skill（先 `skill_view('herdr')` 載入完整命令參考）。

前置硬閘門：

```bash
test "${HERDR_ENV:-}" = 1
```

- 通過 → Hermes 跑在 Herdr 管理的 pane 內，可用 herdr CLI 控制本 session，進入 Herdr 模式。
- 不通過 → ⛔ 不得用 herdr 控制命令；退回 terminal 模式，並告知使用者：要以 Herdr 啟動需把 Hermes 跑在 Herdr pane 內（如 `herdrclaude`）。

建立執行環境（**預設：每個 sub-agent 一個新 tab**；老大已明確指定此拓撲，覆寫 herdr skill 的 sibling-pane 預設）：

```bash
herdr tab create --workspace "$HERDR_WORKSPACE_ID" --cwd /tmp/stepN-a --label "stepN-a"
```

- 從 `.result.tab` 取 tab_id、`.result.root_pane` 取 root pane ID；每個 tab 全寬，輸出可讀性最佳，且不搶使用者焦點（預設 no-focus，要切過去看才 `--focus` 或 `herdr tab focus`）。
- 同 tab `pane split` 分屏改為**備選**：僅當老大要求「一眼同看多 agent 對照進度」或任務極短（分屏比切 tab 快）時使用；寬切 right、窄/高切 down，`--no-focus` 保留焦點。
- 新 tab 內若要跑多個 agent，再對 root pane `pane split`。

啟動執行者（兩種方式）：

1. **批次模式**（與 terminal 模式等價，輸出可監控）：

```bash
herdr pane run <pane-id> "codex exec --model <Phase 0 選定模型> -c 'model_reasoning_effort=\"xhigh\"' --sandbox danger-full-access --skip-git-repo-check \"<prompt>\""
herdr pane wait-output <pane-id> --match "tokens used" --timeout 600000
herdr pane read <pane-id> --source recent-unwrapped --lines 200
```

2. **原生 agent 模式**（Herdr 認得 Codex 生命週期 idle/working/blocked/done）：

```bash
herdr agent start stepN-a --kind codex --pane <pane-id>
herdr agent prompt stepN-a "<prompt>" --wait --timeout 120000
herdr agent get stepN-a
herdr agent read stepN-a --source recent-unwrapped --lines 200
```

- `agent start` 前 pane 必須是空 shell interactive prompt；先用 `herdr agent` 確認本機支援的 kind 清單。
- `blocked` = agent 卡在 approval/問題 UI → `agent read` 檢查後問使用者，勿代答。
- pi 執行者同理：批次用 `pane run "pi -p ..."`；pi 非 Herdr 原生 kind 時走批次模式。

Herdr 模式安全規則：一律 `--current` 或明確 pane ID / agent 名稱；不關閉非自己建立的 workspace/tab/pane；不跑 `herdr server stop`；不殺 Herdr 主程序。

### 共享檔案合併覆蓋防護 ★

多個 sub-agent 各自實作時，**共享檔案**（如 `Program.cs`、路由註冊、DI 設定）容易被後合併的分支覆蓋。

**預防：**
- Prompt 中明確標註共享檔案：「`Program.cs` 已有路由註冊，你的新增必須 **append**，不可覆蓋現有內容」
- 盡量讓 sub-agent 產出**獨立檔案**（新 Controller、新 Hub），減少對共享檔案的編輯

**合併後檢查（必做）：**
1. 合併每個分支後，`git diff main...HEAD -- <共享檔案>` 確認未覆蓋先前分支的內容
2. 若覆蓋發生 → 手動修正：把後合併分支的新增內容 append 回去，保留先合併分支的內容
3. 修正後跑 L5 回歸確認所有路由/端點仍正常
4. 記錄至 `docs/PITFALLS.md` 避免重複踩

### 與 multi-stream 分流模式的差異（codex skill 特例）

> 分流模式（Hermes 寫 src、Codex 只寫 tests）定義於 `codex` skill `references/multi-stream-collaboration.md`，是補測試／技術債的特例——**不是**母版 `AGENT-CODEX.md` 的定義（母版＝Codex 寫全部 code，見「用途」節）。兩者對比：

| | 分流模式（multi-stream，特例） | 並行 sub-agent 模式（本 skill） |
|---|---|---|
| Codex 職責 | 只寫 tests | 完整實作（src + tests） |
| Hermes 職責 | 同時寫 src | 不寫 src，專注編排 + 驗證 |
| 共享檔案風險 | 低（src 由 Hermes 控制） | **高**，需合併覆蓋防護 |
| 適用場景 | 補測試、技術債 | 大 Step 多模組並行開發 |

## 多 Agent 任務分配原則 ★

> 使用者確認的協同架構：**Hermes 架構分派 → 多平行 Codex sub-agent（各自獨立 worktree）→ Codex 負責 coding + 交付前自我測試驗證 → 交付回 Hermes 做最終測試驗證。任務交付前 / coding 前，必須先將測試驗證程式做好。**

### 兩條硬規則（強制，不可跳過）

1. **測試先行（TDD gate）** — 任何 coding 前，先完成測試驗證程式並確認 **RED**，才允許實作至 **GREEN**。Codex 不得先寫實作再補測試。
2. **交付前自我測試** — Codex 交付前必須自己跑測試並確認通過；無法執行時標記 **UNVERIFIED**，不得宣稱完成。Hermes 收到後仍做最終 L1–L5 驗證，不把 Codex 的「完成」當證明。

### 分配原則

1. **依「責任邊界」拆，不依檔案數量硬拆** — 每個 agent 有明確功能目標、獨立可改目錄/檔案、各自驗收與測試、不與他人同時改共享檔案。
2. **同一檔案只能有一個 agent 擁有寫入權** — 尤其 `Program.cs`、`.sln`、DI 註冊、migration、共享 API contract。共享檔案指定唯一 owner，或由最後的整合任務（Integrator）統一處理。
3. **測試必須早於實作** — 每個 stream 先產生 RED，再做 GREEN；不是所有 agent 做完後才補測試。
4. **合併不是驗收** — 每條分支先經 Hermes L1–L4；全部合併後再跑 L5，並檢查共享檔沒有覆蓋。

### 常見切分模式

**模式 A：後端 + 前端 + 整合（最常用）**

| Stream | Codex 職責 | 可改範圍 | 禁止碰觸 |
|---|---|---|---|
| A — Domain/Application | Entity、DTO、Service、商業規則、xUnit | `src/EEMS.Domain/`、`src/EEMS.Application/`、對應測試 | API、前端、`Program.cs` |
| B — API/Infrastructure | Controller、Repository、DbContext、SignalR Hub、整合測試 | `src/EEMS.Api/Controllers/`、指定 Infrastructure 檔、測試 | 前端、未授權共享註冊檔 |
| C — Frontend | Page、Component、API client、圖表/表格 UI | 前端專案目錄 | .NET API、DB migration |
| D — Integrator | DI、路由、`Program.cs`、solution/migration 必要整合 | 明確指定的共享檔案 | 不重寫 A/B/C 已完成的模組 |

> **D 必須最後執行或最後合併**，避免 `Program.cs`、路由註冊被覆蓋。

**模式 B：純後端大型功能**（依賴順序 A → B → C → D；A 已合併時 B/C 可平行）

| Stream | 任務 |
|---|---|
| A | Domain：實體、Enum、值物件、規則單元測試 |
| B | Application：計算服務、DTO、Use Case、單元測試 |
| C | Infrastructure/API：儲存、Controller、授權與整合測試 |
| D | Integrator：DI 註冊、EF migration、端對端回歸 |

> 若 A 尚未合併，B/C 不應猜測 A 的型別與介面；需等 A 的 contract 確定後再平行。

### 每個 sub-agent 任務單必備欄位

```md
### Stream A — <名稱>

**目標** — 實作 <明確行為>。

**允許修改** — <檔案/目錄清單>

**禁止修改** — `Program.cs`、`EEMS.sln`、其他 stream 範圍、Docker、migration（除非明確授權）

**測試先行** — 1) 先新增 xUnit 測試 2) 先執行確認 RED 3) 再實作直到 GREEN

**驗收條件** — <正常情況> / <邊界條件> / <錯誤處理> / <授權與資料一致性>

**Self-test**
dotnet build /path/to/EEMS/EEMS.sln
dotnet test  /path/to/EEMS/EEMS.sln

**交付** — 自我測試通過後才 commit；回報修改檔案、測試結果與未驗證項目。
```

## Agent 生命週期監控（執行中管理）★

Codex spawn 執行期間，Hermes 不得只等 notify_on_complete——要主動監控：

1. **卡死偵測** — Codex 執行中，定期 poll 其輸出（建議每 10–15 分鐘）。若超過閾值（如 20 分鐘）無任何新輸出，判定卡死（網路掛起、等待輸入、程序僵死），直接 kill，再走 Model Capacity 的接手流程（先檢查已產出 → commit → 接手或重試）。
2. **完成自動化** — Codex 退出後立即自動收集：`git status --short`、測試執行摘要、最後產出的檔案清單，作為 L1–L5 驗證的前置資料，不重複收集。
3. **全員完成整合檢查** — 並行 sub-agent 全部退出後，先確認每個 worktree 的完成狀態（有無未 commit 產出、是否標記 UNVERIFIED），確認沒有任何 agent 仍在執行，才開始依序合併。
4. **執行記錄落盤（EOR/ESR）** — 每個 Codex 任務結束後寫入執行記錄檔（如 `docs/exec/<task-id>.md`），固定欄位：任務 ID、修改檔案清單、自我測試指令與結果、UNVERIFIED 項目、capacity/卡死事件、接手人與處理方式。跨 session 可追溯事實；PITFALLS.md 只記教訓，EOR 記事實。

**Herdr 模式下的監控**：poll 來源改用 `pane read`（批次模式）或 `agent get` 的生命週期狀態（原生 agent 模式）——`idle`/`done` 是完成信號，`blocked` 是卡在審批的信號，`unknown` 不代表完成；卡死閾值同上，卡住時可用 `herdr agent send-keys <name> ctrl+c` 中斷後走 capacity 接手流程。

## Model Capacity 處理

`gpt-5.6-luna` 等模型可能因 **capacity 不足** exit 1，但已產出部分檔案。這與 token 耗盡不同：

| | Token 耗盡 | Capacity 不足 |
|---|---|---|
| Exit code | 0（正常退出） | **1**（錯誤退出） |
| 日誌特徵 | "tokens used ~113k" | "capacity" / "rate limit" / "暫時不可用" |
| 檔案狀態 | 已寫但未 commit | **可能已寫也可能未寫** |
| 處理方式 | Hermes 代跑測試 + commit | 先檢查已產出 → 決定接手或重試 |

### 接手流程

1. **檢查已產出** — `git status --short` 在 worktree 確認有無新檔案
2. **若有產出** — Hermes 手動 commit 已產出檔案（`git add -A && git commit -m "feat: partial <task> (Codex capacity exit)"`），然後接手完成剩餘實作 + 測試
3. **若無產出** — 重試 Codex（capacity 不足通常是暫時的）：`codex exec --model gpt-5.6-luna -c 'model_reasoning_effort="xhigh"' --sandbox danger-full-access --skip-git-repo-check "<prompt>"`
4. **重試上限** — 同一目的最多重試 **一次**；二次仍 capacity exit → Hermes 完全接手實作，不反覆重試
5. **Fallback 模型鏈** — 依序嘗試：`gpt-5.6-luna` → 次選模型（如 `glm-5.2:cloud`，視可用性）→ Hermes 完全接手。每階嘗試前先檢查已產出並 commit，避免重複工作
6. **記錄** — 在 session 記錄中標注 capacity exit 事件，供下次評估是否換模型

### Codex CLI 命令格式（指定 model + reasoning）

```
codex exec --model gpt-5.6-luna -c 'model_reasoning_effort="xhigh"' --sandbox danger-full-access --skip-git-repo-check "<prompt>"
```

- `gpt-5.6-luna` + `xhigh` reasoning 是指定配置，不依賴本機預設值
- `--skip-git-repo-check` 在 worktree 可能需要（視 Codex 版本）
- capacity exit 時重試同一命令即可

**Ollama 模式（本機通道，已實測可用）**：

```
# 慣用（2026-09-05 stock 實測，review 場景）：
codex exec --model deepseek-v4-flash:0731-cloud -c 'model_reasoning_effort="max"' -c 'model_provider="ollama"' --sandbox read-only "<prompt>"
# 舊法（亦可用）：
codex exec --oss --local-provider ollama --model glm-5.2:cloud --skip-git-repo-check "<prompt>"
```

- **reasoning 值陷阱**：ollama API 只收 `max/high/medium/low/none`，`xhigh` 會在長任務尾端炸 `invalid reasoning value` + Reconnecting 5 次 exit 1——ollama 通道一律用 `model_reasoning_effort="max"`，且以 `-c` 覆寫不依賴 ~/.codex/config.toml 預設
- **`model_provider="ollama"` 需在 ~/.codex/config.toml 有對應 `[model_providers.ollama]` 區段**（base_url 指向 ollama /v1）；若無，用舊法 `--oss --local-provider ollama`
- exit 1 斷在回報階段時程式碼常已寫畢——先 `git status` 盤點再決定接手

- codex 0.148.0 不支援 `--provider` 參數，必須用 `--oss --local-provider ollama`
- 設定檔 `~/.codex/ollama-launch.config.toml`：定義 provider `ollama-launch`（`wire_api = "responses"`，ollama 已支援 responses API，實測回 `status: completed`）；檔內 `model` 預設值會隨使用調整（2026-09 現況為 `deepseek-v4-flash:0731-cloud`），故命令一律明確指定 `--model`，不可依賴設定檔預設
- 已知非致命警告（不影響執行，但每次啟動會刷出）：
  - `failed to refresh available models: missing field 'models'` — codex 期待 `/v1/models` 回 `{"models":[...]}`，ollama 回 OpenAI 格式 `{"object":"list","data":[...]}`
  - `Model metadata for glm-5.2:cloud not found. Defaulting to fallback metadata` — 效能可能略降
- 適用場景：雲端 `gpt-5.6-luna` capacity 不足時的 fallback 鏈次選（與 pi ollama 通道共用同一本機 ollama）
- **完整工具鏈已實測（2026-08-22）**：寫檔 + 執行測試 + 回報正常，Hermes 獨立核對檔案內容與測試結果一致
- ⚠️ **approval 坑**：`approval_policy = "on-request"` 下，codex 執行 shell 命令（寫檔、跑測試）會觸發 approval 請求；非互動批次（`codex exec`）中該請求會卡住直到 timeout。實測解法：Hermes 以 `terminal` 啟動時由使用者批准，或改用 `--sandbox danger-full-access`（skill 雲端模式已在用）避免逐次批准

### pi CLI 命令格式（指定 provider + model + thinking）

```
pi -p --provider ollama --model deepseek-v4-flash:0731-cloud --thinking xhigh \
   --session-dir <worktree>/.pi-sessions \
   --append-system-prompt <project>/AGENT-PI.md "<prompt>"
```

- 本機通道：`--provider ollama`（`http://127.0.0.1:11434/v1`，與 Hermes 共用）
- 雲端通道：`--provider openai-codex`（OAuth，`pi auth check --provider openai-codex` 驗證）
- 認證過期（OAuth 約 10 天）→ 重新授權，不重試硬撞
- 優先使用 `--thinking xhigh`（對應 Codex 的 extra high 等級）
- `--append-system-prompt AGENT-PI.md` 為強制：把 pi 協作協議注入 system prompt

**pi + glm-5.2:cloud 已實測可用（2026-08-22）**：完整工具鏈（寫檔 → 執行測試 → 回報）正常，`pi auth check --provider ollama` → ready。`~/.pi/agent/models.json` 已註冊 `glm-5.2:cloud`（contextWindow 1000000、reasoning: true）。注意 `settings.json` 的 `defaultModel` 是 `deepseek-v4-flash:0731-cloud`，協同流程必須明確指定 `--model glm-5.2:cloud`，不可依賴預設。

## Pitfalls

> 通用 Codex 陷阱（worktree venv、token 耗盡、假 PASS、sandbox 選擇、property name 對齊等）見 `codex` skill 的 Pitfalls 與 `references/multi-stream-collaboration.md` 失敗模式對策表。以下僅列出**編排層獨有**項目。

- **跳過 TDD gate** — 未先確認 RED 就開始實作，測試形同事後補寫，無法證明目標行為曾被正確觸發。
- **測試事後補寫** — L3 時發現測試是實作完成後才寫的 → 退回，要求重跑 TDD gate（先 RED 再 GREEN）。
- **capacity 不足** — exit 1 但可能已產出部分檔案；先檢查再決定接手或重試，同一目的最多重試一次。
- **共享檔案覆蓋** — 並行 sub-agent 合併時，後合併分支可能覆蓋先合併分支的共享檔案內容；合併後必檢查。
- **失敗斷路器** — 同一目的最多重試一次替代方法；二次仍失敗 → Hermes 完全接手，不反覆重試。
- **HERDR_ENV 未設卻跑 herdr 控制命令** — Hermes 不在 Herdr pane 內時，herdr CLI 無法控制 session（甚至污染使用者自己的 session）；Herdr 模式前必先 `test "${HERDR_ENV:-}" = 1`，不通過退回 terminal 模式。
- **pane 與 agent 混用** — pane 是原始終端、agent 是 Herdr 認得生命週期的 coding agent；需要 blocked/idle/done 偵測就用 `agent start` + `agent prompt`，否則用 `pane run` 批次；`agent start` 不會自己建 pane。
- **卡死未偵測** — Codex 掛住不退出（無新輸出）時若只等 notify_on_complete，會空等數小時；必須定期 poll 輸出並設定卡死閾值。
- **計劃與執行同回合** — 呈現計劃的同時 spawn/write prompt，使用者來不及批准；計劃呈現與執行必須不同回合。
- **未問模型即啟動** — 跳過 Phase 0 模型選擇 Gate，依 skill 記載的預設模型直接 spawn；每次 skill 觸發都必須先以 clarify 詢問使用者本次執行者模型與 reasoning。
- **缺執行記錄** — 任務結束未落盤 EOR，事後無法追溯「誰做了什麼、測了什麼」；每個 Codex 任務結束必寫 `docs/exec/<task-id>.md`。
- **跳過 codex review 直接結案** — 執行者交付後 Hermes 自行驗證就結案，繞過 codex review（2026-09-05 老大指正）；正確流程＝交付→codex review→修復迭代→共識（codex PASS + Hermes L1-L5 綠）才結案，見 Phase 4 Review 迭代迴圈。
- **修復輪與 review 輪合併** — 兩輪修復才送一次 review（2026-09-05 老大指正「為什麼沒 codex 驗證」）；每輪修復後**立即**送 codex 複審，一修一審 1:1，不合併輪次。
- **執行者空轉/pane 不執行** — herdr pane run 後程序未起（pgrep 無進程）或 pi 翻找自己 session 檔零修改；偵測＝5 秒內 pgrep 驗證程序已起＋預期產出檔案 mtime/測試數變化；作廢改開新 tab 重派，同目的不重試第二次（斷路器）。
- **採信執行者自述** — pi/codex 回報的測試數/RED 證據必須以 Hermes 獨立重跑核對，不採信自述（尤其 node --test 計數與 git diff 僅追加）。
- **審查報告被 pane 截斷就猜內容** — codex 長報告用 session 檔（~/.codex/sessions/<date>/rollout-*.jsonl，stat -mmin 找最新，Python parse response_item/message）取全文，pane read 只用來判 RUNNING/DONE。
- **長 prompt 直接寫在 herdr pane run 參數** — 引號/跳脫易錯；prompt 檔案化到 docs/prompts/*.md，pane run 只下「Read docs/prompts/X.md and execute it fully」短句。

## 驗證命令範例

```bash
# Python
python -m py_compile <files>
PYTHONPATH=<repo>/src <repo>/.venv/bin/python -m pytest -q

# .NET
dotnet build <Solution.sln>
dotnet test <Solution.sln>

# TypeScript
tsc --noEmit
npm test
```
