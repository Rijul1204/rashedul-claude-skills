# claude-code-review

A drop-in GitHub Actions workflow that runs [Claude Code](https://docs.claude.com/en/docs/claude-code) against every PR's diff and posts a single sticky review comment (grade + verdict + action items). Manually re-triggerable via `/claude-review` (or `claude review`) comment, or `workflow_dispatch`.

Sibling template to [`workflows/cursor-review/`](../cursor-review) — same structure, same trigger surface, same sticky-comment design; swap the CLI binary, the API secret, and the trigger phrase. Both can coexist in the same target repo (distinct comment markers).

## What's in this folder

```
.github/
├── workflows/claude_code_review.yml    # the workflow
├── scripts/install_claude_code.sh      # installs @anthropic-ai/claude-code via npm
├── claude-code-config.env              # version pin + optional CLAUDE_MODEL override
└── instructions/
    └── code-review.instructions.md     # the review rubric (REPLACE with your repo's)
```

The contents of `.github/` here mirror exactly what gets installed into the target repo's `.github/` directory, so dropping it in is a single `cp -R`.

## Install into another repo

From the target repo's root:

```bash
# 1. Copy the .github tree across (preserving paths)
cp -R /path/to/rashedul-agentic-engineering/workflows/claude-code-review/.github .

# 2. Replace the rubric with one that fits the target repo's stack
$EDITOR .github/instructions/code-review.instructions.md

# 3. Set the API key secret on the target repo
gh secret set ANTHROPIC_API_KEY --repo <owner>/<repo>

# 4. Open a PR and watch it review itself
```

The workflow YAML and install script are project-agnostic — only the instructions file needs editing.

## How it works

1. **Triggers.** Runs on `pull_request` (opened, synchronize, reopened), on a `/claude-review` issue comment, or via `workflow_dispatch` with a PR number.
2. **Install.** Runs `npm install -g @anthropic-ai/claude-code` (version pinned via `claude-code-config.env`'s `CLAUDE_CODE_VERSION`, default `latest`). Caches `~/.npm` between runs.
3. **Diff capture.** Computes the diff between the PR base and head SHAs, listing only added/modified files (deletions excluded).
4. **Prompt assembly.** Concatenates the instructions file (expanding `{{MODULE:...}}` references) with the file list and the diff.
5. **Claude Code invocation.** Pipes the prompt into `claude --print --output-format text`. Optional `--model <id>` from `CLAUDE_MODEL` env. 10-minute hard timeout.
6. **Sticky comment.** Searches existing PR comments for a `<!-- claude-auto-review-bot -->` HTML-comment marker; updates if present, otherwise creates a new one. Distinct marker from cursor-review so both can co-exist on the same PR without overwriting each other.

## Requirements

- **Repository secret `ANTHROPIC_API_KEY`** — get one at [console.anthropic.com](https://console.anthropic.com/) → API Keys.
- **`pull-requests: write` permission** — already declared in the workflow.
- **Node.js** on the runner — `ubuntu-latest` ships with Node, so no extra setup needed.

## Tuning the rubric

Same as cursor-review — the `instructions/code-review.instructions.md` file becomes the system-level rubric. Useful patterns:

- **One file, all rules** — fine for repos under ~200 lines of rubric.
- **Modular files under `instructions/modules/`** — for larger rubrics, split by theme and reference with `{{MODULE:01-framework.md}}`. Module paths can't contain `..` or absolute prefixes (path traversal is blocked at runtime).
- **Always end with a grading + verdict + action-items block** — the workflow doesn't parse the response, but a consistent shape across PRs makes the comments scannable.

## Tuning the model

Edit `claude-code-config.env`:

```bash
# Pin the CLI version (default: latest)
CLAUDE_CODE_VERSION=latest

# Optional: force a specific model for reviews
CLAUDE_MODEL=claude-opus-4-7        # most capable, slower / more expensive
# CLAUDE_MODEL=claude-sonnet-4-6    # balanced
# CLAUDE_MODEL=claude-haiku-4-5     # fastest / cheapest
```

Default behavior (no `CLAUDE_MODEL` set) uses whatever Claude Code's CLI default is — currently the latest Sonnet.

## Re-triggering a review on an open PR

Drop one of these comments on the PR:

- `/claude-review`
- `claude review`
- `claude review this code`

All three phrases match. Or, from the CLI:

```bash
gh workflow run claude_code_review.yml -f pr_number=123
```

## Known limitations

- Diffs larger than the model's context window will be truncated by Claude Code or the API layer; the workflow catches this and posts a "review too large" note.
- The workflow doesn't post line-level review comments — only a single PR-level sticky comment.
- No support for GitLab / Bitbucket — GitHub Actions only.
- Costs scale with PR size + model choice. For high-volume repos, pin `CLAUDE_MODEL=claude-haiku-4-5` or restrict triggers to `pull_request: types: [opened, reopened]` (drop `synchronize`).

## cursor-review vs claude-code-review

| | [cursor-review](../cursor-review) | claude-code-review (this) |
|---|---|---|
| CLI | `cursor-agent` (Cursor) | `claude` (Anthropic) |
| Install | Cursor installer script | `npm install -g @anthropic-ai/claude-code` |
| Secret | `CURSOR_API_KEY` | `ANTHROPIC_API_KEY` |
| Trigger phrase | `/cursor-review` | `/claude-review` |
| Sticky marker | `<!-- cursor-auto-review-bot -->` | `<!-- claude-auto-review-bot -->` |
| Model selection | Cursor's default | Configurable via `CLAUDE_MODEL` env |

Pick whichever maps to the API key you already have. Both can run side-by-side on the same PR.
