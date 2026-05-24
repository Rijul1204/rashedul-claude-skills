---
name: handoff
description: Compact the current conversation into a structured handoff document (saved to the OS temp directory) so a fresh agent can continue the work without losing context. Use when the user invokes /handoff, says "create a handoff doc", "write a handoff document", "compact this for another agent", "pass off to another session", "what will the next session focus on", or generally wants to checkpoint the conversation state before a context-window break. Always references existing artifacts (design docs, plans, PRs, commits, memory entries) by path/URL — never duplicates their content. Includes a mandatory "suggested skills" section. Redacts API keys, passwords, PII.
---

# handoff

Compact the current conversation into a single self-contained Markdown document that a fresh agent can read at the start of the next session and immediately know: what to do, what's already done, what's blocked, and which skills/files to touch. Save it to the OS temp directory (NOT the workspace) so it doesn't accidentally get committed.

The handoff doc is a **briefing**, not a transcript. It references — never duplicates — content that already lives in other artifacts (PRs, plans, design docs, commits, memory entries, ADRs, issue trackers).

*See [README.md](README.md) for the credit (Matt Pocock's original `handoff`) and install / use instructions.*

## When to invoke

Fire on any of:

- User invokes `/handoff` (optionally with an argument describing the next session's focus).
- User says "create a handoff doc", "write a handoff document", "compact this", "pass off to another session", "checkpoint this conversation".
- User says "what will the next session focus on" or "I'll pick this up tomorrow".
- User signals an imminent context-window break and wants the work to survive.

## When NOT to invoke

- Mid-task, when the user wants you to keep going. Handoff is a **session-boundary** ritual, not a status update mid-conversation.
- For one-off questions ("what's the status?") — answer directly; don't write a file.
- When the conversation is short (<20 substantive turns) and nothing material would be lost by starting fresh.
- When the user is asking for documentation that should live IN the repo (design docs, ADRs, READMEs). Handoff docs are ephemeral session-bridge artifacts; if it deserves permanent docs, write it alongside code (e.g. under `docs/`, `project-management/`, or `architecture/`), not in `/tmp`.

## Step 1 — Parse the argument

If the user passed an argument to `/handoff` (or named the next session's focus in their message), treat it as the **mission statement**. The whole doc tailors to that mission.

Examples of argument shapes you might see:

- `/handoff respond to Codex's review on PR #364` → mission = "respond to Codex review, then merge"
- `/handoff and create a skill for X` → mission = "create the X skill"
- `/handoff continue Slice 3` → mission = "implement Slice 3 of the current epic"
- (No argument) → infer the mission from the most recent in-flight work; if ambiguous, ask the user with a one-line question before writing.

## Step 2 — Gather state without asking the user

The user is checking out; don't make them answer questions. Mine the state yourself:

```bash
git status --short
git log --oneline -10
git branch --show-current
gh pr list --repo <owner/repo> --author "@me" --state open
gh pr view <N> --json state,reviewDecision,mergeStateStatus,headRefOid    # for each in-flight PR
date -u +"%Y-%m-%dT%H:%M:%SZ"                                              # timestamp
```

Also scan the recent conversation for:

- **In-flight PRs** + their status + any pending review comments.
- **Recently merged work** (last 1–2 PRs) and their merge commits.
- **Open questions / decisions** the user deferred or you couldn't resolve without them.
- **External dependencies** (waiting on Codex review, waiting on CI, waiting on user input).
- **Memory entries** that materially shaped recent decisions (cite them by filename — don't quote the body).

## Step 3 — Choose the output path

OS temp directory, NOT the workspace. On macOS the canonical user-facing temp is `/tmp/` (symlinked to `$TMPDIR` for the user's session). On Linux, `/tmp/` is standard. Filename pattern:

```
/tmp/handoff-<short-kebab-slug>-<YYYY-MM-DD>.md
```

Where `<short-kebab-slug>` is 3–5 words summarising the next session's focus (e.g. `slice-3-and-skill`, `respond-codex-pr-364`, `bootstrap-rebuild`).

If `/tmp/` doesn't exist or isn't writable (rare), fall back to `$(mktemp -d)/handoff.md` and report that path.

**Never** write to:
- The repo workspace (`./`, `../`, anywhere under the current project).
- The user's home dir outside `~/.claude/`.
- `~/.claude/plans/` (that's for plan-mode artifacts; handoffs are not plans).

## Step 4 — Identify references (don't duplicate)

Before writing a single line of doc body, enumerate every artifact that *already* captures something you'd otherwise restate. Reference these by path or URL; don't paraphrase their content.

| Artifact type | Common locations | How to reference |
|---|---|---|
| Design docs | `docs/design/**/*-design.md`, `project-management/**/*-design.md`, `architecture/**/*.md`, ADR folders | Path + section anchor (e.g. `docs/design/foo-design.md §4.5`) |
| Implementation plans | `<docs-folder>/**/*-plan.md` | Same |
| Peer-review threads (Codex, another Claude, human reviewer) | `<repo>/.dialogue/*-review-thread.md`, `<docs-folder>/**/*-review-thread.md` | Path; note whether closed (Final ACK both sides) or open |
| Open PRs | GitHub / GitLab | URL + PR number; cite head SHA |
| Merged PRs | Same | URL + merge commit SHA |
| Recent commits worth flagging | git history | SHA + one-line subject |
| Auto-memory entries | `~/.claude/projects/<project>/memory/*.md` | Filename only (no body) — the next agent reads `MEMORY.md` on session start |
| Per-package / per-module specs | `packages/<pkg>/{SPEC,CLAUDE}.md`, `apps/<name>/CLAUDE.md`, `<module>/SPEC.md` | Path; note "assume loaded" for the next session |
| Plan files from plan-mode | `~/.claude/plans/<name>.md` | Path; note approval status |

If you find yourself wanting to write out a 10-bullet summary of a doc, **stop and reference the doc instead**. The next agent reads what they need; pre-digesting wastes context.

## Step 5 — Write the doc

Canonical structure — adapt section names but keep this order:

```markdown
# Handoff — <one-line mission> (<YYYY-MM-DD>)

**Repo**: <absolute path> (one-line description)
**Branch at handoff**: `<branch>` (clean | dirty: <files>)
**Working tree**: <state as of timestamp>

## Mission for next session

<2–4 sentences. Lead with the action verb. If the user passed an argument,
this section is shaped around it. If multiple parallel tracks, name them
1. ... 2. ... so the next agent can pick one or run them concurrently.>

## Where we are

### Recent merge / open PR / pending work

<Table: work item × PR/branch × status × one-line note. Cite SHAs.>

### Canonical artifacts to read first

<Bullet list of paths/URLs the next agent MUST read before doing anything.
Order them by load-bearingness — most critical first.>

## Active work / context anchors

<For each in-flight thread, name:
 - What it is + its current state (1–2 sentences)
 - Where the canonical record lives (path/URL)
 - Anything the next agent would otherwise have to reconstruct from this
   conversation. THIS is the section where transient session knowledge
   gets persisted; everything else is references.>

### Anticipated review push-back (when waiting on a peer review)

<If a PR is awaiting Codex or another reviewer, list the 2–4 specific
things you'd anticipate getting flagged, with defensive answers prepped.
This is the highest-value addition over what's already on disk.>

### Key memories worth recalling

<Table: filename × one-line summary. NEVER quote memory bodies. List
only the entries that materially shaped recent decisions; the next agent
loads the full index from MEMORY.md on session start.>

## Suggested skills

<Mandatory section. Table: skill name × why this session needs it.
Order by likely-first-invoked. Include the user-feedback skills
(`grill-me` before finalising plans, `pair-agent-harness` for Codex /
peer-review threads, etc.) that match the mission.>

## Open questions / decisions for the next session

<Numbered list of things you couldn't resolve without the user. Each item:
 - The question (concrete, one sentence)
 - The options you considered + your recommended call (if any)
 - Why it's blocking (or note "non-blocking; can proceed without")>

## How to start the next session cleanly

<3–5 numbered steps. Almost always:
 1. Read these CLAUDE.md files: ...
 2. Read this handoff doc.
 3. Check the in-flight PR / review thread / blocked task.
 4. Invoke <primary skill> with <opening intent>.>

## Hand-off complete checklist

- [x] Branch state clean OR uncommitted changes documented above.
- [x] In-flight PR description has the full state-of-play; no comments need response from THIS session.
- [x] No secrets / PII in this doc.
- [x] References (not duplication): all canonical artifacts cited with paths/URLs/SHAs.

---

*Generated <ISO-8601 UTC timestamp>. Source conversation covered:
<one-line topic list>.*
```

## Step 6 — Redact

Scan the draft for sensitive content before writing:

- **API keys / tokens / secrets**: any string matching `sk-`, `whsec_`, `pk_`, `xoxb-`, `ghp_`, `eyJ`, JWT-shaped tokens, anything from an `.env` example. Redact to `<REDACTED>` or `<example-key>`.
- **Passwords**: any line near the word "password", "passphrase", "secret".
- **PII**: full names other than the user's already-public profile, personal email addresses (other than the user's own as published in repo metadata), phone numbers, addresses, birthdays from journal content. The user's GitHub handle from a PR URL is public and OK.
- **Database connection strings** with credentials: `postgres://user:PASS@host/db` → `postgres://<REDACTED>@host/db`.
- **Local file paths** that include other usernames or sensitive directory names.

When in doubt, redact. Note redactions in a final line: `*Redacted: <count> credentials and <count> PII items.*`

## Step 7 — Print the path

End the chat reply with:

```
Handoff doc written to <absolute-path>.
```

Optionally add 2–3 sentences summarising the doc's structure (mission + the highest-value addition the doc makes vs. what's already on disk). Don't paste the doc body into chat — it's already in the file.

## Doc-shape examples

The most recently written handoff (a worked example you can mimic) is at the path the user last invoked /handoff against. If that's not accessible:

- **Two parallel tracks** (most common): mission has two numbered items; structure has separate sub-sections per track.
- **Single in-flight PR awaiting review**: mission = "respond to review on #N"; the "Anticipated push-back" section becomes load-bearing.
- **Mid-design pivot**: mission = "decide between X and Y approach"; "Open questions / decisions" section is load-bearing.

## Anti-patterns (do not do)

- **Writing to the workspace.** Handoff docs are ephemeral session bridges; they don't belong in git. If the user wants permanent docs, write to wherever the repo keeps them (`docs/`, `project-management/`, `architecture/`, alongside code).
- **Paraphrasing the design doc / plan / PR body.** Cite them. The next agent reads the artifact directly.
- **Dumping the full memory index.** Cite only the entries that shaped recent decisions; `MEMORY.md` loads automatically on session start.
- **Mid-conversation handoff** ("checkpoint and continue"). Handoff is a session-boundary ritual. If you want a status pin without ending the session, just summarise in chat.
- **Asking the user to fill in details before writing.** The whole point of handoff is the user is checking out. Mine the state yourself; the only acceptable question is one-line clarification of the mission when truly ambiguous.
- **Skipping the "suggested skills" section.** Even when no skill obviously applies, suggest the closest ones (`grill-me` for plans, `pair-agent-harness` for any peer review, the most-recently-used domain skill). This section is what makes handoffs *re-bootable*.
- **Skipping redaction.** Even if the conversation didn't visibly contain secrets, the next agent might widen access; scan systematically.

## Validation checklist

Before reporting the path to the user, verify:

- [ ] File written to OS temp dir (path starts with `/tmp/` or `$TMPDIR`), NOT the workspace.
- [ ] Filename matches `handoff-<slug>-<YYYY-MM-DD>.md`.
- [ ] Frontmatter sections present in order: Mission, Where we are, Active work, Suggested skills, Open questions, How to start, Hand-off checklist.
- [ ] Mandatory "Suggested skills" section present with ≥2 entries.
- [ ] References use paths/URLs/SHAs; no duplicated content from cited artifacts.
- [ ] Redaction pass complete; sensitive content removed or replaced.
- [ ] Final timestamp + one-line topic summary at the bottom.
- [ ] Hand-off-complete checklist's items all checked (or unchecked items explicitly noted as known-incomplete).
