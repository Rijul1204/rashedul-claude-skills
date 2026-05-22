# Workflow — Bug-fix track

Use this track when the user reports something broken in the Recall integration: a 502, a 4xx, a transcript that stalled, a Svix verifier rejecting valid payloads, a bot that won't join or won't leave.

All phases hard-block. The non-negotiable rule: **a Recall bug fix without a regression test invites the same bug back the next time the vendor schema drifts.**

## Phase 1 — Reproduce

Two acceptable forms of evidence:

- A failing vitest test that captures the bug.
- A real bot dispatch (sandbox) that exhibits the misbehavior end-to-end, with Vercel function logs / `agent_runs` row evidence captured.

If you cannot reproduce, say so. **Do not speculate-fix**. A speculative fix that "looks right" passes review and reintroduces the bug under a slightly different trigger — the 2026-05-12 nesting bug was exactly this shape.

For schema-drift suspicions: re-read the live Recall doc (`https://docs.recall.ai/docs/<topic>`) BEFORE writing the fix. If the docs disagree with the current call site, the docs are right.

## Phase 2 — Symptom → first-check table

| Symptom | Likely surface | First check |
|---|---|---|
| `dispatchBot` returns 4xx | `bot-client.ts:183` request body | Live-doc the create-bot endpoint. Check `in_call_recording.data` nesting ([gotchas.md](./gotchas.md) row 1); check `realtime_endpoints` spelling (row 3); check `silence_detection.activate_after >= 1` (row 9). |
| `pushAudio` returns 4xx | `bot-client.ts:265` request body | Flat shape `{ kind, b64_data }` at `/output_audio/` (row 2). Decoded body ≤1.35 MB (row 6). Bot was created with `automatic_audio_output` (row 11). |
| `sendChatMessage` returns 4xx | `bot-client.ts:286` request body | 500-char cap on Meet (row 7). Bot still in-call (status `bot.in_call_recording` not yet `bot.call_ended`). |
| Svix signature verification fails | `lib/meet/svix-verify.ts` | Headers may be the **legacy** `svix-*` or the Standard Webhooks `webhook-*` form — verifier accepts both. Body MUST be raw bytes from `await req.text()` — not `await req.json()` then re-stringified (signature is over the exact bytes). |
| Realtime route returns 401/403 | `app/api/meet/webhook/realtime/route.ts` | `?token=` query is the only auth on this route. `timingSafeEqual` requires equal-length buffers — check the secret didn't pick up a trailing newline. |
| Transcript stalled mid-meeting | `webhook-handler.ts::applyChunkRaceFree` + `listen-notify.ts` | Check `agent_runs.final_output.lastChunkSeq` is advancing. If yes, the CAS works and the issue is downstream (SSE / LISTEN-NOTIFY). If no, check the realtime route is reachable and not 60-retry-exhausted (row 12). `DATABASE_SESSION_URL` must point at the **session-mode** pooler, not transaction-mode — `LISTEN`/`NOTIFY` doesn't work on transaction-mode. |
| Bot stuck in waiting room past timeout | `webhook-handler.ts::handleBotCallEnded` + `mapCallEndedStatus` | 10-min timeout maps to `bot.call_ended` with `sub_code: "waiting_room_timeout"` → `agent_runs.status="failed"`, `error="host_did_not_admit"`. Verify the event arrived; verify `sub_code` matches the constant. |
| `endBot` returns 404 and surfaces as error | `bot-client.ts:259` | 404 means **already gone** — treat as success (row 10). If the code is raising, that's a regression of the success path. |
| Transcripts have no speaker name | `webhook-handler.ts:469` | `payload.participant.name` is null for guest participants → falls back to `Speaker <id>`. Confirm the fallback. |
| Bot dispatch silently succeeds but no transcripts | gotcha #3 + gotcha #15 + gotcha #16 | (a) `realtime_endpoints` (one word) typo'd as `real_time_endpoints`. (b) Third-party transcription key registered in the wrong Recall region. (c) ElevenLabs provider, wrong `model_id` for the endpoint (gotcha #14). (d) ElevenLabs API key missing Speech-to-Text scope (gotcha #16). |
| `synthesizeSpeech` (TTS) returns 401 against ElevenLabs | [elevenlabs.md](./elevenlabs.md) "Headers" + gotcha #19 | Header is `xi-api-key: <key>`, NOT `Authorization: Bearer …`. Check key scope (TTS vs. Speech-to-Text — gotcha #16). |
| `synthesizeSpeech` (TTS) throws JSON-parse against ElevenLabs | gotcha #17 | Response is binary `application/octet-stream`. Read via `await res.arrayBuffer()`, not `res.json()`. |
| ElevenLabs TTS returns 4xx for `output_format` | gotcha #18 | Tier-gated formats. `mp3_44100_192` requires Creator tier; PCM/WAV 44.1 kHz requires Pro. Default `mp3_44100_128` is safe on all tiers. |
| Production-only failure that didn't surface in tests | spec-faithful-fixture gap | The repo-root cautionary tale: a one-event fixture missed the cumulative-shape bug. Audit the fixture against the real wire shape and rebuild it with ≥2 events. |

