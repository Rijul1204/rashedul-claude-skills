# Workflow — Feature / Modify track

Use this track when adding or modifying anything that crosses the Recall.ai vendor boundary: a new endpoint method, a new event subscription, a new field in `dispatchBot`, a transcription-provider swap, a webhook handler branch.

All hard-block phases below cannot be skipped. The order is non-negotiable: docs → probe → fixture → failing test → impl → gates → date-stamp.

## Phase 1 — Read live docs (HARD-BLOCK)

Open `https://docs.recall.ai/docs/<topic>` and read it, even if the schema "obviously" hasn't changed. Note today's date. **Do not** infer the shape from training memory, sibling endpoints, or "this is what it used to be" — see repo-root CLAUDE.md "READ THE VENDOR'S CURRENT DOCUMENTATION FIRST".

If the docs are auth-walled or you can't reach them, fall back to Phase 2 with a minimal probe, surface the validation errors, and iterate. **Document the doc URL you read** — it goes into the call-site comment in Phase 6 verbatim.

## Phase 2 — Probe sandbox (HARD-BLOCK)

Fire a real curl against the sandbox base URL with the API key. **Send a fully-populated payload** when you can — a "field is required" error only proves *presence* is missing, not whether the *type* you'd send next is also wrong (the 2026-05-12 lesson: the first probe surfaced only presence, the second probe surfaced the `data: nested object` requirement).

Capture the wire-shape response. If the endpoint takes a complex object (`recording_config`, `automatic_leave`), echo back a GET on the bot to confirm Recall accepted the fields the way you sent them — Recall silently drops unknown keys (see [gotchas.md](./gotchas.md) row 3).

## Phase 3 — Spec-faithful fixture (HARD-BLOCK)

Encode the captured shape in a fixture under `Personal_Docs/lib/meet/__tests__/` (or the matching path).

For **webhook fixtures**: build at least two events. `transcript.data` is cumulative-shape (seq monotonic CAS); a one-event fixture cannot exercise ordering / dedup. See [webhooks.md](./webhooks.md) "Spec-faithful fixture — worked example". For status events, pair the minimum useful set (`bot.in_waiting_room` → `bot.in_call_recording`, or `bot.in_waiting_room` → `bot.call_ended` with `sub_code: "waiting_room_timeout"`).

For **request fixtures**: fully-populated objects, not happy-path slices. The cautionary tale is `automatic_audio_output: { in_call_recording: { data: { kind, b64_data } } }` — a fixture that only built `automatic_audio_output: { in_call_recording: { kind, b64_data } }` would have hidden the production bug.

## Phase 4 — Failing test (HARD-BLOCK)

Red → green per the repo TDD cadence (see repo-root CLAUDE.md "Test-driven development"). Write the smallest test that fails for the right reason and run vitest to confirm. The test path mirrors the surface:

| Surface | Test path |
|---|---|
| `MeetingBotClient` request shapes | `Personal_Docs/lib/meet/__tests__/bot-client.test.ts` |
| Webhook event routing | `Personal_Docs/lib/meet/__tests__/webhook-handler.test.ts` |
| Svix verifier edge cases | `Personal_Docs/lib/meet/__tests__/svix-verify.test.ts` |
| Status route auth + JSON | `Personal_Docs/app/api/meet/webhook/status/__tests__/route.test.ts` |
| Realtime route auth + JSON | `Personal_Docs/app/api/meet/webhook/realtime/__tests__/route.test.ts` |
| `speak` / `chat` route handlers | `Personal_Docs/lib/meet/__tests__/speak-handler.test.ts`, `chat-handler.test.ts` |
| `synthesizeSpeech` (TTS — applies to OpenAI today and ElevenLabs Voice after the swap) | `Personal_Docs/lib/meet/__tests__/tts.test.ts` |
| DB-backed integration (active-bot query) | `Personal_Docs/lib/meet/__tests__/active-bot-query.integration.test.ts` |

Mocks: inject a fake `fetch` into `RecallBotClient` (the `RecallBotClientDeps.fetch` slot). Don't go through `globalThis.fetch` in tests — that re-runs all the network stack and makes the test flaky against real DNS.

## Phase 5 — Implementation behind the seam (HARD-BLOCK)

New requests go through `MeetingBotClient`. Add the method to the interface (`bot-client.ts:146-151`), implement on `RecallBotClient`, expose to the rest of the app through the existing dependency-injection pattern.

