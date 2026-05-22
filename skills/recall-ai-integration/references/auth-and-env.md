# Auth and environment variables — Recall.ai

All four env vars are required for the Meeting Co-Pilot. Sandbox until S2a DoD, then prod handover. Documented verbatim in `Personal_Docs/CLAUDE.md` "Key Environment Variables" → Meeting Co-Pilot block; this file expands the why + the gotchas.

## Env matrix

| Var | Purpose | Source | Used where |
|---|---|---|---|
| `RECALL_API_KEY` | Workspace API key (sandbox or prod). Passed as `Authorization: Token <key>` on every `POST /api/v1/bot/*` call. | Recall dashboard → API Keys | `RecallBotClient.commonHeaders()` (`bot-client.ts:306`) |
| `RECALL_API_BASE_URL` | Regional base URL, e.g. `https://us-west-2.recall.ai`. **Must match the workspace's region** — see Regions below. | Recall dashboard (workspace metadata) | `RecallBotClient` constructor (`bot-client.ts:177`) |
| `MEET_WEBHOOK_SECRET` | `whsec_…` Svix signing secret. Verifies all `/api/meet/webhook/status` deliveries. | Recall dashboard → Webhooks → status endpoint signing secret | `lib/meet/svix-verify.ts::verifyRecallStatusWebhook`; route at `app/api/meet/webhook/status/route.ts` |
| `MEET_REALTIME_WEBHOOK_TOKEN` | Opaque random token spliced into per-bot realtime URLs as `?token=…`. Verifies all `/api/meet/webhook/realtime` deliveries via `timingSafeEqual`. | `openssl rand -base64 32` (we generate) | Embedded by `dispatcher.ts` into the URL it passes to `dispatchBot`; verified inline at `app/api/meet/webhook/realtime/route.ts` |
| `OPENAI_API_KEY` | TTS for `/api/meet/speak`. Used by `synthesizeSpeech` to call OpenAI's `/v1/audio/speech` and return a base64 mp3 the speak handler hands to `pushAudio`. Optional once swapped to ElevenLabs Voice (see below). | OpenAI dashboard | `Personal_Docs/lib/meet/tts.ts` |
| `ELEVENLABS_API_KEY` | ElevenLabs Voice (TTS) and/or Scribe (transcription). Header is `xi-api-key: <key>` (NOT `Authorization: Bearer`). **Permission scope on the key matters** — Voice needs TTS scope, Scribe needs Speech-to-Text scope. A "default" key may have only one. | ElevenLabs dashboard → API Keys | `Personal_Docs/lib/meet/tts.ts` (after Voice swap); Recall dashboard transcription panel (Scribe registration) |
| `ELEVENLABS_VOICE_ID` | Per-voice UUID-shaped ID from your ElevenLabs voice library. Required when calling `POST /v1/text-to-speech/{voice_id}`. | ElevenLabs dashboard → Voice Library | `tts.ts` after Voice swap |
| `ELEVENLABS_MODEL_ID` (optional) | Overrides the default `eleven_multilingual_v2`. Use `eleven_turbo_v2_5` for lower latency, `eleven_multilingual_v2` for quality. | n/a (env override only) | `tts.ts` after Voice swap |

## Channel-locked auth

The two webhook routes have **different verifiers** and **the schemes do not interchange**. Trying to verify Svix on the realtime route fails (no signing headers — token is in the URL). Trying to verify the token on the status route fails (no `?token=` — Svix puts the secret in the headers).

If you're in a verifier and the auth method doesn't look right for the route, you're either on the wrong route or you've confused the channels. See [architecture.md](./architecture.md) "Two-channel webhook model".

## Sandbox vs prod

| Env | `RECALL_API_BASE_URL` | `RECALL_API_KEY` | Dashboard |
|---|---|---|---|
| Sandbox | regional sandbox URL (TLD may differ; check current docs) | sandbox key | Sandbox workspace, separate signing secret |
| Prod | regional prod URL | prod key | Prod workspace, separate signing secret |

