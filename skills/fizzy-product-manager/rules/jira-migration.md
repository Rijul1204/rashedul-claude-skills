---
name: jira-migration
description: One-time runbook for migrating active Fizzy boards into the existing Jira `TG` project on globalcompetitionworld.atlassian.net
metadata:
  tags: jira, migration, cutover, atlassian, tap-games, one-time
---

## When to use

Load this rule only when executing the Fizzy → Jira migration for Tap Games. It is a one-shot cutover, not a repeating workflow. After Phase 4 completes, this file becomes historical.

## Direction

- **Source**: Fizzy account `6132669` — boards `Production Preparation` (`03fw09thuwj0lr952vfpoimoh`), `Performance, security and testing` (`03frf9xrwha93r1iytv9skr5q`), `QA board` (`03fd4omd9qico7wmyyof5yfe4`).
- **Target**: Jira project `TG` (id `10034`) on `globalcompetitionworld.atlassian.net` (cloud id `ada6e144-94d3-4f1d-ad51-81c2d6da243e`). Issue types available: `Task`, `Epic`, `Subtask`, `Bug`.
- **Scope**: active only — open cards plus `Maybe?` plus `Not Now`. Closed cards are dropped.
- **Authoritative context**: board IDs and team emails are in [tap-games-context.md](./tap-games-context.md).

## Tools

- Fizzy side: `curl` + `jq` with `$FIZZY_API_TOKEN`, `$FIZZY_BASE_URL=https://app.fizzy.do`, `$FIZZY_ACCOUNT_SLUG=6132669`. See [api-basics.md](./api-basics.md) and [api-recipes.md](./api-recipes.md).
- Jira side: Atlassian MCP tools — `createJiraIssue`, `editJiraIssue`, `addCommentToJiraIssue`, `lookupJiraAccountId`, `searchJiraIssuesUsingJql`, `getJiraProjectIssueTypesMetadata`, `transitionJiraIssue`. Always pass `cloudId: ada6e144-94d3-4f1d-ad51-81c2d6da243e`.

Work card-by-card, log progress to `/tmp/migration-log-<board>.jsonl` with `{fizzyNumber, jiraKey, status, error?}` per line.

---

## Mapping rules

### Board → Epic
Create these three Epics in TG once, before any card migration. Record `{boardId → epicKey}` in `/tmp/epic-map.json`.

| Fizzy board | Epic summary |
|---|---|
| Production Preparation | `Production Preparation` |
| Performance, security and testing | `Performance, security & testing` |
| QA board | `QA` |

### Column → Jira status (unified 5-state workflow)
Actual Fizzy column names as discovered in the live inventory (2026-04-12):
- Prod Prep: `Ready | In Progress | Blocked | Deployed` (no `Done` column — closure is the `closed:true` flag)
- Perf: `In Progress | Review | Ready for QA`
- QA: `Improvements | Bug | Issues from Cody | In progress | ready for deployment | Ready for QA`

| Fizzy state | Jira status | Extra labels |
|---|---|---|
| No column, not closed, not postponed (`Maybe?`) | `To Do` | `triage` |
| `postponed: true` (`Not Now`) | `To Do` | `postponed` |
| `Ready` (Prod Prep) | `To Do` | |
| `In Progress` / `In progress` | `In Progress` | |
| `Blocked` | `Blocked` | |
| `Review` (Perf) | `In Review` | |
| `Ready for QA` / `ready for deployment` | `In Review` | |
| `Deployed` (Prod Prep) | `In Review` | `deployed` |
| QA `Improvements` / `Bug` / `Issues from Cody` | `To Do` | `improvement` / `bug` / `from-cody` |
| `closed: true` | **DROP — do not migrate** | |

New Jira issues are created with status `To Do`; any final status other than `To Do` is reached via `transitionJiraIssue` after the create call.

### Tag → Jira field
Fizzy returns `tags` as an **array of strings** (not objects) — e.g. `["improvement", "s3"]`. No `.title` accessor needed.

