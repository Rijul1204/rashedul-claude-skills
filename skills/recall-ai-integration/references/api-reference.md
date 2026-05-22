# API reference — Recall.ai endpoints we call

Verbatim shapes copied from `Personal_Docs/lib/meet/bot-client.ts`. If anything here doesn't match the live `docs.recall.ai` page, the doc is right and this file is stale — fix this file in the same PR that updates the call site, and bump the doc-check date.

Auth on every call: header `Authorization: Token <RECALL_API_KEY>`, `Content-Type: application/json`.

Base URL: `${RECALL_API_BASE_URL}` (e.g. `https://us-west-2.recall.ai`). Region locked — see [auth-and-env.md](./auth-and-env.md).

## `POST /api/v1/bot/` — dispatch a bot

`bot-client.ts::dispatchBot` (line 183).

Request body:

```jsonc
{
  "meeting_url": "https://meet.google.com/abc-defg-hij",
  "bot_name": "Rashedul's AI Assistant",
  "metadata": { "userId": "<nanoid>", "calendarEventId": "<optional>" },
  "recording_config": {
    "realtime_endpoints": [                                  // ONE WORD. NOT real_time_endpoints (gotcha #3)
      {
        "type": "webhook",
        "url": "https://<host>/api/meet/webhook/realtime?token=<MEET_REALTIME_WEBHOOK_TOKEN>",
        "events": ["transcript.data"]                        // partial_data deliberately omitted (V1)
      }
    ],
    "transcript": {
      "provider": { "meeting_captions": {} }                 // current default — see alternates section below
    }
  },
  "automatic_leave": {
    "silence_detection": { "timeout": 300, "activate_after": 60 },  // activate_after >= 1 enforced by Recall
    "waiting_room_timeout": 600
  },
  "automatic_audio_output": {                                // unlocks mid-call /output_audio/ — required by Recall
    "in_call_recording": {                                   // !! NESTED: { data: { kind, b64_data } } !!
      "data": { "kind": "mp3", "b64_data": "<SILENT_MP3_B64>" }
    }
  }
}
```

Response: `{ id: "<botId>", … }` — we only consume `id`.

`[Doc check 2026-05-15: https://docs.recall.ai/docs/quickstart]`

## `POST /api/v1/bot/{id}/output_audio/` — mid-call audio

`bot-client.ts::pushAudio` (line 265).

Request body — **flat** at the top, no `data` wrapper:

```jsonc
{ "kind": "mp3", "b64_data": "<base64 mp3 payload>" }
```

Response: 200 OK on success.

`[Doc check 2026-05-15: https://docs.recall.ai/docs/quickstart]`

### Tri-site nesting table

Same payload fields, **different** nesting depending on where you send them:

| Site | File:line | Shape |
|---|---|---|
| Bot create (placeholder) | `bot-client.ts:230` `automatic_audio_output.in_call_recording` | `{ data: { kind, b64_data } }` — **nested** |
| Mid-call audio push | `bot-client.ts:275` `POST /output_audio/` body | `{ kind, b64_data }` — **flat** |
| Hypothetical third site | any future place we send audio | check the live doc; don't infer from siblings |

This nesting asymmetry caused a production 502 on 2026-05-12 (see [gotchas.md](./gotchas.md) row 1 + repo-root CLAUDE.md cautionary tale). Change one site → audit all three in the same PR.

## `POST /api/v1/bot/{id}/send_chat_message/` — chat message

`bot-client.ts::sendChatMessage` (line 286).

Request body:

```jsonc
{ "message": "<text, <=500 chars on Meet>", "to": "everyone" }
```

Response: 200 OK. We don't consume the body.

Caps: Meet caps chat at 500 chars; Zoom/Teams allow 4096. We cap at 500 universally for portability (`packages/chat-agent-secretary/src/tools.ts::sendChatInMeeting`).

`[Doc check 2026-05-15: https://docs.recall.ai/docs/sending-chat-messages]`

