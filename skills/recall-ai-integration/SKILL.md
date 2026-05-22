---
name: recall-ai-integration
description: Meeting-bot vendor integration knowledge — Recall.ai (bot dispatch + webhooks) plus closely-coupled ElevenLabs surfaces (Scribe as Recall's transcription provider, Voice as the TTS swap target). Use when the user asks to touch, extend, debug, or explain anything that calls the Recall.ai or ElevenLabs API or handles their webhooks. Fires on Recall.ai terms (RECALL_API_KEY, in_call_recording, output_audio, send_chat_message, transcript.data, bot.in_call_recording, bot.in_waiting_room, bot.call_ended, bot.fatal, Svix signature, realtime endpoint, sandbox region, us-west-2.recall.ai), ElevenLabs terms (Scribe, Voice, elevenlabs_streaming, elevenlabs_async, scribe_v2, ELEVENLABS_API_KEY, xi-api-key, voice_id, eleven_multilingual_v2), and on any new code that dispatches a bot, pushes audio, sends a chat message, or ends a bot. Enforces docs→fixture→probe→code, tri-site nesting consistency, doc-check date stamps at every call site, spec-faithful webhook fixtures with at least two events, and your repo's standard quality gates.
---

# Recall.ai Integration

Recall.ai is a meeting-bot vendor — you dispatch a bot to a Google Meet / Zoom / Teams URL, it joins, captures audio + transcripts, accepts commands (speak, chat, leave), and webhooks you status + realtime events. This skill also covers two closely-coupled ElevenLabs surfaces — **Scribe** (Recall's `recording_config.transcript.provider` alternate to `meeting_captions`) and **Voice** (the documented TTS swap target) — because the wire-contract rules and quality gates apply identically and the swaps tend to live next to each other in the codebase.

**Why this skill exists.** Two real production incidents (May 2026) — `in_call_recording.data` was assumed to be a scalar when it's a nested object, and an OpenAI Realtime route 502'd because the session schema changed silently — both traced to the same root cause: code written from training-memory intuition instead of from a live doc read + sandbox probe. This skill exists so the next agent reads + probes before coding.

The skill is **modular**. The body below is a manifest; depth lives in [references/](./references/). Load only what the current task needs.

## Portability note

This skill was extracted from a Next.js + TypeScript codebase. The reference files cite example file paths (e.g. `lib/meet/bot-client.ts`, `app/api/meet/webhook/status/route.ts`, `synthesizeSpeech`, `MeetingBotClient`) to make the contracts concrete. **These are examples of where the vendor seam might live, not paths that need to exist in your repo.** Map them to your own structure as you read:

- "`MeetingBotClient`" / "`bot-client.ts`" → your single wrapper class around all Recall HTTP calls (so the documented Attendee fallback stays a one-class swap).
- "`synthesizeSpeech`" / "`lib/meet/tts.ts`" → your single seam for TTS (so the OpenAI ↔ ElevenLabs Voice swap is local).
- "`/api/meet/webhook/status`" / "`/api/meet/webhook/realtime`" → your two webhook routes for Recall's two channels.
- "`Personal_Docs/...`" prefixes → your app root.

The **vendor wire contracts, event shapes, gotchas, and methodology** are universally applicable — every Recall.ai + ElevenLabs integration hits the same constraints.

## Step 1 — Mode detection

Classify the request and announce the mode in one sentence before any tool call.

| Mode | Triggers | Track |
|---|---|---|
| **Feature/Modify** | "add Recall …", "extend speak", "wire up `bot.X` event", new endpoint method, new event subscription, new bot-create field | [references/workflow-feature.md](./references/workflow-feature.md) |
| **Bug-fix** | "speak 502", "transcript stalled", "Svix verify failing", "bot won't join", "404 on /output_audio/", "waiting room never resolves" | [references/workflow-bug-fix.md](./references/workflow-bug-fix.md) |
| **Question** | "how does …", "what does Recall send for …", "where is …" — no change requested | Question track (below) |

If ambiguous, ask which mode applies before continuing.

## Step 2 — Load references

Treat as progressive disclosure. Start with the always-load pair; pull others as the work expands.

### Always load (any non-trivial Recall touch)

- [architecture.md](./references/architecture.md) — two-channel webhook model, the single-client-seam pattern, where the vendor boundary lives.
- [gotchas.md](./references/gotchas.md) — catalog of the non-obvious things Recall has bitten integrators on.

### Load when touching an API call site

- [api-reference.md](./references/api-reference.md) — every endpoint we call, verbatim shapes, the tri-site nesting table, alternate-providers subsection.

### Load when touching webhook handling

- [webhooks.md](./references/webhooks.md) — `/status` vs `/realtime` side-by-side, event catalog, payload shapes, seq derivation, spec-faithful fixture worked example.

### Load when changing env vars, region, or transcription-provider keys

- [auth-and-env.md](./references/auth-and-env.md) — env matrix (Recall + ElevenLabs), channel-locked auth, per-region dashboard-key rule for third-party transcription providers.

### Load when touching ElevenLabs (Voice TTS swap, Scribe transcription swap)

- [elevenlabs.md](./references/elevenlabs.md) — both ElevenLabs surfaces (Voice for TTS, Scribe for transcription), with verbatim wire shapes, combined-swap order of operations, and env requirements.

### Load when adding a new endpoint method

- [recipes-add-endpoint.md](./references/recipes-add-endpoint.md) — multi-file change pattern, with `speak` and `chat` as worked examples.

### Load when refusing

- [refusals.md](./references/refusals.md) — hard-block list with rule citations.

## Step 3 — Follow the track

**Feature**: walk every phase in [workflow-feature.md](./references/workflow-feature.md). Hard-block phases cannot be skipped.

**Bug-fix**: walk every phase in [workflow-bug-fix.md](./references/workflow-bug-fix.md). All hard-block.

**Question**: read the file the user is asking about (don't summarize from memory). Cite specific paths and line numbers. Keep the answer terse. If the question turns into a change mid-conversation, restart from Step 1.

## Hard refusals (summary)

Full list with rule citations in [refusals.md](./references/refusals.md). Headlines:

- **No payload shapes from memory.** Every Recall call site carries `// [Doc check YYYY-MM-DD: <URL>]`. Fix path: read the live doc, probe sandbox, then code.
- **No tri-site asymmetry.** `in_call_recording.data` is **nested** `{ data: { kind, b64_data } }` at bot-create; `/output_audio/` is **flat** `{ kind, b64_data }` mid-call. Change one site → audit all three (`dispatchBot`, `pushAudio`, any handler that constructs the same shape).
- **No single-event webhook fixtures.** Recall's `transcript.data` carries cumulative semantics across events — single-event fixtures don't exercise the seq monotonic CAS and miss whole classes of bugs.
- **No cross-channel auth.** Svix on `/status` only; `?token=` on `/realtime` only. The auth schemes are channel-locked — different routes, different verifiers.
- **No inline `fetch` to Recall.** All calls go through your single bot-client class so the documented Attendee fallback stays a one-class swap. Likewise, all TTS calls go through your `synthesizeSpeech` seam — that's the OpenAI ↔ ElevenLabs Voice swap site.
- **No skipping pre-commit gates.** Whatever your repo's standard gates are (`lint`, `format:check`, `typecheck`, `knip` if configured, scoped tests), run them — no `--no-verify`, no rule loosening.

## Self-check before declaring done

- [ ] Mode declared (Feature / Bug-fix / Question).
- [ ] Right references loaded for the work.
- [ ] Hard-block phases of the chosen track all completed.
- [ ] Every new or modified Recall call site carries `// [Doc check YYYY-MM-DD: <URL>]` with today's date and a working `docs.recall.ai` URL.
- [ ] Webhook fixtures (if any) are spec-faithful: ≥2 events for `transcript.data`, double-nested envelope, real `start_timestamp.relative` values, full `metadata.userId`.
- [ ] Tri-site nesting audited if the change touched `in_call_recording` / `output_audio` / any field where create-time and mid-call shapes diverge.
- [ ] Quality gates green (lint, format:check, typecheck, knip if configured, scoped tests).
- [ ] Sandbox smoke documented (real bot dispatch end-to-end) if the change touched a live call site.

If any box is unchecked, you're not done. Loop back to the failing phase.
