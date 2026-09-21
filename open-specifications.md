---
title: Open specifications
heading: "Your estate, in <em>plain text.</em>"
description: Before anything is rebuilt, the whole estate becomes open, human-readable specifications that live in your repository and outlast any BI platform choice.
permalink: /open-specifications/
parent_title: Platform
kinds:
  - label: Models
    title: SQL
    text: Every dataset and derived table as a SQL model — the tables your dashboards actually query.
  - label: Transformations
    title: Airflow and Python
    text: ETL and data preparation as scheduled, dependency-ordered pipelines.
  - label: Dashboards
    title: JSON and YAML
    text: Metrics, visuals, pages, filters and access policies as structured definitions.
  - label: Lineage
    title: Field-level graph
    text: Every dashboard field traced back through each transformation to its source columns.
---

A migration has two halves. The first — working out what the estate is and what every number means — is the expensive half. Open specifications capture that work in a form you own, so it only has to be done once.

## Four kinds of *specification*

{% include cards.html items=page.kinds %}

## What a spec *looks like*

These excerpts are illustrative. The exact layout is documented for each engagement, but the principle is the same: plain files that any engineer can read, diff and review.

A **metric** records what a number means, where it's calculated from, and where it came from on the source platform:

```yaml
# metrics/net_revenue.yml
metric: net_revenue
label: Net revenue
description: Gross bookings less refunds and discounts.
model: finance.orders
expression: sum(gross_amount) - sum(refund_amount) - sum(discount_amount)
format: currency
source:
  platform: domo
  object: "Beast Mode: Net Rev (v2)"
```

That metric came from a Domo Beast Mode — exactly what happens in a [Domo to Power BI migration](/domo-to-power-bi/). A **model** is the SQL behind it:

```sql
-- models/finance/orders.sql
select
  order_id,
  order_date,
  region,
  gross_amount,
  coalesce(refund_amount, 0)   as refund_amount,
  coalesce(discount_amount, 0) as discount_amount
from raw.orders
where is_test = false
```

A **dashboard** describes pages and visuals in terms of metrics, not platform widgets:

```json
{
  "dashboard": "Regional revenue",
  "pages": [
    {
      "title": "Overview",
      "visuals": [
        { "type": "line", "metric": "net_revenue", "x": "order_date:month", "series": "region" }
      ]
    }
  ]
}
```

## Why it *matters*

- **You own it.** The specifications live in your repository, not inside our tool or a vendor's file format.
- **You can review it.** Changes are plain-text diffs that your team can read and discuss like any other code.
- **It's portable.** To target a different BI platform, you re-run our automated migration tool against the specs. You don't start a new migration project.
- **It's auditable.** The lineage graph shows exactly where every number comes from.

## After *cutover*

The specifications don't expire when the migration ends. They remain the documented, platform-neutral record of your estate: a reference for new team members, the starting point for impact analysis, and the source for whichever BI platform comes next.