`MEET_WEBHOOK_SECRET` differs per workspace. **Don't reuse** sandbox secrets in prod — the signing key is the only thing standing between the route and a spoofed event. `MEET_REALTIME_WEBHOOK_TOKEN` is ours and can be rotated independently; rotation requires re-dispatching live bots (the token is baked into their realtime URL at create time).

Handover steps when moving from sandbox to prod:

1. Update `RECALL_API_KEY` and `RECALL_API_BASE_URL` in Vercel project env (Production scope).
2. Create the prod webhook in the prod Recall dashboard; copy its `whsec_…` into `MEET_WEBHOOK_SECRET`.
3. Generate a fresh `MEET_REALTIME_WEBHOOK_TOKEN` for prod (don't reuse sandbox).
4. Re-deploy. The next bot dispatch picks up the new env. Existing sandbox bots stay on sandbox (different base URL).

## Regions

Recall workspaces are region-locked at sign-up. The available regions:

| Region | Base URL |
|---|---|
| US East | `https://us-east-1.recall.ai` |
| US West | `https://us-west-2.recall.ai` |
| EU | `https://eu-central-1.recall.ai` |
| Asia Pacific | `https://ap-northeast-1.recall.ai` |

The `RECALL_API_BASE_URL` must match the workspace's region. Mismatched URL surfaces as 401 ("invalid API key" — the key is workspace-scoped) or DNS failure if the URL is malformed.

## Third-party transcription-provider keys

When `recording_config.transcript.provider` is **not** `meeting_captions` (i.e. you're using `elevenlabs_streaming`, `assembly_ai_v3_streaming`, `deepgram_streaming`, …), the third-party provider's API key is **separate from `RECALL_API_KEY`** and lives in the Recall dashboard's transcription-keys panel.

Key invariants:

- **Per-region storage.** Third-party transcription keys are scoped to a single Recall region. A key registered in `us-east-1` is **invisible** to a `us-west-2` workspace. When switching regions or testing cross-region, re-register the key in the target region — see [gotchas.md](./gotchas.md) row 15.
- **Failure timing.** A missing or wrong-region key surfaces as a transcription auth error on `bot.in_call_recording` (the bot joins, but no `transcript.data` events arrive), NOT at bot-create time. `dispatchBot` returns 200 OK either way — the provider key is only exercised once the bot starts recording.
- **ElevenLabs Scribe specifically** requires the API key to have **Speech-to-Text** access permission. ElevenLabs API keys are scope-gated; the default key may only have TTS, in which case transcription silently fails.
- **No way to inspect from code.** The keys are dashboard-only; there is no `/api/v1/transcription-keys` endpoint we use. If a transcription run silently fails, the dashboard is the first place to look.

`[Doc check 2026-05-15: https://docs.recall.ai/docs/elevenlabs]`

## ElevenLabs API key — scope gating

Both ElevenLabs surfaces (Voice TTS via `tts.ts`, Scribe transcription via Recall config) share **one** `ELEVENLABS_API_KEY`, but the key's permission scope determines which surfaces work:

| Surface | Required scope on the API key |
|---|---|
| Voice (TTS) — `POST /v1/text-to-speech/{voice_id}` | Text-to-Speech access |
| Scribe (transcription) — registered in Recall dashboard | Speech-to-Text access |

A single key can hold both scopes; create or update the key in the ElevenLabs dashboard's API Keys panel. Symptoms of a scope mismatch:

- **Voice without TTS scope** → `401` from the direct `api.elevenlabs.io` call. `synthesizeSpeech` throws `[meet-tts] ElevenLabs returned 401: …`.
- **Scribe without Speech-to-Text scope** → bot dispatches succeed; `bot.in_call_recording` fires; no `transcript.data` events arrive. Identical symptom to a wrong-region key (`auth-and-env.md` → "Third-party transcription-provider keys") and to a `realtime_endpoints` typo ([gotchas.md](./gotchas.md) row 3); the Recall dashboard transcription panel is the only place to see the actual auth failure.

See [elevenlabs.md](./elevenlabs.md) for the full ElevenLabs surface reference.

`[Doc check 2026-05-15: https://elevenlabs.io/docs/api-reference/text-to-speech/convert]`
