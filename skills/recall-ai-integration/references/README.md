# Recall.ai Integration — References

Depth pages for the [recall-ai-integration](../SKILL.md) skill. Each file is loaded on demand based on what the current task touches.

## Files

| File | Load when… |
|---|---|
| [`architecture.md`](architecture.md) | Always (any non-trivial Recall touch) — two-channel webhook model, single-client-seam pattern, vendor boundary |
| [`gotchas.md`](gotchas.md) | Always — the catalog of non-obvious bites |
| [`api-reference.md`](api-reference.md) | Touching an API call site — verbatim endpoint shapes, tri-site nesting table |
| [`webhooks.md`](webhooks.md) | Touching webhook handling — `/status` vs `/realtime`, event catalog, spec-faithful fixtures |
| [`auth-and-env.md`](auth-and-env.md) | Changing env vars, region, or transcription-provider keys |
| [`elevenlabs.md`](elevenlabs.md) | Touching ElevenLabs (Voice TTS swap, Scribe transcription) |
| [`recipes-add-endpoint.md`](recipes-add-endpoint.md) | Adding a new endpoint method |
| [`workflow-feature.md`](workflow-feature.md) | Building a new feature against Recall — full TDD cadence |
| [`workflow-bug-fix.md`](workflow-bug-fix.md) | Fixing a Recall / ElevenLabs production bug |
| [`refusals.md`](refusals.md) | Hard-block list with rule citations |

## A note on the example codebase references

These files were extracted from a Next.js + TypeScript codebase. Citations like `lib/meet/bot-client.ts:230`, `Personal_Docs/app/api/meet/webhook/status/route.ts`, `synthesizeSpeech`, `MeetingBotClient`, or "the repo-root CLAUDE.md cautionary tale" point at that originating codebase — **they're concrete examples of where the vendor seam lives, not paths that must exist in your repo.** Map them to your own structure as you read.

The **vendor wire contracts, event shapes, gotchas, and methodology** are the portable value — every Recall.ai + ElevenLabs integration hits the same constraints regardless of host stack.

If a reference page cites a date-stamped incident (`2026-05-10`, `2026-05-12`, `2026-05-13`), it's a real cautionary tale from that codebase included verbatim because the teaching weight is in the specificity. The lesson generalizes; the file path doesn't.
