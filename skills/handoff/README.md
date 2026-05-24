# handoff

Compact the current conversation into a single self-contained Markdown document that a fresh agent can read at the start of the next session and immediately know: what to do, what's already done, what's blocked, and which skills/files to touch. Saved to the OS temp directory (NOT the workspace) so it doesn't accidentally get committed.

The handoff doc is a **briefing, not a transcript**. It references — never duplicates — content that already lives in other artifacts (PRs, plans, design docs, commits, memory entries, ADRs, issue trackers). Pairs naturally with [`pair-agent-harness`](../pair-agent-harness/README.md) when the next session will be a different agent.

**Inspired by** Matt Pocock's [`handoff`](https://github.com/mattpocock/skills/blob/main/skills/productivity/handoff/SKILL.md) skill. This version extends his with explicit redaction rules (API keys, JWTs, DB connection strings, PII), a mandatory "Suggested skills" section so the next session re-boots cleanly, a stricter "reference, don't duplicate" discipline with a per-artifact citation table, and a portable artifact-locations table (works for `docs/design/`, `project-management/`, `architecture/`, ADR folders, etc. instead of hard-coding one layout).

## Install

Just this skill (run from the repo root):

```bash
ln -s "$PWD/skills/handoff" ~/.claude/skills/handoff
```

Or install every skill + agent in this repo in one line — see the [top-level Install section](../../README.md#install). Claude Code only loads `SKILL.md` from a skill folder, so this `README.md` is human-facing only; safe to leave alongside `SKILL.md`, or delete after install.

## Use

**With Claude Code:**

```text
/handoff                                     # infer the mission from recent work
/handoff respond to Codex review on PR #364  # explicit mission for the next session
/handoff continue Slice 3                    # narrower mission
```

Or just say *"create a handoff doc"*, *"compact this for another agent"*, *"I'll pick this up tomorrow"*. The skill mines `git status` / open PRs / recent commits / in-flight review threads / memory entries without asking you, redacts secrets and PII, writes to `/tmp/handoff-<slug>-<YYYY-MM-DD>.md`, and prints the absolute path.

**With any other agentic system** (OpenAI Codex, Cursor agent mode, Cline, Aider, Devin, custom SDK agents):

Copy the body of [SKILL.md](SKILL.md) into the agent's system prompt (or paste at the top of a new conversation). The structure carries cleanly — only the Claude-Code-specific bits are the `Bash` / `Read` / `Edit` tool names (substitute your agent's equivalents) and the OS temp directory default (`/tmp` works on Linux + macOS; Windows agents should swap to `%TEMP%`). The redaction rules, the mandatory "Suggested skills" section, and the "reference, don't duplicate" discipline are universally applicable.

> [!NOTE]
> Chat UIs (ChatGPT, Claude.ai web, Gemini web) can produce the doc *content* in the chat window — just paste the SKILL.md body and ask for a handoff — but they can't write the file. You'd copy the response into a `/tmp/...md` yourself.

> [!TIP]
> Run `/handoff` as the **last action** of a long session, not mid-conversation. Mid-task summaries are friction; session-boundary handoffs are gold.

Full operational spec: [SKILL.md](SKILL.md).
