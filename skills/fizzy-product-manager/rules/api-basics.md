---
name: api-basics
description: Fizzy API authentication, URL structure, pagination, caching, and error handling
metadata:
  tags: api, authentication, token, pagination, caching, errors, url-structure
---

## Authentication

All API requests require a Bearer token in the `Authorization` header:

```bash
curl -s \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  -H "Accept: application/json" \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/boards"
```

### Environment variables

Set these at the start of every session:

```bash
export FIZZY_API_TOKEN="<your-token>"
export FIZZY_BASE_URL="https://app.fizzy.do"
export FIZZY_ACCOUNT_SLUG="<account-slug>"
```

### Token permissions

- **Read**: allows `GET` and `HEAD` requests only
- **Read + Write**: allows all HTTP methods

A product manager needs **Read + Write** permission.

### Discovering your account slug

```bash
curl -s -H "Authorization: Bearer $FIZZY_API_TOKEN" \
     -H "Accept: application/json" \
     "$FIZZY_BASE_URL/my/identity" | jq '.accounts[] | {name, slug}'
```

The `slug` field (e.g. `/897362094`) is the account prefix for all account-scoped endpoints.

## URL structure

Fizzy uses path-based multi-tenancy. Every account-scoped endpoint is prefixed with the account slug:

```
https://app.fizzy.do/{account_slug}/boards
https://app.fizzy.do/{account_slug}/cards
https://app.fizzy.do/{account_slug}/cards/42/comments
```

Global endpoints (identity, access tokens, pins) have no account prefix:

```
https://app.fizzy.do/my/identity
https://app.fizzy.do/my/access_tokens
https://app.fizzy.do/my/pins
```

## Pagination

List endpoints return paginated results. When more results exist, the response includes a `Link` header:

```
Link: <https://app.fizzy.do/897362094/cards?page=2>; rel="next"
```

Follow `rel="next"` until no `Link` header is present. Pagination loop pattern:

```bash
URL="$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards"
while [ -n "$URL" ]; do
  RESPONSE=$(curl -s -D /tmp/fizzy-headers \
    -H "Authorization: Bearer $FIZZY_API_TOKEN" \
    -H "Accept: application/json" "$URL")
  echo "$RESPONSE" | jq '.[]'
  URL=$(grep -i '^link:' /tmp/fizzy-headers | sed -n 's/.*<\(.*\)>; rel="next".*/\1/p')
done
```

## Caching with ETags

Responses include `ETag` headers. Send `If-None-Match` to avoid re-downloading unchanged data:

```bash
# Returns 304 Not Modified if unchanged
curl -s -H "Authorization: Bearer $FIZZY_API_TOKEN" \
     -H "Accept: application/json" \
     -H "If-None-Match: \"abc123\"" \
     "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards/42"
```

## List parameters

Parameters accepting multiple values use `[]` suffix:

```
?tag_ids[]=id1&tag_ids[]=id2&board_ids[]=id3
```

## Error responses

| Status | Meaning |
|--------|---------|
| `400` | Malformed request or missing required parameters |
| `401` | Authentication failed or token invalid |
| `403` | Insufficient permission |
| `404` | Resource not found or inaccessible |
| `422` | Validation failed (details in body) |
| `429` | Rate limit exceeded |
| `500` | Server error |

Validation errors return JSON keyed by field name:

```json
{ "avatar": ["must be a JPEG, PNG, GIF, or WebP image"] }
```

## Full API reference

For complete endpoint details, request/response schemas, and parameter lists, see `docs/fizzy-api.md`.

## See also

- [board-management.md](./board-management.md) - Board CRUD operations
- [card-lifecycle.md](./card-lifecycle.md) - Card state transitions
- [api-recipes.md](./api-recipes.md) - Multi-step workflow scripts
