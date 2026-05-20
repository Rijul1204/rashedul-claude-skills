---
name: kanban-principles
description: The 4 Kanban principles and 6 core practices applied to Fizzy board management
metadata:
  tags: kanban, principles, practices, wip, flow, visualization, improvement
---

## Change Management Principles

1. **Start with what you do now** — Model the board to reflect actual current workflows, not an idealized process. Map existing team habits into columns.
2. **Pursue evolutionary change** — Improve incrementally. Rename a column, adjust a WIP limit, add a tag category. Don't reorganize everything at once.
3. **Encourage leadership at all levels** — Anyone on the team can triage a card, flag a stalled item, or suggest a workflow change.

## Service Delivery Principles

1. **Focus on customer needs** — Prioritize cards that deliver value to users. Use the triage step to filter signal from noise.
2. **Manage the work, not the people** — Track cards and flow, not individual output. The board shows what needs attention.
3. **Review policies regularly** — Revisit column structure, tag taxonomy, and entropy settings periodically. What worked last month may not work now.

## 6 Core Practices

### 1. Visualize

Fizzy boards are your visualization. Every card, column, and tag makes work visible.

**In Fizzy**: Keep boards up to date. A card that is done but still in "In Progress" is worse than invisible — it is misleading.

### 2. Limit Work in Progress

Cap the number of cards in active columns. When a column is full, finish work before starting new work.

**In Fizzy**: Monitor column card counts via the API. Flag columns exceeding the WIP threshold. See [wip-limits.md](./wip-limits.md).

### 3. Manage Flow

Work should move steadily from left to right. Watch for bottlenecks — columns where cards pile up.

**In Fizzy**: Use `last_active_at` to spot stalled cards. Use `indexed_by=stalled` and `indexed_by=postponing_soon` filters. See [entropy-management.md](./entropy-management.md).

### 4. Make Policies Explicit

Document how work moves through the board. What does "In Progress" mean? When is a card "Done"?

**In Fizzy**: Use board `public_description` for workflow rules. Use column names that describe the policy (e.g., "Needs Review" not just "Review"). Use [tap-games-context.md](./tap-games-context.md) to record conventions.

### 5. Implement Feedback Loops

Regular check-ins surface problems early. Review metrics, discuss blockers, celebrate completions.

**In Fizzy**: Run weekly health checks ([board-hygiene.md](./board-hygiene.md)). Generate activity digests ([board-reports.md](./board-reports.md)). Use comments to document retrospective findings.

### 6. Improve Collaboratively

Experiment with small changes. Measure impact. Keep what works, revert what doesn't.

**In Fizzy**: Try adjusting entropy periods, adding a new column, or changing the tagging scheme. Review the effect in the next health check.

## Key Metrics

- **Lead time**: How long from card creation to closure
- **Delivery rate**: Cards closed per week
- **WIP count**: Active cards in progress right now
- **Triage queue size**: Untriaged cards waiting for a decision

Track these through the API using card filters (`creation`, `closure`, `indexed_by`).

## See also

- [wip-limits.md](./wip-limits.md) - Detailed WIP limit enforcement
- [board-hygiene.md](./board-hygiene.md) - Weekly maintenance routine
- [board-reports.md](./board-reports.md) - Generating metric reports
