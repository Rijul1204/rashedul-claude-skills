---
name: wip-limits
description: WIP limit theory and enforcement via Fizzy API monitoring
metadata:
  tags: wip, limits, flow, bottleneck, columns, monitoring
---

## What are WIP limits?

Work In Progress (WIP) limits cap how many cards can be in a column at the same time. When a limit is reached, no new card should enter that column until one exits. This forces the team to **finish work before starting new work**.

## Why WIP limits matter

- **Less context switching** — Fewer active items means deeper focus
- **Faster delivery** — Cards flow through the board instead of piling up
- **Visible bottlenecks** — A full column signals a problem to address
- **Higher quality** — Less multitasking leads to better work

## Setting WIP limits

**Rule of thumb**: WIP per column = number of people working in that stage, minus 1.

| Team members in stage | Suggested WIP limit |
|-----------------------|---------------------|
| 2 | 1-2 |
| 3 | 2-3 |
| 4 | 3 |
| 5 | 4 |

Start conservative. It's easier to raise a limit than to lower one.

## Enforcement in Fizzy

Fizzy has no native WIP limit field. The PM agent enforces limits by **monitoring column card counts** via the API.

### Check WIP for a board

```bash
# Get columns
COLUMNS=$(curl -s -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  -H "Accept: application/json" \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/boards/$BOARD_ID/columns")

# Get all cards on the board
CARDS=$(curl -s -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  -H "Accept: application/json" \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards?board_ids[]=$BOARD_ID")

# Count cards per column
echo "$COLUMNS" | jq -r '.[].id' | while read COL_ID; do
  COL_NAME=$(echo "$COLUMNS" | jq -r ".[] | select(.id == \"$COL_ID\") | .name")
  COUNT=$(echo "$CARDS" | jq "[.[] | select(.column.id == \"$COL_ID\")] | length")
  echo "$COL_NAME: $COUNT cards"
done
```

### Define thresholds

Record WIP limits in [tap-games-context.md](./tap-games-context.md) under "Column Conventions per Board". Example:

```
Board: Mobile App
- To Do: WIP 5
- In Progress: WIP 3
- Code Review: WIP 2
```

### Flag violations

When a column exceeds its WIP limit, report it in the health check output. The agent should flag the column name, current count, and the limit.

## What to do when WIP is exceeded

1. **Don't add more cards** — Resist the urge to start new work
2. **Help clear the bottleneck** — Can anyone assist in the overloaded column?
3. **Move a card back** — If something was triaged prematurely, send it back to triage
4. **Investigate the cause** — Is there a blocker? A dependency? A review bottleneck?

## See also

- [kanban-principles.md](./kanban-principles.md) - WIP limits in Kanban theory
- [column-structure.md](./column-structure.md) - Designing columns
- [board-hygiene.md](./board-hygiene.md) - Checking WIP during hygiene routine
