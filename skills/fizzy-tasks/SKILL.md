---
name: fizzy-tasks
description: >
  Fetch open Fizzy cards assigned to the user, open bugs, and unassigned tasks.
  Presents a prioritised digest with deep links. Use when user says "fizzy tasks",
  "my fizzy cards", "what are my open tasks in fizzy", "fizzy action items",
  "bugs in fizzy", "show my tasks", or wants a digest of current Fizzy workload.
metadata:
  bashPattern:
    - "fizzy"
---

# Fizzy Tasks — Open Cards Digest

Fetch and display open Fizzy cards assigned to the current user, open bugs, blockers, and unassigned items — enriched with priority and effort estimates using Jackpot Snap project context.

## Credentials

**Bearer token**: `R2Rek4vNLSrr12F9QFkBy3BZ`
**Account ID**: `6132669`
**Base URL**: `https://app.fizzy.do`

## Workflow

### Step 1 — Fetch assigned cards

```bash
curl -s "https://app.fizzy.do/6132669/cards?status=open" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer R2Rek4vNLSrr12F9QFkBy3BZ"
```

Filter the response for cards where the current user is assigned. Also fetch all open cards to identify bugs (tagged "bug") and unassigned items.

If the API supports `?assigned=me`, use that parameter to reduce results:

```bash
curl -s "https://app.fizzy.do/6132669/cards?status=open&assigned=me" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer R2Rek4vNLSrr12F9QFkBy3BZ"
```

### Step 2 — Fetch users (to resolve names)

```bash
curl -s "https://app.fizzy.do/6132669/users" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer R2Rek4vNLSrr12F9QFkBy3BZ"
```

### Step 3 — Categorise cards

Group cards into:

1. **My Cards** — assigned to the current user
2. **Open Bugs** — tagged "bug" or "defect"
3. **Blockers** — tagged "blocker" or description contains "blocked"
4. **Unassigned** — open with no assignee

### Step 4 — Assign Priority and Effort

For every card, assign a **priority level** and **effort estimate** based on Jackpot Snap service context. Do NOT ask the user — infer from card title, description, and tags.

#### Priority Levels

| Level | Label              | When to assign |
|-------|--------------------|----------------|
| P0    | `[P0 — Critical]`  | Touches `game-engine` WebSocket, `payment-service` (Bankful/Dots), `user` auth/JWT/JWKS, or `validity-check` card deals |
| P1    | `[P1 — High]`      | Touches `competition` service (enrollments, leaderboard, knockout), or QA-reported bug visible to players |
| P2    | `[P2 — Medium]`    | Non-blocking feature work, DX improvements, dev env issues, non-critical UI bugs |
| P3    | `[P3 — Low]`       | Nice-to-have, docs, observability, refactors, no user-facing impact |

Cross-reference rules:

- Any card affecting `user` JWKS/auth → escalate to P0 (all services depend on it)
- Any card affecting `validity-check` → P0 (game-engine cannot deal cards without it)
- Any card affecting `payment-service` → P0 (real money at stake)
- QA bug reports → start at P1 unless narrowed to cosmetic (P2)

#### Effort Estimates

- **< 1h** — config change, env var, single-file fix, deploy of already-merged code
- **1–2h** — small bug fix (single service, known root cause)
- **2–4h** — moderate bug (cross-service, needs investigation), new endpoint or component
- **4–8h** — story-sized: new flow touching multiple layers (DB → API → UI)
- **> 1 day** — flag as requiring sprint planning; do not estimate precisely

State reasoning in one line after the estimate.

### Step 5 — Build deep links

For each card, construct a deep link:

```text
https://app.fizzy.do/6132669/cards/<CARD_NUMBER>
```

### Step 6 — Present the digest

> **IMPORTANT — Fizzy does NOT support Markdown.**
> When writing card descriptions, comments, or any content sent to Fizzy via the API, use plain text with spacing and line breaks only. No `**bold**`, `# headers`, `- bullets`, or any Markdown syntax. Use indentation and blank lines for structure instead.

```text
Fizzy Digest — YYYY-MM-DD HH:MM

MY CARDS (N)
  [P1 — High] ~2h  #42 — Fix payment webhook retry logic
  → https://app.fizzy.do/6132669/cards/42
  Reason: payment-service — real money at stake if retries fail.

  [P2 — Medium] ~1h  #38 — Update admin dashboard label
  → https://app.fizzy.do/6132669/cards/38
  Reason: Non-blocking UI change, no live game impact.

OPEN BUGS (N)
  [P1 — High] ~2–4h  #45 — Game disconnects on round 8
  → https://app.fizzy.do/6132669/cards/45
  Reason: game-engine WebSocket — visible to players.

BLOCKERS (N)
  [P0 — Critical]  #41 — JWKS endpoint returning 500
  → https://app.fizzy.do/6132669/cards/41
  Reason: All services depend on user JWKS — blocks auth entirely.

UNASSIGNED (N)
  [P3 — Low]  #39 — Refactor seed script
  → https://app.fizzy.do/6132669/cards/39

---
Boards scanned: QA Board
Total open cards: N
```

Omit empty sections.

### Step 7 — Offer follow-up actions

After the digest, offer:

1. Create a new card
2. Close / mark a card done
3. Add a comment to a card
4. Sync cards to local task tracker (`~/.claude/task-tracker.md`)
5. Filter by specific board or tag
