# Issue Templates

## EPIC Issue Template

```md
## EPIC: <Title>

## Parent SRS
#<SRS-issue-number>

## Description
High-level capability derived from the SRS.

## Success Criteria
- [ ] Capability is fully functional
- [ ] All child stories completed

## Child Stories
- #<story-1>
- #<story-2>
```

---

## STORY Issue Template

```md
## Parent EPIC
#<EPIC-number>

## Parent SRS
#<SRS-number>

## What to build
Describe the end-to-end vertical slice.

## Acceptance criteria
- [ ] Works end-to-end
- [ ] Testable independently
- [ ] Integrated across all layers

## Blocked by
- #<issue-number> (if any)
OR
None - can start immediately

## Tasks
- [ ] Task 1
- [ ] Task 2

## User stories addressed
- User story X
- User story Y

## Type
AFK / HITL
```

---

## TASK Issue Template (Option B)

Use this template when creating separate sub-issues per task (Option B). Every field is REQUIRED — a task without full context is not actionable.

```md
## Parent STORY
#<STORY-number>

## Context
Why this task exists. What story/feature it enables. What came before
and what comes after in the dependency chain.

## Problem Statement
The specific technical gap this task fills. What doesn't exist or work
yet that this task will create or fix.

## Scope
**In scope:**
- File/module 1: what changes
- File/module 2: what changes

**Out of scope:**
- What this task explicitly does NOT touch

## Definition of Done
- [ ] Binary checklist item 1
- [ ] Binary checklist item 2

## Acceptance Criteria
- [ ] Behavioral criteria from user/product perspective
- [ ] Observable outcome that proves correctness

## Testing Plan
- [ ] Unit tests: what to test, edge cases
- [ ] Integration tests: end-to-end verification
- [ ] Manual checks: what to try in the browser/terminal

## Validation
Steps the implementer runs to confirm the task is complete:
1. Command or action
2. Expected result

## Key Files
- `path/to/file.ts` — what it provides, why it matters
- `path/to/reference.ts` — pattern to follow

## Implementation Notes
Patterns to follow, functions to reuse, gotchas to avoid.
Reference existing code by path.

## Layer
DB / API / UI / Integration / Tests

## Estimate
2-8 hours
```
