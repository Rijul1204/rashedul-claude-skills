---
name: card-triage
description: Workflow for processing cards in the triage queue and deciding their fate
metadata:
  tags: triage, maybe, workflow, prioritization, decision-making, batch
---

## What is triage?

Triage is the process of reviewing new cards in the "Maybe?" queue and deciding where they belong. Cards enter triage when created and stay there until someone moves them.

## Decision framework

For each card in triage, ask these questions in order:

1. **Does this align with current priorities?** → Triage to the appropriate column
2. **Is this important but not for now?** → Move to Not Now
3. **Is this already done or a duplicate?** → Close it
4. **Does this need more information?** → Add a comment asking for clarity, leave in triage

Always **tag** and **assign** during triage. A triaged card with no tag and no assignee will be forgotten.

## Finding untriaged cards

```bash
# Get all cards on a board that are in triage (no column, not closed, not postponed)
curl -s -H "Authorization: Bearer $FIZZY_API_TOKEN" \
     -H "Accept: application/json" \
     "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards?board_ids[]=$BOARD_ID" \
  | jq '[.[] | select(.column == null and .closed != true and .postponed != true)] | length'
```

## Triage a single card

### Step 1: Read the card

```bash
curl -s -H "Authorization: Bearer $FIZZY_API_TOKEN" \
     -H "Accept: application/json" \
     "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards/$CARD_NUMBER" \
  | jq '{number, title, description, tags, creator: .creator.name}'
```

### Step 2: Decide (apply the decision framework above)

### Step 3: Execute the decision

```bash
# Triage to a column
curl -s -X POST \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"column_id\": \"$COLUMN_ID\"}" \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards/$CARD_NUMBER/triage"

# Or move to Not Now
curl -s -X POST \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards/$CARD_NUMBER/not_now"

# Or close
curl -s -X POST \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards/$CARD_NUMBER/closure"
```

### Step 4: Tag the card

```bash
curl -s -X POST \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"tag_title": "bug"}' \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards/$CARD_NUMBER/taggings"
```

### Step 5: Assign the card

```bash
curl -s -X POST \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"assignee_id\": \"$USER_ID\"}" \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards/$CARD_NUMBER/assignments"
```

### Step 6: Add a triage comment (optional but recommended)

```bash
curl -s -X POST \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"comment": {"body": "Triaged to In Progress. This aligns with the Q2 mobile push."}}' \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards/$CARD_NUMBER/comments"
```

## Batch triage workflow

Process all untriaged cards on a board:

1. Fetch untriaged cards (see "Finding untriaged cards" above)
2. For each card: read title and description
3. Present the card to the user with the decision framework
4. Execute the chosen action (triage/not now/close)
5. Tag and assign
6. Move to the next card

## See also

- [card-lifecycle.md](./card-lifecycle.md) - Full lifecycle including triage
- [column-structure.md](./column-structure.md) - Understanding available columns
- [assignments-workload.md](./assignments-workload.md) - Who to assign to
- [tagging-strategy.md](./tagging-strategy.md) - How to tag during triage
