---
name: comments-collaboration
description: Using comments for PM communication, status updates, and decision documentation
metadata:
  tags: comments, collaboration, discussion, rich-text, updates, communication
---

## List comments on a card

```bash
curl -s -H "Authorization: Bearer $FIZZY_API_TOKEN" \
     -H "Accept: application/json" \
     "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards/$CARD_NUMBER/comments" \
  | jq '.[] | {id, creator: .creator.name, body: .body.plain_text, created_at}'
```

Paginated, sorted chronologically (oldest first).

## Create a comment

```bash
curl -s -X POST \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"comment": {"body": "Moving to In Progress. Aligned with Q2 priorities."}}' \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards/$CARD_NUMBER/comments"
```

Supports rich text HTML in the `body` field.

## Update a comment

Only the creator can update:

```bash
curl -s -X PUT \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"comment": {"body": "Updated: this is now blocked on API review."}}' \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards/$CARD_NUMBER/comments/$COMMENT_ID"
```

## Delete a comment

Only the creator can delete:

```bash
curl -s -X DELETE \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards/$CARD_NUMBER/comments/$COMMENT_ID"
```

## PM uses for comments

### Triage decisions

When triaging a card, leave a comment explaining the decision:
> "Moving to In Progress. This aligns with the mobile push this sprint."

### Asking for information

> "Can you clarify the expected behavior on iOS? The description mentions Android only."

### Status updates

> "Blocked on design review. Expected to unblock by Thursday."

### Closing notes

> "Shipped in v2.3. Verified in production."

## Comments prevent entropy

Posting a comment resets the card's `last_active_at` timestamp. This is the simplest way to prevent a card from being auto-postponed.

## Comments trigger notifications

Card watchers receive notifications when comments are posted. Use this to keep stakeholders informed without separate communication channels.

## Watch / unwatch a card

```bash
# Watch
curl -s -X POST \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards/$CARD_NUMBER/watch"

# Unwatch
curl -s -X DELETE \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards/$CARD_NUMBER/watch"
```

## See also

- [card-writing.md](./card-writing.md) - Rich text formatting
- [entropy-management.md](./entropy-management.md) - Comments as activity
- [card-details.md](./card-details.md) - Reactions on comments
