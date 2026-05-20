<div align="center">

# rashedul-agentic-engineering

**My agentic-engineering workbench.**

Personal [Claude Code](https://docs.claude.com/en/docs/claude-code) skills, prompts, and tooling I reuse across projects — small, composable, version-controlled.

</div>

---

## Contents

| Section | |
|---|---|
| [What's here](#whats-here) | Current categories and what's coming |
| [Skills](#skills) | Drop-in `SKILL.md` folders for Claude Code |
| [Layout](#layout) | Repo structure |
| [Install](#install) | Symlink or copy into Claude Code |
| [Notes](#notes) | Variants, naming collisions, one-off files |

---

## What's here

| Category | Status | Location |
|---|---|---|
| **Skills** — Claude Code `SKILL.md` folders | Live | [`skills/`](skills) |
| **Prompts** — reusable prompts and prompt fragments | Planned | `prompts/` |
| **Hooks** — Claude Code lifecycle hooks | Planned | `hooks/` |
| **Configs** — shareable `settings.json` snippets, keybindings | Planned | `configs/` |
| **Agents** — subagent definitions | Planned | `agents/` |

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

## Layout

```
skills/
└── <skill-name>/
    ├── SKILL.md            # required — YAML frontmatter + body
    └── rules/              # optional — reference files the skill can load
```

Each skill is a self-contained folder. The `SKILL.md` carries YAML frontmatter (`name`, `description`) that Claude Code reads on startup; the folder name should match the `name:` field so the `/skill-name` invocation resolves cleanly.

---

## Install

Pick a skill and either symlink (recommended — keeps this repo as the source of truth) or copy it into your Claude skills directory.

```bash
# user-scoped (available in every Claude Code session)
ln -s "$PWD/skills/html-output" ~/.claude/skills/html-output

# project-scoped (only inside one repo)
ln -s "$PWD/skills/fizzy-tasks" <project>/.claude/skills/fizzy-tasks

# or copy instead of symlink
cp -R skills/html-output ~/.claude/skills/html-output
```

> [!TIP]
> Symlinks let you `git pull` here once and have every install pick up the change.

> [!NOTE]
> `grill-me` and `grill-me-codex` both register as `/grill-me` if you install them under their original folder names. Pick one per install, or rename on install if you want both side-by-side.

> [!IMPORTANT]
> `skills/fizzy-product-manager/rules/jira-migration.md` is a single-use runbook for the Tap Games Fizzy → Jira cutover. The file documents its own removal date — prune it (and the pointer from `SKILL.md`) once Phase 4 completes.

---

## Notes

- **Source of truth.** This repo is canonical. Project-local copies elsewhere in `~/Projects/*/.claude/skills/` are historical and may diverge — when in doubt, trust here.
- **No runtime dependencies.** Skills are plain markdown. They're consumed by Claude Code, not executed.
- **Adding a new skill.** Drop a folder under `skills/`, give it a `SKILL.md` with `name:` and `description:` in frontmatter, link it from the table above.
- **Adding a new category.** Create the top-level folder (`prompts/`, `hooks/`, etc.) only when you have real content for it. Update the [What's here](#whats-here) table when you do.

---

<div align="center">
<sub>Maintained by <a href="https://github.com/Rijul1204">@Rijul1204</a></sub>
</div>
