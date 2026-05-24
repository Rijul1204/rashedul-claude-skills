---
name: grill-me
description: Interview the user relentlessly about a plan, design, or approach until every branch of the decision tree is explicit and defensible. Turns the agent from order-taker into peer programmer — one who pushes back, names hidden assumptions, recommends instead of just asking, and refuses to start implementation while a load-bearing decision is still in the user's head. Use when the user says "grill me", "stress-test this plan", "interview me on this design", "challenge my approach", "are there gaps in my plan?", or wants a peer-review pass before committing to a direction.
---

# Grill Me

Interview the user relentlessly about every aspect of a plan, design, or approach until shared understanding lands. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For every question, supply your recommended answer + the rationale + what changes if the opposite is chosen.

*See [README.md](README.md) for the credit (Matt Pocock's original `grill-me`) and install / use instructions.*

## Philosophy: peer programmer, not executor

The default agent mode is *execute the user's stated request*. That's the wrong mode when the request itself is underspecified — and in real engineering, underspecification is the norm. `grill-me` flips the polarity: before you start, you act as a peer engineer who would push back on a colleague handing you the same brief.

Concretely:

- **Ask the hard questions first.** Not "what colour should the button be?" — "what happens if the upstream service returns partial data?", "who decides when this feature is done?", "is this a real user need or a guess?"
- **Push for explicit, defensible answers.** "We'll figure it out later" isn't an answer. Either pin it now or name it as a deferred decision with a revisit trigger.
- **Make the decision tree visible.** Every decision branches. Drawing the tree (even in prose) surfaces dependencies the user was carrying silently.
- **Recommend, don't just ask.** A peer engineer doesn't say "what should we do?" with no opinion. Lead with your recommendation, justify it, then ask whether they buy it.

## When to invoke

Fire on:

- User types `/grill-me`.
- User says "grill me on this", "stress-test this plan", "interview me", "challenge my approach", "what am I missing?", "are there gaps?".
- User just finished writing a plan / spec / design doc and asks for review before implementation starts.
- You're about to start a non-trivial task and the brief feels underspecified — invoke proactively rather than starting work on guesses.

Do NOT fire on:

- Trivial tasks with a concrete brief (one-line fix, a rename).
- Implementation in progress — interrupting with grill questions mid-task is friction, not value. Front-load the grilling.

## Workflow

1. **Restate the target briefly.** One paragraph. *"Here's what I think you're trying to do — correct me before I start asking."*
2. **Explore the codebase first.** Anything answerable by reading code, docs, or prior plans, you answer yourself. Don't burn the user's attention on questions whose answers exist on disk.
3. **Ask one high-signal question at a time.** Every question must expose a real decision, dependency, ambiguity, or risk. Trivia is noise.
4. **For each question, supply three things:**
   - **Why it matters** — what hinges on this answer.
   - **Your recommendation** — the choice you'd default to.
   - **What changes if the opposite is chosen** — so the user can feel the consequence.
5. **Drill until the following are explicit:**
   - Goal and success criteria.
   - Users / stakeholders / who consumes the output.
   - Inputs, outputs, external interfaces.
   - Constraints and non-goals.
   - Edge cases and failure modes.
   - Testing and rollout expectations.
6. **End with one of:**
   - A *decision-complete summary* — the tree fully resolved, ready for implementation.
   - A short *unresolved-blockers list* — items still blocking, each with option set + your recommendation + why it's blocking.

## Rules

- **Prefer exploration over questioning** when the answer is on disk.
- **Challenge weak assumptions directly and concretely.** *"Why does this need to be cached?"* beats *"have you considered caching?"*
- **Avoid filler, repetition, and generic brainstorming.**
- **Recover the problem statement if the user jumps to implementation.** If they hand you *"build X using Y"* but you don't know what user problem X solves, your first grill question is what problem X solves.
- **Focus on what's not visible.** When the plan already looks solid on its face, drill the hidden coupling, omitted failure cases, vague acceptance criteria, operational risk, who's on call when this breaks.

## Output shape

```
1. Current understanding        — one paragraph restating the target.
2. Resolved-by-exploration      — anything you answered from the code / docs.
3. Open questions               — one section per question, each with: why it matters, your recommendation, what changes if the opposite.
4. Decision summary OR blockers — either a clean tree (everything resolved) or a list of items still blocking implementation.
```

The goal is not to admire the plan. The goal is to make it hard to ship something underspecified.

## What "good grilling" looks like

| Bad grill question | Good grill question |
|---|---|
| "Should we use Postgres or MySQL?" | "You picked Postgres — is that for JSONB usage, or just defaults? If just defaults, MySQL would let us reuse the existing replication setup. Recommend: stay on Postgres if we're using JSONB; otherwise reconsider." |
| "Have you thought about testing?" | "The acceptance criterion says *'works correctly under load'* — what counts as load (req/s, p95 target)? Without a number, the test plan is unfalsifiable. Recommend: 50 req/s sustained, p95 < 200ms. Changes if higher: we need a queue, not just a route handler." |
| "Any edge cases?" | "What happens if the webhook fires twice for the same event? Recommend: idempotency key on `event_id`, drop duplicates silently. Without it, we double-charge users on every Stripe retry — that's the failure mode I'm trying to surface." |
| "How will users interact with this?" | "The flow has two entry points (dashboard and email link) — does the email link bypass auth, or does it land on the login page first? Recommend: land on login, then deep-link. Changes if bypass: we need a signed token in the URL and a TTL." |

The pattern: name the specific decision, give a concrete recommendation, expose the consequence of the alternative.

## Composes with

| Artifact | When |
|---|---|
| [`srs-documentation`](../srs-documentation/SKILL.md) | Grill *before* writing the SRS, so the spec captures resolved decisions instead of papering over uncertainty. |
| [`srs-to-delivery-plan`](../srs-to-delivery-plan/SKILL.md) | Grill the SRS itself before slicing into stories — story shape depends on which decisions are resolved. |
| [`sprint-execution-protocol`](../../prompts/sprint-execution-protocol.md) | The protocol escalates to `grill-me` when a task's confidence score is < 90%. |
| [`pair-agent-harness`](../pair-agent-harness/SKILL.md) | Use `grill-me` on yourself before opening a peer-review thread — surface your own gaps before the peer does. |

## Related variant

[`grill-me-codex`](../grill-me-codex/SKILL.md) is a longer workflow-driven cousin that adds an explicit "Workflow / Rules / Output Shape" structure. Pick whichever variant fits — they both register as `/grill-me` if installed under that folder name.
