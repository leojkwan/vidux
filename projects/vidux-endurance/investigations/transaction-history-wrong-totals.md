# Investigation: Transaction History Wrong Totals

## Tickets
- [FT-201] "Summary says $4,280 settled, but the visible rows add up to $4,080 after a refund posts." — triaged
- [FT-214] "When I switch to Card only, the rows change but the summary tiles do not." — triaged
- [FT-229] "Going to page 2 and back doubles one reversal in the total until I hard refresh." — triaged

## Evidence
- [Source: `../evidence/2026-04-04-fintech-dashboard-baseline.md#findings`] The fake fintech dashboard should follow a blocked-but-legible operator pattern, keep summary totals tied to the same normalized ledger as the detailed table, and treat cleared/pending/reversed states as real business events rather than styling only.
- Simulated surface owner files for this fake project:
  - `app/dashboard/transactions/page.tsx`
  - `components/transactions/summary-cards.tsx`
  - `components/transactions/transaction-table.tsx`
  - `lib/transactions/selectors.ts`
  - `lib/transactions/normalizers.ts`
  - `lib/api/transactions.ts`
- Related tickets on the same surface: FT-201, FT-214, FT-229. Three tickets on one surface triggers the three-strike rule, so the investigation requires a full Impact Map before any code.
- Recent commits: none. This endurance scenario treats the surface as an early fake-project incident bundle rather than a mature commit history.
- Repro:
  1. Open the fake dashboard on "All Accounts" for the current month.
  2. Change filter to `Card only`.
  3. Open page 2, then return to page 1.
  4. Compare the summary tile total with the row sum after a refunded transaction is present.

## Root Cause
The fake surface is computing totals from two incompatible data paths. Summary cards read a cached `accountTotals` object keyed only by account and date range, while the table renders `visibleTransactions` keyed by account, date range, filter, and page. A refunded transaction is normalized out of the visible row set but remains inside the cached summary total, and a page-back navigation merges page data by array position instead of transaction id. The result is a three-part mismatch: filter changes update rows without recomputing the summary, refunded rows remain in the header total, and returning from page 2 can duplicate the reversal amount in cached aggregates.

## Impact Map
- Other UI paths that render this surface:
  - `components/dashboard/account-overview.tsx` reads the same `accountTotals` object for the month-end settled number.
  - `app/dashboard/transactions/export/route.ts` derives CSV footer totals from the same selector family.
  - `components/transactions/reconciliation-banner.tsx` uses the settled total to decide whether to show a mismatch warning.
- Other tickets fixed or broken by this change:
  - Fixing only the table rows would leave FT-214 open because the filter mismatch lives in summary cache keys.
  - Fixing only summary recomputation would leave FT-229 open because duplicate reversal rows still pollute merged page state.
  - A correct fix should also prevent a likely future export mismatch because the CSV footer shares the same totals pipeline.
- State flow:
  - `/api/transactions?accountId&range&status&page` -> `lib/api/transactions.ts`
  - raw payload -> `lib/transactions/normalizers.ts`
  - normalized ledger -> `lib/transactions/selectors.ts`
  - selectors -> summary cards, reconciliation banner, table, export footer

## Fix Spec
- `lib/api/transactions.ts:40-88` — Stop returning pre-aggregated settled totals that ignore `status` and pagination state. Return raw transaction pages plus server-side reconciliation metadata only.
- `lib/transactions/normalizers.ts:15-74` — Normalize refunded and reversed transactions into distinct status buckets and exclude them from the settled-total accumulator unless `status=all`.
- `lib/transactions/selectors.ts:22-118` — Introduce one shared selector that derives `summaryTiles`, `visibleRows`, `reconciliationDelta`, and `exportFooter` from the same normalized transaction store keyed by account, date range, status filter, and transaction id.
- `components/transactions/transaction-table.tsx:55-96` — Merge paginated pages by transaction id, not by array index, before passing data into selectors so page-back navigation cannot duplicate reversal amounts.
- `components/transactions/summary-cards.tsx:10-42` — Render the selector-derived totals and surface a muted "pending adjustments excluded" note when reversed or refunded rows are hidden from the settled total.
- [Evidence: `../evidence/2026-04-04-fintech-dashboard-baseline.md#findings`] This fix keeps the dashboard blocked-but-legible: users still see totals, but the totals and warnings now come from the same ledger state as the rows.

## Tests
- Test 1: Filter from `all` to `card_only` recomputes summary tiles, reconciliation banner, and visible rows from the same selector output.
- Test 2: Refunded or reversed transactions appear in the table with status badges but do not inflate the settled total unless the view is explicitly `status=all`.
- Test 3: Visiting page 2 and returning to page 1 does not duplicate any transaction or reversal amount in the summary, table, or export footer.

## Gate
- [x] Three related tickets are bundled into one investigation rather than treated as isolated fixes.
- [x] Root Cause names one shared state divergence instead of three separate symptoms.
- [x] Impact Map covers every dependent surface that would regress if totals and rows diverged again.
- [x] Fix Spec ties summary cards, pagination merge logic, and export totals back to one selector pipeline.
