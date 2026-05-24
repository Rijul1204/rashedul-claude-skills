# pair-agent-harness

A coordination harness for two AI agents working in **complementary roles** on a shared markdown file:

- **Reviewer** — critiques, challenges assumptions, asks pointed questions, ratifies decisions.
- **Implementor** — proposes designs, implements code changes, responds to critique, runs quality gates.

The roles swap per topic. The harness pins the **discipline** (one agent appends at a time, each reads the whole file before responding, the file is the single source of truth), not the role assignment. Decouples the two agents from each other's runtime — neither has to be online at the same time.

## When to reach for it

- You want a second pair of eyes on a design before committing to it — pair Claude with Codex (or another Claude) through a shared `*-review-thread.md`.
- A patch is contentious and you want both sides to converge on the same record in writing.
- You're handing off mid-task and the next session might be a different agent.

## Install

Just this skill (run from the repo root):

```bash
ln -s "$PWD/skills/pair-agent-harness" ~/.claude/skills/pair-agent-harness
```

Or install every skill + agent in this repo in one line — see the [top-level Install section](../../README.md#install). Claude Code only loads `SKILL.md` from a skill folder, so this `README.md` is human-facing only; safe to leave alongside `SKILL.md`, or delete after install.

## Use

**With Claude Code:**

```text
"review this with Codex"
"open a peer review thread on the cancel-event design"
"pair me with another agent on this"
"respond to Codex on .dialogue/foo-review-thread.md"
```

Or invoke against an existing thread by naming the file: *"continue the watchdog thread"* / *"monitor `<thread>.md`"*. The skill seeds the file from a template if missing, picks the right section header for the next round, drives a pyramid-principle response, and arms a file-mtime monitor so each peer append fires a notification.

**With any other agentic system** (OpenAI Codex, Cursor agent mode, Cline, Aider, Devin, custom SDK agents):

This is the skill most worth installing on **both** sides of the pair. Copy the body of [SKILL.md](SKILL.md) into the peer agent's system prompt (or paste at the top of a new conversation) so it follows the same convention: append-only writes, dated section headers, pyramid-principle responses, "Final ACK" close-out marker. The mtime-monitor step is Claude-Code-specific (uses Claude Code's `Monitor` tool); for other agents, substitute a `tmux`/`screen` loop or whatever long-lived background mechanism the runtime offers — the `bash stat -f %m` pattern in the skill body is portable.

> [!NOTE]
> Chat UIs (ChatGPT, Claude.ai web, Gemini web) can play the Reviewer role manually — you'd paste the thread into the chat, ask for a critique, then copy the response back into the file yourself. They can't be the Implementor (no file-write capability) but they can be the second opinion.

> [!TIP]
> Pair this with [`grill-me`](../grill-me/README.md): run `/grill-me` on yourself **before** opening a peer-review thread to surface your own gaps before the peer does.

Full operational spec: [SKILL.md](SKILL.md).
