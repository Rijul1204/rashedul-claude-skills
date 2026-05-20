---
name: entropy-management
description: Understanding and managing Fizzy's entropy system — auto-postponement of stale cards
metadata:
  tags: entropy, auto-postpone, stale, not-now, inactivity, postponing-soon
---

## What is entropy?

Cards automatically move to "Not Now" after a period of inactivity. This is called **entropy**. It prevents boards from accumulating an endless backlog of forgotten cards.

Entropy is a feature, not a bug. If a card keeps getting auto-postponed, that's a signal: either do it, close it, or accept it's Not Now.

## Checking entropy settings

### Account default

```bash
curl -s -H "Authorization: Bearer $FIZZY_API_TOKEN" \
     -H "Accept: application/json" \
     "$FIZZY_BASE_URL/account/settings" | jq '.auto_postpone_period_in_days'
```

### Board override

Board entropy is visible in the board response's `auto_postpone_period_in_days` field.

## Updating entropy

### Account level (admin required)

```bash
curl -s -X PUT \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"entropy": {"auto_postpone_period_in_days": 30}}' \
  "$FIZZY_BASE_URL/account/entropy"
```

### Board level (board admin required)

```bash
curl -s -X PUT \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"board": {"auto_postpone_period_in_days": 90}}' \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/boards/$BOARD_ID/entropy"
```

Use longer periods for boards with long-running work (e.g., 90 days for strategic planning).

## Finding at-risk cards

```bash
# Cards approaching entropy
curl -s -H "Authorization: Bearer $FIZZY_API_TOKEN" \
     -H "Accept: application/json" \
     "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards?indexed_by=stalled" | jq '.[].title'

# Cards about to be auto-postponed
curl -s -H "Authorization: Bearer $FIZZY_API_TOKEN" \
     -H "Accept: application/json" \
     "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards?indexed_by=postponing_soon" | jq '.[].title'
```

## What counts as activity

The `last_active_at` timestamp resets when:
- A comment is added
- The card description or title is edited
- A state change occurs (triaged, closed, reopened)
- Steps are added or completed
- Reactions are added

## Preventing unwanted entropy

### Touch a card with a comment

```bash
curl -s -X POST \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"comment": {"body": "Still active — waiting on design review."}}' \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards/$CARD_NUMBER/comments"
```

### Override last_active_at directly

```bash
curl -s -X PUT \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"card\": {\"last_active_at\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}}" \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards/$CARD_NUMBER"
```

## See also

- [card-lifecycle.md](./card-lifecycle.md) - How Not Now fits in the lifecycle
- [board-hygiene.md](./board-hygiene.md) - Checking stalled cards in the hygiene routine
- [kanban-principles.md](./kanban-principles.md) - Managing flow