The TG project's Task/Bug issue types do not expose Story Points, Sprint, or Priority fields, and per PM direction these signals are not preserved in Jira.

| Fizzy tag | Target |
|---|---|
| `bug`, `untracked bug` | `issuetype: Bug` (not a label) |
| `est 1h` ... `est 8h` | **Dropped** — no Story Points field in TG |
| `s1`, `s2`, `s3` | **Dropped** — no Sprint field in TG |
| `blocker`, `improvement`, `system design`, `cody` | Label (lowercased, spaces → hyphens) |
| `golden` (card flag, not tag) | **Dropped** — no Priority field in TG |

### User mapping
- Read [tap-games-context.md](./tap-games-context.md) lines 15–27 for the canonical email list.
- For each unique Fizzy email, call `lookupJiraAccountId`. Cache to `/tmp/fizzy-migration/user-map.json` = `{fizzyUserId: {name, email, jiraAccountId, action?}}`.
- **Ex-team members** (Fizzy `active: false`, action `drop`): strip from assignees AND from the footer. Do not mention. Example: Omor Faruk (id `03ffcfg5g8ezb8rhopikdso8l`) — no longer on the team.
- **Unknown but still-active users** (no Jira account found): `assignee: null`, preserve original name in the description footer (`Original assignees: ...`) so the team can re-assign later.
- **Known users**: map by email to `jiraAccountId`.
- Drop Fizzy's multi-assign semantics — use only `assignees[0]`. If the first assignee is a dropped user, fall through to `assignees[1]`. Any remaining secondary (non-dropped) names go into the footer.

### Description (Trix HTML → Markdown)
Fizzy cards have TWO description fields: `description` (plain text, derived) and `description_html` (Trix HTML source). **Always convert from `description_html`** — it's the authoritative source with formatting intact. See [card-writing.md](./card-writing.md) for allowed tags.

The converter emits Markdown (not ADF), and the issue is created with `contentFormat: "markdown"` on `createJiraIssue`. The implementation is [/tmp/fizzy-migration/convert.py](../../../../../tmp/fizzy-migration/convert.py) (ephemeral, not committed). Tag handling:

- `<h1>`/`<h2>`/`<h3>` → `#`/`##`/`###`
- `<p>` → paragraph break
- `<strong>` / `<em>` / `<code>` → `**...**` / `*...*` / `` `...` ``
- `<blockquote>` → `> ...`
- `<ul>`/`<ol>`/`<li>` → bullet / ordered list
- `<a href>` → `[text](href)`
- `<br>` → soft break
- `<action-text-attachment>` → `[attachment: {filename} — see Fizzy source]` placeholder (stripped subtree)

Fizzy `steps[]` are a separate array on the card (not inline in the HTML). Append them as a Markdown task list under a `**Steps:**` heading at the bottom of the description — `- [x]` for completed, `- [ ]` for open.

Append this footer to every migrated description:

```
---
Migrated from Fizzy #{number} · https://app.fizzy.do/6132669/cards/{number} · created {created_at}
Original secondary assignees: {names}    ← only if >1 non-dropped assignee existed
Has attachments (manual backfill): {filenames}    ← only if has_attachments
```

### Comments
Migrate each Fizzy comment to a Jira comment via `addCommentToJiraIssue`, preserving oldest-first order. Prefix the body with `[{author_name} · {created_at}]` so author and original timestamp survive (Jira will attribute the comment to the migration runner, not the original author). Drop reactions on comments.

### Attachments
Fizzy stores attachments as inline `<action-text-attachment>` elements in `description_html`, not as top-level fields. The card's `has_attachments: true` flag is the signal. Only **6 cards across all boards** have attachments (0 Prod Prep + 2 Perf + 4 QA), so handle them as a targeted post-cutover manual step:

1. During conversion, when an `<action-text-attachment>` element is encountered, strip it from the ADF output but keep a placeholder paragraph `[attachment: {filename} — see Fizzy source]`.
2. Add an extra label `has-attachment` on the Jira issue for findability.
3. Append `Has attachments: {filenames}` to the footer.
4. After the cutover, the PM manually downloads each file from the Fizzy URL (while the read-only window is open) and uploads to the corresponding Jira issue via the Jira web UI or `addAttachmentToJiraIssue` equivalent.

