---
name: api-recipes
description: Complete multi-step curl recipes for common PM workflows
metadata:
  tags: api, recipes, curl, scripts, automation, workflows, jq
---

All recipes use these environment variables:
- `$FIZZY_API_TOKEN` — Bearer token
- `$FIZZY_BASE_URL` — `https://app.fizzy.do`
- `$FIZZY_ACCOUNT_SLUG` — Account slug (e.g., `897362094`)

Standard headers used throughout:
```bash
AUTH="-H \"Authorization: Bearer $FIZZY_API_TOKEN\" -H \"Accept: application/json\""
```

---

## Recipe 1: Initial board setup

Create a board with columns and first cards.

```bash
# Create board
BOARD=$(curl -s -X POST \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"board": {"name": "Q2 Sprint", "all_access": true}}' \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/boards")

BOARD_ID=$(echo "$BOARD" | jq -r '.id // empty')

# Create columns
for COL in "To Do" "In Progress" "Review"; do
  curl -s -X POST \
    -H "Authorization: Bearer $FIZZY_API_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"column\": {\"name\": \"$COL\"}}" \
    "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/boards/$BOARD_ID/columns"
done

# Create initial cards
for TITLE in "Set up project structure" "Define API contracts" "Write integration tests"; do
  curl -s -X POST \
    -H "Authorization: Bearer $FIZZY_API_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"card\": {\"title\": \"$TITLE\"}}" \
    "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/boards/$BOARD_ID/cards"
done
```

---

## Recipe 2: Full triage session

Process all untriaged cards on a board.

```bash
# Get columns (need IDs for triage)
COLUMNS=$(curl -s -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  -H "Accept: application/json" \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/boards/$BOARD_ID/columns")

echo "Available columns:"
echo "$COLUMNS" | jq -r '.[] | "  \(.name): \(.id)"'

# Get untriaged cards
CARDS=$(curl -s -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  -H "Accept: application/json" \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards?board_ids[]=$BOARD_ID")

UNTRIAGED=$(echo "$CARDS" | jq '[.[] | select(.column == null and .closed != true and .postponed != true)]')
COUNT=$(echo "$UNTRIAGED" | jq 'length')

echo "$COUNT cards in triage"
echo "$UNTRIAGED" | jq '.[] | {number, title, creator: .creator.name, tags}'
```

Then for each card, use the triage commands from [card-triage.md](./card-triage.md).

---

## Recipe 3: Weekly health check

Run across all boards.

```bash
BOARDS=$(curl -s -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  -H "Accept: application/json" \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/boards")

echo "$BOARDS" | jq -r '.[].id' | while read BOARD_ID; do
  BOARD_NAME=$(echo "$BOARDS" | jq -r ".[] | select(.id == \"$BOARD_ID\") | .name")
  
  CARDS=$(curl -s -H "Authorization: Bearer $FIZZY_API_TOKEN" \
    -H "Accept: application/json" \
    "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards?board_ids[]=$BOARD_ID")
  
  TRIAGE=$(echo "$CARDS" | jq '[.[] | select(.column == null and .closed != true and .postponed != true)] | length')
  
  STALLED=$(curl -s -H "Authorization: Bearer $FIZZY_API_TOKEN" \
    -H "Accept: application/json" \
    "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards?indexed_by=stalled&board_ids[]=$BOARD_ID" | jq 'length')
  
  UNASSIGNED=$(curl -s -H "Authorization: Bearer $FIZZY_API_TOKEN" \
    -H "Accept: application/json" \
    "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards?assignment_status=unassigned&board_ids[]=$BOARD_ID" | jq 'length')
  
  echo "Board: $BOARD_NAME | Triage: $TRIAGE | Stalled: $STALLED | Unassigned: $UNASSIGNED"
done
```

---

## Recipe 4: Close completed cards

Find cards in a "Done"-like column and close them.

```bash
# Find the target column ID
DONE_COL_ID=$(curl -s -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  -H "Accept: application/json" \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/boards/$BOARD_ID/columns" \
  | jq -r '.[] | select(.name == "Done" or .name == "Shipped") | .id')

# Get cards in that column
CARDS=$(curl -s -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  -H "Accept: application/json" \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards?board_ids[]=$BOARD_ID")

echo "$CARDS" | jq -r ".[] | select(.column.id == \"$DONE_COL_ID\") | .number" | while read NUM; do
  echo "Closing card #$NUM"
  curl -s -X POST \
    -H "Authorization: Bearer $FIZZY_API_TOKEN" \
    "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards/$NUM/closure"
done
```

---

## Recipe 5: Rescue cards from Not Now

Review postponed cards and re-triage relevant ones.

```bash
curl -s -H "Authorization: Bearer $FIZZY_API_TOKEN" \
     -H "Accept: application/json" \
     "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards?indexed_by=not_now&board_ids[]=$BOARD_ID" \
  | jq '.[] | {number, title, last_active_at}'
```

For each card worth rescuing:
```bash
curl -s -X POST \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"column_id\": \"$COLUMN_ID\"}" \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards/$CARD_NUMBER/triage"
```

---

## Recipe 6: Activity digest

Summarize the past week's activity.

```bash
curl -s -H "Authorization: Bearer $FIZZY_API_TOKEN" \
     -H "Accept: application/json" \
     "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/activities?board_ids[]=$BOARD_ID" \
  | jq 'group_by(.action) | .[] | {action: .[0].action, count: length}' \
  | jq -s 'sort_by(-.count)'
```

---

## Recipe 7: Workload rebalancing

Identify overloaded and underloaded team members.

See [assignments-workload.md](./assignments-workload.md) for the full workload report script.

---

## Recipe 8: Bulk tagging

Apply a tag to all cards matching a search term.

```bash
# Find cards matching search
CARDS=$(curl -s -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  -H "Accept: application/json" \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards?terms[]=login&board_ids[]=$BOARD_ID")

echo "$CARDS" | jq -r '.[].number' | while read NUM; do
  echo "Tagging card #$NUM with 'auth'"
  curl -s -X POST \
    -H "Authorization: Bearer $FIZZY_API_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"tag_title": "auth"}' \
    "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards/$NUM/taggings"
done
```

---

## Pagination helper

For any paginated endpoint, follow the `Link` header:

```bash
URL="$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards"
ALL_RESULTS="[]"
while [ -n "$URL" ]; do
  RESPONSE=$(curl -s -D /tmp/fizzy-headers \
    -H "Authorization: Bearer $FIZZY_API_TOKEN" \
    -H "Accept: application/json" "$URL")
  ALL_RESULTS=$(echo "$ALL_RESULTS $RESPONSE" | jq -s '.[0] + .[1]')
  URL=$(grep -i '^link:' /tmp/fizzy-headers | sed -n 's/.*<\(.*\)>; rel="next".*/\1/p')
done
echo "$ALL_RESULTS" | jq 'length'
```

## See also

- [api-basics.md](./api-basics.md) - API fundamentals
- [card-triage.md](./card-triage.md) - Triage decision framework
- [board-hygiene.md](./board-hygiene.md) - Health check routine
