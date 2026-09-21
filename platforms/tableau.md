---
title: Tableau migration
crumb: Tableau
heading: "Tableau, <em>unbundled.</em>"
lead: "Tableau workbooks, data sources, extracts, calculations and user filters — read, translated into open specifications and regenerated natively on your chosen BI platform."
description: "Tableau migration: workbooks, data sources, extracts, LOD expressions and user filters translated into open specs and regenerated natively on any BI platform."
permalink: /platforms/tableau/
related:
  - label: Migration service
    title: Tableau to Power BI migration
    text: The dedicated page for the route we're asked about most.
    url: /tableau-to-power-bi/
    link: Tableau to Power BI
  - label: Migration guide
    title: Tableau calculations to DAX
    text: LOD expressions, table calculations and parameters, pattern by pattern.
    url: /migration-guides/tableau-to-power-bi/
    link: Read the guide
  - label: Service
    title: Estate assessment
    text: Inventory every workbook and data source, and see which ones are still viewed.
    url: /services/estate-assessment/
---

Moving to Power BI? See our dedicated page on **[Tableau to Power BI migration](/tableau-to-power-bi/)**.

Tableau estates spread fast: a workbook per question, an extract per workbook, and calculated fields copied from one sheet to the next. The logic that matters is scattered across hundreds of `.twb` files. We read all of it, so nothing has to be rebuilt by eye.

## What we *read*

- **Workbooks** — worksheets, dashboards, stories and their layout.
- **Data sources** — published and embedded, including joins, relationships and blends.
- **Extracts** — what each extract contains and how often it refreshes.
- **Calculated fields** — row-level and aggregate calculations, LOD expressions and table calculations.
- **Parameters, sets and groups**, and the calculations that depend on them.
- **Actions** — filter, highlight and URL actions between sheets.
- **User filters and permissions** — including `USERNAME()` and `ISMEMBEROF()` logic.
- **Tableau Prep flows** — the preparation steps before the data source.
- **Usage** — view counts, so stale workbooks can be retired first.

## How it *translates*

| Tableau | Open specification | On the target (e.g. Power BI) |
|---|---|---|
| Data source | SQL model | Table in a shared semantic model |
| Extract | SQL model (materialised) | Import-mode or warehouse table |
| Prep flow | SQL, Airflow and Python | Warehouse pipeline or Power Query |
| Calculated field / LOD | Metric definition (YAML) | DAX measure |
| Table calculation | Metric definition (YAML) | DAX window function or visual calculation |
| Parameter | Parameter definition | Field or what-if parameter |
| Worksheet and dashboard | Dashboard definition (JSON) | Report visuals and pages |
| User filter | Access policy (YAML) | Row-level security role |

## Where the *care* goes

- **LOD expressions** — `FIXED`, `INCLUDE` and `EXCLUDE` become explicit filter-context logic, and each one is parity-tested.
- **Table calculations** — addressing and partitioning set on each sheet are made explicit in the target.
- **Duplicated data sources** — near-identical extracts are consolidated into shared models.
- **Blends** — secondary data sources become real relationships.

## Moving *to* Tableau

Tableau is a target as well. From open specifications, our automated migration tool can generate Tableau data sources and workbooks.

{% include cards.html items=page.related %}
