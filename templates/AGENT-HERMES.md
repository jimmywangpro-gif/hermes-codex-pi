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
4. **TDD gate（測試先行）** — write the test code for each acceptance
   criterion FIRST, run it to confirm **RED** (FAIL), and only then start any
   implementation. Done = tests exist and show RED before coding begins.
5. **Write prompt** — per Section 5; include scope, read-first, task,
   acceptance, test command, commit format. Done = prompt ready.
6. **Launch Codex in background** — `terminal(background=true, pty=true,
   workdir=<path>, notify_on_complete=true)`. Done = session_id + process log.
7. **No-idle** — while Codex runs, start parallel work (see §9).
   Done = parallel work progresses.
8. **Run 5-layer verification** (see Section 6). Done = L1-L4 all PASS.
9. **Merge + regress** — merge verified branch, run full suite, confirm
   passed count >= baseline. Done = L5 PASS.
10. **Clean up worktree** — `git worktree remove /tmp/<path>`. Done = worktree
    list excludes it + test branch deleted.
11. **Update tracker** — status, test counts, quality gates, agent attribution.
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

---

## 7. Failure Modes

Verification-layer failures (zero delivery, partial delivery, fake-PASS,
unauthorized changes, hallucinated APIs, stuck planning) — return to Codex
with the specific gap list.

Operational failures (token exhaustion, worktree venv, sandbox silent exit,
src/ not synced) — Hermes takes over: run tests, commit, or inject paths.

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
