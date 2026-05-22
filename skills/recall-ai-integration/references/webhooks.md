# Webhooks — `/status` and `/realtime` side-by-side

Two routes, two auth schemes, two payload shapes. Don't try to cross-pollinate. The pure event-routing logic lives in `Personal_Docs/lib/meet/webhook-handler.ts` — the routes are thin auth + JSON-parse wrappers.

## At a glance

| Aspect | `/api/meet/webhook/status` | `/api/meet/webhook/realtime` |
|---|---|---|
| Configured | Recall dashboard, **global** | Per-bot via `recording_config.realtime_endpoints` |
| Auth | Svix signature on headers, secret `MEET_WEBHOOK_SECRET` (`whsec_…`) | `?token=` query param, secret `MEET_REALTIME_WEBHOOK_TOKEN`, timing-safe compare |
| Verifier | `lib/meet/svix-verify.ts::verifyRecallStatusWebhook` | inline `timingSafeEqual` in route |
| Subscribed events | `bot.in_call_recording`, `bot.in_waiting_room`, `bot.call_ended`, `bot.fatal` | `transcript.data` only — `partial_data` deliberately omitted |
| Retry policy | Recall retries 5xx (standard webhook backoff) | 60 × 1 s, then endpoint marked dead |
| Idempotency | Doc-create checks existence first; status updates are conditional | seq monotonic CAS via `jsonb_set` against `agent_runs.final_output.lastChunkSeq` |

## Status payload — double-nested

Recall envelopes status events as:

```jsonc
{
  "event": "bot.in_call_recording",
  "data": {
    "data": {                                  // <-- per-event payload (double nesting)
      "code": "in_call_recording",
      "sub_code": null,
      "updated_at": "2026-05-15T19:01:02.345Z"
    },
    "bot": {
      "id": "<botId>",
      "metadata": { "userId": "<nanoid>", "calendarEventId": "<optional>" }
    }
  }
}
```

Notable fields:

| Field | Meaning |
|---|---|
| `event` | Discriminator at the top level. Switch on this. |
| `data.data.sub_code` | Reason qualifier on `bot.call_ended` — `"waiting_room_timeout"` is the one we route on (host_did_not_admit mapping). Often null on other events. |
| `data.bot.id` | Recall's bot UUID. Match to `agent_runs.input.botId`. |
| `data.bot.metadata.userId` | **Required for tenant scoping.** Missing → handler throws → route 400. Always echoed back from `dispatchBot`'s `metadata` argument. |

### Event handler matrix

`lib/meet/webhook-handler.ts::handleMeetStatusEvent` routes by `event` name:

| Event | Action |
|---|---|
| `bot.in_call_recording` | Idempotent transcript-doc create (`createDocument` keyed by deterministic `documentId`); clear `agent_runs.input.inWaitingRoomSince` if present. |
| `bot.in_waiting_room` | Stamp `agent_runs.input.inWaitingRoomSince = now`. Drives the "Bot is in the waiting room" empty state and the downstream `host_did_not_admit` mapping. |
| `bot.call_ended` | Terminal status via `mapCallEndedStatus({ subCode, lastSeq, wasInWaitingRoom })` — direct map on `sub_code="waiting_room_timeout"`, otherwise inferred from accumulated state. Fires post-meeting summary via `after()` only if mapped to `completed`. |
| `bot.fatal` | `agent_runs.status = "failed"`, `error = "bot_fatal[:sub_code]"`. |
| anything else | Logged, no-op. |

## Realtime payload — `transcript.data`

```jsonc
{
  "event": "transcript.data",
  "data": {
    "data": {
      "words": [
        { "text": "Hello", "start_timestamp": { "relative": 12.034 }, "end_timestamp": { "relative": 12.5 } },
        { "text": "world", "start_timestamp": { "relative": 12.6 }, "end_timestamp": { "relative": 13.1 } }
      ],
      "language_code": "en",
      "participant": { "id": 42, "name": "Alice", "is_host": false }
    },
    "bot": {
      "id": "<botId>",
      "metadata": { "userId": "<nanoid>", "calendarEventId": "<optional>" }
    }
  }
}
```

