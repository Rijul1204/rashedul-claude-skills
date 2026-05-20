---
name: fizzy-product-manager
description: Product management knowledge for Fizzy Kanban boards — Kanban principles, API workflows, triage, hygiene, and reporting
metadata:
  tags: fizzy, kanban, product-management, api, triage, boards, cards
---

## When to use

Use this skill whenever you are managing Fizzy Kanban boards, triaging cards, running board health checks, generating reports, or performing any product management task via the Fizzy API.

## API Reference

The full Fizzy API specification is at [docs/fizzy-api.md](../../../docs/fizzy-api.md). Load it when you need complete endpoint details, request/response schemas, or parameter references.

## Kanban principles

When applying Kanban methodology to board management, load the [./rules/kanban-principles.md](./rules/kanban-principles.md) file.

## Tap Games operating defaults

When you need Tap Games-specific board templates, ticket templates, working procedure, or code-aware triage defaults, load the [./rules/tap-games-context.md](./rules/tap-games-context.md) file.

## Board triage

When processing the triage queue (Maybe? cards), load the [./rules/card-triage.md](./rules/card-triage.md) file for the decision framework and batch workflow.

## Board hygiene

For routine board maintenance and health checks, load the [./rules/board-hygiene.md](./rules/board-hygiene.md) file for the 7-step weekly checklist.

## Reports

When generating board status reports, activity summaries, or workload breakdowns, load the [./rules/board-reports.md](./rules/board-reports.md) file.

## API recipes

For multi-step curl workflows (triage sessions, health checks, bulk operations), load the [./rules/api-recipes.md](./rules/api-recipes.md) file.

## Jira migration (one-time cutover)

When executing the Fizzy → Jira migration for Tap Games, load the [./rules/jira-migration.md](./rules/jira-migration.md) file. It is the single-use runbook for the cutover into the `TG` project on `globalcompetitionworld.atlassian.net`. Remove the file (and this pointer) after Phase 4 completes.

## How to use

Read individual rule files for detailed explanations, API examples, and workflows:

- [rules/api-basics.md](rules/api-basics.md) - Token setup, URL structure, pagination, caching, and error handling
- [rules/kanban-principles.md](rules/kanban-principles.md) - 4 Kanban principles and 6 core practices applied to Fizzy
- [rules/board-management.md](rules/board-management.md) - Creating, configuring, publishing, and organizing boards
- [rules/column-structure.md](rules/column-structure.md) - Designing workflow columns, colors, and common patterns
- [rules/card-lifecycle.md](rules/card-lifecycle.md) - Full card lifecycle from triage through closure
- [rules/card-triage.md](rules/card-triage.md) - Triage decision framework and batch processing workflow
- [rules/card-writing.md](rules/card-writing.md) - Best practices for card titles, descriptions, and rich text
- [rules/card-details.md](rules/card-details.md) - Steps (todos), reactions (boosts), and pins
- [rules/tagging-strategy.md](rules/tagging-strategy.md) - Tag taxonomy, naming conventions, and filtering
- [rules/assignments-workload.md](rules/assignments-workload.md) - Assignment management and workload balancing
- [rules/wip-limits.md](rules/wip-limits.md) - WIP limit theory and enforcement via API monitoring
- [rules/entropy-management.md](rules/entropy-management.md) - Auto-postpone system and stale card handling
- [rules/board-hygiene.md](rules/board-hygiene.md) - 7-step weekly board maintenance checklist
- [rules/board-reports.md](rules/board-reports.md) - Board snapshots, velocity, health, and workload reports
- [rules/comments-collaboration.md](rules/comments-collaboration.md) - Using comments for PM communication and status updates
- [rules/webhooks-automation.md](rules/webhooks-automation.md) - Real-time webhook setup for external integrations
- [rules/api-recipes.md](rules/api-recipes.md) - Complete multi-step curl recipes for common PM workflows
- [rules/tap-games-context.md](rules/tap-games-context.md) - Team-specific context: boards, members, conventions, templates, code-aware triage defaults
- [rules/jira-migration.md](rules/jira-migration.md) - One-time Fizzy → Jira (`TG` project on GCW) cutover runbook
