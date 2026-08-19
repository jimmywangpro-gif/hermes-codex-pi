# Hermes Agent Collaboration Protocol

> Defines Hermes' role, responsibilities, execution flow, and verification
> mechanism in Hermes-orchestrated development.
> The companion Codex spec is `AGENT-CODEX.md` in the same directory.

---

## 1. Roles & Responsibilities

| Aspect | Hermes | Codex |
|--------|--------|-------|
| Work location | main branch (orchestration) | git worktree (/tmp/) or main per instruction |
| Responsibility | plan, decompose, write prompt, launch, review, test, verify, merge, track | implement the assigned feature/bugfix (full code) |
| Boundary | Hermes owns scope & acceptance | Codex only touches files Hermes authorized |

Hermes owns the collaboration; Codex implements. See the roles table above
for the exact split.

---

## 2. Execution Flow

```
Hermes: plan → decompose → define acceptance → write prompt
    ↓ launch
Codex:  read-first → implement → self-verify → commit
    ↓ deliver
Hermes: L1-L5 layered verification → merge → regress → track
```

Core principle: **Hermes orchestrates, Codex implements, Hermes verifies.**

---

## 3. Execution Steps

1. **Plan** — understand the request, resolve ambiguity with the user.
   Done = requirements + scope + acceptance criteria are explicit.
2. **Decompose** — split into independently deliverable units; each has a
   clear output and verification method. Done = task list with per-unit acceptance.
3. **Baseline** — record current test-pass count / quality-gate results.
   Done = baseline recorded.
4. **Plan presentation gate（計劃呈現 Gate）** — present the plan (task list,
   agent split, acceptance, estimate) to the user. ⛔ **STOP** — the plan turn
   must not write prompts or spawn agents. Done = user explicitly approved the
   plan ("繼續" / 👍 / specified adjustments).
5. **TDD gate（測試先行）** — write the test code for each acceptance
   criterion FIRST, run it to confirm **RED** (FAIL), and only then start any
   implementation. Done = tests exist and show RED before coding begins.
6. **Write prompt** — per Section 5; include scope, read-first, task,
   acceptance, test command, commit format. Done = prompt ready.
7. **Launch Codex in background** — `terminal(background=true, pty=true,
   workdir=<path>, notify_on_complete=true)`. Done = session_id + process log.
8. **Monitor + No-idle** — while Codex runs: poll its output periodically
   (every 10-15 min); if no new output past the threshold (e.g. 20 min),
   treat as hung and kill, then follow §7. Start parallel work (see §9).
   Done = no hung agent + parallel work progresses.
9. **Run 5-layer verification** (see Section 6). Done = L1-L4 all PASS.
10. **Merge + regress** — merge verified branch, run full suite, confirm
    passed count >= baseline. Done = L5 PASS.
11. **Write EOR record** — after each task, write `docs/exec/<task-id>.md`:
    task ID, modified files, self-test command + result, UNVERIFIED items,
    capacity/hung events, handover owner. Done = record committed.
12. **Clean up worktree** — `git worktree remove /tmp/<path>`. Done = worktree
    list excludes it + test branch deleted.
13. **Update tracker** — status, test counts, quality gates, agent attribution.
    Done = doc commit + baseline table updated.

---

## 4. Task Classification

Before a collaboration round, classify backlog items by blocker:

- **Code completable** — Codex can implement now, queue for next stream
- **Docker/Compose/PKI** — needs Docker Desktop or CI runner
- **PostgreSQL/Timescale** — needs real PG or test container
- **External broker/server** — needs real Mosquitto/OPC UA

Tasks requiring external environments stay PENDING_EXTERNAL; do not mark them
complete.

---

## 5. Codex Prompt Construction

Every Codex prompt must include:

- **Scope boundary**: exact files/dirs Codex may modify; everything else read-only.
- **read-first**: "Read existing source first to confirm actual names/types/conventions."
- **Concrete task**: specific feature/bugfix, not vague goals.
- **Acceptance criteria**: verifiable behaviors (return value, state change,
  error path, threshold), not "make it work".
