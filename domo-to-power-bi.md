---
title: Domo to Power BI Migration, Automated
crumb: Domo to Power BI
heading: "Domo to Power BI migration, <em>automated.</em>"
description: Migrate Domo to Power BI without rebuilding by hand. DataSets, Beast Modes, cards and PDP policies become native Power BI, with every metric parity-tested.
lead: "Move your whole Domo instance to Power BI without rebuilding cards by eye. Our automated migration tool converts DataSets, Magic ETL, Beast Modes, cards and PDP policies into native semantic models, DAX measures, reports and row-level security — and proves every number matches before you cut over."
permalink: /domo-to-power-bi/
parent_title: Platforms
parent_url: /platforms/
accent: amber
image: /assets/img/og/domo-to-power-bi.png
hero_ctas: true
service:
  name: Domo to Power BI migration
  type: BI platform migration
glance:
  - label: Automated
    title: Around 78% converted by tooling
    text: In a typical estate, most of the work is done by our automated migration tool, with no analyst in the loop.
  - label: Parity
    title: Every metric tested
    text: Each Beast Mode and card total is compared between Domo and Power BI before cutover.
  - label: Security
    title: PDP becomes RLS
    text: Personalized Data Permissions are rebuilt as Power BI row-level security roles and tested role by role.
  - label: Yours
    title: Open specifications
    text: The whole estate also lands in your repository as SQL, Python, JSON and YAML — so you never have to migrate twice.
steps:
  - title: Scan your Domo instance
    text: A read-only metadata export inventories every DataSet, DataFlow, Beast Mode, card, page and PDP policy — with usage.
  - title: Retire what nobody uses
    text: Dormant cards and duplicated Beast Modes are flagged, so owners can retire them before they're migrated.
  - title: Translate to open specifications
    text: DataSets and DataFlows become SQL and pipelines; Beast Modes become metric definitions; cards and pages become dashboard definitions.
  - title: Generate native Power BI
    text: Our automated migration tool builds semantic models, DAX measures, reports and row-level security roles.
  - title: Prove parity
    text: Every measure is compared with Domo for the same slices. Anything outside tolerance is fixed before sign-off.
  - title: Cut over in waves
    text: Business areas move one wave at a time, with Domo kept live until each wave is signed off.
faqs:
  - q: How long does a Domo to Power BI migration take?
    a: It depends on the size of your Domo instance and how much of it is still used, which is what the [estate assessment](/services/estate-assessment/) measures. Across our engagements, the median time from kickoff to cutover is 11 weeks.
  - q: Can Beast Modes be converted to DAX automatically?
    a: Most of them, yes. Our automated migration tool rewrites each Beast Mode as a DAX measure or calculated column, depending on whether it aggregates or works row by row. Every one is then parity-tested against the original card's results, and engineers handle the exceptions.
  - q: What happens to Domo PDP policies?
    a: Personalized Data Permissions are read into access policies and rebuilt as Power BI row-level security roles. Each role is tested by checking that a user sees the same rows in Domo and in Power BI.
  - q: How are Magic ETL and SQL DataFlows migrated?
    a: They're translated into SQL models and scheduled pipelines — usually in your data warehouse — or into Power Query where that's a better fit. The dependency order between DataFlows is preserved.
  - q: Do you need access to our Domo instance?
    a: Not to start. The free estate scan works from a read-only metadata export, with a mutual NDA as standard. Scoped, read-only access is only needed later in the migration, and it's agreed in writing.
  - q: Will our dashboards look the same in Power BI?
    a: They'll show the same metrics, filters and drill paths, rebuilt with native Power BI visuals rather than pixel-copied. Most teams take the chance to tidy layouts, and we recommend retiring unused cards first.
---

Moving from Domo to Power BI usually means an analyst opening every card, working out what each Beast Mode is meant to calculate, and building it again in DAX. It's slow, it's expensive, and the knowledge gained ends up locked inside Power BI. We do it differently: **the Domo estate is read, translated once into open specifications, and regenerated natively in Power BI** by our automated migration tool.

## Domo to Power BI *at a glance*

{% include cards.html items=page.glance %}

## What we *migrate*

Every part of a Domo instance has a native home in Power BI. The [concept mapping guide](/migration-guides/domo-to-power-bi/) goes deeper; here's the summary:

| In Domo | In Power BI |
|---|---|
| DataSets | Tables in a semantic model, with relationships |
| Connectors | Data sources or warehouse pipelines |
| Magic ETL and SQL DataFlows | SQL pipelines or Power Query |
| Beast Modes | DAX measures and calculated columns |
| Cards | Native report visuals |
| Pages and dashboards | Report pages |
| Drill paths | Hierarchies and drill-through |
| Variables | Parameters and field parameters |
| PDP policies | Row-level security roles |
| Alerts | Data alerts and subscriptions |

## How a Domo to Power BI migration *works*

{% include cards.html items=page.steps numbered=true %}

## The hard parts, *handled*

### Beast Modes to DAX

A Beast Mode is evaluated inside a single card. A DAX measure is evaluated in the semantic model's filter context, across related tables. The same formula can give a different answer, which is why every translated Beast Mode is parity-tested, not just converted.

### Duplicated calculations

Large Domo instances often hold many copies of the same Beast Mode that have drifted apart. We flag them, so your team can agree one definition rather than migrating several DAX measures with confusingly similar names.

### Wide DataSets

Domo cards often read wide, denormalised DataSets. In Power BI, reshaping these into facts and dimensions gives smaller models and simpler DAX, so we check the grain before building relationships.

### Fiscal calendars

Domo's date grains and fiscal calendar settings become an explicit, shared date table in Power BI.

## Why teams move from Domo to *Power BI*

Teams usually move to consolidate onto the Microsoft data platform they already use, bring BI costs under control, or build on a larger pool of Power BI skills. Whatever the reason, the migration shouldn't lock you in again. Because your estate also lands as [open specifications](/open-specifications/), your next platform decision starts from a documented estate, not from scratch.

## Domo to Power BI *FAQs*

{% include faq.html items=page.faqs %}

## Related

- [Domo migration](/platforms/domo/) — everything we read from a Domo instance
- [Power BI migration](/platforms/power-bi/) — what we generate in Power BI
- [Domo to Power BI concept mapping](/migration-guides/domo-to-power-bi/) — the detailed guide
- [Tableau to Power BI migration](/tableau-to-power-bi/) — the other route we're asked about most
- [Estate assessment](/services/estate-assessment/) and [rationalisation](/services/rationalisation/) — size and shrink the estate first
