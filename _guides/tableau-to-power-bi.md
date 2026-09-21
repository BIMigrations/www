---
title: "Tableau to DAX: LOD Expressions & Table Calcs"
crumb: Tableau calculations to DAX
heading: "Tableau calculations to <em>DAX.</em>"
description: "How Tableau calculated fields, LOD expressions, table calculations, parameters and user filters translate into DAX and Power BI — and where to take care."
from: Tableau
to: Power BI
order: 2
---

This guide covers the part of a [Tableau to Power BI migration](/tableau-to-power-bi/) that takes the most time when it's done by hand: turning Tableau calculations into DAX. The two languages look similar, but they evaluate differently. Tableau calculates in the context of the marks in a view, while DAX calculates in the filter context of a semantic model.

## Concept *mapping*

| Tableau | Power BI | Notes |
|---|---|---|
| Row-level calculated field | Calculated column, or a column upstream | Compute it in the warehouse where possible. |
| Aggregate calculated field | DAX measure | |
| `{FIXED ...}` | `CALCULATE` with `ALLEXCEPT` or `REMOVEFILTERS` | The grain is fixed regardless of the view. |
| `{INCLUDE ...}` | Measure iterating a finer grain (`SUMX` over `VALUES`) | |
| `{EXCLUDE ...}` | `CALCULATE` removing a dimension's filters | |
| `RUNNING_SUM`, `WINDOW_AVG` | `WINDOW`, or visual calculations | Partitioning becomes explicit. |
| `LOOKUP`, `PREVIOUS_VALUE` | `OFFSET` | |
| `RANK` | `RANKX` or `INDEX` | |
| `ZN()`, `IFNULL()` | `COALESCE()` | |
| `DATETRUNC`, `DATEPART` | Columns on a shared date table | |
| Parameter | Field parameter or what-if parameter | |
| Set | Group, calculated table or measure filter | |
| `USERNAME()`, `ISMEMBEROF()` | Row-level security with `USERPRINCIPALNAME()` | Tested role by role. |

## Where to take *care*

### FIXED expressions and filters

In Tableau, `FIXED` expressions are computed before dimension filters but after context filters. In DAX, filter context applies unless it's removed explicitly. Decide which filters should affect the expression, write the `CALCULATE` accordingly, and parity-test the result with filters applied.

### Table calculation addressing

A Tableau table calculation's result depends on its addressing and partitioning — "compute using" — which can differ from sheet to sheet for the same formula. Before translating, record the addressing for each use. It often means one Tableau calculation becomes several DAX measures.

### Aggregations of aggregations

Expressions such as `AVG({FIXED [Customer] : SUM([Sales])})` need an explicit iterator in DAX, such as `AVERAGEX(VALUES(Customer[Customer]), [Sales])`.

### Blended data sources

Calculations that mix fields from a primary and a secondary data source rely on blending semantics. Model the relationship properly first; the DAX is usually simpler afterwards.

## A migration *checklist*

1. Inventory workbooks and data sources with view counts; retire stale content.
2. Consolidate duplicated data sources into shared semantic models.
3. Classify calculations: row-level, aggregate, LOD or table calculation.
4. Translate each class with the patterns above, and record addressing for table calculations.
5. Parity-test every measure at the slices each dashboard uses.
6. Rebuild dashboards and actions as report pages, cross-filtering and drill-through.
7. Map user filters to row-level security, test each role, then cut over in waves.

See also: [Tableau to Power BI migration](/tableau-to-power-bi/) · [Tableau](/platforms/tableau/) · [Power BI](/platforms/power-bi/)
