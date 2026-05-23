---
name: pair-agent-harness
description: Harness two AI agents (typically Claude + OpenAI Codex, or two Claudes, or an agent + human reviewer) into a Reviewer / Implementor pair that collaborate asynchronously through a shared markdown thread. One agent reviews / critiques / asks pointed questions; the other implements / responds / drives the code changes; the file mediates. Use when the user says "pair another agent on this", "harness Codex on this", "review this with Codex", "open a Codex thread", "respond to Codex", "open a peer review", "monitor this review file", names a *-review-thread.md or *-dialogue-thread.md, or wants to coordinate structured async back-and-forth between two AI agents on a code or design question. Seeds the file from a template if missing, appends a numbered Claude response under its own section header, arms a file-mtime monitor so each peer append triggers a fresh read + response, drives the pyramid-principle response shape (position first, justification second), detects consensus markers like "Final ACK" / "No further objections", and implements + quality-gates any code changes the thread converges on.
---

# Pair-Agent Harness

A coordination harness for two AI agents working in **complementary roles** on a shared markdown file. The two canonical roles are:

- **Reviewer** — critiques, challenges assumptions, asks pointed questions, ratifies decisions.
- **Implementor** — proposes designs, implements code changes, responds to critique, runs quality gates.

The roles swap per topic — when Claude opens the thread with findings + questions for Codex, Claude is the Implementor / Codex is the Reviewer. When Codex opens the thread asking for review of a Codex-generated patch, the roles flip. The harness doesn't pin roles; it pins the **discipline**: one agent appends at a time, each side reads the whole file before responding, the markdown thread is the single source of truth.

This decouples the two agents from each other's runtime: neither has to be online at the same time. The Implementor can land code changes between rounds; the Reviewer can take a day to think; the file persists across both sessions.

## When to invoke

Fire on:

- User says "pair another agent on this", "harness Codex on this", "pair me with Codex on this design".
- User says "review this with Codex", "open a Codex review", "let's get Codex's take on this".
- User says "open a peer review", "get a second pair of eyes on this", "ping another Claude on this".
- User points at an existing `*-review-thread.md` / `*-dialogue-thread.md` and says "respond" / "continue" / "monitor".
- User says "monitor this file" with a path that looks like a pair-agent thread.

Do NOT fire on:

- One-off code review by a single agent (use a normal code-review subagent instead).
- Synchronous chat or pair-programming (no file involved).
- Generic file-watching for build artifacts / logs (use the Monitor tool directly).

## Step 1: Seed or locate the thread file

Default location, in order:

1. If the cwd is inside a git repo, place under `<repo>/.dialogue/<topic>-review-thread.md`. Create the `.dialogue/` directory if missing; add it to `.gitignore` if the user prefers ephemeral threads, or commit it if the user wants the audit trail.
2. If a `project-management/`, `docs/design/`, or similar design-docs folder already exists in the repo, prefer `<that-folder>/<topic>-review-thread.md`.
3. If outside any repo, use `~/.claude/review-threads/<topic>-review-thread.md`.

If the file does not exist and the user wants Claude to open the thread, write the seed template:

```markdown
# <Topic> Review Thread

Purpose: <one-line problem statement / what's being reviewed>.

## Claude - Findings - <YYYY-MM-DD>

<Claude's opening take. Lead with the recommendation in 2-3 sentences (pyramid
principle). Then justify with the relevant code references, file:line citations,
and tradeoffs. End with 2-3 specific questions for the reviewer.>

## Peer Response

<Peer agent (Codex / another Claude / reviewer): please respond here. In particular:>
- <question 1>
- <question 2>
- <question 3>

## Claude Follow-Up

(Claude appends here after reading the peer's response.)
```

If the file already exists and contains a peer-opened section (e.g. `## Codex (OpenAI) - Findings - <date>`) with an empty `## Claude Response` placeholder, **do not rewrite** the file — append Claude's response under that header.

Print the absolute file path back to the user once seeded so they can hand it to the peer agent.

## Step 2: Read the whole thread, then respond in role

Always read the **whole** file before drafting. Stale assumptions about earlier sections are the most common pair-thread bug.

Pick your role for this round:

- If the latest peer section asked questions or critiqued a design, you're acting as **Implementor**: address the critique, defend or revise the design, and (if consensus is near) implement the code change.
- If the latest peer section proposed a design or landed a patch, you're acting as **Reviewer**: critique the proposal, name the load-bearing assumptions, ask pointed questions, ratify or push back.

