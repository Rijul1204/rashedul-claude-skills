<div align="center">

<img src=".github/assets/logo.png" alt="Rashedul Agentic Engineering — Agentic Workbench" width="480">

# rashedul-agentic-engineering

Personal [Claude Code](https://docs.claude.com/en/docs/claude-code) skills, subagents, and CI workflows I reuse across projects — small, composable, version-controlled.

</div>

---

## Contents

| Section | Purpose |
|---|---|
| [What's here](#whats-here) | Current categories and what's coming |
| [Skills](#skills) | Drop-in `SKILL.md` folders for Claude Code |
| [Agents](#agents) | Subagent definitions for delegation |
| [Workflows](#workflows) | Drop-in GitHub Actions templates for other repos |
| [Layout](#layout) | Repo structure |
| [Install](#install) | How to use these in your own setup |
| [Notes](#notes) | Variants, naming collisions, one-off files |

---

## What's here

| Category | Status | Location |
|---|---|---|
| **Skills** — Claude Code `SKILL.md` folders | Live | [`skills/`](skills) |
| **Agents** — subagent definitions for delegation | Live | [`agents/`](agents) |
| **Workflows** — drop-in GitHub Actions templates for other repos | Live | [`workflows/`](workflows) |
| **Prompts** — reusable prompts and prompt fragments | Planned | `prompts/` |
| **Hooks** — Claude Code lifecycle hooks | Planned | `hooks/` |
| **Configs** — shareable `settings.json` snippets, keybindings | Planned | `configs/` |

The repo started as a skills-only collection and is expanding into a broader home for everything I plug into Claude Code. New categories get folders only when I have something to put in them — no empty scaffolding.

---

## Skills

### General-purpose

> **[`html-output`](skills/html-output/SKILL.md)**
> Convert the current plan, spec, or markdown context into a single self-contained `.html` file — tables, inline SVG diagrams, responsive layout, in-page TOC. No external runtime deps.
> _Trigger: `/html-output`, "export as HTML", "make a web version", "share this as a link"._

> **[`grill-me`](skills/grill-me/SKILL.md)** &nbsp;·&nbsp; **[`grill-me-codex`](skills/grill-me-codex/SKILL.md)**
> Interview you relentlessly about a plan until each decision is explicit and defensible. Two flavors: a terse short version and a longer workflow-driven version that ends with a decision summary or blocker list.
> _Trigger: `/grill-me`, "stress-test this plan", "grill me on the design"._

> **[`file-review-dialogue`](skills/file-review-dialogue/SKILL.md)**
> Coordinate an async file-based design / code review with a peer agent (Codex, another Claude, or a human reviewer) through a shared markdown thread. Seeds the file, drives the pyramid-principle response shape, monitors for peer appends, implements + quality-gates any code change the thread converges on, and detects "Final ACK" close-out.
> _Trigger: "review this with Codex", "open a peer review thread", "respond to Codex on `<thread>.md`", or naming any `*-review-thread.md` path._

### Spec & delivery planning

> **[`srs-documentation`](skills/srs-documentation/SKILL.md)**
> Write a formal Software Requirements Specification following the IEEE 830 standard structure. Walks the full template (Introduction, Overall Description, Specific Requirements, Appendices), enforces requirement quality (necessary, unambiguous, verifiable, traceable, MoSCoW-prioritized), and ships a [`template.md`](skills/srs-documentation/template.md) + [`checklists.md`](skills/srs-documentation/checklists.md) you can copy for any new spec.
> _Trigger: "write an SRS", "draft a requirements doc", "IEEE 830 spec", "formal requirements for `<feature>`"._

> **[`srs-to-delivery-plan`](skills/srs-to-delivery-plan/SKILL.md)**
> Convert an SRS into EPICs → STORIES → TASKS → SPRINT PLAN using vertical-slicing (tracer-bullet) principles. Enforces end-to-end thin slices over horizontal layer-by-layer work, classifies stories as HITL vs AFK, prescribes the 10 required fields per TASK (Context, Problem, Scope, DoD, Acceptance, Testing, Validation, Key Files, Implementation Notes, Framework Integration), and ends with a sprint plan and GitHub-issue creation flow.
> _Trigger: "break this SRS into stories", "make a delivery plan", "epic / story / task breakdown", "sprint plan for `<feature>`"._

### Vendor integrations

> **[`recall-ai-integration`](skills/recall-ai-integration/SKILL.md)**
> Modular vendor knowledge for [Recall.ai](https://recall.ai) (meeting bots, status + realtime webhooks) plus the closely-coupled ElevenLabs surfaces (Scribe for transcription, Voice for TTS). Bundles a 10-file [`references/`](skills/recall-ai-integration/references) library with verbatim wire contracts, a tri-site nesting gotcha catalog, spec-faithful webhook fixtures, and full feature / bug-fix workflows. Enforces docs → probe → fixture → code with date-stamped `[Doc check]` comments at every call site to prevent schema-drift outages.
> _Trigger: any mention of Recall.ai, `RECALL_API_KEY`, `in_call_recording`, `transcript.data`, Svix verification, `us-west-2.recall.ai`, ElevenLabs, Scribe, `xi-api-key`, `voice_id`, or new code dispatching / commanding / handling webhooks from a Recall bot._

### Fizzy Kanban toolkit

> **[`fizzy-product-manager`](skills/fizzy-product-manager/SKILL.md)**
> Product-management knowledge for Fizzy boards — Kanban principles, API workflows, triage, hygiene, reporting. Bundles a [`rules/`](skills/fizzy-product-manager/rules) reference library (see below).
> _Trigger: PM-shaped questions about Fizzy boards, columns, WIP, or workflow._

> **[`fizzy-tasks`](skills/fizzy-tasks/SKILL.md)**
> Prioritised digest of open Fizzy cards assigned to you, plus unassigned bugs.
> _Trigger: "fizzy tasks", "my fizzy cards", "what are my open tasks in fizzy"._

> **[`fizzy-board-monitor`](skills/fizzy-board-monitor/SKILL.md)**
> On-demand Kanban overview of any Fizzy board — cards grouped by column with counts.
> _Trigger: "show fizzy board", "fizzy board overview", "what's on the board"._

> **[`fizzy-write`](skills/fizzy-write/SKILL.md)**
> Mutations against Fizzy: create / update / close cards and boards, comment, assign, move between columns.
> _Trigger: "create card", "close fizzy card", "comment on fizzy card", "move card to column"._

<details>
<summary><b>Fizzy PM rules library</b> — 20 reference files bundled with <code>fizzy-product-manager</code></summary>

| File | Topic |
|---|---|
| [`kanban-principles.md`](skills/fizzy-product-manager/rules/kanban-principles.md) | Core Kanban model the agent should defend |
| [`wip-limits.md`](skills/fizzy-product-manager/rules/wip-limits.md) | When to push back on overloaded columns |
| [`column-structure.md`](skills/fizzy-product-manager/rules/column-structure.md) | How columns should map to workflow stages |
| [`board-management.md`](skills/fizzy-product-manager/rules/board-management.md) | Board lifecycle and ownership |
| [`board-hygiene.md`](skills/fizzy-product-manager/rules/board-hygiene.md) | Routine cleanup and pruning rules |
| [`board-reports.md`](skills/fizzy-product-manager/rules/board-reports.md) | Reporting shapes (throughput, aging) |
| [`card-lifecycle.md`](skills/fizzy-product-manager/rules/card-lifecycle.md) | Open → in-progress → done transitions |
| [`card-details.md`](skills/fizzy-product-manager/rules/card-details.md) | Required fields per card type |
| [`card-writing.md`](skills/fizzy-product-manager/rules/card-writing.md) | ActionText/Trix HTML rules + curl recipe |
| [`card-triage.md`](skills/fizzy-product-manager/rules/card-triage.md) | Triage heuristics |
| [`tagging-strategy.md`](skills/fizzy-product-manager/rules/tagging-strategy.md) | Tag taxonomy and use |
| [`assignments-workload.md`](skills/fizzy-product-manager/rules/assignments-workload.md) | Workload balance and reassignment |
| [`comments-collaboration.md`](skills/fizzy-product-manager/rules/comments-collaboration.md) | Comment etiquette and threading |
| [`api-basics.md`](skills/fizzy-product-manager/rules/api-basics.md) | Auth, endpoints, pagination |
| [`api-recipes.md`](skills/fizzy-product-manager/rules/api-recipes.md) | Common curl/jq patterns |
| [`webhooks-automation.md`](skills/fizzy-product-manager/rules/webhooks-automation.md) | Webhook payload shapes and use |
| [`entropy-management.md`](skills/fizzy-product-manager/rules/entropy-management.md) | Keeping boards from drifting into chaos |
| [`tap-games-context.md`](skills/fizzy-product-manager/rules/tap-games-context.md) | Tap Games-specific context |
| [`jira-migration.md`](skills/fizzy-product-manager/rules/jira-migration.md) | One-time Fizzy → Jira (`TG` project on GCW) cutover runbook |

</details>

---

## Agents

> **[`quality-gates`](agents/quality-gates.md)**
> Runs the repo's quality gates (lint, format:check, typecheck, knip, scoped vitest) and returns a concise pass/fail report. Delegate after writing or editing TS/TSX so the verbose tool output stays out of the parent context. Read-only — never edits code, never bypasses checks.
> _Delegate to: `quality-gates` subagent with a scope (which packages were touched, optionally which test files)._

> [!TIP]
> `quality-gates` ships generic — it discovers `lint` / `format:check` / `typecheck` / `knip` / `test` scripts from `package.json` and adapts. If your repo uses a non-pnpm workspace manager or has custom gates, fill in the "Project-specific tuning" section at the bottom of the agent file.

---

## Workflows

Shareable GitHub Actions templates. Each entry is a self-contained folder mirroring a target repo's `.github/` tree — drop it in with one `cp -R` and it works.

> **[`cursor-review/`](workflows/cursor-review)**
> Runs the [Cursor Agent](https://docs.cursor.com/agents) against every PR diff and posts a single sticky review comment with grade + verdict + action items. Sticky-comment design means re-runs update the existing comment instead of stacking new ones. Manually re-triggerable via `/cursor-review` comment or `workflow_dispatch`.
> _Install: see [`workflows/cursor-review/README.md`](workflows/cursor-review/README.md). Requires a `CURSOR_API_KEY` secret on the target repo._

> [!NOTE]
> These templates are **not active on this repo** — they live under `workflows/<name>/.github/` (one level down) so GitHub Actions doesn't pick them up here. Copy the inner `.github/` tree into your own repo's root to activate.

---

## Layout

```
skills/
└── <skill-name>/
    ├── SKILL.md            # required — YAML frontmatter + body
    └── rules/              # optional — reference files the skill can load

agents/
└── <agent-name>.md         # YAML frontmatter (name, description, tools, model) + body

workflows/
└── <workflow-name>/
    ├── README.md           # how to install in a target repo
    └── .github/            # mirror of target repo's .github tree — copy in with one cp -R
        ├── workflows/<workflow-name>.yml
        ├── scripts/        # support scripts
        ├── instructions/   # review rubrics, prompt templates
        └── *.env           # optional config (version pins, checksums)
```

Each **skill** is a self-contained folder; the `SKILL.md` carries YAML frontmatter (`name`, `description`) that Claude Code reads on startup; the folder name should match the `name:` field so the `/skill-name` invocation resolves cleanly.

Each **agent** is a single `.md` file under `agents/`. The frontmatter declares the agent `name`, `description` (used by the parent agent to decide when to delegate), allowed `tools`, and a `model` override.

Each **workflow** lives under `workflows/<workflow-name>/` and contains a complete `.github/` subtree plus a per-workflow `README.md`. The inner `.github/` is intentionally one level down so this repo's own Actions runner ignores it — these are templates, not active workflows.

---

## Install

### Skills and agents

**One-shot install (everything):**

```bash
./scripts/install.sh                            # user-scope (~/.claude/), symlink, all categories
./scripts/install.sh --target ~/Projects/foo    # project-scope (<target>/.claude/)
./scripts/install.sh --only skills --dry-run    # preview only — no filesystem changes
./scripts/install.sh --copy --force             # snapshot copy, overwrite existing
```

Run from the repo root. The script symlinks (or copies) every `skills/<name>/` and `agents/*.md` into the target's `.claude/` tree. Existing targets are skipped with a warning unless `--force` is passed.

**Per-item install** (when you only want one):

```bash
# skills — user-scoped (available in every Claude Code session)
ln -s "$PWD/skills/html-output" ~/.claude/skills/html-output

# skills — project-scoped (only inside one repo)
ln -s "$PWD/skills/fizzy-tasks" <project>/.claude/skills/fizzy-tasks

# agents — project-scoped (typically; agents are usually tied to a repo's tooling)
ln -s "$PWD/agents/quality-gates.md" <project>/.claude/agents/quality-gates.md

# or copy instead of symlink
cp -R skills/html-output ~/.claude/skills/html-output
cp agents/quality-gates.md <project>/.claude/agents/quality-gates.md
```

### Workflows

Each workflow ships its own install steps — see the per-workflow README:

- [`workflows/cursor-review/README.md`](workflows/cursor-review/README.md) — drop the inner `.github/` tree into your target repo's root, replace the rubric, set `CURSOR_API_KEY`.

> [!TIP]
> Symlinks let you `git pull` here once and have every install pick up the change.

> [!NOTE]
> `grill-me` and `grill-me-codex` both register as `/grill-me` if you install them under their original folder names. Pick one per install, or rename on install if you want both side-by-side.

> [!IMPORTANT]
> `skills/fizzy-product-manager/rules/jira-migration.md` is a single-use runbook for the Tap Games Fizzy → Jira cutover. The file documents its own removal date — prune it (and the pointer from `SKILL.md`) once Phase 4 completes.

---

## Notes

- **Source of truth.** This repo is canonical. Project-local copies elsewhere in `~/Projects/*/.claude/skills/` and `~/Projects/*/.claude/agents/` are historical and may diverge — when in doubt, trust here.
- **No runtime dependencies.** Skills and agents are plain markdown. They're consumed by Claude Code, not executed.
- **Adding a new skill.** Drop a folder under `skills/`, give it a `SKILL.md` with `name:` and `description:` in frontmatter, link it from the table above.
- **Adding a new agent.** Drop a `.md` file under `agents/`, give it `name:` / `description:` / `tools:` / `model:` in frontmatter, link it from the [Agents](#agents) section.
- **Adding a new workflow template.** Create `workflows/<name>/` with a `README.md` and a `.github/` subtree. Keep the inner `.github/` one level down so this repo's own Actions runner ignores it.
- **Adding a new category.** Create the top-level folder (`prompts/`, `hooks/`, etc.) only when you have real content for it. Update the [What's here](#whats-here) table when you do.

---

<div align="center">
<sub>Maintained by <a href="https://github.com/Rijul1204">@Rijul1204</a></sub>
</div>