Full list of cards requiring manual attachment backfill is logged to `/tmp/fizzy-migration/cards-with-attachments.jsonl` during Phase 0 inventory.

### Explicitly dropped (no Jira equivalent)
- Reactions / boosts (card and comment level)
- Pins (per-user bookmarks)
- `last_active_at` (Jira tracks its own timestamps)
- `status: "drafted"` (draft cards — include content, but strip the draft flag; reporter = migration user)
- Inline Trix attachments — migrated manually post-cutover (see above)

---

## Phase 0 — Prep (before freeze)

1. **Verify token**: `echo ${FIZZY_API_TOKEN:+set}` returns `set`. If empty, stop and ask the user.

2. **Live inventory** — dump all three boards.
   ```bash
   mkdir -p /tmp
   for BOARD_ID in 03fw09thuwj0lr952vfpoimoh 03frf9xrwha93r1iytv9skr5q 03fd4omd9qico7wmyyof5yfe4; do
     curl -s -H "Authorization: Bearer $FIZZY_API_TOKEN" -H "Accept: application/json" \
       "$FIZZY_BASE_URL/$FIZZY_ACCOUNT_SLUG/cards?board_ids[]=$BOARD_ID&per_page=100" \
       > "/tmp/fizzy-cards-$BOARD_ID.json"
     echo -n "$BOARD_ID active: "
     jq '[.[] | select(.closed != true)] | length' "/tmp/fizzy-cards-$BOARD_ID.json"
   done
   ```
   Follow `Link: rel="next"` pagination if any board exceeds 100 cards (see [api-basics.md](./api-basics.md)).

3. **User lookup** — for each unique email across the inventory:
   ```bash
   jq -r '[.[].assignees[]?.email] | unique | .[]' /tmp/fizzy-cards-*.json \
     | sort -u > /tmp/fizzy-emails.txt
   ```
   Then call `mcp__atlassian__lookupJiraAccountId` for each email. Build `/tmp/user-map.json`. Flag nulls; decide per-user whether to invite to GCW Jira or leave unassigned.

4. **Create Epics** — call `mcp__atlassian__createJiraIssue` three times with `projectKey: TG`, `issueType: Epic`. Record keys:
   ```json
   {
     "03fw09thuwj0lr952vfpoimoh": "TG-?",
     "03frf9xrwha93r1iytv9skr5q": "TG-?",
     "03fd4omd9qico7wmyyof5yfe4": "TG-?"
   }
   ```

5. **Dry run** — `python3 /tmp/fizzy-migration/convert.py <board_id>` writes `/tmp/fizzy-migration/dryrun-<board_id>.jsonl` with one ready-to-post payload per active card. Spot-check 5 payloads:
   - Markdown description renders correctly (headings, lists, links)
   - `**Steps:**` block present when the card had steps, with `- [x]` / `- [ ]`
   - Labels include `triage`/`postponed`/`deployed`/`has-attachment`/`improvement`/`from-cody`/etc. as expected
   - Attachment placeholder and footer line are present for cards with `has_attachments`
   - Assignee resolved to the expected `accountId` (or explicit `null` with secondaries in footer)
   Iterate until clean.

6. **Confirm TG field set** via `getJiraIssueTypeMetaWithFields` (Task `issueTypeId: 10041`) before the cutover. As of 2026-04-13, TG exposes only: `assignee`, `attachment`, `description`, `duedate`, `issuelinks`, `issuetype`, `labels`, `parent`, `project`, `reporter`, `summary`, plus `customfield_10000` (Development), `customfield_10001` (Team), `customfield_10015` (Start date), `customfield_10019` (Rank), `customfield_10021` (Flagged). Story Points, Sprint, and Priority are NOT exposed and are not migrated.

---

