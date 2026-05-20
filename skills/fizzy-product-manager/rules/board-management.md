---
name: board-management
description: Creating, configuring, publishing, and organizing Fizzy boards
metadata:
  tags: boards, create, update, publish, access-control, organization
---

## List boards

```bash
curl -s -H "Authorization: Bearer $FIZZY_API_TOKEN" \
     -H "Accept: application/json" \
     "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/boards" | jq '.[].name'
```

Returns boards the authenticated user can access.

## Create a board

```bash
curl -s -X POST \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"board": {"name": "Q2 Sprint", "all_access": true}}' \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/boards"
```

Returns `201 Created` with a `Location` header pointing to the new board.

**Parameters**: `name` (required), `all_access` (default true), `auto_postpone_period_in_days`, `public_description` (rich text).

## Access control

- `all_access: true` — every user in the account can see the board
- `all_access: false` — only users listed in `user_ids` can access it

Update access:

```bash
curl -s -X PUT \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"board": {"all_access": false, "user_ids": ["USER_ID_1", "USER_ID_2"]}}' \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/boards/$BOARD_ID"
```

## Publish a board

Make a board publicly accessible via a shareable link:

```bash
# Publish
curl -s -X POST \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  -H "Accept: application/json" \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/boards/$BOARD_ID/publication"

# Unpublish
curl -s -X DELETE \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/boards/$BOARD_ID/publication"
```

## Board entropy

Set how many days of inactivity before cards auto-postpone to "Not Now":

```bash
curl -s -X PUT \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"board": {"auto_postpone_period_in_days": 60}}' \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/boards/$BOARD_ID/entropy"
```

## Board naming conventions

- Short, project-oriented: "Mobile App", "Backend API", "Q2 Sprint"
- Avoid generic names like "Board 1" or "Stuff"
- One board per workstream or project — don't overload a single board

## Delete a board

**Destructive — confirm before executing.**

```bash
curl -s -X DELETE \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/boards/$BOARD_ID"
```

## See also

- [column-structure.md](./column-structure.md) - Setting up columns on a board
- [entropy-management.md](./entropy-management.md) - Managing auto-postpone settings
- [board-hygiene.md](./board-hygiene.md) - Ongoing board maintenance
