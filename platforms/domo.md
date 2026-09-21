---
title: Domo migration
crumb: Domo
heading: "Leave Domo. <em>Keep</em> every answer."
description: DataSets, DataFlows, Beast Modes, cards and PDP policies — read, translated into open specifications, and regenerated natively on the BI platform you choose.
permalink: /platforms/domo/
accent: amber
related:
  - label: Migration service
    title: Domo to Power BI migration
    text: The dedicated page for the route we're asked about most.
    url: /domo-to-power-bi/
    link: Domo to Power BI
  - label: Migration guide
    title: Domo to Power BI concept mapping
    text: Beast Modes, DataFlows and PDP policies mapped concept by concept.
    url: /migration-guides/domo-to-power-bi/
    link: Read the guide
  - label: Service
    title: Estate assessment
    text: Find out what's in your Domo instance — and what's still used — before you plan the move.
    url: /services/estate-assessment/
---

Moving to Power BI? See our dedicated page on **[Domo to Power BI migration](/domo-to-power-bi/)**.

Domo estates grow quickly: a connector here, a Magic ETL there, a Beast Mode copied into a dozen cards with slightly different logic. Moving off Domo by rebuilding cards by eye means re-deriving all of it. We read it instead.

## What we *read*

- **DataSets** — schemas, connector configuration and refresh schedules.
- **DataFlows** — Magic ETL and SQL DataFlows, including the order they depend on each other.
- **Beast Modes** — every calculated field, and every card that uses it.
- **Cards and pages** — chart types, filters, drill paths and layout.
- **PDP policies** — who is allowed to see which rows.
- **Usage** — card and page views, so dormant content can be retired rather than migrated.

## How it *translates*

| Domo | Open specification | On the target (e.g. Power BI) |
|---|---|---|
| DataSet | SQL model | Table in the semantic model |
| Magic ETL / SQL DataFlow | SQL, Airflow and Python | Warehouse pipeline or Power Query |
| Beast Mode | Metric definition (YAML) | DAX measure or calculated column |
| Card | Visual definition (JSON) | Report visual |
| Page | Dashboard definition (JSON) | Report page |
| PDP policy | Access policy (YAML) | Row-level security role |

## Where the *care* goes

Most of a Domo estate converts with no analyst in the loop. The work that needs an engineer tends to sit in a few places:

- **Beast Modes that mix row-level and aggregate logic.** These are split into the right mix of calculated columns and measures, then parity-tested.
- **Near-duplicate Beast Modes.** Copies that drifted apart are flagged, so owners can agree one definition instead of migrating five.
- **Fiscal calendars and date grains.** These become an explicit date table rather than platform settings.
- **Drill paths.** These are rebuilt as hierarchies or drill-through on the target.

{% include cards.html items=page.related %}