Drafting rules (apply in either role):

- **Pyramid principle.** Lead with one of: "Aligned." / "Aligned with one correction." / "Partially aligned — three deltas." / "Disagree on X." The peer should know your position from sentence one. Justify after.
- **Pick the next section header.** Scan the file for the most recent `## Claude *` heading; the new one uses the next numbered slot:
  - First reply: `## Claude Response - <YYYY-MM-DD>`
  - First follow-up: `## Claude Follow-Up - <YYYY-MM-DD>`
  - Subsequent: `## Claude Follow-Up 2`, `## Claude Follow-Up 3`, …
  - Final close-out: `## Claude Final ACK - <YYYY-MM-DD>` (only when nothing more to add and the peer has also closed).
- **Use tables for decision matrices, status, and acceptance criteria.** Long prose blocks degrade thread skimmability; tables make convergence visible at a glance.
- **Cite file:line for every code claim.** A peer agent re-reading the thread weeks later needs anchors, not vibes.
- **Acknowledge corrections explicitly.** When the peer catches an error, write "Correction accepted." in the first sentence and explain what changed.

Append using Edit against the file's last line (or a stable trailing anchor). Never overwrite an existing peer section.

## Step 3: Monitor for the next append

After writing the response, arm a file-mtime watcher so each peer append fires a notification. Reference pattern (works on macOS + Linux):

```bash
FILE=/abs/path/<topic>-review-thread.md
last=$(stat -f %m "$FILE" 2>/dev/null || stat -c %Y "$FILE")
echo "monitoring $FILE (last mtime=$last)"
while true; do
  sleep 3
  cur=$(stat -f %m "$FILE" 2>/dev/null || stat -c %Y "$FILE" 2>/dev/null || echo "$last")
  if [ "$cur" != "$last" ]; then
    echo "CHANGED at $(date -u +%H:%M:%SZ) mtime=$cur"
    last=$cur
  fi
done
```

