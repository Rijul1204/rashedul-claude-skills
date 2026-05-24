# grill-me

Interview the user relentlessly about a plan, design, or approach until every branch of the decision tree is explicit and defensible. **Turns the agent from order-taker into peer programmer** — one who pushes back, names hidden assumptions, recommends instead of just asking, and refuses to start implementation while a load-bearing decision is still in the user's head.

The single-clearest expression of the repo's [Peer, not executor](../../README.md#peer-not-executor) thesis. Adopt this when you'd rather the agent ask "why?" once than implement the wrong thing three times.

**Inspired by** Matt Pocock's [`grill-me`](https://github.com/mattpocock/skills/blob/main/skills/productivity/grill-me/SKILL.md) skill. The framing — interviewing the user as a peer rather than executing on their first instinct — is his. This version extends it with the peer-programmer philosophy block, bad-vs-good grill examples, and a composes-with table linking the other skills this drives. There's also a [longer workflow-driven cousin](../grill-me-codex/SKILL.md) if you want explicit phase structure.

## Install

Just this skill (run from the repo root):

```bash
ln -s "$PWD/skills/grill-me" ~/.claude/skills/grill-me
```

Or install every skill + agent in this repo in one line — see the [top-level Install section](../../README.md#install). Claude Code only loads `SKILL.md` from a skill folder, so this `README.md` is human-facing only; safe to leave alongside `SKILL.md`, or delete after install if you want a lean `~/.claude/skills/grill-me/` tree.

## Use

**With Claude Code:**

```text
/grill-me
```

Or just ask in natural language: *"grill me on this plan"*, *"stress-test this design"*, *"challenge my approach"*, *"what am I missing?"*. The agent restates the target, explores the codebase first (anything answerable on disk doesn't burn a question), then asks one high-signal question at a time — each with **why it matters / its recommendation / what changes if the opposite is chosen** — until either a decision-complete summary or a list of unresolved blockers lands.

**With any other agentic system** (OpenAI Codex, Cursor agent mode, Cline, Aider, Devin, custom agents built on the Anthropic / OpenAI / Vercel AI SDKs):

Copy the body of [SKILL.md](SKILL.md) into the agent's system prompt (or paste at the top of a new conversation). The behavior carries: restate → explore → one-question-at-a-time → decision summary. No Claude-Code-specific tool calls are required for this skill — it's pure conversation discipline.

> [!NOTE]
> Chat UIs (ChatGPT, Claude.ai web, Gemini web) work fine here too because `grill-me` doesn't require tool use — it's a pure conversational pattern. Paste the SKILL.md body into the system / opening message and the chat will follow the discipline.

Full operational spec: [SKILL.md](SKILL.md).
