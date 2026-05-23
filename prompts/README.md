# Prompts

Paste-ready prompt fragments. One file per prompt, kebab-case name, body is the prompt text. No magic — copy the contents of a file into a Claude conversation (or into the system prompt of a Claude API call) and the rule kicks in.

## Convention

- **One prompt per file**, named `<kebab-case-topic>.md`.
- **Frontmatter optional.** If present, YAML with `name` (matching the filename) and `description` (one line). Useful when a future skill auto-loads prompts as slash commands; not required today.
- **Body is the prompt text itself.** Lead with the rule in 2-3 sentences (pyramid principle). Justify after. End with concrete examples or a one-line "apply by:" if the rule isn't self-evident.
- **No multi-prompt files.** If two rules naturally compose, link to them; don't merge.

## When to add a prompt here

A pattern earns a file under `prompts/` when it's:

- **Reusable across stacks and conversations** — not tied to a specific repo or vendor.
- **Already documented somewhere** (a CLAUDE.md rule, a written best-practice, a paragraph in a design doc) — i.e. you've already articulated it.
- **Short enough to paste verbatim** — under ~25 lines. Longer guidance belongs in a skill.

Anti-patterns: anything project-specific (lives in that project's CLAUDE.md), anything that needs tools or branching logic (becomes a skill instead), or anything that's only useful once (lives in the conversation, not the repo).

## Prompts

| File | What it does |
|---|---|
| [`pyramid-response.md`](pyramid-response.md) | Forces pyramid-principle responses — recommendation in sentences 1-3, justification after. |
| [`docs-probe-before-code.md`](docs-probe-before-code.md) | Pre-arms a third-party-integration conversation to follow docs → probe → fixture → code. |
| [`sprint-execution-protocol.md`](sprint-execution-protocol.md) | Multi-step delivery contract: per-task fields, confidence scoring, three-lens review, sprint-end validation gate. Composes with `srs-to-delivery-plan`, `grill-me`, `quality-gates`. |

## How to use

**Inline (one-off):** Paste the file's body at the top of a new conversation.

**System prompt (durable):** Add the body to your project's `CLAUDE.md` under the relevant section, or to the system prompt in an Anthropic SDK call.

**As a skill trigger (advanced):** A future skill could auto-load these files as slash commands (`/pyramid-response`, etc.). Not built yet.
