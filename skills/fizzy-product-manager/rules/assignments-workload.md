---
name: assignments-workload
description: Managing card assignments and monitoring team workload balance
metadata:
  tags: assignments, assignees, workload, team, users, balance
---

## List users

```bash
curl -s -H "Authorization: Bearer $FIZZY_API_TOKEN" \
     -H "Accept: application/json" \
     "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/users" | jq '.[] | {id, name, role}'
```

Returns active users. Roles: `owner`, `admin`, `member`.

## Toggle assignment

Assigns the user if unassigned, unassigns if already assigned:

```bash
curl -s -X POST \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"assignee_id\": \"$USER_ID\"}" \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards/$CARD_NUMBER/assignments"
```

## Assignment guidelines

- **One primary assignee per card** — Fizzy supports multiple, but clarity of ownership matters
- **Assign during triage** — Don't triage a card without assigning it
- **Unassigned cards in active columns are a smell** — They indicate unclear ownership

## Checking workload

### Cards per assignee

```bash
# Active cards assigned to a specific user
curl -s -H "Authorization: Bearer $FIZZY_API_TOKEN" \
     -H "Accept: application/json" \
     "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards?assignee_ids[]=$USER_ID" | jq 'length'
```

### Unassigned active cards

```bash
curl -s -H "Authorization: Bearer $FIZZY_API_TOKEN" \
     -H "Accept: application/json" \
     "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards?assignment_status=unassigned" | jq 'length'
```

## Workload report pattern

For each user, count their active assigned cards and flag imbalances:

```bash
# Get all users
USERS=$(curl -s -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  -H "Accept: application/json" \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/users")

# For each user, count active cards
echo "$USERS" | jq -r '.[].id' | while read USER_ID; do
  NAME=$(echo "$USERS" | jq -r ".[] | select(.id == \"$USER_ID\") | .name")
  COUNT=$(curl -s -H "Authorization: Bearer $FIZZY_API_TOKEN" \
    -H "Accept: application/json" \
    "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards?assignee_ids[]=$USER_ID" | jq 'length')
  echo "$NAME: $COUNT cards"
done
```

## When to reassign

- Team member is overloaded (significantly more cards than peers)
- Team member is on leave or unavailable
- Card is blocked and needs different expertise
- Card has been stalled with the current assignee for too long

## See also

- [card-triage.md](./card-triage.md) - Assigning during triage
- [board-reports.md](./board-reports.md) - Workload reports
- [board-hygiene.md](./board-hygiene.md) - Finding unassigned cards
