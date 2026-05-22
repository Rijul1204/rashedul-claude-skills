# Recipe — add a new Recall endpoint method

Use this recipe when extending `MeetingBotClient` with a new method that calls a Recall endpoint we haven't called before (e.g. "send a reaction emoji", "update bot name mid-call", "request a participant list").

The worked example throughout is the **speak / chat pair** (the existing `pushAudio` + `sendChatMessage` methods) — a six-file change pattern. Mirror it.

## Step 1 — Read the live Recall doc

`https://docs.recall.ai/docs/<topic>`. Capture today's date and the URL — you'll embed both in the code comment in step 4.

If the docs page covers multiple endpoints (`/api/v1/bot/{id}/<verb>/`), copy the exact request body shape and response shape into a scratch buffer. **Don't** infer the shape from sibling endpoints — see [gotchas.md](./gotchas.md) row 1 (the 2026-05-12 nesting tale).

## Step 2 — Probe sandbox

Fire one curl against the sandbox base URL with the API key. Send a **fully-populated** payload. Capture the wire-shape response.

If the endpoint takes a complex object and you're unsure of a field's type, just send what you'd actually send and let the validation error name the type — that's faster than guessing and surfaces the type mismatch the way the 2026-05-12 probe did on its second try.

## Step 3 — Add the input shape + method to the interface

File: `Personal_Docs/lib/meet/bot-client.ts`.

Add a `<Verb>Input` interface modeled on the existing `PushAudioInput` / `SendChatMessageInput` patterns. Carry `botId` plus the wire fields. Use JSDoc to capture preconditions / caps (analogous to "≤500 chars enforced by the caller" on `SendChatMessageInput.message`).

Add the method to the `MeetingBotClient` interface:

```ts
export interface MeetingBotClient {
  dispatchBot(input: DispatchBotInput): Promise<{ botId: string }>;
  endBot(botId: string): Promise<void>;
  pushAudio(input: PushAudioInput): Promise<void>;
  sendChatMessage(input: SendChatMessageInput): Promise<void>;
  reactInMeeting(input: ReactInput): Promise<void>;   // <-- new
}
```

## Step 4 — Implement on `RecallBotClient` with a date-stamped comment

```ts
async reactInMeeting(input: ReactInput): Promise<void> {
  // [Doc check 2026-05-15: https://docs.recall.ai/docs/<topic>]
  // Wire shape: { emoji: "<unicode>", target?: { participantId } }
  const res = await this.fetchImpl(
    `${this.deps.apiBaseUrl}/api/v1/bot/${input.botId}/<verb>/`,
    {
      method: "POST",
      headers: this.commonHeaders(),
      body: JSON.stringify({ emoji: input.emoji /* … */ }),
    },
  );
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`[recall-bot-client] reactInMeeting ${input.botId} failed (${res.status}): ${text}`);
  }
}
```

Mirror the error-message format from the existing methods so log greps stay consistent (`[recall-bot-client] <method> <botId> failed (<status>): <text>`).

## Step 5 — Update fake clients used in tests

Search for places that implement `MeetingBotClient`:

```
rg -n 'implements MeetingBotClient|: MeetingBotClient =' Personal_Docs/
```

You'll typically find:

- `Personal_Docs/lib/meet/__tests__/bot-client.test.ts` — uses an injected fake `fetch` against the real class (`RecallBotClient`). No interface change needed; just add a test case.
- `Personal_Docs/lib/meet/__tests__/<other>-handler.test.ts` — these often use an inline `FakeMeetingBotClient` object literal that satisfies the interface. **Add a stub method** with the same signature; missing methods now fail typecheck.

Also `rg -n 'MeetingBotClient' packages/` to catch any package-level fake (e.g. `packages/chat-agent-secretary/src/__tests__/tools.test.ts` references the secretary's `prepMeetingBriefing` tools, which indirectly take a `MeetingBotClient`).

## Step 6 — Add the failing unit test

`Personal_Docs/lib/meet/__tests__/bot-client.test.ts`. Inject a fake `fetch` and assert:

1. URL is `${base}/api/v1/bot/${botId}/<verb>/`.
2. Headers carry `Authorization: Token <key>` and `Content-Type: application/json`.
3. Body matches the wire shape from step 1, **exactly** — including any nesting.
4. 4xx response paths surface a useful error (`includes(<status>)` + `includes(<body>)`).

Run vitest and confirm the test fails for the right reason.

## Step 7 — Make it green

Now the impl from step 4 should make the test green.

## Step 8 — Extend or add a thin route (if user-facing)

If callers outside `lib/meet/` need to invoke the new method (e.g. a secretary tool, a UI button on `/calendar`), extend an existing route or add a new one under `app/api/meet/`. Mirror the `app/api/meet/speak/route.ts` + `speak-handler.ts` split: the route does auth + JSON-parse, the handler does the work.

Co-locate a `<verb>-handler.spec.md` capturing the FR mapping if the SRS is changing.

## Step 9 — Add the secretary tool (if the secretary should be able to call it)

File: `packages/chat-agent-secretary/src/tools.ts`. Mirror the shape of `speakInMeeting` / `sendChatInMeeting`. Add a `chat-tool-summaries` entry in `packages/chat-tool-summaries/` so the pill renders.

## Step 10 — Quality gates + sandbox smoke

Same checklist as [workflow-feature.md](./workflow-feature.md) Phase 8 and Phase 9. Dispatch a real bot, exercise the new method, confirm Recall reflects the action in the meeting.

## Step 11 — Update `api-reference.md` and (if novel) `gotchas.md`

Add a new endpoint section to [api-reference.md](./api-reference.md) following the existing pattern: verbatim request shape, response shape, `[Doc check YYYY-MM-DD: <URL>]` stamp. If the new endpoint has a quirk worth catalogging (silent-ignore field, asymmetric nesting, caps), add a row to [gotchas.md](./gotchas.md).

## File-touch summary (six-file pattern)

1. `Personal_Docs/lib/meet/bot-client.ts` — interface + impl.
2. `Personal_Docs/lib/meet/__tests__/bot-client.test.ts` — new test case.
3. `Personal_Docs/lib/meet/__tests__/<other>-handler.test.ts` — stub the new method on inline fakes (if you have them).
4. `Personal_Docs/app/api/meet/<route>/` + handler (if user-facing).
5. `packages/chat-agent-secretary/src/tools.ts` + `packages/chat-tool-summaries/` (if secretary needs to call it).
6. `.claude/skills/recall-ai-integration/references/api-reference.md` — new endpoint section; bump doc-check date.

Plus zero or one of `gotchas.md`, the route's `.spec.md`, or repo-root CLAUDE.md (only if the change introduced something the next agent must know).
