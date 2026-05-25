---
name: multi-lens-review
description: Review a change through six senior-engineer lenses — senior engineer, senior product engineer, senior UI engineer, senior UX engineer, product owner, and AI-integration engineer — and report a confidence score for each, with explained reasoning. Every confidence level requires justification; any score below 90% must name the gap (missing context, untested branch, vendor-schema risk, etc.). No file in the diff goes unreviewed. Use when stress-testing a PR, design, or implementation before commit / merge. Deeper variant of the three-lens review in sprint-execution-protocol.
---

# Multi-lens review

When reviewing a non-trivial change (a PR, a design proposal, a finished slice ready for commit), put on six senior-reviewer hats in order. Each lens produces an explicit verdict, a confidence score, **and the reasoning behind that score**. Bare numbers are invalid. Skipping a lens silently is invalid.

The discipline is meant to surface the blind spots a single-perspective review misses — code that looks correct but ships the wrong feature, UI that types-check but is unusable, a clever AI integration that costs $0.40 per request.

## The six lenses

| Lens | What it cares about |
|---|---|
| **Senior engineer** | Types are correct and meaningful (no `any` escapes). Error modes handled, not swallowed. Tests cover invariants, not just the happy path. Anything that can fail silently fails loud. The simpler design wasn't overlooked. No machine-local paths / secrets leaked. |
| **Senior product engineer** | Does this actually solve the user's job? Does the data model match the user's mental model, or is the user being asked to learn the implementation? Is this the shortest path to outcome, or is it a clever solution to a problem the user doesn't have? |
| **Senior UI engineer** | Component structure (no mode-switching props masking deeper coupling). Hook usage and dependencies. Accessibility — labels, focus order, contrast ratio, keyboard nav. Responsive behavior across breakpoints. Performance regressions (re-renders, bundle size). |
| **Senior UX engineer** | The full user flow — entry points, copy, affordances, friction. Edge states are explicit and designed: empty / loading / partial / error / success / offline. Microcopy is precise. What happens on slow networks, on small screens, with assistive tech. |
| **Product owner** | Business value vs cost. Scope discipline — what's IN, what's explicitly OUT. Prioritization vs other in-flight work. Alignment with the roadmap / quarterly objective. Is this the right thing to ship *now*, or should it be deferred / split? |
| **AI-integration engineer** | Vendor boundaries (one client class per vendor, not inline `fetch`). Prompt design (token efficiency, instruction clarity, JSON-mode where applicable). Schema-drift risk (does the call site have a date-stamped `[Doc check]` comment?). Hallucination paths and fallback / retry strategy. Cost per call and latency budget. |

## The discipline

Apply these four rules without exception:

1. **Every lens reports.** No silent skips. If a lens genuinely doesn't apply (e.g. a docs-only change has no UI/UX surface), say so explicitly with a one-line reason: *"UX: N/A — this PR only touches README markdown, no user-facing flow changed."* Omitting a lens reads as "I forgot," not "I considered and dismissed."

2. **Every confidence level carries explained reasoning.** The format is non-negotiable:

   ```
   <Lens>: <NN>% — <one-to-two-sentence reasoning>
   ```

   A confidence number without reasoning is just a guess wearing a percent sign. State *why* you landed at that number: what you saw, what you didn't see, what would change the score.

3. **Confidence < 90% requires a "why" + a remediation hint.** Name the gap concretely:
   - *"missing context: the spec doesn't say what happens on partial vendor response"* → ask the user, or read the vendor doc.
   - *"untested branch: the retry path in `lib/foo.ts:88` has no test covering the 5xx case"* → write the test.
   - *"unfamiliar surface: I haven't worked with the Realtime API; can't judge the auth model"* → defer to a `pair-agent-harness` thread with a vendor-savvy peer.

   The remediation hint converts a low score from a complaint into an action item.

4. **No file in the diff goes unreviewed.** For each lens, list which files were considered. If a lens scanned a file and found nothing material, write *"`path/to/file.ts` — scanned, no issues"* rather than dropping it from the list. Omission and "fine" must be distinguishable in writing.

## Output shape

Use this shape verbatim:

```markdown
## Multi-lens review — <one-line change summary>

### Senior engineer — <NN>% confidence
**Reasoning:** <why this number>
**Files scanned:**
- `path/to/file.ts` — <one-line finding, or "scanned, no issues">
- ...
**Findings:**
- <issue 1, with file:line citation>
- ...

### Senior product engineer — <NN>% confidence
**Reasoning:** ...
**Files scanned:** ...
**Findings:** ...

### Senior UI engineer — <NN>% confidence
... (same shape)

### Senior UX engineer — <NN>% confidence
... (same shape)

### Product owner — <NN>% confidence
... (same shape)

### AI-integration engineer — <NN>% confidence
... (same shape)

---

## Verdict

- **Lowest confidence:** <lens> at <NN>% — <why this is the weakest link>
- **Highest confidence:** <lens> at <NN>% — <why this is the strongest>
- **Overall recommendation:** APPROVE / APPROVE WITH MINOR CHANGES / REQUEST CHANGES / REJECT
- **Blockers** (if any):
  - <concrete action item with owner>

## Action items by priority

1. <highest-priority fix, file + line + what to change>
2. ...
```

## What this rules out

- **Bare confidence numbers.** "Senior engineer: 92%" is invalid. Must include reasoning.
- **Silent lens skips.** If you didn't review through a lens, say "N/A because X" — don't omit the heading.
- **"Confidence < 90%" without a "why".** A low score with no explanation is uncalibrated noise.
- **Omitting files from the file-scan lists.** A reader should be able to ask "did the reviewer look at `lib/foo.ts`?" and find a yes/no answer in the report.
- **One-line "looks good to me" reviews.** Every lens produces real findings or an explicit "scanned — no issues" — the *act of scanning* must be recorded.
- **Confidence-shopping the verdict.** If three lenses are < 80%, the overall recommendation can't be APPROVE.

## Calibration

Confidence is a forecast, not a vibe. If you write 95% on a lens and then a follow-up bug ships from exactly the area that lens was supposed to cover, **retroactively lower the next review's score for that lens by 5–10 points**. Over time the number becomes data; bad calibration is more valuable than no calibration.

## Composes with

| Skill / prompt | Relationship |
|---|---|
| [`sprint-execution-protocol`](sprint-execution-protocol.md) | Has a lighter three-lens version (senior engineer / product / UI-UX) embedded in its per-task contract. Reach for `multi-lens-review` when the change has more surface — anything touching UI + UX + AI integration in one PR — or when the stakes warrant the extra rigor. |
| [`grill-me`](../skills/grill-me/README.md) | Use *before* a non-trivial design lands; use `multi-lens-review` *after* on the implementation. The two close a loop: grill the design until decisions are explicit, then verify the build through six lenses. |
| [`quality-gates`](../agents/quality-gates.md) | Mechanical pass/fail (lint, types, tests). Multi-lens-review is judgment-pass; gates is mechanical-pass. Run both before commit. |
| [`pair-agent-harness`](../skills/pair-agent-harness/README.md) | Open a peer-review thread with this prompt loaded on both sides for the most thorough cross-agent review of the same change. |
