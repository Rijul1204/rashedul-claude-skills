---
name: fizzy-write
description: >
  Create cards, create boards, update cards, close/reopen cards, add comments, assign users,
  or move cards to a column in Fizzy. Use when user says "create card", "create board",
  "add task to fizzy", "close fizzy card", "comment on fizzy card", "assign fizzy card",
  "move card to column", or anything involving writing to the Fizzy task board.
metadata:
  bashPattern:
    - "fizzy"
---

# Fizzy Write — Manage Cards & Boards

Create and manage cards, boards, comments, and assignments in the Fizzy task board.

## Credentials

**Bearer token**:

```text
eCaGiEZPirmuqVQwuNmCMNd6
```

**Account ID**: `6132669`
**Base URL**: `https://app.fizzy.do`

## Known Boards

| Board ID                    | Name        | Default? |
|-----------------------------|-------------|----------|
| 03fd4omd9qico7wmyyof5yfe4   | QA Board    | YES      |

> If the user names a specific board, resolve it by calling `GET /6132669/boards` and matching by name. Otherwise, always use the QA board.

## Workflow

### Step 1 — Parse the user's intent

Identify the operation:

| Intent                      | Operation         |
|-----------------------------|-------------------|
| "create a card / task"      | Create card       |
| "create a board"            | Create board      |
| "update / edit card #N"     | Update card       |
| "close / done card #N"      | Close card        |
| "reopen card #N"            | Reopen card       |
| "comment on card #N"        | Add comment       |
| "assign card #N to [user]"  | Assign            |
| "move card #N to [column]"  | Triage (move)     |
| "tag card #N with [tag]"    | Apply tag         |

For **create card**: extract title, optional description, optional board name (defaults to QA board).
For **create board**: extract board name and optional description.

> **IMPORTANT — Fizzy does NOT support Markdown.**
> Do not use `**bold**`, `# headers`, `- bullet` syntax, or any Markdown in card titles, descriptions, or comments.
> Use plain text with spacing and line breaks for structure. Example:
>
> ```
> Implementation notes:
>
>   - Check user region against Dots coverage map
>   - Block enrollment if region unsupported
>   - Show clear error message to player
> ```
>
> Use indentation and blank lines for readability — not Markdown syntax.

### Step 2 — Execute the API call

Use `curl` with the Bearer token. All endpoints are under `https://app.fizzy.do`.

#### Create card (on QA board by default)

```bash
curl -s -X POST "https://app.fizzy.do/6132669/boards/03fd4omd9qico7wmyyof5yfe4/cards" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer R2Rek4vNLSrr12F9QFkBy3BZ" \
  -H "Content-Type: application/json" \
  -d '{
    "card": {
      "title": "<TITLE>",
      "description": "<OPTIONAL_DESCRIPTION>"
    }
  }'
```

#### Create board

```bash
curl -s -X POST "https://app.fizzy.do/6132669/boards" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer R2Rek4vNLSrr12F9QFkBy3BZ" \
  -H "Content-Type: application/json" \
  -d '{
    "board": {
      "name": "<BOARD_NAME>",
      "description": "<OPTIONAL_DESCRIPTION>"
    }
  }'
```

#### List boards (to resolve a board name → ID)

```bash
curl -s "https://app.fizzy.do/6132669/boards" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer R2Rek4vNLSrr12F9QFkBy3BZ"
```

#### Update card

```bash
curl -s -X PUT "https://app.fizzy.do/6132669/cards/<CARD_NUMBER>" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer R2Rek4vNLSrr12F9QFkBy3BZ" \
  -H "Content-Type: application/json" \
  -d '{
    "card": {
      "title": "<NEW_TITLE>"
    }
  }'
```

#### Close card

```bash
curl -s -X POST "https://app.fizzy.do/6132669/cards/<CARD_NUMBER>/closure" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer R2Rek4vNLSrr12F9QFkBy3BZ" \
  -H "Content-Type: application/json"
```

#### Reopen card

```bash
curl -s -X DELETE "https://app.fizzy.do/6132669/cards/<CARD_NUMBER>/closure" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer R2Rek4vNLSrr12F9QFkBy3BZ"
```

#### Add comment

```bash
curl -s -X POST "https://app.fizzy.do/6132669/cards/<CARD_NUMBER>/comments" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer R2Rek4vNLSrr12F9QFkBy3BZ" \
  -H "Content-Type: application/json" \
  -d '{
    "comment": {
      "body": "<COMMENT_TEXT>"
    }
  }'
```

#### Assign user (toggle — assigns if unassigned, unassigns if already assigned)

```bash
curl -s -X POST "https://app.fizzy.do/6132669/cards/<CARD_NUMBER>/assignments" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer R2Rek4vNLSrr12F9QFkBy3BZ" \
  -H "Content-Type: application/json" \
  -d '{
    "assignee_id": "<USER_ID>"
  }'
```

#### Move card to column (triage)

```bash
curl -s -X POST "https://app.fizzy.do/6132669/cards/<CARD_NUMBER>/triage" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer R2Rek4vNLSrr12F9QFkBy3BZ" \
  -H "Content-Type: application/json" \
  -d '{
    "column_id": "<COLUMN_ID>"
  }'
```

> To resolve a column name → ID, first call `GET /6132669/boards/<BOARD_ID>/columns`.

#### Apply or remove tag

```bash
curl -s -X POST "https://app.fizzy.do/6132669/cards/<CARD_NUMBER>/taggings" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer R2Rek4vNLSrr12F9QFkBy3BZ" \
  -H "Content-Type: application/json" \
  -d '{
    "tag_title": "<TAG_TITLE>"
  }'
```

### Step 3 — Confirm or report error

**On success**:

- For card creation: confirm with card number and deep link:
  `https://app.fizzy.do/6132669/cards/<CARD_NUMBER>`
- For board creation: confirm with board name and deep link:
  `https://app.fizzy.do/6132669/boards/<BOARD_ID>`
- For other operations: confirm the action taken (e.g., "Card #42 closed.")

**On error** (non-2xx response or error field in JSON):

- Show the error message and suggest a fix (e.g., wrong card number, token expired)

## Pagination

List endpoints return paginated results with a `Link` header containing `rel="next"`. Follow the next link if you need all results and the response is paginated.
