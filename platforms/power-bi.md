---
title: Power BI migration
crumb: Power BI
heading: "Native Power BI. <em>Not</em> a lookalike."
description: Semantic models, DAX measures, Power Query and reports generated from open specifications — with row-level security mapped and every metric parity-tested.
permalink: /platforms/power-bi/
related:
  - label: Migration guide
    title: Domo to Power BI
    text: How DataSets, Beast Modes and PDP policies land in Power BI.
    url: /migration-guides/domo-to-power-bi/
    link: Read the guide
  - label: Migration guide
    title: Qlik to Power BI
    text: From load scripts and set analysis to star schemas and DAX.
    url: /migration-guides/qlik-to-power-bi/
    link: Read the guide
  - label: Migration guide
    title: Looker to Power BI
    text: From LookML explores and derived tables to semantic models.
    url: /migration-guides/looker-to-power-bi/
    link: Read the guide
---

Power BI is the most common destination we see. The goal is not a copy that looks right on the first screen. It's a model your team would have built themselves: a clean star schema, measures written in idiomatic DAX, and security that behaves the way it did before.

## What we *generate*

- **Semantic models** — tables, relationships and a proper date table.
- **DAX measures** — calculations rewritten in DAX from the metric definitions, not transliterated line by line.
- **Data preparation** — warehouse SQL and pipelines, or Power Query where that's the better fit.
- **Reports** — pages and visuals built from the dashboard definitions, with filters and drill-through.
- **Row-level security** — roles built from the access policies read from the source platform.
- **Parity tests** — every measure compared with the source for the same slices before cutover.

## From specification to *Power BI*

| Open specification | Power BI artifact |
|---|---|
| SQL model | Table (import or DirectQuery) |
| Airflow / Python transformation | Warehouse pipeline, or Power Query where appropriate |
| Metric definition (YAML) | DAX measure |
| Dashboard definition (JSON) | Report pages and visuals |
| Access policy (YAML) | Row-level security role |
| Lineage graph | Documentation of every measure's upstream sources |

## Leaving *Power BI*

Power BI is a source too. We read semantic models, DAX, Power Query and report definitions into the same open specifications, so the estate can be regenerated on another BI platform.

{% include cards.html items=page.related %}