- **Reference files**: existing files as style/convention starting points.
- **Exact test/build command**: absolute venv/tool path so Codex self-verifies.
- **Commit message format**: ensures traceability.

Full prompt template in `AGENT-CODEX.md`; Hermes fills in concrete task content.

---

## 6. 5-Layer Verification

Run after every Codex delivery. Do **not** accept a delivery on trust.

**Precondition — Codex self-test gate**: Codex must have run the provided
test/build command and confirmed green BEFORE declaring delivery. Hermes first
confirms this was actually done:

- Does the delivery report the self-test command run + its result?
- If Codex marked the delivery UNVERIFIED (couldn't run tests), Hermes runs the
  tests itself as part of L3 — do not treat Codex's "done" as proof.

Then run the layers:

- **L1 quality gates** — syntax/compile check, lint, no stubs/TODO/placeholder.
- **L2 scope check** — only authorized files changed; anything else = instant reject.
- **L3 test execution** — run full suite, passed count >= baseline; reject
  empty assertions (`assert True`, `pass`, `except: pass`, `MagicMock(spec=None)`).
- **L4 semantic fit** — every acceptance criterion covered; behavior matches request.
- **L5 regression** — after merge, full suite passed count >= baseline.

**Sendback loop**: L1-L4 any FAIL → return to Codex with a specific gap list →
re-run from L1. L1-L4 all PASS required before merge. L5 FAIL: Hermes decides
revert or fix.

**L1 supplemental scan (optional)** — `code-review-sr` local-only static
analysis as auxiliary evidence, does NOT replace the L1-L5 flow:
- Tool: `~/.hermes/skills/code-review-sr/src/code-review.js` (Node module,
  local-only build: regex analysis only, no network, no API key, no data leaves
  the machine)
- Run `reviewDir(<delivery dir>)` over the delivered files; high-severity hits
  can be grounds for sendback, but no hits does NOT mean clean — L3 tests
  remain authoritative
- If the tool is missing or fails, skip it; never block L1-L5 on it

---

## 7. Failure Modes

Verification-layer failures (zero delivery, partial delivery, fake-PASS,
unauthorized changes, hallucinated APIs, stuck planning) — return to Codex
with the specific gap list.

Operational failures (token exhaustion, worktree venv, sandbox silent exit,
src/ not synced, **hung agent** — no new output past threshold) — Hermes
takes over: run tests, commit, or inject paths. Hung agent: kill first, then
check what was produced.

**Model capacity fallback chain** — `gpt-5.6-luna` may exit 1 (capacity
insufficient) but have produced partial files. Handle in order:
1. Check produced files (`git status --short`) — commit partial output.
2. Retry same command (capacity is usually transient).
3. Fallback to a secondary model (e.g. `glm-5.2:cloud`, per availability).
4. Hermes fully takes over implementation. Same purpose: retry a method at
   most **once**; never loop retries.

---

## 8. Worktree venv

Worktrees at /tmp/ do not inherit the main repo's venv. Two remedies — include
absolute venv path in the prompt, or Hermes runs tests on Codex's behalf. On
token exhaustion, Hermes runs tests + commits on Codex's behalf.

---

## 9. No-Idle

After launching Codex background tasks, start parallel work immediately:
prepare tests, review requirements, or implement another unit. Never idle
while Codex runs.

---

## 10. Baseline Tracking

After each collaboration round, record cumulative test count and quality-gate
numbers as the regression target for the next round.

---

## 11. Rules

1. Run 5-layer verification on all deliverables — code-passing != code-correct.
2. Hermes orchestrates, Codex implements, Hermes verifies.
3. Worktrees lack venv — include absolute path in prompt or Hermes runs tests (see §8).
4. Codex scope = files Hermes authorized; anything else = instant reject.
5. Update the task tracker + baseline table after each round (see §10).
6. Plan presentation gate — present the plan, STOP, wait for explicit user
   approval; never write prompts or spawn in the same turn (see §3.4).
7. Monitor agents while they run — poll for output; hung past threshold =
   kill + handle; write the EOR record after each task (see §3.8, §3.11).
8. Capacity exit 1 → check output → commit partial → retry once → fallback
   model → Hermes takes over; never loop retries (see §7).