Run this in a long-lived background task (Claude Code's `Monitor` tool, a `tmux`/`screen` session, or whatever the runtime offers). Save the task / process ID — you'll need it to stop the monitor at the end.

When a CHANGED event arrives:

1. Read the file again (full).
2. Diff against your memory: is there a new peer section, or was it a no-op touch (editor save, formatter)? If no new content, reply "File touched, no new content — monitor stays armed."
3. If there's new content, draft the next Claude response per Step 2.

### Cross-runtime asymmetry (important if the peer is Codex)

Claude Code's `Monitor` tool fires notifications as real conversation messages — the runtime auto-wakes Claude on each file change without the user having to prompt. **Codex's runtime does not work the same way**: its background watcher's stdout only reaches Codex while a turn is open or when the user types something. If the peer agent is Codex (or another tool with the same constraint), set the user's expectation explicitly when handing off:

- "On Claude's side, monitor armed — you'll see my reply automatically when the peer edits the thread."
- "On the peer's side, you may need to type `claude replied` or `check file` to wake them after they post a final answer."

This asymmetry is benign — both sides land replies eventually — but the user shouldn't be surprised when one side appears silent until they ping it.

## Step 4: When playing the Implementor role, act on consensus

When the thread converges on a code change — both sides agree on a specific edit, with file path + value or shape — implement it BEFORE the next response:

1. Make the code edit (Edit tool, or Write for new files).
2. Run the project's quality gates. Use whichever of these the repo provides, in order of preference:
   - A configured `quality-gates` subagent (delegate to it with the touched scope).
   - The repo's documented pre-commit checklist (in `CLAUDE.md`, `README.md`, or `CONTRIBUTING.md`).
   - The standard combo for the stack (e.g. `pnpm lint && pnpm typecheck && pnpm test` for TS/JS).
3. Only after gates pass, append the response with a **Status table**:

```
| Item | Status |
|---|---|
| <change>: <before> → <after> | **Landed** in `<path>:<line>` |
| Quality gates | **All pass.** N tests pass. |
| <follow-up scope> | **Queued.** Not in this PR. |
```

Never claim "landed" without running the gates. If gates fail, fix the underlying issue (no `--no-verify`, no rule loosening) before reporting.

**Respect the active collaboration mode and user instructions.** If mutation is forbidden — Plan Mode is active, an `ExitPlanMode` contract hasn't been approved, the user said "don't edit anything", or the sandbox is read-only — write the agreed plan/status into the thread instead of editing files. Append a Status row marking the change as `Queued — blocked by <mode>` rather than `Landed`. The thread is the record either way; the file edit is the optional output that depends on permission.

## Step 5: Detect convergence + close the loop

The thread is converged when EITHER:

- The peer posts a "Final ACK" / "No further objections" / "Closing my side" line, AND Claude has nothing structural to add. Append a brief `## Claude Final ACK - <date>` (one paragraph) and inform the user the thread is closed.
- The user says "stop monitor" / "kill the watch" / "we're done here".

Stop the monitor with the saved task / process ID. Do NOT leave a monitor running after the user signals close — that burns context on no-op touches.

If the peer keeps posting after your Final ACK with substantive disagreement, treat that as the loop reopening. Otherwise, the thread is closed.

## Conventions

- **One thread, one topic.** If a tangential issue surfaces while discussing the main topic, spin a separate thread file rather than letting the current one drift.
- **Date stamps in headers** use `YYYY-MM-DD` (no timezone). Multiple same-day follow-ups use the number suffix, not a time.
- **Code blocks for shell, TypeScript, SQL, etc.** Tables for decision matrices, acceptance criteria, status. Plain prose for justification only.
- **Cite the peer's reasoning when you accept it.** "The peer's reasoning is sound — [paraphrase]" beats unattributed agreement.
- **Don't restate the peer's section back to them.** They wrote it; quoting it is noise.

## Examples

### Example 1: User says "review the cancel-event change with Codex"

1. Pick a path: `.dialogue/cancel-event-review-thread.md` (or wherever the repo's convention puts design threads).
2. Seed the file with Claude's findings (the cancel-event design + 2-3 questions for Codex). Claude is playing **Implementor**; Codex will play **Reviewer**.
3. Print the path back: *"Seeded at `<path>`. Hand this prompt to Codex: 'Read `<path>`. Respond in `## Codex Response`. If you disagree with any part, explain in the thread.'"*
4. Arm the monitor.

### Example 2: User says "respond to Codex on the watchdog thread"

1. Read the existing file.
2. Find the peer's latest section. Identify what's new.
3. Decide the role for this round (Reviewer if Codex just landed a patch; Implementor if Codex critiqued a design).
4. Append `## Claude Follow-Up <N> - <date>` with pyramid-shape response.
5. If you're acting as Implementor AND the change Codex is asking for is a code edit AND Claude agrees: make the edit, run gates, then append.
6. Re-arm the monitor (or note it's already armed).

### Example 3: User says "we're done, push the changes"

1. Stop the monitor.
2. Commit + push the agreed code change (per the repo's commit conventions).
3. Tell the user: thread converged, commit `<hash>`, branch pushed, monitor stopped.

## Troubleshooting

**Monitor fires on a touch with no new content.** Editor save or formatter run produced the mtime bump. Read the file, confirm no new section, reply briefly that no action is needed. Don't append a new Claude section just because mtime changed.

**Peer's section uses an unexpected header pattern.** Stay flexible — match the header shape they use (e.g. `## Codex (OpenAI) - Findings - <date>` vs `## Codex - Initial Take`). Use your own consistent pattern for Claude headers.

**Two agents diverge in opinion.** Don't try to force a single answer. State the disagreement explicitly in your section, list the tradeoffs in a table, and ask the user to break the tie if both peers stay deadlocked after two rounds.

**File has hundreds of lines and is hard to scan.** Append a status table to your latest Claude section that summarizes where every thread item stands (Landed / Queued / Disputed / Resolved). This is what convergence looks like in long threads.

**Quality gates fail after the agreed change.** Treat the fail as a re-opener of the thread, not a private problem. Append a section explaining what broke, what the fix is, and whether the original consensus still holds.

**A tangential bug surfaces inside the thread.** Don't fold it into the current decision — spin a separate `<other-topic>-review-thread.md` so each thread converges on a single decision instead of dragging.

**Roles are blurring (same agent reviewing + implementing in one round).** That's normal at convergence — the Implementor finishes the change, runs gates, and ratifies their own status table. But if it's happening every round, the harness has degraded into a monologue; ask the user whether the peer is actually engaged.
