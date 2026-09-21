---
title: Looker to Power BI migration guide
crumb: Looker to Power BI
heading: "Looker to Power BI, <em>mapped.</em>"
description: How LookML models, explores, views, derived tables and access filters map onto Power BI semantic models and reports.
from: Looker
to: Power BI
order: 4
---

Looker and Power BI both put a semantic layer at the centre, which makes this one of the more natural migrations. LookML is already code. The work is in resolving what that code does at query time, and in modelling it correctly for Power BI's engine.

## Concept *mapping*

| Looker | Power BI | Notes |
|---|---|---|
| Model | Semantic model | Often several models consolidate into fewer. |
| Explore | Relationships within a semantic model | Join logic becomes relationships. |
| View | Table | |
| Dimension | Column or calculated column | Compute upstream where possible. |
| Dimension group (time) | Date table | Shared across facts. |
| Measure | DAX measure | |
| Derived table (SQL or native) | SQL view or table | |
| Persistent derived table | Scheduled warehouse table | Rebuilt by a pipeline instead of the BI tool. |
| Parameter / templated filter | Field parameter or what-if parameter | Liquid is resolved into explicit logic. |
| `sql_always_where` | Filter in the model, or row-level security | |
| Access filter / user attribute | Row-level security role | Tested role by role. |
| LookML or user-defined dashboard | Report | |
| Look | Report page or visual | |
| Schedule | Subscription | |

## Where to take *care*

### Symmetric aggregates

Looker automatically protects measures from double-counting when joins fan out. Power BI doesn't. Relationships and grain must be modelled so that measures aggregate correctly, and parity tests confirm they do.

### Liquid templating

LookML can change its SQL at query time based on filters, parameters and user attributes. Each templated block has to be resolved into explicit model logic or parameters.

### Explores with many joins

Wide explores with many optional joins may become several focused semantic models, or one model with carefully chosen relationship directions.

### Access filters

User attributes that drive row-level access map to row-level security roles. The mapping is tested by checking what a user in each role sees on both platforms.

## A migration *checklist*

1. Parse LookML and usage; retire explores, Looks and dashboards nobody queries.
2. Translate views and derived tables into SQL models; schedule PDT replacements.
3. Design semantic models from explores, with a shared date table.
4. Translate measures into DAX and parity-test against Looker results.
5. Resolve Liquid templating into parameters or model logic.
6. Rebuild dashboards and Looks as reports; map access filters to row-level security.
7. Run both platforms in parallel, sign off each wave, then cut over.

See also: [Looker](/platforms/looker/) · [Power BI](/platforms/power-bi/) · [Risk & governance](/risk-governance/)
