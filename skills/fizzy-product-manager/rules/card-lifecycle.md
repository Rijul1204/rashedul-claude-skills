---
name: card-lifecycle
description: Understanding and managing the full card lifecycle from triage through closure
metadata:
  tags: cards, lifecycle, triage, close, reopen, not-now, done, status
---

## Lifecycle diagram

```
  Triage (Maybe?) ──► Column (triaged) ──► Done (closed)
        │                                       │
        └──► Not Now (postponed) ◄──────────────┘
                     │
                     └──► Column (re-triaged)
```

- **Triage / Maybe?** — New cards start here, waiting to be sorted
- **Column** — Card is triaged into an active workflow stage
- **Not Now** — Card is parked (manually or auto-postponed by entropy)
- **Done** — Card is closed

## Creating a card

Cards are created on a board and start in triage:

```bash
curl -s -X POST \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"card": {"title": "Add dark mode toggle"}}' \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/boards/$BOARD_ID/cards"
```

## State transitions

### Triage into a column

```bash
curl -s -X POST \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "{\"column_id\": \"$COLUMN_ID\"}" \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards/$CARD_NUMBER/triage"
```

### Send back to triage

```bash
curl -s -X DELETE \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards/$CARD_NUMBER/triage"
```

### Move to Not Now

```bash
curl -s -X POST \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards/$CARD_NUMBER/not_now"
```

### Close (Done)

```bash
curl -s -X POST \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards/$CARD_NUMBER/closure"
```

### Reopen

```bash
curl -s -X DELETE \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards/$CARD_NUMBER/closure"
```

## Card filters

Use `indexed_by` to filter cards by state:

| Value | Shows |
|-------|-------|
| `all` | Everything active (default) |
| `closed` | Done cards |
| `not_now` | Parked/postponed cards |
| `stalled` | Cards at risk of entropy |
| `postponing_soon` | Cards about to be auto-postponed |
| `golden` | Highlighted important cards |

```bash
curl -s -H "Authorization: Bearer $FIZZY_API_TOKEN" \
     -H "Accept: application/json" \
     "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards?indexed_by=stalled"
```

## Decision framework

- **Is this done?** → Close it. Don't leave completed work in a column.
- **Is this active and someone is working on it?** → Keep in its column.
- **Is this important but not right now?** → Move to Not Now. It's not forgotten.
- **Is this no longer relevant?** → Close it with a comment explaining why.
- **Is this in the wrong column?** → Re-triage to the correct column.

## Identifying untriaged cards

Cards in triage have **no `column` field** in the API response, are **not closed**, and are **not postponed**. Filter by board and check for missing `column`:

```bash
curl -s -H "Authorization: Bearer $FIZZY_API_TOKEN" \
     -H "Accept: application/json" \
     "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards?board_ids[]=$BOARD_ID" \
  | jq '[.[] | select(.column == null and .closed != true and .postponed != true)]'
```

## See also

- [card-triage.md](./card-triage.md) - Triage decision framework
- [entropy-management.md](./entropy-management.md) - Auto-postpone behavior
- [golden-cards](./card-details.md) - Marking cards as golden
