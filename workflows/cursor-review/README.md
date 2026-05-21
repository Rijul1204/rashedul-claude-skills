# cursor-review

A drop-in GitHub Actions workflow that runs the [Cursor Agent](https://docs.cursor.com/agents) against every PR's diff and posts a single sticky review comment (grade + verdict + action items). Manually re-triggerable via `/cursor-review` (or `cursor review`) comment, or `workflow_dispatch`.

## What's in this folder

```
.github/
├── workflows/cursor_review.yml         # the workflow
├── scripts/install_cursor_agent.sh     # installs cursor-agent CLI with checksum + cache
├── cursor-agent-config.env             # version pin + install checksum (optional)
└── instructions/
    └── code-review.instructions.md     # the review rubric (REPLACE with your repo's)
```

The contents of `.github/` here mirror exactly what gets installed into the target repo's `.github/` directory, so dropping it in is a single `cp -R`.

## Install into another repo

From the target repo's root:

```bash
# 1. Copy the .github tree across (preserving paths)
cp -R /path/to/rashedul-agentic-engineering/workflows/cursor-review/.github .

# 2. Replace the rubric with one that fits the target repo's stack
$EDITOR .github/instructions/code-review.instructions.md

# 3. Set the API key secret on the target repo
gh secret set CURSOR_API_KEY --repo <owner>/<repo>

# 4. Open a PR and watch it review itself
```

The workflow YAML and install script are project-agnostic — only the instructions file needs editing.

## How it works

1. **Triggers.** Runs on `pull_request` (opened, synchronize, reopened), on a `/cursor-review` issue comment, or via `workflow_dispatch` with a PR number.
2. **Install.** Caches the `cursor-agent` CLI between runs; checksum-verifies the installer when one is pinned in `cursor-agent-config.env`.
3. **Diff capture.** Computes the diff between the PR base and head SHAs, listing only added/modified files (deletions excluded).
4. **Prompt assembly.** Concatenates the instructions file (expanding `{{MODULE:...}}` references) with the file list and the diff.
5. **Cursor invocation.** Pipes the prompt into `cursor-agent --trust --output-format text`. 10-minute hard timeout.
6. **Sticky comment.** Searches existing PR comments for a `<!-- cursor-auto-review-bot -->` HTML-comment marker; updates if present, otherwise creates a new one. Avoids stacking comments across re-runs.

## Requirements

- **Repository secret `CURSOR_API_KEY`** — get one at https://cursor.com → Settings → API.
- **`pull-requests: write` permission** — already declared in the workflow.
- Linux runner (ubuntu-latest). The install script is Linux-only.

## Tuning the rubric

The `instructions/code-review.instructions.md` file becomes the system-level rubric. Useful patterns:

- **One file, all rules** — fine for repos under ~200 lines of rubric.
- **Modular files under `instructions/modules/`** — for larger rubrics, split by theme and reference with `{{MODULE:01-framework.md}}`. Module paths can't contain `..` or absolute prefixes (path traversal is blocked at runtime).
- **Always end with a grading + verdict + action-items block** — the workflow doesn't parse the response, but a consistent shape across PRs makes the comments scannable.

## Re-triggering a review on an open PR

Drop one of these comments on the PR:

- `/cursor-review`
- `cursor review`
- `cursor review this code`

All three phrases match. Or, from the CLI:

```bash
gh workflow run cursor_review.yml -f pr_number=123
```

## Known limitations

- Diffs larger than Cursor's prompt limit will fail at the API layer; the workflow catches this and posts a "review too large" note.
- The workflow doesn't post line-level review comments — only a single PR-level sticky comment.
- No support for GitLab / Bitbucket — GitHub Actions only.
