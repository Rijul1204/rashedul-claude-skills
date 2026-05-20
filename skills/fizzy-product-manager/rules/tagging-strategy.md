---
name: tagging-strategy
description: Effective tagging strategy for organizing and filtering cards across boards
metadata:
  tags: tags, organization, filtering, categorization, taxonomy
---

## List existing tags

```bash
curl -s -H "Authorization: Bearer $FIZZY_API_TOKEN" \
     -H "Accept: application/json" \
     "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/tags" | jq '.[].title'
```

Returns all tags in the account, sorted alphabetically.

## Toggle a tag on a card

Adds the tag if absent, removes it if present. Creates the tag automatically if it doesn't exist.

```bash
curl -s -X POST \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"tag_title": "bug"}' \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards/$CARD_NUMBER/taggings"
```

The leading `#` is stripped automatically (`#bug` and `bug` are equivalent).

## Naming conventions

- **Lowercase, hyphenated**: `front-end`, `api-v2`, `mobile-app`
- **Short and scannable**: 1-3 words max
- **No overlap with column names**: Tags categorize *what*, columns track *where in the workflow*

## Recommended tag categories

### Type tags

`bug`, `feature`, `enhancement`, `chore`, `docs`, `spike`

### Area tags

`frontend`, `backend`, `mobile`, `infrastructure`, `design`, `data`

### Priority tags (use sparingly)

`urgent`, `important`

Most prioritization should be positional (column ordering), not tag-based. Only use priority tags for things that genuinely need special attention.

### Size tags (optional)

`small`, `medium`, `large`

Useful for workload estimation if the team finds it helpful.

## Filtering by tags

```bash
# Cards with a specific tag
curl -s -H "Authorization: Bearer $FIZZY_API_TOKEN" \
     -H "Accept: application/json" \
     "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards?tag_ids[]=$TAG_ID"

# Combine with other filters
curl -s -H "Authorization: Bearer $FIZZY_API_TOKEN" \
     -H "Accept: application/json" \
     "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards?tag_ids[]=$TAG_ID&board_ids[]=$BOARD_ID&assignee_ids[]=$USER_ID"
```

## Tag audit

Periodically list all tags and look for:
- **Duplicates**: `bug` and `bugs`, `frontend` and `front-end`
- **Unused tags**: Tags with no cards (check by filtering)
- **Overly broad tags**: If a tag is on 80% of cards, it's not useful

## See also

- [card-triage.md](./card-triage.md) - Tagging during triage
- [board-reports.md](./board-reports.md) - Reporting by tag
