# Contributing

This repo is a personal collection of Claude Code skills, subagents, prompts, and CI workflow templates — but contributions are welcome. Issues and PRs both fit, depending on the size of the change.

## What kinds of contributions are useful

| Type | Use when | Examples |
|---|---|---|
| **Issue** | You spotted a problem or want to suggest something | Skill or workflow you'd find useful here; broken link; frontmatter error; README typo; a generalization the repo should make |
| **PR** | You have a concrete change ready | New skill / agent / prompt / workflow; generalization of an existing one; doc improvements |
| **Discussion (open an issue)** | You're not sure if the idea fits | "Have you considered X?" patterns, naming questions, scope questions |

For typos or single-line fixes, open a PR directly — that's faster than an issue.

## Adding a new artifact

Match the existing layout:

| Type | Path | Required |
|---|---|---|
| **Skill** | `skills/<name>/SKILL.md` (optional `references/`, `rules/` subdirs) | YAML frontmatter with `name:` matching the folder name, `description:` with concrete trigger phrases |
| **Agent** | `agents/<name>.md` | YAML frontmatter: `name`, `description`, `tools`, optionally `model` |
| **Prompt** | `prompts/<name>.md` | Body is the paste-ready prompt; YAML frontmatter optional but recommended |
| **Workflow template** | `workflows/<name>/{README.md, .github/...}` | Nested `.github/` one level down so this repo's Actions runner ignores it; per-workflow `README.md` documents install |

After adding the file(s), update the top-level `README.md`:

- **"What's here" table** — move a category from Planned → Live if you're materializing it.
- **Relevant section** (`## Skills`, `## Agents`, `## Prompts`, `## Workflows`) — add a blockquote card matching the existing style (one-line description + trigger phrasing).
- **Skills overview table** at the top of `## Skills` — add your skill to the appropriate group row.
- **Layout block** — only if the artifact introduces a new directory shape.

## Generalization PRs

Two artifacts in the repo retain `lib/...`-style example paths from the codebase they were extracted from:

- [`skills/recall-ai-integration/`](skills/recall-ai-integration/) — references `lib/meet/bot-client.ts`, `Personal_Docs/...` etc. as concrete examples of where the vendor seam lives.
- [`agents/quality-gates.md`](agents/quality-gates.md) — has a "Project-specific tuning" section that's currently empty.

PRs that swap those for parameterized placeholders, or add a worked example showing how to map them to other stacks (Vite, SvelteKit, Express, Bun, etc.), are welcome.

## Style

- **No emoji.** Use prose, GitHub alerts (`> [!NOTE]`, `> [!TIP]`, `> [!IMPORTANT]`), tables, and code blocks.
- **Trigger phrases are concrete.** A skill `description:` should list what a user would actually type (e.g. *"make this an HTML page"*, *"structure your response as HTML"*), not abstract verbs.
- **File-path citations** in skill bodies use `path/to/file.ts:line` format.
- **One artifact per file.** Multi-skill files or multi-prompt files aren't accepted.
- **Pyramid principle** in docs: lead with the recommendation/decision; justify after.

## What's out of scope

- Highly project-specific skills with no portable value (e.g. ones tied to a single internal tool with no public docs).
- Skills that wrap content already in an established plugin marketplace without adding meaningful tailoring.
- Anything that requires committing secrets / API keys / private endpoints.
- Changes that break the no-emoji house style without a strong reason.

## Local development

Clone the repo and run the smoke checks before opening a PR:

```bash
git clone https://github.com/Rijul1204/rashedul-agentic-engineering
cd rashedul-agentic-engineering

# Verify the installer runs cleanly against a temp target
./scripts/install.sh --dry-run --target /tmp/install-smoke

# Verify markdown links resolve (if you have markdown-link-check or similar)
# Otherwise: eyeball the diff and the rendered README on github.com
```

## License

By contributing, you agree your contribution is licensed under the [MIT License](LICENSE) covering this repo.
