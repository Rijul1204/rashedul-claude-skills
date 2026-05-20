---
name: board-hygiene
description: 7-step weekly board maintenance checklist for keeping boards healthy
metadata:
  tags: hygiene, maintenance, cleanup, stale, routine, health-check, weekly
---

## Weekly board hygiene checklist

Run this checklist weekly (or bi-weekly) on each active board.

### Step 1: Process the triage queue

Find untriaged cards and decide their fate.

```bash
curl -s -H "Authorization: Bearer $FIZZY_API_TOKEN" \
     -H "Accept: application/json" \
     "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards?board_ids[]=$BOARD_ID" \
  | jq '[.[] | select(.column == null and .closed != true and .postponed != true)] | length'
```

If count > 0, run the triage workflow. See [card-triage.md](./card-triage.md).

### Step 2: Sweep stalled and postponing-soon cards

```bash
# Stalled cards
curl -s -H "Authorization: Bearer $FIZZY_API_TOKEN" \
     -H "Accept: application/json" \
     "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards?indexed_by=stalled&board_ids[]=$BOARD_ID" \
  | jq '.[] | {number, title, last_active_at}'

# About to be auto-postponed
curl -s -H "Authorization: Bearer $FIZZY_API_TOKEN" \
     -H "Accept: application/json" \
     "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards?indexed_by=postponing_soon&board_ids[]=$BOARD_ID" \
  | jq '.[] | {number, title, last_active_at}'
```

For each: touch it (add a comment), move to Not Now, or close.

### Step 3: Check for empty columns

```bash
COLUMNS=$(curl -s -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  -H "Accept: application/json" \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/boards/$BOARD_ID/columns")

CARDS=$(curl -s -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  -H "Accept: application/json" \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards?board_ids[]=$BOARD_ID")

echo "$COLUMNS" | jq -r '.[].id' | while read COL_ID; do
  COL_NAME=$(echo "$COLUMNS" | jq -r ".[] | select(.id == \"$COL_ID\") | .name")
  COUNT=$(echo "$CARDS" | jq "[.[] | select(.column.id == \"$COL_ID\")] | length")
  if [ "$COUNT" -eq 0 ]; then
    echo "EMPTY: $COL_NAME"
  fi
done
```

Consider removing columns that have been empty for multiple cycles.

### Step 4: Find unassigned active cards

```bash
curl -s -H "Authorization: Bearer $FIZZY_API_TOKEN" \
     -H "Accept: application/json" \
     "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards?assignment_status=unassigned&board_ids[]=$BOARD_ID" \
  | jq '[.[] | select(.column != null)] | .[] | {number, title, column: .column.name}'
```

Cards in active columns without an assignee need an owner.

### Step 5: Flag WIP limit violations

Check each column's card count against the limits defined in [tap-games-context.md](./tap-games-context.md). See [wip-limits.md](./wip-limits.md) for the monitoring script.

### Step 6: Review Not Now cards

```bash
curl -s -H "Authorization: Bearer $FIZZY_API_TOKEN" \
     -H "Accept: application/json" \
     "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards?indexed_by=not_now&board_ids[]=$BOARD_ID" \
  | jq '.[] | {number, title, last_active_at}'
```

Scan for cards that have become relevant again. Re-triage any that should come back into play.

### Step 7: Verify recently closed cards

```bash
curl -s -H "Authorization: Bearer $FIZZY_API_TOKEN" \
     -H "Accept: application/json" \
     "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards?indexed_by=closed&closure=thisweek&board_ids[]=$BOARD_ID" \
  | jq '.[] | {number, title}'
```

Confirm these are truly done. Reopen any that were closed prematurely.

## Health check output format

Present results as a summary table:

| Check | Status | Count | Action Needed |
|-------|--------|-------|---------------|
| Triage queue | ... | N | ... |
| Stalled cards | ... | N | ... |
| Empty columns | ... | N | ... |
| Unassigned active | ... | N | ... |
| WIP violations | ... | N | ... |
| Not Now review | ... | N | ... |
| Closed this week | ... | N | ... |

## See also

- [card-triage.md](./card-triage.md) - Processing the triage queue
- [entropy-management.md](./entropy-management.md) - Handling stalled cards
- [wip-limits.md](./wip-limits.md) - WIP limit checking
- [board-reports.md](./board-reports.md) - More detailed reports
