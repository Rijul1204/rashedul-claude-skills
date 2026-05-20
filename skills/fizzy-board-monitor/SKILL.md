---
name: fizzy-board-monitor
description: >
  Show an on-demand Kanban overview of a Fizzy board — cards grouped by column with counts.
  Default board is the QA board. Use when user says "show fizzy board", "fizzy board overview",
  "list fizzy cards", "what's on the board", "show [board name] board", or wants to see
  the current state of any Fizzy board.
metadata:
  bashPattern:
    - "fizzy"
---

# Fizzy Board Monitor — On-Demand Board Overview

Display an on-demand Kanban-style overview of any Fizzy board, with cards grouped by column.

## Credentials

**Bearer token**: `R2Rek4vNLSrr12F9QFkBy3BZ`
**Account ID**: `6132669`
**Base URL**: `https://app.fizzy.do`

## Known Boards

| Board ID                    | Name      | Default? |
|-----------------------------|-----------|----------|
| 03fd4omd9qico7wmyyof5yfe4   | QA Board  | YES      |

> **Default behaviour**: always show the QA board unless the user explicitly names a different board.

## Workflow

### Step 1 — Determine target board

- If the user says "show the board" or "fizzy board" with no board name → use QA board (`03fd4omd9qico7wmyyof5yfe4`)
- If the user names a board (e.g., "show the backend sprint board") → list all boards and match by name:

```bash
curl -s "https://app.fizzy.do/6132669/boards" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer R2Rek4vNLSrr12F9QFkBy3BZ"
```

### Step 2 — Fetch columns

```bash
curl -s "https://app.fizzy.do/6132669/boards/<BOARD_ID>/columns" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer R2Rek4vNLSrr12F9QFkBy3BZ"
```

Note column IDs and names (e.g., "To Do", "In Progress", "Done").

### Step 3 — Fetch open cards

```bash
curl -s "https://app.fizzy.do/6132669/cards?board_ids[]=<BOARD_ID>&status=open" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer R2Rek4vNLSrr12F9QFkBy3BZ"
```

Follow `Link: rel="next"` headers for pagination if the board has many cards.

### Step 4 — Group cards by column

Map each card to its column using the card's `column_id` field. Count cards per column.

### Step 5 — Present the Kanban overview

```text
Fizzy Board — QA Board (YYYY-MM-DD HH:MM)
https://app.fizzy.do/6132669/boards/03fd4omd9qico7wmyyof5yfe4

┌─────────────────────────────────────────────────────────────┐
│ TO DO (3)          │ IN PROGRESS (2)    │ DONE (5)          │
├─────────────────────────────────────────────────────────────┤
│ #45 Game disconnect│ #42 Payment retry  │ #38 Admin label   │
│ #44 Seed script    │ #41 JWKS 500       │ #37 Leaderboard   │
│ #43 Refactor auth  │                    │ ...               │
└─────────────────────────────────────────────────────────────┘

Total open: 5  |  Closed today: 5
```

If the terminal doesn't support box-drawing characters, use plain text with `---` separators.

Show each card as: `#<number> <title>` — keep titles to 20 chars, truncate with `…` if longer.

### Step 6 — Offer follow-up actions

After the overview, offer:

1. Create a card in a specific column
2. Close a card (mark done)
3. Move a card to a different column
4. Drill into a specific column (show all cards with descriptions)
5. Show a different board (list available boards)
6. Sync open cards to local task tracker

## Error Handling

- Board not found by name → list available boards and ask user to confirm
- No cards in a column → show column with `(empty)` label
- API error → show the HTTP status and response body