## Phase 3 — Failing regression test

Convert the reproduction into a vitest test that fails for the right reason. Path mirrors the surface (same table as [workflow-feature.md](./workflow-feature.md) Phase 4).

If the bug surfaced because the existing fixture was happy-path-shaped, **expand the fixture** in the same commit — the new test pins both the fix and the better fixture.

## Phase 4 — Fix

Smallest patch that turns the regression test green. No surrounding cleanup.

If the bug is a **wire-shape** bug (Recall changed the schema, or our code drifted from the docs), the fix path is:

1. Re-read the live doc.
2. Probe sandbox with a fully-populated payload to confirm the right shape.
3. Translate that shape into the code.
4. Update the doc-check comment at the call site with today's date and the doc URL.

If the bug is a **logic** bug inside the handler (CAS condition wrong, branch missing, `userId` not pulled correctly), no doc-check update is needed — just the code fix.

If the bug is in `handleMeetStatusEvent` or `handleMeetRealtimeEvent` routing, prefer to fix at the pure handler (`webhook-handler.ts`) rather than the route — the route stays thin.

## Phase 5 — Tri-site audit (when applicable)

If the change touches `in_call_recording` / `output_audio` / any field where create-time and mid-call shapes diverge, audit all three sites in the same PR ([gotchas.md](./gotchas.md) row 1 + 2).

If the change touches `realtime_endpoints` / `recording_config.transcript.provider` / metadata field handling, audit `dispatchBot` AND the corresponding webhook handler branch — both sides of the same wire contract.

## Phase 6 — Quality gates (HARD-BLOCK)

Same as Feature Phase 8:

```
pnpm lint \
  && pnpm format:check \
  && pnpm typecheck \
  && pnpm -C Personal_Docs knip \
  && pnpm --filter "...[origin/main]" run test
```

No `--no-verify`. No "will fix in follow-up".

## Phase 7 — Sandbox smoke

Re-run the reproduction from Phase 1 end-to-end against sandbox. Confirm the bug is gone AND that nothing nearby regressed:

1. Dispatch a bot, join a real meeting.
2. Exercise the speak path and the chat path (both go through `MeetingBotClient` — a fix in one method can silently break the other if shared helpers moved).
3. Confirm both status webhooks (`bot.in_call_recording`, `bot.call_ended`) and realtime webhooks (`transcript.data`) land.
4. End the bot cleanly.

For Svix verifier fixes, send a malformed-signature request as well to confirm the 401 path still works (no auth-bypass regression).

## Phase 8 — Update gotchas / cautionary tale (when novel)

If the bug class was novel (not already in [gotchas.md](./gotchas.md)), add a row in the same PR. If the bug class is severe enough to be worth a tale-in-CLAUDE.md (a production hit, a schema-drift class, a silent-failure mode), draft the addition to repo-root CLAUDE.md and surface it in the PR description for the user's review — don't merge the CLAUDE.md edit unilaterally.

## Self-check before declaring done

- [ ] Mode declared (Bug-fix).
- [ ] Reproduction documented (failing test or sandbox smoke evidence).
- [ ] Regression test exists and fails before the fix, passes after.
- [ ] If wire-shape bug: live doc re-read; sandbox probed with full payload; doc-check comment updated with today's date.
- [ ] Tri-site audit done if `in_call_recording` / `output_audio` / sibling field touched.
- [ ] Quality gates green.
- [ ] Sandbox smoke covers the original bug AND adjacent endpoints (`speak`, `chat`, `endBot`).
- [ ] gotchas.md updated if the bug class was novel.
- [ ] Commit message names the gotcha or the doc URL — future agents grep for both.

If any box is unchecked, you're not done.