Notable fields:

| Field | Meaning |
|---|---|
| `words[]` | The finalised utterance, broken into words. Always non-empty in a real delivery; empty array is logged + ignored. |
| `words[i].start_timestamp.relative` | **Seconds** (float) since recording start. Multiply by 1e6 for the microsecond seq we store as `lastChunkSeq`. |
| `participant.name` | Speaker label; falls back to `Speaker <id>` when null. |
| `data.bot.metadata.userId` | Required, same as status — tenant scoping. |

### Seq derivation

```
seq = Math.floor(words[0].start_timestamp.relative * 1_000_000)
```

`lib/meet/webhook-handler.ts::handleTranscriptData` line 467. Monotonic per `(bot, utterance)`. Two speakers starting at the same microsecond is the only collision risk and would drop the second utterance — acceptable for V1.

### Race-free apply

`applyChunkRaceFree` uses a CAS pattern via `jsonb_set`:

```sql
UPDATE agent_runs
SET final_output = jsonb_set(coalesce(final_output, '{}'::jsonb),
                             '{lastChunkSeq}', to_jsonb(<new seq>::bigint))
WHERE id = <runId>
  AND user_id = <userId>
  AND coalesce((final_output->>'lastChunkSeq')::bigint, 0) < <new seq>
RETURNING id
```

Returns 0 rows when the seq has already been seen → idempotent retry path. Returns 1 row → append-body + `publishWake(botId, seq)` over Postgres `LISTEN`/`NOTIFY` so the SSE route wakes any open EventSource.

## Spec-faithful fixture — worked example

The webhook-test fixture rule from the repo-root CLAUDE.md applies here. When unit-testing a transcript handler, **build at least two events** with monotonically increasing `start_timestamp.relative` values, exercising the seq CAS. A one-event fixture cannot catch ordering bugs.

```ts
const event1: RealtimeTranscriptBody = {
  event: "transcript.data",
  data: {
    data: {
      words: [
        { text: "Hello", start_timestamp: { relative: 1.0 }, end_timestamp: { relative: 1.5 } },
      ],
      participant: { id: 1, name: "Alice", is_host: false },
    },
    bot: { id: "bot_abc", metadata: { userId: "user_xyz" } },
  },
};

const event2: RealtimeTranscriptBody = {
  event: "transcript.data",
  data: {
    data: {
      words: [
        { text: "world", start_timestamp: { relative: 2.0 }, end_timestamp: { relative: 2.5 } },
      ],
      participant: { id: 2, name: "Bob", is_host: false },
    },
    bot: { id: "bot_abc", metadata: { userId: "user_xyz" } },
  },
};

// Test must exercise BOTH:
// - event1 then event2 → both applied (seq advances 1_000_000 → 2_000_000)
// - event2 then event1 → only event2 applied (seq=2_000_000 wins; event1.seq=1_000_000 rejected)
// - event1 then event1 → only first applied (CAS rejects duplicate)
```

A single-event fixture would let a `seq` regression slip through. See [gotchas.md](./gotchas.md) row 5 and the repo-root CLAUDE.md cautionary tale (Web Speech 2026-05-10).

## Status fixture — pair the events too

Same rule for status: a fixture that only sends `bot.in_call_recording` doesn't exercise the `inWaitingRoomSince` clear path. The minimum useful pair is `bot.in_waiting_room` → `bot.in_call_recording`. The minimum useful triple to cover `host_did_not_admit` is `bot.in_waiting_room` → `bot.call_ended` with `sub_code: "waiting_room_timeout"`.

## Header-name fallback (Svix)

Recall delivers via Svix using the **Standard Webhooks** header names (`webhook-id`, `webhook-timestamp`, `webhook-signature`). The verifier (`lib/meet/svix-verify.ts::extractSvixHeaders`) also accepts legacy `svix-*` names. If you're rolling a fixture, use `webhook-*` — that's what real Recall deliveries send (verified during Sprint 2a smoke).

`[Doc check 2026-05-15: https://docs.recall.ai/docs/real-time-webhook-endpoints]`
`[Doc check 2026-05-15: https://docs.recall.ai/docs/bot-real-time-transcription]`
