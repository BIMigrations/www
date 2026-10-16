---
title: Looker to Power BI migration guide
crumb: Looker to Power BI
heading: "Looker to Power BI, <em>mapped.</em>"
description: How LookML models, explores, views, derived tables and access filters map onto Power BI semantic models and reports.
from: Looker
to: Power BI
order: 4
---

Looker and Power BI both put a semantic layer at the center, which makes this one of the more natural migrations. LookML is already code. The work is in resolving what that code does at query time, and in modeling it correctly for Power BI's engine.

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

Looker automatically protects measures from double-counting when joins fan out. Power BI doesn't. Relationships and grain must be modeled so that measures aggregate correctly, and parity tests confirm they do.

### Liquid templating

LookML can change its SQL at query time based on filters, parameters and user attributes. Each templated block has to be resolved into explicit model logic or parameters.

### Explores with many joins

Wide explores with many optional joins may become several focused semantic models, or one model with carefully chosen relationship directions.

### Access filters

User attributes that drive row-level access map to row-level security roles. The mapping is tested by checking what a user in each role sees on both platforms.

## Three translations that look simple and aren't

### Filtered measures

A Looker measure can carry its own filter. Per Looker's reference, the `filters` parameter applies a filter to that one measure, not to the whole query, and it works on `count`, `count_distinct`, `sum` and `average` measures but not on `type: number`.

```lookml
measure: contractor_count {
  type: count
  filters: [is_contractor: "yes"]
}
```

The Power BI equivalent is a measure that changes the filter context with `CALCULATE`:

```dax
Contractor Count =
CALCULATE ( COUNTROWS ( Staff ), Staff[Is Contractor] = TRUE () )
```

The catch is the `type: number` rule. A Looker measure that divides two filtered measures is a `number` measure built on top of them. In DAX you keep that layering by writing each piece as its own measure, then combining them. Flattening them into one long expression is how parity bugs get in.

### Persistent derived tables

Looker defines a persistent derived table (PDT) as a derived table written into a scratch schema on your database, rebuilt by a trigger: `datagroup_trigger`, `sql_trigger_value`, or time-based `persist_for`. Power BI has no equivalent object, because the storage layer is not the BI tool's job. Each PDT becomes a table or view in the warehouse, and its trigger becomes a pipeline schedule or a dependency on the upstream load. Write the trigger down before migrating. It is often the only record of when the business expects that number to refresh.

### Access filters and who sees what

A Looker `access_filter` takes a fully scoped field and a user attribute. Looker's reference says users with no value set for that attribute get an error when they open the Explore, admins included. Power BI row-level security works differently in the ways that matter for testing:

- A role is a DAX expression that returns true or false per row, such as `[UserEmail] = USERPRINCIPALNAME()`.
- Microsoft documents that RLS applies only to workspace Viewers. It does not apply to Admin, Member or Contributor, so whoever built the migration will see everything unless they test as a role.
- Test as role uses your own identity, so a dynamic rule based on `USERPRINCIPALNAME()` has to be checked with a real account for each kind of user, guests included.

A parity test for security is a table: one real user per role, the row count each sees in Looker, the row count each sees in Power BI. They match or the cutover waits.

## A migration *checklist*

1. Parse LookML and usage; retire explores, Looks and dashboards nobody queries.
2. Translate views and derived tables into SQL models; schedule PDT replacements.
3. Design semantic models from explores, with a shared date table.
4. Translate measures into DAX and parity-test against Looker results.
5. Resolve Liquid templating into parameters or model logic.
6. Rebuild dashboards and Looks as reports; map access filters to row-level security.
7. Run both platforms in parallel, sign off each wave, then cut over.

Sources: Looker's reference pages for measure `filters`, measure types, `access_filter` and persistent derived tables (docs.cloud.google.com/looker), and Microsoft Learn's pages on `CALCULATE` and row-level security.

See also: [Looker](/platforms/looker/) · [Power BI](/platforms/power-bi/) · [Risk & governance](/risk-governance/)
