# Hard refusals — what the skill blocks and why

Refuse outright (and explain why) when the request or your own work product hits any of these. Each row cites the rule that codified it — naming the rule makes the refusal specific and actionable.

When refusing, say "I can't do this because <rule>; here's the alternative."

## Vendor-boundary refusals

| Refusal | Source | Alternative |
|---|---|---|
| **R1 — No payload shapes from training memory.** Writing a Recall request body or webhook handler without first reading the live `docs.recall.ai` page and probing sandbox is forbidden. | Repo-root `CLAUDE.md` → "READ THE VENDOR'S CURRENT DOCUMENTATION FIRST" (2026-05-12 + 2026-05-13 cautionary tales) | Read the live doc, probe sandbox with a fully-populated payload, capture the wire shape, then code. Every call site gets `// [Doc check YYYY-MM-DD: <URL>]`. |
| **R2 — No tri-site asymmetry.** Changing `in_call_recording.data` nesting at one site without auditing all three is forbidden. The shapes are: bot-create `automatic_audio_output.in_call_recording.data: { kind, b64_data }` (NESTED) vs. mid-call `/output_audio/` body `{ kind, b64_data }` (FLAT). | [gotchas.md](./gotchas.md) rows 1 + 2; 2026-05-12 production 502 | Audit all three sites in the same PR: `dispatchBot`, `pushAudio`, and any handler that constructs the same shape. |
| **R3 — No single-event webhook fixtures.** A unit test for `transcript.data` (or any cumulative-shape webhook) that builds a one-event fixture is forbidden. | Repo-root `CLAUDE.md` → "Test fixtures for browser / native APIs must be spec-faithful" (2026-05-10 Web Speech cautionary tale) | Build at least two events with monotonically increasing `start_timestamp.relative` values and exercise the seq monotonic CAS. See [webhooks.md](./webhooks.md) "Spec-faithful fixture — worked example". |
| **R4 — No cross-channel auth.** Verifying Svix on `/api/meet/webhook/realtime` or `?token=` on `/api/meet/webhook/status` is forbidden — the auth schemes are channel-locked. | `Personal_Docs/CLAUDE.md` → Meeting Co-Pilot webhook architecture table; [architecture.md](./architecture.md) | Use the right verifier for the route. If the auth you're reaching for doesn't match the route's existing scheme, you're on the wrong route. |
| **R5 — No inline `fetch` to Recall.** Calling `fetch(<recall-url>, …)` directly anywhere outside `Personal_Docs/lib/meet/bot-client.ts` is forbidden. | `meet-design.md` §7.2 vendor swap revisit trigger; `bot-client.ts:4-13` JSDoc | Add a method to `MeetingBotClient`, implement on `RecallBotClient`, inject the client through the existing dependency-injection pattern. See [recipes-add-endpoint.md](./recipes-add-endpoint.md). |
| **R5b — No inline `fetch` to a TTS vendor.** Calling `fetch(<openai-url>` or `fetch(<elevenlabs-url>` directly anywhere outside `Personal_Docs/lib/meet/tts.ts` is forbidden — `synthesizeSpeech` is the swap seam between OpenAI TTS today and ElevenLabs Voice after the documented swap. | `meet-design.md` §7.2 "Cartesia / ElevenLabs" revisit trigger; `tts.ts:1-16` JSDoc | Extend `synthesizeSpeech` or replace its body in-place. The consumer (`speak-handler.ts` → `pushAudio`) is vendor-agnostic — it only sees `{ b64Mp3, byteCount }`. See [elevenlabs.md](./elevenlabs.md). |

## Test / quality refusals

| Refusal | Source | Alternative |
|---|---|---|
| **R6 — No skipping the pre-commit gate set.** Bypassing with `--no-verify`, loosening a rule to make a check pass, or committing partial work with a "will fix in follow-up" note is forbidden. | Repo-root `CLAUDE.md` → "Pre-commit checklist (MANDATORY for Claude sessions)" | Run `pnpm lint && pnpm format:check && pnpm typecheck && pnpm -C Personal_Docs knip && pnpm --filter "...[origin/main]" run test`. Fix the underlying issue. |
| **R7 — No speculative fix without reproduction.** Fixing a Recall bug without first reproducing it (a failing test or a sandbox bot dispatch showing the misbehavior) is forbidden. | Repo-root `CLAUDE.md` → "Test-driven development"; [workflow-bug-fix.md](./workflow-bug-fix.md) Phase 1 | Reproduce. If reproduction isn't possible, say so explicitly and propose an investigation step instead of a code change. |
| **R8 — No fix without a regression test.** A Recall bug fix without a vitest regression test that fails before and passes after is forbidden. | Repo-root `CLAUDE.md` → "Test-driven development"; [workflow-bug-fix.md](./workflow-bug-fix.md) Phase 3 | Write the failing test first. If the bug is sandbox-only and untestable, document the gap in the PR description and rely on sandbox smoke — but the smoke evidence must be in the PR body. |

## Scope refusals

| Refusal | Source | Alternative |
|---|---|---|
| **R9 — No silent provider swaps.** Changing `recording_config.transcript.provider` from `meeting_captions` to a third-party provider (Scribe / Deepgram / Assembly / …) OR swapping `synthesizeSpeech` from OpenAI to ElevenLabs Voice without following [workflow-feature.md](./workflow-feature.md) end-to-end is forbidden — even if the wire shape "looks compatible". | Repo-root `CLAUDE.md` → "Per-feature override > global cap lift"; [gotchas.md](./gotchas.md) rows 14 + 15 + 16 + 17 + 18 | Run the full feature track: live doc read, sandbox probe, fixture, failing test, impl, gates, sandbox smoke. Provider keys are per-region, scope-gated, and per-`model_id`-vs-endpoint; all are silent-failure surfaces. If doing BOTH ElevenLabs swaps, ship as two PRs ([elevenlabs.md](./elevenlabs.md) "Combined-swap order of operations"). |
| **R10 — No undocumented gotcha additions.** Adding a new wire-contact behavior (third nesting site, new shape diff, new silent-failure mode) without updating [gotchas.md](./gotchas.md) and / or [api-reference.md](./api-reference.md) in the same PR is forbidden. | This skill's reason-to-exist | Add the row(s) in the same commit as the code change. The catalog only stays useful if every agent who learns something feeds it back in. |
| **R11 — No vendor-swap fantasies.** Introducing abstractions, registries, or feature flags to "support multiple bot vendors" before Attendee is a real second consumer is forbidden. | Repo-root `CLAUDE.md` → "Concrete-first beats registry-now"; `meet-design.md` §7.2 | The `MeetingBotClient` interface is the existing seam. When Attendee actually lands, extract a real second shape from two real consumers — not from one real shape and a hypothetical. |

## Out of session

If the user requests one of the above, refuse and name the rule + the file path. If the user pushes back ("just do it once, I'll fix later"), still refuse — the cost of the rule is much lower than the cost of re-litigation.

The exception is explicit one-time authorization for a specific deviation ("yes, skip the sandbox smoke for this fix, I'll smoke it myself before merging"). Document the deviation in the commit message + PR body and proceed.
