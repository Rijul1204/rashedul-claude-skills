---
name: tap-games-context
description: Team-specific context for Tap Games — boards, members, conventions, and current focus
metadata:
  tags: tap-games, team, context, conventions, configuration
---

# Tap Games Context

**Account**: Rashedul's Fizzy
**Account Slug**: `6132669`
**Product**: Jackpot Snap (tap game)
**Organization**: Audacity Ventures

## Team Members & Roles

| Name | User ID | Role | Email |
|------|---------|------|-------|
| Rashedul Hasan Rijul | `03fcgt6qb0fwa58clr8f61c6b` | owner | rashedul@audacityventures.ca |
| Rifat Jahan Azad | `03ficas3vlytzg3o534v44dvt` | member | azad@audacityventures.ca |
| Abu Bakkar Siddiq | `03fcgvzp9h8f9a0he9aad586y` | member | siddiq@audacityventures.ca |
| Naimuddin Shahjalal Bhuyan | `03ffby70id83w8aj6ryo7v6kz` | member | naimuddin@audacityventures.ca |
| Ridi Hossain | `03fcgvno2r4g731eh9w7e04zi` | member | ridi@audacityventures.ca |
| Raufir Shanto | `03fm98xqtkf4v3vljfgj7jz1w` | member | raufir@audacityventures.ca |
| Mamun Morshed | `03fckl5p9l50oun0qco95u9ar` | member | mamun@audacityit.com |
| Labonno | `03fcgx6fu87008ynrnlq2mrwt` | member | qa@audacityventures.ca |
| Cody | `03ffivvqbsqn35iiz9xbzbu8n` | member | cody@globalcompetitionworld.com |

## Active Boards & Purpose

| Board | ID | Purpose | Entropy |
|-------|------|---------|---------|
| Production Preparation | `03fw09thuwj0lr952vfpoimoh` | Launch readiness, deployment coordination, and final release tasks | 30 days |
| Performance, security and testing | `03frf9xrwha93r1iytv9skr5q` | Engineering hardening work for performance, security, and test stabilization | 30 days |
| QA board | `03fd4omd9qico7wmyyof5yfe4` | Bug tracking, QA verification, and deployment follow-up | 30 days |

## Column Conventions per Board

### Production Preparation
No columns yet.

### Performance, security and testing
| Column | Meaning |
|--------|---------|
| In Progress | Actively being worked on |
| Review | Awaiting code review |
| Ready for QA | Done coding, needs QA verification |

### QA board
| Column | Meaning |
|--------|---------|
| Improvements | General improvement items |
| Bug | Confirmed bugs |
| Issues from Cody | Issues reported by Cody |
| In progress | Being investigated/fixed |
| ready for deployment | Fix verified, awaiting deploy |
| Ready for QA | Needs QA re-verification |

## Tag Taxonomy

### Type
- `bug` — Confirmed bug
- `untracked bug` — Bug found outside normal tracking
- `blocker` — Blocking other work
- `improvement` — Enhancement to existing functionality
- `system design` — Architecture/design task

### Estimation (hours)
- `est 1h`, `est 2h`, `est 3h`, `est 5h`, `est 8h`

### Sprint
- `s1`, `s2`, `s3` — Sprint identifiers

### Person
- `cody` — Items related to/reported by Cody

## Current Sprint/Cycle Focus

<!-- Update this with current priorities -->
**Current phase**: Production Preparation (as of April 2026)
- Production Preparation is the primary board for launch readiness and release coordination
- Performance, security and testing is the active engineering hardening board
- QA board is tracking defects, verification, and deployment readiness

## Recurring Cadences

<!-- Fill in your team's meeting schedule -->
| Cadence | Frequency | Day/Time | Purpose |
|---------|-----------|----------|---------|
| <!-- Standup --> | <!-- Daily --> | <!-- TBD --> | <!-- Quick sync --> |
| <!-- Triage --> | <!-- Weekly --> | <!-- TBD --> | <!-- Process Maybe? queue --> |
| <!-- Board Review --> | <!-- Bi-weekly --> | <!-- TBD --> | <!-- Health check --> |

## Team Operating Playbook

Unless explicitly told otherwise, use the conventions in this section for Tap Games board design, ticket writing, and day-to-day Kanban operation.

