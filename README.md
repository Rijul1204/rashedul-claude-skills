# rashedul-claude-skills

Personal collection of [Claude Code](https://docs.claude.com/en/docs/claude-code) skills I reuse across machines and projects.

## Layout

```
skills/
└── <skill-name>/
    └── SKILL.md
```

Each subdirectory is a self-contained skill — the `SKILL.md` carries YAML frontmatter (`name`, `description`) that Claude Code reads on startup. The folder name should match the skill's `name:` field so `/skill-name` resolves cleanly.

## Skills

| Skill | What it does |
|---|---|
| [`html-output`](skills/html-output/SKILL.md) | Convert the current plan / spec / markdown context into a single self-contained shareable `.html` file. |
| [`grill-me`](skills/grill-me/SKILL.md) | Short variant — interview the user relentlessly about a plan until each branch of the decision tree is resolved. |
| [`grill-me-codex`](skills/grill-me-codex/SKILL.md) | Longer workflow-driven variant — restate the target, drill on goals / constraints / failure modes, end with a decision summary or blocker list. |
| [`fizzy-product-manager`](skills/fizzy-product-manager/SKILL.md) | PM knowledge for Fizzy Kanban boards — principles, API workflows, triage, hygiene, reporting. Bundles a `rules/` reference library. |
| [`fizzy-tasks`](skills/fizzy-tasks/SKILL.md) | Fetch open Fizzy cards assigned to the user (plus bugs and unassigned), present a prioritised digest with deep links. |
| [`fizzy-board-monitor`](skills/fizzy-board-monitor/SKILL.md) | On-demand Kanban overview of a Fizzy board — cards grouped by column with counts. |
| [`fizzy-write`](skills/fizzy-write/SKILL.md) | Create / update / close cards and boards, add comments, assign users, move cards between columns. |

## Install

Pick one skill folder and either symlink or copy it into your local Claude skills directory:

```bash
# symlink (recommended — keeps the repo as the source of truth)
ln -s "$PWD/skills/html-output" ~/.claude/skills/html-output

# or copy
cp -R skills/html-output ~/.claude/skills/html-output
```

For project-scoped install, target `<project>/.claude/skills/<name>` instead of `~/.claude/skills/`.

`grill-me` and `grill-me-codex` both register as `/grill-me` if installed under that folder name — pick one per install or rename on install.
