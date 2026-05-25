---
name: sprint-execution-protocol
description: Drives a sprint-based delivery loop where every task carries an explicit contract (Context / Scope / Definition of Done / Acceptance Criteria / Testing Step), gets a confidence score with a < 90% escalation path, passes three review lenses (senior engineer, product engineer, UI/UX), and the agent self-validates the whole sprint before asking for the user's go-ahead between sprints. Composes with the srs-to-delivery-plan, grill-me, quality-gates, and pair-agent-harness skills.
---

# Sprint execution protocol

When the user hands you a sprint-shaped plan (EPIC → STORIES → TASKS → SPRINT) and asks you to execute it, drive every sprint with this protocol. The protocol is non-negotiable; the agent runs it round-to-round without being asked.

## Per-task contract

Before writing a single line of code on a task, fill in every field:

| Field | What it answers |
|---|---|
| **Context** | Why this task exists. What story / feature it enables, what comes before, what comes after. |
| **Scope** | Exactly which files / modules are touched. What's IN scope and what's explicitly OUT. |
| **Definition of Done** | Binary checklist — when is this task finished, with no ambiguity? |
| **Acceptance Criteria** | Behavioural criteria from the user / product perspective the task must satisfy. |
| **Testing Step** | Concrete commands to run, browser steps to walk, DB queries to inspect. **Test-driven (red → green → refactor) wherever the surface allows.** |

You validate these fields yourself. If you cannot reason them out from the available context, **stop and ask the user** — do not invent acceptance criteria or definitions of done.

## Confidence scoring

Assign each task a confidence score (0–100%) before starting.

- **If the score is < 90%, state why in one sentence** — missing context? ambiguous acceptance criteria? unfamiliar tech surface? Then try to improve it: read the relevant code, fetch the doc, run a probe, or invoke [`grill-me`](../skills/grill-me/SKILL.md) on the user to pin down the missing decision.
- **Double-confirm the final score before announcing it.** A confidence number you didn't sanity-check is worse than no number.
- **A score is a forecast, not a vibe.** If you wrote 95% and then hit two surprises mid-task, lower the next task's score accordingly — the number is calibration data over time.

## Three-lens task review

Before declaring a task complete, review what you built through three perspectives. Each lens produces a one-line note. If any lens flags something material, fix it before moving on.

1. **Senior engineer** — Are types correct? Are error modes handled, not swallowed? Are tests covering invariants, not just the happy path? Anything that can fail silently failing loud?
2. **Product engineer** — Does it actually solve the user's job? Does the data model match the user's mental model? Is the flow the shortest path to the outcome?
3. **UI/UX expert** — Mobile readable? Loading and empty states present? Keyboard nav + accessibility (labels, focus order, contrast) accounted for? *If the change has no UI, skip this lens explicitly rather than omitting it.*

> For PRs with broader surface (UI + UX + AI-integration in one change) or higher-stakes work, escalate to [`multi-lens-review`](multi-lens-review.md) — six lenses (engineer / product engineer / UI engineer / UX engineer / product owner / AI-integration engineer), each with an explained confidence score, and every file in the diff covered. The three lenses above are the lightweight default; `multi-lens-review` is the rigor pass.

## Sprint-end validation gate

After every task in a sprint is complete, validate the whole sprint end-to-end **before** asking the user for the go-ahead to start the next sprint:

| Check | How |
|---|---|
| UI / UX walk-through | Exercise the new flow in a browser (or device). Capture obvious regressions. |
| Server log inspection | Tail relevant logs through one end-to-end run. Look for unexpected errors, warnings, stack traces. |
| API testing | Hit each touched endpoint with `curl` / `httpie` / Postman. Verify status codes, response shapes, error-case cleanliness. |
| Quality gates | Run the repo's standard gates (delegate to [`quality-gates`](../agents/quality-gates.md) if configured). |

Report a sprint summary back to the user covering: tasks completed, tests passing, regressions found + fixed, recommended go / no-go for the next sprint. **Wait for the user's explicit go-ahead** before starting the next sprint.

## After implementation — capture learnings

When a task or sprint uncovered something non-obvious (a vendor quirk, a framework gotcha, a convention that should be documented), write it down:

- **Codebase-specific lesson** → drop it in the repo's `CLAUDE.md` under the relevant section.
- **Portable rule for future sessions** → save it as an auto-memory entry (`feedback` or `project` type).
- **Pattern with no skill yet** → draft a `SKILL.md` proposal.

Don't capture every detail — only what a future agent would otherwise have to re-discover.

## What this rules out

- Starting code before the per-task contract is filled in.
- Announcing a confidence score without sanity-checking it.
- Skipping the three-lens review because "it looked fine."
- Moving to the next sprint without the user's explicit go-ahead.
- Quietly silencing failures (skipping tests, loosening lint, `--no-verify`) to make a checkpoint pass.

## Composes with

| Skill / agent | When |
|---|---|
| [`srs-to-delivery-plan`](../skills/srs-to-delivery-plan/SKILL.md) | Produces the sprint plan this protocol executes against. |
| [`grill-me`](../skills/grill-me/SKILL.md) | When confidence on a task is < 90% and the missing decision lives in the user's head. |
| [`quality-gates`](../agents/quality-gates.md) | After each task and at the sprint-end validation gate. |
| [`pair-agent-harness`](../skills/pair-agent-harness/SKILL.md) | When the senior-engineer review lens flags something you want a second opinion on before fixing. |
| [`multi-lens-review`](multi-lens-review.md) | Deeper six-lens variant of the three-lens review above. Reach for it when the change has broader surface (UI + UX + AI integration in one PR) or higher stakes. |
| [`handoff`](../skills/handoff/SKILL.md) | At sprint boundaries if the next sprint will run in a fresh session. |