### Board Template

#### Default Fizzy policy

- Treat `Maybe?`, `Not Now`, and `Done` as Fizzy lifecycle states, not custom columns.
- Keep active workflow columns lean and outcome-based.
- Every active card should have one owner, clear acceptance criteria, and an obvious next step.
- Use tags to classify work where possible; avoid creating extra columns for classification only.

#### Production Preparation template

- Lifecycle: `Maybe?` -> `In Progress` -> `Blocked` -> `Deployed` -> `Done`
- Use `Not Now` for explicitly deferred work, not for items awaiting active pull.
- `In Progress` means the team is actively moving the item now.
- `Blocked` means work cannot proceed without a dependency, decision, or external input.
- `Deployed` means the change is shipped or released but still open for verification, monitoring, or follow-up.
- `Done` means the card can be closed in Fizzy because no more action is required.

#### Production Preparation WIP defaults

- `In Progress`: max 3
- `Blocked`: max 2
- `Deployed`: max 2

### Ticket Template

Tickets should be detailed enough that anyone can self-assign and execute without additional briefing. Use HTML formatting (Fizzy uses ActionText/Trix — markdown does not render).

**Required sections** (in this order):

```html
<h2>What</h2>
<p>What needs to be done (1-2 sentences).</p>

<h2>Why</h2>
<p>Business context and motivation. Reference source (email, meeting, stakeholder request). Why does this matter?</p>

<h2>How</h2>
<ol>
  <li>Step-by-step implementation approach</li>
  <li>Include file paths, service names, and code entry points where known</li>
</ol>

<h2>Solution Sketches</h2>
<ul>
  <li>Alternative approaches considered</li>
  <li>Key technical decisions and trade-offs</li>
  <li>Optional/future enhancements worth noting</li>
</ul>

<h2>Acceptance Criteria</h2>
<ul>
  <li>Testable outcomes (not implementation tasks)</li>
  <li>Each criterion should be independently verifiable</li>
</ul>

<h2>Validation Steps</h2>
<ul>
  <li>Concrete steps to verify the work is done correctly</li>
  <li>Tools to use, what to check, expected results</li>
</ul>

<h2>Definition of Done</h2>
<p>One-line summary of when this ticket can be closed.</p>
```

**Optional fields** (add when relevant):
- `<p><strong>Depends on:</strong> ticket #NNN</p>` — cross-ticket dependencies
- References to related Snap repo paths, services, or external docs

#### Ticket writing rules

- Keep titles short, specific, and action-oriented.
- Prefer engineering language over product-marketing wording.
- Write acceptance criteria as testable outcomes, not implementation tasks.
- Reference business context sources briefly in the Why section (email dates, meeting names).
- Include technical specifics in How and Solution Sketches (file paths, code patterns, IDs).
- Keep Validation Steps explicit enough that QA or another engineer can verify the work without guessing.
- Always use HTML tags in descriptions — markdown syntax renders as literal text in Fizzy.

### Working Procedure

#### Intake and triage

1. New work starts in `Maybe?`.
2. During triage, decide one of four outcomes:
   - move to an active workflow state if it should be worked now
   - move to `Not Now` if it is valid but deferred
   - close it if it is duplicate, obsolete, or already done
   - leave it in `Maybe?` and request clarification if it is not decision-ready

#### Before starting work

- Assign one primary owner.
- Make sure the ticket has objective, acceptance criteria, and basic technical context.
- Confirm the work belongs on the current board and is not blocked by missing inputs.

#### While work is active

- Use `In Progress` only for work being acted on now.
- Move cards to `Blocked` immediately when progress stops.
- Add a comment describing the blocker, dependency, or decision needed.
- Do not keep stale or waiting work in `In Progress`.

#### When work is shipped

- Move the card to `Deployed` when the change is out but still needs confirmation.
- Close the card only after verification, monitoring, or follow-up is complete.
- Reopen or move back into active work if issues are found after deployment.

#### Weekly maintenance

- Review `Maybe?` and `Not Now`.
- Check for stale `In Progress` or `Blocked` cards.
- Clear `Deployed` cards that are ready to close.
- Review unassigned active work and any WIP violations.

