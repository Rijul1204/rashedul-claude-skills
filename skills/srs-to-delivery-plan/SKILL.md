---
name: srs-to-delivery-plan
description: Convert a SRS into EPICS, user stories, tasks, and a sprint plan using vertical slicing (tracer bullet) principles. Use when breaking down a SRS into implementable work and planning execution.
---

# SRS to Delivery Plan

Convert a Software Requirements Specification (SRS) into a structured delivery plan:

SRS → EPICS → STORIES → TASKS → SPRINT PLAN

This system combines:
- Product thinking (EPICS)
- Vertical slicing (STORIES)
- Execution clarity (TASKS)
- Delivery planning (SPRINTS)

---

# Core Principles

## Vertical Slice (Tracer Bullet)

Each STORY must:

- Deliver a thin but complete end-to-end flow
- Cut through ALL layers (DB → API → UI → integration → tests)
- Be independently testable and demoable
- Provide real user value

Avoid horizontal slices like:
- "Build database schema"
- "Create API layer"

Instead:
- "User can create account and log in"

---

## HITL vs AFK

### HITL (Human-in-the-loop)
Requires:
- Product decisions
- Architecture discussions
- UX validation

### AFK
- Can be implemented and merged independently
- No external decision required

Always maximize AFK stories.

---

# PROCESS

---

## Step 1 — Locate the SRS

Ask the user for:

- GitHub issue number OR
- URL OR
- Raw SRS document

If not available → ask for it.

Do NOT proceed without understanding the SRS.

---

## Step 2 — Understand the System

Extract:

- Core features
- User stories
- Key flows
- System boundaries
- Constraints (tech, product, compliance)

Summarize briefly before proceeding.

---

## Step 3 — Create EPICS

Group features into high-level capabilities.

### EPIC Rules

- Represents a major deliverable
- Takes ~1–3 weeks
- Contains multiple STORIES
- Focus on outcomes, not implementation

### Output Format

For each EPIC:

- Title
- Description
- Covered SRS sections

---

## Step 4 — Create STORIES (Vertical Slices)

Break each EPIC into STORIES.

### STORY Rules

- End-to-end functionality
- Demoable independently
- Small (ideally 1–2 days)
- User-value focused

### STORY Fields

- Title
- Type: HITL / AFK
- Blocked by
- User stories covered (from SRS)

---

## Step 5 — Create TASKS

Break STORIES into TASKS. Each task must be a self-contained work packet with enough detail that the implementer (human or AI agent) can execute without further clarification.

### TASK Rules

- Technical units of work
- 2–8 hours each
- Can be layer-specific
- NOT user-facing
- Must be independently executable with full context

### Required TASK Fields

Every task MUST include ALL of the following:

| Field | Description |
|-------|-------------|
| **Context** | Why this task exists. What story/feature it enables. What came before it and what comes after |
| **Problem Statement** | The specific technical gap this task fills. What doesn't exist or work yet |
| **Scope** | Exactly what files/modules are touched. What is IN scope and what is explicitly OUT of scope |
| **Definition of Done** | Concrete, binary checklist — when is this task finished? No ambiguity |
| **Acceptance Criteria** | Behavioral criteria from the user/product perspective that this task must satisfy |
| **Testing Plan** | What tests to write or run. Unit tests, integration tests, manual verification steps |
| **Validation** | How to verify the task is complete — specific commands to run, pages to check, DB queries to inspect |
| **Key Files** | Existing files to read/modify, with brief explanation of what each provides |
| **Implementation Notes** | Patterns to follow, functions to reuse, gotchas to avoid. Reference existing code by path |
| **Framework Integration** | (Required if task adds a third-party library) SSR compatibility, Next.js config flags, React version requirements, required wrappers or polyfills. Read the library's framework docs and document findings here |

### TASK Examples

- Define DB schema
- Implement API endpoint
- Build UI component
- Write integration test

---

## Step 6 — Quiz the User (MANDATORY)

Present:

### EPICS
### STORIES (grouped by EPIC)
### TASKS (optional preview)

Ask:

- Is EPIC grouping correct?
- Are stories too big or too small?
- Any missing flows?
- Are dependencies valid?
- Are HITL vs AFK classifications correct?
- Should any stories be split or merged?

Iterate until user approves.

---

## Step 7 — Create GitHub Issues

Create issues in this order:

1. EPICS
2. STORIES
3. (Optional) TASK issues

Use the issue templates from [template.md](template.md) for EPIC, STORY, and TASK formatting.

### TASK Handling

Two options:

#### Option A (default)

Keep tasks as a checklist inside the STORY issue.

#### Option B (advanced teams)

Create sub-issues per task. Use the TASK template from [template.md](template.md).

---

## Step 8 — Sprint Planning

After STORIES are created, organize them into sprints.

### Sprint Rules

- Duration: 1 week (recommended)
- Prioritize:
  1. Unblocking stories
  2. Core flows
  3. First usable system
- Balance workload based on capacity

### Sprint Output Format

```md
# Sprint Plan

## Sprint 1
Goal: First working end-to-end flow

Stories:
- #12 User signup & login (AFK)
- #13 Basic dashboard (AFK)
- #14 First data capture (HITL)

---

## Sprint 2
Goal: Core functionality expansion

Stories:
- #15 Data processing (AFK)
- #16 Task extraction (AFK)
```

### Prioritization Strategy

1. Foundations (auth, schema, infra)
2. First usable loop
3. Feature expansion
4. Optimization & scale

---

# Rules to Enforce

- Do NOT skip vertical slicing
- Do NOT create horizontal-only stories
- Do NOT over-bundle stories
- Prefer many small stories over few large ones
- Always validate with user before creating issues
- Always maintain dependency correctness

---

# Final Output Checklist

Before finishing, ensure:

- [ ] EPICS clearly defined
- [ ] STORIES follow vertical slicing
- [ ] TASKS are actionable
- [ ] Dependencies are valid
- [ ] HITL vs AFK correctly assigned
- [ ] Sprint plan is realistic
- [ ] User has approved structure

---

# Optional Enhancements

If user asks, also provide:

- Jira version
- Linear version
- Confluence documentation
- Roadmap view (monthly)
- Team allocation plan

---

# Example (Reference)

## EPIC: Memory System

Stories:

1. Save journal entry (AFK)
2. Extract structured memory (AFK)
3. Link memory to entities (HITL)

---

This skill transforms a static SRS into a complete execution-ready system.

See [template.md](template.md) for all issue templates.
