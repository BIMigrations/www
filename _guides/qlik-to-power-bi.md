---
title: Qlik to Power BI migration guide
crumb: Qlik to Power BI
heading: "Qlik to Power BI, <em>mapped.</em>"
description: From load scripts, QVDs and set analysis to star schemas, pipelines and DAX, for both Qlik Sense and QlikView.
from: Qlik
to: Power BI
order: 3
faqs:
  - q: How does Qlik set analysis translate to DAX?
    a: Simple expressions with a modifier, such as `Sum({<Year={2024}>} Sales)`, become `CALCULATE` with a filter argument. Expressions that use `P()`, `E()`, set operators or nested sets need explicit filter logic, often with `TREATAS` or `EXCEPT`, and are the calculations to parity-test first.
  - q: What does Qlik's {1} set identifier become in DAX?
    a: There is no one-function equivalent. `{1}` drops the user's selections but keeps the chart's dimension, so `ALL` on a table can drop too much and `ALLSELECTED` drops the wrong side. The safer translation names the columns to clear, with `REMOVEFILTERS` on the columns the slicers use or `ALLEXCEPT` with the columns the visual groups by. See [Qlik's {1} ignores selections, not the axis](/insights/qlik-set-analysis-identifier/).
  - q: Does Power BI have an equivalent of the Qlik associative model?
    a: No. Power BI relies on explicit relationships in a star schema, so synthetic keys and link tables are reshaped into facts and dimensions with a clear grain before any DAX is written. Users also lose the gray "excluded values" view, so analyses that depend on it need explicit measures or visuals.
  - q: What happens to QVD files?
    a: A QVD is a storage layer, not a report. The usual target is a warehouse table, or files in a lakehouse, with incremental-load patterns rebuilt as scheduled pipelines.
  - q: How do you test a migrated Qlik measure?
    a: Compare the Qlik chart and the Power BI visual cell by cell with a selection applied, grouped by the chart's real dimensions. With nothing selected, `{1}` and `{$}` return the same records, so an unfiltered check can pass on a wrong translation.
---

Qlik and Power BI both have powerful in-memory engines, but they're built on different ideas. Qlik's associative model links every table automatically and lets users explore through selections. Power BI relies on explicit relationships and measures evaluated in filter context. The migration is as much remodeling as translation.

## Concept *mapping*

| Qlik | Power BI | Notes |
|---|---|---|
| Load script | Warehouse SQL pipeline or Power Query | Business logic in scripts is moved upstream where possible. |
| QVD | Warehouse table (or files in a lakehouse) | Incremental-load patterns become scheduled pipelines. |
| Mapping load / `ApplyMap` | Join or lookup in SQL | |
| Associative model | Star schema with relationships | Link tables and synthetic keys are removed. |
| Master dimension | Column or hierarchy | |
| Master measure | DAX measure | |
| Set analysis | `CALCULATE` with filter arguments | Modifiers need careful translation. |
| `Aggr()` | Virtual tables in DAX (`SUMMARIZE`, `ADDCOLUMNS`) | |
| Variable / `$(...)` expansion | Measure or parameter | |
| Sheet | Report page | |
| Bookmark | Bookmark | |
| Alternate states | Disconnected tables or calculation groups | No direct equivalent. |
| Section Access | Row-level security role | Tested role by role. |

## Where to take *care*

### Set analysis

Simple set expressions such as `Sum({<Year={2024}>} Sales)` translate directly to `CALCULATE`. Expressions that use `P()`, `E()`, set operators or nested sets need explicit filter logic, often with `TREATAS` or `EXCEPT`. These are the calculations that most need parity tests. Even the simple ones can change meaning once a chart axis is involved; [this post explains where and how to test it](/insights/qlik-set-analysis-identifier/).

### Associative selections

Users may rely on seeing *excluded* (gray) values to answer questions like "which customers didn't buy this product?". Power BI doesn't show exclusions the same way, so identify these analyses early and build explicit measures or visuals for them.

### Synthetic keys and link tables

Qlik tolerates models Power BI can't use as-is. Reshape them into facts and dimensions with a clear grain before writing any DAX.

### Logic hidden in scripts

Business rules often live in `IF` statements and mapping tables inside load scripts. Translating scripts into SQL models makes those rules visible and reviewable, often for the first time.

## A migration *checklist*

1. Inventory apps and documents with usage; retire what isn't opened.
2. Translate load scripts and QVD chains into SQL models and pipelines.
3. Remodel into star schemas; replace synthetic keys and link tables.
4. Translate master measures and set analysis into DAX; parity-test them.
5. Rebuild sheets as report pages and bookmarks.
6. Map Section Access to row-level security and test each role.
7. Run both platforms in parallel, sign off each wave, then cut over.

## Qlik to Power BI *FAQs*

{% include faq.html items=page.faqs %}

See also: [Qlik](/platforms/qlik/) · [Power BI](/platforms/power-bi/) · [Rationalization](/services/rationalization/)