## Phase 1 — Perf board cutover (smallest real board)

1. **Announce freeze** in the team channel: *"Fizzy is now read-only. Jira cutover starting. ETA 2–4h."*

2. **Migrate Perf cards**. For each active card in `/tmp/fizzy-cards-03frf9xrwha93r1iytv9skr5q.json`:
   - Build the Jira payload per the mapping rules above.
   - `createJiraIssue` with `parent: {key: <Perf epic>}`.
   - If target status ≠ `To Do`, `transitionJiraIssue` to the mapped status.
   - For each Fizzy comment on the card, `addCommentToJiraIssue` oldest-first with the `[author · date]` prefix.
   - Append `{fizzyNumber, jiraKey, targetStatus, ok}` to `/tmp/migration-log-perf.jsonl`.

3. **Spot-check 10 cards** in the Jira web UI. Checklist:
   - Description renders as formatted Markdown (not raw HTML).
   - Task-list checkboxes present if the Fizzy card had steps.
   - Labels applied (including `triage`/`postponed`/`deployed`/`has-attachment` where relevant).
   - Assignee correct (or deliberately null with footer note explaining).
   - Comments in correct order, `[author · date]` prefix preserved.
   - Footer line links back to `https://app.fizzy.do/6132669/cards/{number}`.

4. **Fix and re-migrate** any broken cards: delete the Jira issue, fix the conversion logic, re-create.

5. **Count parity**:
   ```bash
   jq '[.[] | select(.closed != true)] | length' /tmp/fizzy-cards-03frf9xrwha93r1iytv9skr5q.json
   ```
   vs `mcp__atlassian__searchJiraIssuesUsingJql` with JQL `project = TG AND parent = <Perf epic key>`. These must match.

---

## Phase 2 — Prod Prep + QA cutover

1. Run the same loop for **Production Preparation** → `/tmp/migration-log-prodprep.jsonl`.
2. Run the same loop for **QA board** → `/tmp/migration-log-qa.jsonl`.
3. Spot-check 10 random cards per board.
4. Count parity per board via the same JQL query, one epic at a time.

Stop condition: if more than 10% of cards on any board fail any verification step, halt. Delete that board's newly created Jira issues, fix the conversion logic, re-run that board.

---

## Phase 3 — Go live

1. Announce in the team channel: *"Jira is live. New work in `TG`. https://globalcompetitionworld.atlassian.net/jira/software/projects/TG/boards"*.
2. Update [tap-games-context.md](./tap-games-context.md) with a `## Migration status` section noting the cutover date, Jira project URL, and Fizzy read-only date.
3. The agent definition update (pointing `tap-games-pm` at Jira MCP instead of Fizzy API) is tracked as a separate follow-up, not part of this cutover.

---

## Phase 4 — T+30 days

1. Revoke `FIZZY_API_TOKEN`.
2. Archive or delete the Fizzy account.
3. Remove this file once the migration is complete and fully validated — it is single-use.

---

## Verification (summary)

| Check | How |
|---|---|
| Count parity per board | `jq` on Fizzy cards file vs JQL `project = TG AND parent = <epic>` |
| Description fidelity | Open 10 cards per board in Jira UI, confirm Markdown rendering |
| Status distribution | JQL by status, compare against Fizzy column counts |
| Team smoke test | Team picks 3 familiar cards per board, confirms they look right, signs off in channel |
| Rollback trigger | >10% verification failures on a board → delete, fix, re-run |

Fizzy stays read-only for 30 days as a safety net for cross-referencing any discrepancy.

## See also

- [api-basics.md](./api-basics.md) — Fizzy curl/jq patterns, pagination
- [api-recipes.md](./api-recipes.md) — existing multi-step bash workflows this runbook extends
- [tap-games-context.md](./tap-games-context.md) — authoritative board IDs, team emails, current column conventions
- [card-writing.md](./card-writing.md) — Trix HTML allowed tags (input for the Markdown converter)
- [card-details.md](./card-details.md) — steps, reactions, pins (sources and what is/isn't migrated)
