---
title: Qlik to Power BI migration guide
crumb: Qlik to Power BI
heading: "Qlik to Power BI, <em>mapped.</em>"
description: From load scripts, QVDs and set analysis to star schemas, pipelines and DAX — for both Qlik Sense and QlikView.
from: Qlik
to: Power BI
order: 2
---

Qlik and Power BI both have powerful in-memory engines, but they're built on different ideas. Qlik's associative model links every table automatically and lets users explore through selections. Power BI relies on explicit relationships and measures evaluated in filter context. The migration is as much remodelling as translation.

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

Simple set expressions such as `Sum({<Year={2024}>} Sales)` translate directly to `CALCULATE`. Expressions that use `P()`, `E()`, set operators or nested sets need explicit filter logic, often with `TREATAS` or `EXCEPT`. These are the calculations that most need parity tests.

### Associative selections

Users may rely on seeing *excluded* (grey) values to answer questions like "which customers didn't buy this product?". Power BI doesn't show exclusions the same way, so identify these analyses early and build explicit measures or visuals for them.

### Synthetic keys and link tables

Qlik tolerates models Power BI can't use as-is. Reshape them into facts and dimensions with a clear grain before writing any DAX.

### Logic hidden in scripts

Business rules often live in `IF` statements and mapping tables inside load scripts. Translating scripts into SQL models makes those rules visible and reviewable — often for the first time.

## A migration *checklist*

1. Inventory apps and documents with usage; retire what isn't opened.
2. Translate load scripts and QVD chains into SQL models and pipelines.
3. Remodel into star schemas; replace synthetic keys and link tables.
4. Translate master measures and set analysis into DAX; parity-test them.
5. Rebuild sheets as report pages and bookmarks.
6. Map Section Access to row-level security and test each role.
7. Run both platforms in parallel, sign off each wave, then cut over.

See also: [Qlik](/platforms/qlik/) · [Power BI](/platforms/power-bi/) · [Rationalisation](/services/rationalisation/)
