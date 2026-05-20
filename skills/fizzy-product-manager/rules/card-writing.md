---
name: card-writing
description: Best practices for writing effective card titles, descriptions, and rich text content
metadata:
  tags: cards, writing, titles, descriptions, rich-text, best-practices
---

## Title best practices

- **Use action-oriented language**: "Add dark mode toggle", "Fix login crash on iOS"
- **Keep it under 80 characters**: The title should be scannable in a board view
- **Use imperative tense**: "Add", "Fix", "Update", "Remove", "Investigate"
- **Include context when ambiguous**: "Fix login on iOS Safari" not just "Fix login"
- **Be specific**: "Reduce API response time for /cards endpoint" not "Performance improvements"

## Description best practices

- **Start with the "why"**: What problem does this solve? Why does it matter?
- **Include acceptance criteria**: How do we know this is done?
- **Link to context**: Reference prior discussions, designs, or related cards
- **Use formatting**: Bold for key points, lists for requirements

## Rich text HTML

Fizzy uses ActionText (Trix editor) and accepts **HTML only** in description and comment fields. **Markdown is not supported** — characters like `##`, `**`, and `- ` render as literal text.

```json
{
  "card": {
    "description": "<p>We need to <strong>reduce API latency</strong> for the cards endpoint.</p><h3>Acceptance Criteria</h3><ul><li>P95 latency under 200ms</li><li>No regression in accuracy</li></ul>"
  }
}
```

Supported tags: `<p>`, `<strong>`, `<em>`, `<ul>`, `<ol>`, `<li>`, `<a>`, `<h1>`-`<h3>`, `<blockquote>`, `<code>`, `<br>`. Nesting is supported (e.g., `<ul>` inside `<li>`).

### Reliable curl pattern for long descriptions

For card descriptions with special characters, quotes, or multi-line content, use the heredoc-to-jq-to-curl pattern:

```bash
source .env && cat <<'EOF' | jq -c '.' | curl -s -X POST \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d @- \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/boards/$BOARD_ID/cards"
{
  "card": {
    "title": "Card title here",
    "description": "<h2>What</h2><p>Description here...</p>"
  }
}
EOF
```

Key points:
- Quote the heredoc delimiter (`'EOF'`) to prevent shell variable expansion inside the JSON
- Pipe through `jq -c` to validate and compact the JSON
- Use `-d @-` to read the JSON body from stdin
- **Do not** use shell variables with `jq --arg` for long content — heredoc is more reliable

## Draft vs published

- `status: "drafted"` — Card is visible only to the creator. Use for incomplete ideas.
- `status: "published"` — Card is visible to everyone with board access. Default.

```bash
curl -s -X POST \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"card": {"title": "Idea: offline mode", "status": "drafted"}}' \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/boards/$BOARD_ID/cards"
```

## Updating a card

```bash
curl -s -X PUT \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"card": {"title": "Add dark mode toggle (v2)", "description": "<p>Updated scope to include system preference detection.</p>"}}' \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards/$CARD_NUMBER"
```

## See also

- [card-details.md](./card-details.md) - Adding steps, reactions, and pins to cards
- [card-lifecycle.md](./card-lifecycle.md) - Card state management