## `POST /api/v1/bot/{id}/leave_call/` — end the bot

`bot-client.ts::endBot` (line 250).

Request body: empty.

Response handling: 200 = asked Recall to leave; **404 = bot already gone** (race with manual removal or silence-timeout firing first) — both are acceptable terminal states. Surface only true failures.

`[Doc check 2026-05-15: https://docs.recall.ai/docs/quickstart]`

## Realtime endpoints field

`recording_config.realtime_endpoints[]` — note **one word, no underscore**. `real_time_endpoints` (with underscore) was the original placeholder name in early code and **Recall silently ignores it** — bot dispatches succeed but transcripts never arrive. See [gotchas.md](./gotchas.md) row 3.

Each element:

```jsonc
{
  "type": "webhook",
  "url": "<absolute URL with ?token=…>",
  "events": ["transcript.data"]            // partial_data NOT subscribed in V1
}
```

Recall retries failed deliveries up to **60 times at 1 s intervals** before marking the endpoint dead.

## Regions

| Region | Base URL |
|---|---|
| US East | `https://us-east-1.recall.ai` |
| US West | `https://us-west-2.recall.ai` |
| EU | `https://eu-central-1.recall.ai` |
| Asia Pacific | `https://ap-northeast-1.recall.ai` |

Region is locked to the workspace at sign-up. The wrong base URL surfaces as 401 (key from another region) or DNS failure — see [auth-and-env.md](./auth-and-env.md).

## Alternate transcription providers

`recording_config.transcript.provider` accepts one of several shapes. We ship `meeting_captions` today. This subsection documents the alternates so a future swap doesn't restart the docs read from scratch.

Provider keys (real-time):

| Key | Notes |
|---|---|
| `meeting_captions` | Current default. Empty config: `{}`. |
| `recallai_streaming` | Recall's own ASR. |
| `assembly_ai_v3_streaming` | AssemblyAI. |
| `deepgram_streaming` | Deepgram. |
| `aws_transcribe_streaming` | AWS Transcribe. |
| `rev_streaming` | Rev.ai. |
| `speechmatics_streaming` | Speechmatics. |
| `gladia_v2_streaming` | Gladia v2. |
| `elevenlabs_streaming` | ElevenLabs Scribe (real-time). |

Post-call equivalents take an `_async` suffix (e.g. `elevenlabs_async`).

ElevenLabs Scribe — canonical shape:

```jsonc
// Real-time:
"recording_config": {
  "transcript": {
    "provider": {
      "elevenlabs_streaming": { "model_id": "scribe_v2_realtime" }
    }
  }
}

// Post-call (separate from the realtime delivery the webhook receives):
"recording_config": {
  "transcript": {
    "provider": {
      "elevenlabs_async": { "model_id": "scribe_v2" }
    }
  }
}
```

Notes:

- `model_id` is **provider-specific and endpoint-specific**: `scribe_v2_realtime` for `_streaming`, `scribe_v2` for `_async`. They are NOT interchangeable — see [gotchas.md](./gotchas.md) row 14.
- `language_code` left unset → auto-detect (multilingual).
- The webhook payload shape (`transcript.data` with `words[].start_timestamp.relative`) is **provider-agnostic**: switching providers does not require touching `webhook-handler.ts::handleTranscriptData`.
- Third-party transcription API keys are configured in the Recall **transcription dashboard** and live **per Recall region** — see [auth-and-env.md](./auth-and-env.md). A key in the wrong region surfaces as a transcription failure on `bot.in_call_recording`, not at bot-create time.
- **Scope-locked**: this subsection is reference-only. No swap from `meeting_captions` is implied by listing them here. To swap, follow [workflow-feature.md](./workflow-feature.md).

`[Doc check 2026-05-15: https://docs.recall.ai/docs/elevenlabs]`
`[Doc check 2026-05-15: https://docs.recall.ai/docs/bot-real-time-transcription]`
`[Doc check 2026-05-15: https://docs.recall.ai/docs/multilingual-transcription]`
