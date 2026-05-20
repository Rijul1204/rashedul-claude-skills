---
name: webhooks-automation
description: Setting up webhooks for real-time automation and external integrations
metadata:
  tags: webhooks, automation, integration, real-time, events, notifications
---

Webhooks push real-time notifications to external URLs when events occur on a board. Only account admins can manage webhooks.

## List webhooks

```bash
curl -s -H "Authorization: Bearer $FIZZY_API_TOKEN" \
     -H "Accept: application/json" \
     "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/boards/$BOARD_ID/webhooks" \
  | jq '.[] | {id, name, active, subscribed_actions}'
```

## Create a webhook

```bash
curl -s -X POST \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "webhook": {
      "name": "Slack Notifications",
      "url": "https://hooks.slack.com/services/...",
      "subscribed_actions": ["card_closed", "card_auto_postponed", "comment_created"]
    }
  }' \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/boards/$BOARD_ID/webhooks"
```

Returns the webhook with a generated `signing_secret` for verification.

## Available actions

| Action | Fires when |
|--------|-----------|
| `card_assigned` | A user is assigned to a card |
| `card_unassigned` | A user is unassigned from a card |
| `card_published` | A new card is published |
| `card_triaged` | A card is moved into a column |
| `card_closed` | A card is marked done |
| `card_reopened` | A closed card is reopened |
| `card_postponed` | A card is manually moved to Not Now |
| `card_auto_postponed` | Entropy auto-postpones a card |
| `card_board_changed` | A card is moved to a different board |
| `card_sent_back_to_triage` | A card is sent back to Maybe? |
| `comment_created` | A new comment is posted |

## Update a webhook

The `url` is immutable after creation. Only name and subscribed_actions can be changed:

```bash
curl -s -X PATCH \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"webhook": {"subscribed_actions": ["card_closed", "card_auto_postponed"]}}' \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/boards/$BOARD_ID/webhooks/$WEBHOOK_ID"
```

## Reactivate a deactivated webhook

Fizzy deactivates webhooks after repeated delivery failures:

```bash
curl -s -X POST \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/boards/$BOARD_ID/webhooks/$WEBHOOK_ID/activation"
```

## Check delivery history

```bash
curl -s -H "Authorization: Bearer $FIZZY_API_TOKEN" \
     -H "Accept: application/json" \
     "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/boards/$BOARD_ID/webhooks/$WEBHOOK_ID/deliveries" \
  | jq '.[] | {state, event_action: .event.action, response_code: .response.code}'
```

## Signature verification

Verify webhook authenticity by computing HMAC-SHA256 of the request body with the `signing_secret`:

```ruby
expected = OpenSSL::HMAC.hexdigest("SHA256", signing_secret, request_body)
secure_compare(expected, request.headers["X-Webhook-Signature"])
```

## Automation ideas

- **Slack alert on auto-postpone** — Catch entropy early, decide if the card needs attention
- **CI trigger on triage to "Ship"** — Start deployment when a card enters the shipping column
- **Analytics logging on close** — Track velocity in an external dashboard
- **Alert on triage send-back** — Possible scope issue or blocked work

## Delete a webhook

```bash
curl -s -X DELETE \
  -H "Authorization: Bearer $FIZZY_API_TOKEN" \
  "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/boards/$BOARD_ID/webhooks/$WEBHOOK_ID"
```

## See also

- [entropy-management.md](./entropy-management.md) - Auto-postpone events
- [board-reports.md](./board-reports.md) - Activity reporting
