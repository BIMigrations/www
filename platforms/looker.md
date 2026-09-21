---
title: Looker migration
crumb: Looker
heading: "LookML in. <em>Anything</em> out."
lead: "Looker is already half-way to open specifications. We read LookML models, explores and derived tables, and carry them to your next BI platform — or bring other estates into Looker."
description: "Looker migration: LookML models, explores, derived tables and access filters translated into open specifications and regenerated natively on any BI platform."
permalink: /platforms/looker/
related:
  - label: Migration guide
    title: Looker to Power BI
    text: Explores, views and access filters mapped to Power BI concepts.
    url: /migration-guides/looker-to-power-bi/
    link: Read the guide
  - label: Resource
    title: Risk & governance
    text: How access filters and user attributes are carried across and tested.
    url: /risk-governance/
  - label: Service
    title: Rationalisation
    text: Retire unused Looks and dashboards before they're migrated.
    url: /services/rationalisation/
---

LookML is code, which makes Looker estates easier to read than most. The hard part is everything around the code: which explores are actually used, what the Liquid templating does at query time, and how access filters combine with user attributes.

## What we *read*

- **Models and explores** — joins, relationships and the fields each explore exposes.
- **Views** — dimensions, measures and dimension groups, including their SQL.
- **Derived tables** — SQL-based, native and persistent derived tables, and how they're rebuilt.
- **Dashboards and Looks** — LookML dashboards and user-defined dashboards, tiles and filters.
- **Access controls** — access filters, `sql_always_where` and user attributes.
- **Usage** — which Looks, dashboards and explores people actually query.

## How it *translates*

| Looker | Open specification | On the target (e.g. Power BI) |
|---|---|---|
| View | SQL model | Table |
| Dimension | Column in the SQL model | Column or calculated column |
| Measure | Metric definition (YAML) | DAX measure |
| Explore | Model relationships (YAML) | Semantic model relationships |
| Derived table / PDT | SQL model, scheduled in Airflow | Warehouse table or view |
| Access filter | Access policy (YAML) | Row-level security role |
| Dashboard / Look | Dashboard definition (JSON) | Report pages and visuals |

## Where the *care* goes

- **Symmetric aggregates.** Looker protects measures from fan-out joins automatically. On the target, the model's grain has to be right, and parity tests prove it.
- **Liquid templating.** Templated filters and parameters are resolved into explicit parameters or field selections.
- **Dimension groups.** Timeframes become a shared date table instead of per-view variants.

## Moving *to* Looker

Looker is a target as well. From open specifications, our automated migration tool writes LookML views, explores and dashboards that your team can review like any other code.

{% include cards.html items=page.related %}
