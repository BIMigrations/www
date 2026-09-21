---
title: Tableau to Power BI Migration, Automated
crumb: Tableau to Power BI
heading: "Tableau to Power BI migration, <em>automated.</em>"
description: "Migrate Tableau to Power BI without rebuilding by hand. LOD expressions, table calcs and user filters become native Power BI and DAX, all parity-tested."
lead: "Move Tableau workbooks, data sources and calculations to Power BI without rebuilding them one sheet at a time. Our automated migration tool converts calculated fields, LOD expressions, table calculations and user filters into native semantic models, DAX, reports and row-level security — and proves every number matches before you cut over."
permalink: /tableau-to-power-bi/
parent_title: Platforms
parent_url: /platforms/
image: /assets/img/og/tableau-to-power-bi.png
hero_ctas: true
service:
  name: Tableau to Power BI migration
  type: BI platform migration
glance:
  - label: Automated
    title: Around 78% converted by tooling
    text: In a typical estate, most of the work is done by our automated migration tool, with no analyst in the loop.
  - label: Parity
    title: Every metric tested
    text: LOD expressions and table calculations are compared between Tableau and Power BI before cutover.
  - label: Security
    title: User filters become RLS
    text: User filters and USERNAME() or ISMEMBEROF() logic are rebuilt as Power BI row-level security roles.
  - label: Yours
    title: Open specifications
    text: The whole estate also lands in your repository as SQL, Python, JSON and YAML — so you never have to migrate twice.
steps:
  - title: Scan Tableau Server or Cloud
    text: A read-only metadata export inventories workbooks, data sources, extracts, calculations, dashboards and permissions — with view counts.
  - title: Retire what nobody views
    text: Stale workbooks and duplicated data sources are flagged for owners to retire before they're migrated.
  - title: Translate to open specifications
    text: Data sources and Prep flows become SQL and pipelines; calculations become metric definitions; dashboards become dashboard definitions.
  - title: Generate native Power BI
    text: Our automated migration tool builds shared semantic models, DAX measures, reports and row-level security roles.
  - title: Prove parity
    text: Every measure is compared with Tableau for the same slices. Anything outside tolerance is fixed before sign-off.
  - title: Cut over in waves
    text: Projects move one wave at a time, with Tableau kept live until each wave is signed off.
faqs:
  - q: How long does a Tableau to Power BI migration take?
    a: It depends on how many workbooks and data sources you have and how many are still viewed, which is what the [estate assessment](/services/estate-assessment/) measures. Across our engagements, the median time from kickoff to cutover is 11 weeks.
  - q: Can Tableau LOD expressions be converted to DAX?
    a: Yes. FIXED, INCLUDE and EXCLUDE expressions are rewritten as DAX measures that change filter context with CALCULATE and functions such as ALLEXCEPT, REMOVEFILTERS and VALUES. Because the semantics differ subtly, every converted expression is parity-tested. See the [Tableau calculations to DAX guide](/migration-guides/tableau-to-power-bi/).
  - q: What happens to table calculations?
    a: Running totals, moving averages, ranks and differences are rewritten with DAX window functions such as WINDOW, OFFSET and INDEX, with RANKX, or as visual calculations, depending on how they're used.
  - q: Can you migrate Tableau Prep flows?
    a: Yes. Prep flows are translated into SQL models and scheduled pipelines in your data warehouse, or into Power Query where that's a better fit.
  - q: How is Tableau row-level security migrated?
    a: User filters, and calculations that use USERNAME() or ISMEMBEROF(), are read into access policies and rebuilt as Power BI row-level security roles. Each role is tested on both platforms.
  - q: Do we have to rebuild dashboards by hand?
    a: No. Dashboards, worksheets and actions are described as dashboard definitions and generated as native Power BI report pages, visuals, cross-filtering and drill-through.
---

Most Tableau to Power BI migrations are hand rebuilds. Someone opens each workbook, reverse-engineers the calculated fields and LOD expressions, and builds them again in DAX. We replace that with automation: **your Tableau estate is read, translated once into open specifications, and regenerated natively in Power BI** by our automated migration tool.

## Tableau to Power BI *at a glance*

{% include cards.html items=page.glance %}

## What we *migrate*

Every part of a Tableau site has a native home in Power BI. The [Tableau calculations to DAX guide](/migration-guides/tableau-to-power-bi/) goes deeper; here's the summary:

| In Tableau | In Power BI |
|---|---|
| Published data sources | Shared semantic models |
| Embedded data sources | Tables in a semantic model |
| Extracts (.hyper) | Import-mode tables, or warehouse tables |
| Live connections | DirectQuery |
| Relationships, joins and blends | Model relationships |
| Calculated fields | DAX measures and calculated columns |
| LOD expressions | DAX measures using CALCULATE |
| Table calculations | DAX window functions or visual calculations |
| Parameters | Field parameters and what-if parameters |
| Sets and groups | Groups, calculated tables or measure filters |
| Worksheets and dashboards | Report visuals and pages |
| Dashboard actions | Cross-filtering, drill-through and bookmarks |
| User filters | Row-level security roles |
| Tableau Prep flows | SQL pipelines or Power Query |
| Projects | Workspaces and apps |

## How a Tableau to Power BI migration *works*

{% include cards.html items=page.steps numbered=true %}

## The hard parts, *handled*

### LOD expressions

`{FIXED [Region] : SUM([Sales])}` has no single DAX equivalent. It becomes a measure that deliberately changes filter context, and the right pattern depends on how the expression is used in each view. Every converted LOD expression is parity-tested.

### Table calculations

Tableau computes table calculations over the marks in a view, with addressing and partitioning set per sheet. In Power BI, that logic moves into DAX window functions or visual calculations, with the partitioning made explicit.

### Data blending

Blends between data sources become proper relationships in a shared semantic model, so the same numbers are available to every report, not just one workbook.

### Many workbooks, one model

Tableau estates often hold dozens of workbooks built on slightly different copies of the same data. Consolidating them into shared semantic models is where much of the long-term value of the move lies.

## Why teams move from Tableau to *Power BI*

Teams usually move to consolidate BI onto the Microsoft platform they already run, rationalise licensing, or standardise on shared semantic models. Whatever the reason, the migration shouldn't lock you in again. Because your estate also lands as [open specifications](/open-specifications/), your next platform decision starts from a documented estate, not from scratch.

## Tableau to Power BI *FAQs*

{% include faq.html items=page.faqs %}

## Related

- [Tableau migration](/platforms/tableau/) — everything we read from a Tableau site
- [Power BI migration](/platforms/power-bi/) — what we generate in Power BI
- [Tableau calculations to DAX](/migration-guides/tableau-to-power-bi/) — LOD expressions, table calculations and parameters
- [Domo to Power BI migration](/domo-to-power-bi/) — the other route we're asked about most
- [Estate assessment](/services/estate-assessment/) and [rationalisation](/services/rationalisation/) — size and shrink the estate first
