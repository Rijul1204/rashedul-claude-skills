# Automated Code Review Guidelines

> **Replace this file with your repo's review rubric before relying on the workflow.**
>
> This is a starter template. The workflow at `.github/workflows/cursor_review.yml` reads this file (and any `{{MODULE:...}}` files under `.github/instructions/modules/`) verbatim into the review prompt, so anything written here becomes the rubric Cursor uses on every PR.

**Context:** Briefly describe what this repo is — framework, language, architecture, key conventions. The reviewing agent uses this to calibrate its expectations. Example: *"This is a Next.js 15 monorepo using TypeScript, Drizzle ORM, and Tailwind. Apps live under `apps/`, shared code under `packages/`."*

**CRITICAL:** Review ONLY the code changes shown in the diff below. Do NOT review files that weren't changed.

---

## What to check

List the conventions, patterns, and pitfalls that matter for this repo. Group by theme. Suggested sections:

### Framework & architecture

- Bullet specific patterns the framework enforces or that your team has agreed on.
- E.g. *"Server Components by default; only mark `'use client'` when the component uses hooks or browser APIs."*

### Type safety

- E.g. *"No `any`. Prefer `unknown` + narrowing. Use `satisfies` for inferred-but-checked literals."*

### Data layer

- E.g. *"All DB writes go through the repository layer (`lib/db/repos/`), never inline Drizzle calls in route handlers."*

### Security

- Flag unsanitized HTML injection paths (e.g. raw HTML inserted into the DOM without an explicit sanitizer).
- No secrets, tokens, or API keys committed.
- Inputs crossing trust boundaries must be validated before use.

### Performance

- E.g. *"Avoid waterfall fetches in Server Components — use `Promise.all` or React's `cache()`."*

### Testing

- E.g. *"Every new public function gets a vitest unit test; every new route gets an integration test."*

---

## Optional: modular rules

For larger rubrics, split rules into files under `.github/instructions/modules/` and reference them here:

```
### Framework & architecture
{{MODULE:01-framework-patterns.md}}

### Type safety
{{MODULE:02-typescript-standards.md}}
```

The workflow expands `{{MODULE:filename.md}}` to the contents of `.github/instructions/modules/filename.md` at runtime. Module paths must not contain `..` or absolute prefixes.

---

## Grading & verdict

End every review with:

**Overall Grade:** (A+, A, A-, B+, B, B-, C+, C, C-, D, F)
- A+ / A: Exceptional — follows all conventions, no issues.
- B: Good with minor issues.
- C: Acceptable but needs improvements.
- D / F: Significant issues that must be addressed.

**Verdict:** (Choose one)
- APPROVE — ready to merge.
- APPROVE WITH MINOR COMMENTS — small suggestions, can merge.
- REQUEST CHANGES — issues must be fixed first.
- REJECT — major problems, needs rework.

**Summary:** 2–3 sentences justifying grade and verdict.

**Action Items:** Concrete fixes with file paths and line references. Skip when grade is A / A+.
