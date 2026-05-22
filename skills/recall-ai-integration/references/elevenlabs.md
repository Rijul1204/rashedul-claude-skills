# ElevenLabs — Voice (TTS) and Scribe (transcription)

The Meet integration crosses two vendor boundaries: Recall.ai (bot dispatch + webhooks) and ElevenLabs (TTS via `lib/meet/tts.ts`, optionally transcription via Recall's `recording_config.transcript.provider`). This reference covers the ElevenLabs side end-to-end.

Both surfaces share **one** ElevenLabs API key (`ELEVENLABS_API_KEY`) but the key's permission scope gates which surfaces work — see [auth-and-env.md](./auth-and-env.md).

## ElevenLabs Voice — TTS replacement for `/speak`

The current `lib/meet/tts.ts` calls OpenAI's `/v1/audio/speech` endpoint. The documented revisit trigger in `project-management/ai-secretary/meet-design.md` §9.2 is "swap to Cartesia / ElevenLabs when voice quality / cost becomes the constraint." This subsection covers the ElevenLabs swap.

### Endpoint

```
POST https://api.elevenlabs.io/v1/text-to-speech/{voice_id}
```

`{voice_id}` is a per-voice UUID-shaped ID from your ElevenLabs voice library. Pick once at config time; store in env (`ELEVENLABS_VOICE_ID` or similar) the way OpenAI TTS today picks `nova` from `MEET_TTS_VOICE`.

### Headers

```
xi-api-key: <ELEVENLABS_API_KEY>     // NOT Authorization: Bearer — gotcha #16
Content-Type: application/json
```

### Request body

```jsonc
{
  "text": "Hello, this is the assistant speaking.",      // required
  "model_id": "eleven_multilingual_v2",                  // default; "eleven_turbo_v2_5" for lower latency
  "language_code": "en",                                 // optional ISO 639-1; null → model decides
  "voice_settings": {                                    // optional; defaults shown
    "stability": 0.5,                                    // 0..1 — randomness vs. stability
    "similarity_boost": 0.75,                            // 0..1 — adherence to source voice
    "style": 0,                                          // 0..1 — style exaggeration
    "use_speaker_boost": true,
    "speed": 1.0                                         // speech rate multiplier
  }
}
```

Other optional fields exist (`seed`, `previous_text`, `next_text`, `pronunciation_dictionary_locators`, `apply_text_normalization`, `apply_language_text_normalization`); skip unless a concrete need shows up.

### Query params

```
?output_format=mp3_44100_128                             // default; safe for Recall /output_audio/
?enable_logging=false                                    // optional zero-retention mode
?optimize_streaming_latency=0..4                         // higher = faster, lower quality
```

For Recall's `/output_audio/` body (`{ kind: "mp3", b64_data }`), pick an `mp3_*` `output_format`. The base64-encoded payload must stay under Recall's 1.8 MB ceiling — `MAX_DECODED_BYTES ≈ 1_415_577 bytes` is already enforced in `tts.ts`; the same cap applies after a vendor swap.

**Tier-gated formats** (paid plan required):
- `mp3_44100_192` — Creator tier or above.
- All `pcm_44100`, `wav_44100` (44.1 kHz PCM/WAV) — Pro tier or above.

Stick with `mp3_44100_128` or lower unless you've confirmed the workspace tier.

### Response

| Status | Content-Type | Body |
|---|---|---|
| 200 | `application/octet-stream` | **Binary** audio stream (NOT JSON-wrapped). Read as `ArrayBuffer`, base64-encode for Recall. |
| 422 | `application/json` | `HTTPValidationError` — `{ detail: [...] }`. |
| 401 | `application/json` | API key invalid / wrong scope. |
| 429 | `application/json` | Rate-limited (tier-dependent). |

Mirror the existing `tts.ts` shape: throw `[meet-tts] ElevenLabs returned <status>: <truncated body>` on non-200, return `{ b64Mp3, byteCount }`.

### Swap impl sketch

Mirror `synthesizeSpeech` in `tts.ts` 1:1 — the consumer (`speak-handler.ts` → `bot-client.ts::pushAudio`) already takes `b64Mp3`, so the swap is contained to one file:

```ts
// [Doc check 2026-05-15: https://elevenlabs.io/docs/api-reference/text-to-speech/convert]
const res = await fetchImpl(
  `https://api.elevenlabs.io/v1/text-to-speech/${voiceId}?output_format=mp3_44100_128`,
  {
    method: "POST",
    headers: {
      "xi-api-key": apiKey,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ text, model_id: modelId }),
  },
);
if (!res.ok) {
  const errBody = await res.text();
  const truncated = errBody.length > 400 ? `${errBody.slice(0, 400)}…` : errBody;
  throw new Error(`[meet-tts] ElevenLabs returned ${res.status}: ${truncated}`);
}
const ab = await res.arrayBuffer();
const bytes = new Uint8Array(ab);
if (bytes.byteLength > MAX_DECODED_BYTES) { /* same cap as today */ }
return { b64Mp3: encodeBase64(bytes), byteCount: bytes.byteLength };
```

### Env required for the swap

- `ELEVENLABS_API_KEY` (with Voice / TTS access on the key's scope).
- `ELEVENLABS_VOICE_ID` (or hardcode at config time).
- Optional: `ELEVENLABS_MODEL_ID` overriding the default `eleven_multilingual_v2`.

`OPENAI_API_KEY` becomes optional once `synthesizeSpeech` no longer calls OpenAI — but leave it if any other code path (embeddings, etc.) still uses it.

`[Doc check 2026-05-15: https://elevenlabs.io/docs/api-reference/text-to-speech/convert]`

## ElevenLabs Scribe — transcription provider inside Recall

Recall accepts ElevenLabs Scribe as a drop-in for `meeting_captions`. The wire contract lives in `recording_config.transcript.provider` on `dispatchBot`; see [api-reference.md](./api-reference.md) "Alternate transcription providers" for the verbatim snippet.

### Provider keys (one of)

| Key | Use | `model_id` |
|---|---|---|
| `elevenlabs_streaming` | Real-time (`transcript.data` over the realtime webhook) | `"scribe_v2_realtime"` |
| `elevenlabs_async` | Post-meeting (single payload, not streamed) | `"scribe_v2"` |

`language_code` left unset → auto-detect with code-switching support. Per the live docs, "If `language_code` is unset, the model will detect the language automatically." This is the right choice for multilingual meetings (the 2026-05-13 Bangla mistranscription was the trigger for evaluating Scribe at all).

### What changes on the webhook side: **nothing**

The `transcript.data` payload shape on `/api/meet/webhook/realtime` is provider-agnostic — `words[].start_timestamp.relative`, `participant`, `language_code` are all the same. `webhook-handler.ts::handleTranscriptData` does not change.

Provider-specific data (confidence scores, alignment metadata, …) is delivered via a separate event subscription (`transcript.provider_data`). We do NOT subscribe to that today and the swap doesn't require it.

### What changes at bot-create: **one field**

`bot-client.ts::dispatchBot` body, line 209-211:

```jsonc
// before:
"transcript": { "provider": { "meeting_captions": {} } }

// after (real-time):
"transcript": { "provider": { "elevenlabs_streaming": { "model_id": "scribe_v2_realtime" } } }
```

That's it — same webhook URL, same events list, same metadata, same retries.

### Setup before the swap

1. Subscribe to ElevenLabs (any tier with Scribe access).
2. Generate an API key on the ElevenLabs side with **Speech-to-Text** permission scope. (A "default" key may only have TTS scope — see [gotchas.md](./gotchas.md) row 16.)
3. In the Recall dashboard transcription panel, register the key **in the same region** as `RECALL_API_BASE_URL`. Set Data Residency to match.
4. Verify: dispatch a sandbox bot, join a meeting, speak. If `transcript.data` events arrive on `/api/meet/webhook/realtime`, the registration is correct. If `bot.in_call_recording` fires but no transcripts arrive, suspect region mismatch ([gotchas.md](./gotchas.md) row 15) or scope mismatch (row 16).

`[Doc check 2026-05-15: https://docs.recall.ai/docs/elevenlabs]`

## Combined-swap order of operations

If you're doing BOTH swaps in one delivery (Voice for TTS + Scribe for transcription), run them as **two separate PRs**:

1. **PR 1 — Scribe.** Single-field change in `dispatchBot`, no UI surface, no `tts.ts` touch. Smaller blast radius, easier rollback.
2. **PR 2 — Voice TTS.** New `tts.ts` impl, env additions, speak-handler unchanged. Touches a hot path (mid-call audio); ship behind a quiet rollout.

Doing them simultaneously is technically possible but makes rollback ambiguous if transcripts AND speak both regress.

## Cross-references

- [api-reference.md](./api-reference.md) — Scribe verbatim snippet inside the alternate-providers subsection.
- [auth-and-env.md](./auth-and-env.md) — `ELEVENLABS_API_KEY` env entry, per-region transcription-key rule.
- [gotchas.md](./gotchas.md) — ElevenLabs-specific rows (#14 model_id mismatch, #15 per-region keys, #16 scope-gated key, #17 binary response, #18 tier-gated output formats).
- [workflow-feature.md](./workflow-feature.md) — full track for the swap (doc → probe → fixture → test → impl → gates → sandbox smoke).
