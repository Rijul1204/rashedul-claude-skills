---
name: column-structure
description: Designing and managing board columns for effective workflow stages
metadata:
  tags: columns, workflow, stages, organization, color, patterns
---

## List columns

```bash
curl -s -H "Authorization: Bearer $FIZZY_API_TOKEN" \
     -H "Accept: application/json" \
     "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/boards/$BOARD_ID/columns" | jq '.[] | {name, id}'
```

Columns are returned sorted by position.

## Create a column

```bash
curl -s -X POST \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"column": {"name": "In Progress", "color": "var(--color-card-4)"}}' \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/boards/$BOARD_ID/columns"
```

## Available colors

| Value | Label |
|-------|-------|
| `var(--color-card-default)` | Blue |
| `var(--color-card-1)` | Gray |
| `var(--color-card-2)` | Tan |
| `var(--color-card-3)` | Yellow |
| `var(--color-card-4)` | Lime |
| `var(--color-card-5)` | Aqua |
| `var(--color-card-6)` | Violet |
| `var(--color-card-7)` | Purple |
| `var(--color-card-8)` | Pink |

Use color to visually distinguish workflow stages. Example: Blue for "To Do", Lime for "In Progress", Aqua for "Review".

## Common workflow patterns

**Simple (3 columns)**:
- To Do → In Progress → Ready to Ship

**Feature-driven (5 columns)**:
- Discovery → Design → Build → Test → Ship

**Cycle-based (3 columns)**:
- This Cycle → Next Cycle → Shipped

## Design guidelines

- **Keep it to 3-5 columns.** More than 5 creates confusion and dilutes focus.
- **Name columns by what work looks like in that stage**, not who does it.
- **Columns are separate from the card lifecycle.** Cards in "Maybe?" (triage), "Not Now", and "Done" are NOT in columns. Columns are for active, triaged work only.
- **Delete empty columns** that are no longer part of the workflow to reduce noise.

## Update a column

```bash
curl -s -X PUT \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"column": {"name": "Code Review", "color": "var(--color-card-6)"}}' \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/boards/$BOARD_ID/columns/$COLUMN_ID"
```

## Delete a column

```bash
curl -s -X DELETE \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/boards/$BOARD_ID/columns/$COLUMN_ID"
```

## See also

- [card-triage.md](./card-triage.md) - How cards enter columns via triage
- [wip-limits.md](./wip-limits.md) - Setting WIP limits per column
- [board-hygiene.md](./board-hygiene.md) - Cleaning up empty columns