**No inline `fetch` to Recall** anywhere outside `bot-client.ts`. The vendor-swap revisit trigger (`meet-design.md` §7.2) depends on this property.

New event handlers go into `webhook-handler.ts` as a new branch or new exported function. Routes stay thin (auth + JSON-parse only).

If the change touches `in_call_recording` / `output_audio` / any field where create-time and mid-call shapes diverge, **audit all three sites** ([gotchas.md](./gotchas.md) row 1 + row 2) in the same PR.

## Phase 6 — Date-stamped doc comment (HARD-BLOCK)

Every new or modified Recall call site gets a code comment with today's date and the doc URL you read in Phase 1:

```ts
// [Doc check 2026-05-15: https://docs.recall.ai/docs/quickstart]
```

The comment goes immediately above the request body or the response-handling block, whichever is the wire-contact surface. Use the **exact** doc URL from the live docs — `git grep "[Doc check"` is how the next agent finds every staleness candidate in one pass.

Webhook handler branches get a stamp on the branch (status or realtime), not on every line.

## Phase 7 — Update gotchas / api-reference (if applicable)

If the change introduces a novel non-obvious behavior (a third nesting site, a new shape diff vs. existing endpoints, a new silent-failure mode), add a row to [gotchas.md](./gotchas.md) and update the relevant section in [api-reference.md](./api-reference.md) in the same PR. The skill loses its value if the catalog goes stale.

## Phase 8 — Quality gates (HARD-BLOCK)

The repo pre-commit checklist from repo-root CLAUDE.md:

```
pnpm lint \
  && pnpm format:check \
  && pnpm typecheck \
  && pnpm -C Personal_Docs knip \
  && pnpm --filter "...[origin/main]" run test
```

If you touched a root-level / shared file (root `package.json`, `pnpm-lock.yaml`, `pnpm-workspace.yaml`, root `tsconfig*.json`, `eslint.config.mjs`), run `pnpm -r run test` instead.

No `--no-verify`. No loosening a rule to make a check pass.

## Phase 9 — Sandbox smoke

Dispatch a real bot against the sandbox base URL end-to-end:

1. POST to `/api/meet/speak` (or your new endpoint).
2. Watch the bot's actions in a real meeting (join a personal Meet/Zoom/Teams).
3. Confirm status webhooks land (check `agent_runs` rows + Vercel function logs).
4. Confirm realtime webhooks land if the change touched transcript handling.
5. Confirm `endBot` cleanly stops the bot.

If you can't run a real meeting (no second account, no peer to join), say so explicitly in the PR description rather than claiming smoke success. Type checks and unit tests verify code correctness; they do not verify feature correctness — see repo-root CLAUDE.md "Browser smoke is mandatory for UI/SSR" and the parallel principle for vendor integrations.

## Phase 10 — Update `.spec.md` (when wire shape changed)

If the change shifts a wire shape (new field on `dispatchBot`, new event subscribed, new failure mode), update the co-located `.spec.md` in the same commit. The specs that exist today: `active-bot-query.spec.md`, `agent-run-final-output.spec.md`, `chat-handler.spec.md`, `outbound.spec.md`, `speak-handler.spec.md`, `summarise.spec.md`, `tts.spec.md`, and the route `route.spec.md` siblings.

## Self-check before declaring done

- [ ] Mode declared (Feature).
- [ ] Live doc read; URL captured; today's date stamped in the comment.
- [ ] Sandbox probe ran with fully-populated payload; response shape captured.
- [ ] Fixture is spec-faithful (≥2 events for webhook tests; fully-populated objects for request tests).
- [ ] Failing test ran red; impl made it green; refactor didn't break it.
- [ ] Implementation goes through `MeetingBotClient` (no inline Recall `fetch`).
- [ ] Tri-site nesting audited if `in_call_recording` / `output_audio` / sibling field touched.
- [ ] `// [Doc check YYYY-MM-DD: <URL>]` present at every new/modified call site.
- [ ] Quality gates green.
- [ ] Sandbox smoke documented (or explicit "smoke not possible because …").
- [ ] `.spec.md` updated if the wire shape changed.
- [ ] gotchas.md / api-reference.md updated if the change introduced novel non-obvious behavior.

If any box is unchecked, you're not done. Loop back.