## Snap Codebase Reference

Use the Snap product repo as the canonical code reference during ticket triage and ticket updates:

- Repo root: `/Users/rijul/Projects/snap`
- This PM repo stores durable pointers and triage procedure only. Do not duplicate large amounts of Snap architecture or volatile implementation detail here.
- When a ticket needs code-aware refinement, inspect the Snap repo directly before updating the card.

### Read order before code-aware triage

1. Read `/Users/rijul/Projects/snap/CLAUDE.md` for overall product topology and service boundaries.
2. Read the relevant service `CLAUDE.md` next when it exists.
3. Read the service `README.md` after that for commands, environment, and local conventions.
4. Inspect nearby code paths only after the docs pass narrows the likely ownership.

### Service index

| Repo | Primary responsibility |
|------|------------------------|
| `tap-games-frontend` | Player-facing Next.js frontend and BFF routes |
| `payment-service` | Bankful payment processing and payout flows |
| `competition` | Competition lifecycle, enrollments, rounds, and leaderboards |
| `game-engine` | Real-time gameplay over Socket.IO |
| `user` | Auth, profile, wallet, and identity services |
| `validity-check` | Card fairness and anti-bot verification |
| `snap-admin` | Admin dashboard and competition operations |
| `snap-infra` | Terraform, deployment, environment, and infrastructure |
| `tap-games-qa` | Internal QA tool for test data setup, inspection, and cleanup |

### Board-to-codebase map

| Board | Typical code ownership |
|------|-------------------------|
| `Production Preparation` | Cross-cutting launch and release work across `tap-games-frontend`, `snap-admin`, backend services, `snap-infra`, and sometimes `tap-games-qa` |
| `Performance, security and testing` | Engineering hardening work across `tap-games-frontend`, `game-engine`, `competition`, `user`, `payment-service`, `validity-check`, and `snap-infra` |
| `QA board` | Defect verification and regression follow-up across any product repo; include `tap-games-qa` when the task needs QA data setup or cleanup |

### Concern-to-entry-point map

| Concern | Stable starting points |
|---------|------------------------|
| Payments / enrollment | `/Users/rijul/Projects/snap/tap-games-frontend/app/api/payment/route.ts`, `/Users/rijul/Projects/snap/payment-service/src/payment/payment.service.ts`, `/Users/rijul/Projects/snap/competition/src/competitions/competitions.service.ts` |
| Gameplay / realtime | `/Users/rijul/Projects/snap/game-engine/CLAUDE.md`, `/Users/rijul/Projects/snap/validity-check/CLAUDE.md`, `/Users/rijul/Projects/snap/tap-games-frontend/components/game/` |
| Auth / profile | `/Users/rijul/Projects/snap/user/CLAUDE.md`, `/Users/rijul/Projects/snap/tap-games-frontend/CLAUDE.md` |
| Admin / competition ops | `/Users/rijul/Projects/snap/snap-admin/CLAUDE.md`, `/Users/rijul/Projects/snap/competition/CLAUDE.md` |
| Infra / deploy / env | `/Users/rijul/Projects/snap/snap-infra/CLAUDE.md` |
| QA tooling / test data | `/Users/rijul/Projects/snap/tap-games-qa/CLAUDE.md` |

### Code-aware triage procedure

1. Identify the user flow, subsystem, or operational concern from the Fizzy ticket.
2. Map the ticket to the most likely primary repo and any secondary repos using the board map and concern map above.
3. Read the canonical docs in order before making assumptions about ownership or implementation.
4. Inspect nearby code only far enough to confirm the likely entry points, constraints, and cross-service dependencies.
5. Update the ticket with concrete code-facing notes instead of vague guesses.

### Ticket enrichment output

When a ticket has been refined using code inspection, include these fields where useful:

- `Likely affected repo(s)`
- `Primary entry point(s) / paths`
- `Dependencies / cross-service touchpoints`
- `Testing path`
- `Open unknowns` only when code inspection cannot resolve them

### Stability rule

- Prefer absolute paths, repo names, and stable entrypoints over copied implementation detail.
- Do not copy volatile branch names, deployment state, or deep architecture notes into this PM repo unless they are needed as recurring triage guidance.
