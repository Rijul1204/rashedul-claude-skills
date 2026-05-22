# Architecture — Recall.ai + ElevenLabs integration shape

The Meeting Co-Pilot crosses two vendor boundaries: **Recall.ai** (bot dispatch + webhooks, the primary surface) and **ElevenLabs** (TTS via `lib/meet/tts.ts` after the documented swap from OpenAI, and optionally transcription via Recall's `recording_config.transcript.provider`). Both vendors share this skill's quality rules — docs → probe → fixture → TDD → date-stamp — because the same schema-drift class hit Recall on 2026-05-12 and OpenAI Realtime on 2026-05-13.

Recall pricing/billing is YAGNI; this skill is about wire contracts.

## Two-channel webhook model

Recall splits the events we care about across two routes with different auth schemes. The channels are locked — don't try to verify Svix on realtime or `?token=` on status.

| Channel | Route | Configured where | Auth | Events we subscribe to |
|---|---|---|---|---|
| **Status** | `Personal_Docs/app/api/meet/webhook/status/route.ts` | Recall dashboard (one URL + one signing secret per workspace) | Svix headers (`webhook-id` / `webhook-timestamp` / `webhook-signature`, with legacy `svix-*` fallback) verified against `MEET_WEBHOOK_SECRET` | `bot.in_call_recording`, `bot.in_waiting_room`, `bot.call_ended`, `bot.fatal` (others logged + ignored) |
| **Realtime** | `Personal_Docs/app/api/meet/webhook/realtime/route.ts` | Per-bot at create time via `recording_config.realtime_endpoints[]` in `dispatchBot` | `?token=…` query param (timing-safe-equal against `MEET_REALTIME_WEBHOOK_TOKEN`) | `transcript.data` only — `transcript.partial_data` is intentionally NOT subscribed in V1 (it overwrites with finalised text and causes visible flicker) |

If you find yourself adding a third route, stop — Recall delivers everything we care about through one of these two.

## Vendor seam — `MeetingBotClient`

The seam between the rest of the app and Recall lives at `Personal_Docs/lib/meet/bot-client.ts:146-151`:

```
export interface MeetingBotClient {
  dispatchBot(input: DispatchBotInput): Promise<{ botId: string }>;
  endBot(botId: string): Promise<void>;
  pushAudio(input: PushAudioInput): Promise<void>;
  sendChatMessage(input: SendChatMessageInput): Promise<void>;
}
```

Every Recall call goes through this interface. The runtime impl is `RecallBotClient` in the same file. Tests inject a fake.

The interface exists so that swapping the bot vendor (the documented Attendee fallback from `project-management/ai-secretary/meet-design.md` §9.2 — revisit when "Recall.ai's monthly bill or reliability becomes an issue") is **one new class implementing the same shape plus an env-var flip**. Inline `fetch` to Recall anywhere outside this class breaks that property silently.

## File map

| Concern | File |
|---|---|
| Vendor seam + Recall impl | `Personal_Docs/lib/meet/bot-client.ts` |
| Status webhook route | `Personal_Docs/app/api/meet/webhook/status/route.ts` |
| Realtime webhook route | `Personal_Docs/app/api/meet/webhook/realtime/route.ts` |
| Svix verifier | `Personal_Docs/lib/meet/svix-verify.ts` |
| Pure event handler logic | `Personal_Docs/lib/meet/webhook-handler.ts` |
| Bot dispatcher (callers of `dispatchBot`) | `Personal_Docs/lib/meet/dispatcher.ts` |
| `/api/meet/speak` route | `Personal_Docs/app/api/meet/speak/route.ts` + `speak-handler.ts` + `tts.ts` |
| `/api/meet/chat` route | `Personal_Docs/app/api/meet/chat/route.ts` + `chat-handler.ts` |
| SSE wake-up (sibling channel into the UI) | `Personal_Docs/lib/meet/listen-notify.ts` + `app/api/meet/stream/[botId]/route.ts` |
| Secretary tools that call into Meet | `packages/chat-agent-secretary/src/tools.ts` — `prepMeetingBriefing`, `sendAssistantToMeeting`, `speakInMeeting`, `sendChatInMeeting` |
| Env-var wiring | `Personal_Docs/CLAUDE.md` "Key Environment Variables" → Meeting Co-Pilot block |

## Request/event flow (happy path)

```
User clicks "Send assistant" in /chat
  └── secretary tool `sendAssistantToMeeting`
        └── lib/meet/dispatcher.ts
              └── RecallBotClient.dispatchBot(...)
                    POST {RECALL_API_BASE_URL}/api/v1/bot/
                      with metadata.userId + realtime_endpoints[?token=…]
                                                 │
                                                 ▼
                                       Recall provisions bot, joins meeting
                                                 │
                ┌────────────────────────────────┼────────────────────────────────┐
                ▼                                                                 ▼
       /api/meet/webhook/status                                      /api/meet/webhook/realtime
       (Svix-signed, dashboard)                                       (token in URL, per-bot)
                │                                                                 │
       bot.in_call_recording                                              transcript.data
       bot.in_waiting_room                                              (words[] with start_timestamp.relative)
       bot.call_ended                                                            │
       bot.fatal                                                                 ▼
                │                                                  webhook-handler.ts::applyChunkRaceFree
                ▼                                                  → jsonb_set CAS on agent_runs.lastChunkSeq
       webhook-handler.ts::handleMeetStatusEvent                  → appendBody to the transcript doc
       → mutates agent_runs.status / input / finalOutput          → publishWake(botId, seq) via pg LISTEN/NOTIFY
                                                                                 │
                                                                                 ▼
                                                                  SSE route fans out to open EventSources
                                                                  → live transcript panel in /[...slug]
```

Out-of-band: `/api/meet/speak` and `/api/meet/chat` are user-initiated mid-call POSTs that go through the **same** `MeetingBotClient` (`pushAudio` and `sendChatMessage`), not through webhooks. They're listed here because they're Recall calls too — and they're where the **tri-site nesting** rule applies (see [api-reference.md](./api-reference.md)).

## Sibling vendor — ElevenLabs

ElevenLabs is a second, closely-coupled vendor that the Meet integration touches at two surfaces:

| ElevenLabs surface | Where it shows up in the codebase | Wire contract reference |
|---|---|---|
| **Scribe (transcription)** | One-field swap inside `bot-client.ts::dispatchBot` body: `recording_config.transcript.provider = { elevenlabs_streaming: { model_id: "scribe_v2_realtime" } }`. The transcript output still arrives at our `/api/meet/webhook/realtime` route in the same `transcript.data` shape — Recall normalizes provider output before the webhook. | [elevenlabs.md](./elevenlabs.md) → "ElevenLabs Scribe — transcription provider inside Recall" |
| **Voice (TTS)** | A drop-in replacement for `synthesizeSpeech` in `Personal_Docs/lib/meet/tts.ts`. The downstream consumer (`speak-handler.ts` → `bot-client.ts::pushAudio`) is vendor-agnostic — it takes `b64Mp3` and posts to Recall's `/output_audio/`. The swap is contained to `tts.ts`. | [elevenlabs.md](./elevenlabs.md) → "ElevenLabs Voice — TTS replacement for `/speak`" |

Both surfaces share one `ELEVENLABS_API_KEY` but the key's permission scope determines which works — see [auth-and-env.md](./auth-and-env.md) → "ElevenLabs API key — scope gating".

## Invariants

- Every call site that crosses a vendor boundary (Recall **or** ElevenLabs — request OR response handling) carries `// [Doc check YYYY-MM-DD: <URL>]`. The stamp is how the next agent can tell at a glance whether the schema is stale. See repo-root `CLAUDE.md` § "READ THE VENDOR'S CURRENT DOCUMENTATION FIRST".
- Tenant scoping flows through `metadata.userId` echoed back on every webhook event; every DB write in the handler is inside `withTenant(userId, …)` so RLS holds.
- All vendor calls are server-only. API keys never reach the browser.
- Idempotency: webhook handlers are idempotent (doc-create checks first, seq CAS rejects out-of-order replays). Recall retries on 5xx — and the realtime channel retries up to 60 × 1 s before marking the endpoint dead.
- TTS calls go through `synthesizeSpeech` (the OpenAI-vs-ElevenLabs swap seam). No inline `fetch` to either TTS vendor outside `tts.ts`.
