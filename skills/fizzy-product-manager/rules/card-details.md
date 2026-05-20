---
name: card-details
description: Managing card sub-resources — steps (todos), reactions (boosts), and pins
metadata:
  tags: steps, reactions, boosts, pins, todos, checklists, bookmarks
---

## Steps (Todo Items)

Steps are checklist items attached to a card. Use them for acceptance criteria or sub-tasks.

### Create a step

```bash
curl -s -X POST \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"step": {"content": "Write migration script"}}' \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards/$CARD_NUMBER/steps"
```

### Complete a step

```bash
curl -s -X PUT \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"step": {"completed": true}}' \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards/$CARD_NUMBER/steps/$STEP_ID"
```

### Delete a step

```bash
curl -s -X DELETE \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards/$CARD_NUMBER/steps/$STEP_ID"
```

### Guidelines

- **3-7 steps per card** — More than 7 means the card is too big; split it
- **Concrete and verifiable** — "Write unit tests for auth module" not "Testing"
- Completed steps count as card activity (helps prevent entropy)
- Steps appear in the card detail response under the `steps` array

## Reactions (Boosts)

Reactions are short text responses (max 16 characters) on cards or comments. Use for quick feedback without comment noise.

### Add a reaction to a card

```bash
curl -s -X POST \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"reaction": {"content": "Nice work"}}' \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards/$CARD_NUMBER/reactions"
```

### Add a reaction to a comment

```bash
curl -s -X POST \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"reaction": {"content": "Agreed"}}' \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards/$CARD_NUMBER/comments/$COMMENT_ID/reactions"
```

### Remove a reaction

Only the creator can remove their reaction:

```bash
curl -s -X DELETE \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards/$CARD_NUMBER/reactions/$REACTION_ID"
```

## Pins (Personal Bookmarks)

Pins are per-user bookmarks for quick access. Different from golden cards (which are team-visible).

### Pin / unpin a card

```bash
# Pin
curl -s -X POST \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards/$CARD_NUMBER/pin"

# Unpin
curl -s -X DELETE \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards/$CARD_NUMBER/pin"
```

### List pinned cards

```bash
curl -s -H "Authorization: Bearer $FIZZY_API_TOKEN" \
     -H "Accept: application/json" \
     "$FIZZY_BASE_URL/my/pins" | jq '.[].title'
```

Returns up to 100 pinned cards (not paginated).

### Golden cards

Mark a card as golden to highlight it for the whole team:

```bash
# Mark golden
curl -s -X POST \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards/$CARD_NUMBER/goldness"

# Remove golden
curl -s -X DELETE \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards/$CARD_NUMBER/goldness"

# List golden cards
curl -s -H "Authorization: Bearer $FIZZY_API_TOKEN" \
     -H "Accept: application/json" \
     "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards?indexed_by=golden"
```

Golden should be rare — if everything is golden, nothing is. Use for cards with external commitments or critical deadlines.

## See also

- [card-writing.md](./card-writing.md) - Writing good card content
- [card-lifecycle.md](./card-lifecycle.md) - Card state management
- [comments-collaboration.md](./comments-collaboration.md) - Comment-based collaboration
