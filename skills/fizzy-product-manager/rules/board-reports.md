---
name: board-reports
description: Generating board snapshots, velocity reports, health reports, and workload breakdowns
metadata:
  tags: reports, summary, status, dashboard, metrics, velocity, health
---

## Report types

### 1. Board snapshot

Current state of all cards by column.

```bash
COLUMNS=$(curl -s -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  -H "Accept: application/json" \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/boards/$BOARD_ID/columns")

CARDS=$(curl -s -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  -H "Accept: application/json" \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards?board_ids[]=$BOARD_ID")

# Count by column
echo "$COLUMNS" | jq -r '.[] | "\(.id)\t\(.name)"' | while IFS=$'\t' read COL_ID COL_NAME; do
  COUNT=$(echo "$CARDS" | jq "[.[] | select(.column.id == \"$COL_ID\")] | length")
  echo "$COL_NAME: $COUNT"
done

# Also count untriaged, not now, closed
TRIAGE=$(echo "$CARDS" | jq '[.[] | select(.column == null and .closed != true and .postponed != true)] | length')
echo "In Triage: $TRIAGE"
```

**Output format**:

| Column | Cards |
|--------|-------|
| To Do | 5 |
| In Progress | 3 |
| Review | 2 |
| In Triage | 4 |

### 2. Activity summary

What happened in a time period.

```bash
curl -s -H "Authorization: Bearer $FIZZY_API_TOKEN" \
     -H "Accept: application/json" \
     "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/activities?board_ids[]=$BOARD_ID" \
  | jq 'group_by(.action) | .[] | {action: .[0].action, count: length}'
```

**Output format**:

| Action | Count |
|--------|-------|
| card_published | 3 |
| card_triaged | 5 |
| card_closed | 2 |
| comment_created | 8 |

### 3. Workload report

Cards per assignee. See [assignments-workload.md](./assignments-workload.md) for the full script.

**Output format**:

| Team Member | Active Cards |
|-------------|-------------|
| Alice | 4 |
| Bob | 7 |
| Charlie | 2 |

### 4. Health report

Combines hygiene check metrics into a single view.

| Metric | Count | Status |
|--------|-------|--------|
| Triage queue | 4 | Needs attention |
| Stalled cards | 2 | Warning |
| Unassigned active | 1 | Warning |
| WIP violations | 0 | OK |
| Postponing soon | 3 | Warning |

### 5. Velocity report

Cards closed in a time period.

```bash
# This week's closures
curl -s -H "Authorization: Bearer $FIZZY_API_TOKEN" \
     -H "Accept: application/json" \
     "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards?indexed_by=closed&closure=thisweek" | jq 'length'

# Last week's closures
curl -s -H "Authorization: Bearer $FIZZY_API_TOKEN" \
     -H "Accept: application/json" \
     "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards?indexed_by=closed&closure=lastweek" | jq 'length'
```

**Output format**:

| Period | Cards Closed |
|--------|-------------|
| This week | 5 |
| Last week | 8 |
| This month | 22 |

## Useful card filters for reporting

| Filter | Purpose |
|--------|---------|
| `creation=thisweek` | New card inflow |
| `closure=thisweek` | Throughput |
| `indexed_by=stalled` | Risk assessment |
| `sorted_by=oldest` | Finding neglected cards |
| `indexed_by=golden` | Tracking high-priority items |

## See also

- [board-hygiene.md](./board-hygiene.md) - Weekly health check routine
- [assignments-workload.md](./assignments-workload.md) - Workload balancing
- [activity-monitoring](./comments-collaboration.md) - Activity tracking via comments
