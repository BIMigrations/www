---
title: "Domo to Power BI Mapping: Beast Modes to DAX"
crumb: Domo to Power BI mapping
heading: "Domo to Power BI, <em>mapped.</em>"
description: How Domo DataSets, DataFlows, Beast Modes, cards and PDP policies map onto Power BI concepts, and the places a migration needs the most care.
from: Domo
to: Power BI
order: 1
---

This guide is the detailed companion to our [Domo to Power BI migration](/domo-to-power-bi/) service. Domo and Power BI organize analytics differently. Domo keeps data preparation, calculations and visuals close together around each DataSet. Power BI centers on the semantic model: tables, relationships and measures shared by many reports. A good migration doesn't copy one into the other. It reshapes the estate around the model.

## Concept *mapping*

| Domo | Power BI | Notes |
|---|---|---|
| DataSet | Table in a semantic model | Several related DataSets usually become one model with relationships. |
| Connector | Data source or warehouse pipeline | Many teams land data in a warehouse first, then import. |
| Magic ETL | Warehouse SQL pipeline or Power Query | Heavy transformations belong upstream of the model. |
| SQL DataFlow | SQL model | Translated to your warehouse's SQL dialect. |
| DataSet view / DataFusion | SQL view or model table | Joins become model relationships where possible. |
| Beast Mode (aggregate) | DAX measure | Rewritten for filter context. |
| Beast Mode (row-level) | Calculated column, or a column upstream | Better computed before the model where possible. |
| Card | Report visual | Chart types are mapped to the nearest native visual. |
| Page / dashboard | Report page | Layout follows the dashboard definition. |
| Drill path | Hierarchy or drill-through | |
| Variables | Parameters or field parameters | |
| PDP policy | Row-level security role | Tested role by role. |
| Alert | Data alert or subscription | |

## Where to take *care*

### Beast Modes and filter context

Beast Modes are evaluated in the context of a single card. DAX measures are evaluated in the model's filter context, which spans related tables. A formula that looks identical can give a different answer. Every translated Beast Mode is parity-tested against the original card's results.

### Near-duplicate calculations

Large Domo instances often contain several copies of the same Beast Mode that have drifted apart. Pick one definition before migrating, rather than creating several DAX measures with confusingly similar names.

### Dates and fiscal calendars

Domo's fiscal calendar and date granularity settings should become an explicit date table in Power BI, marked as a date table and related to every fact table.

### DataSet grain

Domo cards often read wide, denormalized DataSets. In Power BI, reshaping these into facts and dimensions gives smaller models and simpler DAX. Check the grain before building relationships.

## Two translations that look simple and aren't

### FIXED functions and the filters they still obey

Domo documents FIXED functions as level of detail expressions: they calculate against the DataSet instead of row by row. What gets lost in translation is the filter rule. Domo's page says that if you don't set up filter logic, all filters are applied. Three arguments change that:

```
SUM(SUM(`Total Sales`) FIXED (BY `Region` FILTER NONE))
SUM(SUM(`Total Sales`) FIXED (BY `Region` FILTER ALLOW `Product Category`))
SUM(SUM(`Total Sales`) FIXED (BY `Region` FILTER DENY `State`))
```

`FILTER NONE` applies no card filters, `FILTER ALLOW` applies none except the fields you name, and `FILTER DENY` applies all except the fields you name. A bare `FIXED (BY ...)` is a fourth behavior: group at that level, but keep every filter.

DAX has its own pair of filter-removing functions, and neither matches any of the four. Microsoft says `ALLEXCEPT` "removes all context filters in the table except filters that have been applied to the specified columns", and that `ALLSELECTED` ignores filters applied inside the query while keeping filters that come from outside. So `ALLEXCEPT(Sales, Sales[Region])` is closer to `FILTER NONE` than to the default, and still not the same, because it keeps a filter on Region itself and only touches filters on that one table. For each FIXED Beast Mode, write down which of the four behaviors it had, then test it with a filter on one dimension at a time. The longer version is in [Beast Mode FIXED to DAX](/insights/beast-mode-fixed-to-dax/).

Domo also lists three limits: FIXED works only on non-federated DataSets, it can't share a calculation with window functions, and a calculation containing it can't be used as a card or dashboard filter. Check which of your cards were built around those limits before you copy their shape.

### PDP policies, All Rows and who is exempt

Personalized Data Permissions and row-level security both filter rows by person. They disagree about who is exempt, how policies combine, and what happens to columns.

**Who sees everything.** Domo says DataSet owners and admins have access to all data, and the All Rows policy lets you give other people and groups the same. Power BI's rule is by workspace role: Microsoft documents that RLS restricts only Viewers, and does not apply to Admin, Member or Contributor, who can edit the semantic model. Viewers with Build permission are still restricted. So an All Rows member has no role to port. It becomes a decision: is this person a Viewer who needs a role that lets every row through, or a Contributor who can also edit the model? The second is the easier answer and usually the wrong one.

**Who sees nothing.** Domo says people not included in a PDP policy can't access the DataSet. Microsoft says users not assigned to any RLS role typically see no data. Both fail closed, which is good, but test it with a real account rather than reading it off the docs.

**How policies combine.** In Domo, separate policies on one DataSet are OR logic, and one policy with two or more values is AND logic. In Power BI, a user can belong to more than one role and the roles are additive. The mapping follows: each Domo policy becomes a role, and a policy with two values becomes one role whose expression requires both. Getting this backwards gives people more rows or fewer rows than they had, with no error either way.

**Dynamic rules.** Domo offers Simple PDP, assigned by group, and Dynamic PDP, driven by user attributes. The Power BI pattern for the second is a user-mapping table and `USERPRINCIPALNAME()`. Microsoft notes that Test as role uses your own identity, so check guests and other special accounts by signing in as them.

**Pipelines.** Domo applies PDP to DataFlows built on the DataSet, and says a DataFlow runs only if its owner is an admin with the right grant, owns the input, or is in All Rows. After migration the pipeline lives in the warehouse. For imported models, Microsoft says the security roles in the data source aren't used, so every rule that Domo enforced upstream has to be written again in the model or the warehouse, on purpose.

**Column masking.** Domo's column policies hide some or all of a column's values. Microsoft says RLS can't limit columns: if you can see a row, you see all its columns. Object-level security hides a column from a role, set up in TMDL view or an external tool such as Tabular Editor, and visuals that use it show a field-not-found message to those viewers. A card that used to show masked values becomes a card that errors. That is a design conversation with the data owner, not a mapping rule.

A parity test for security is a table: one real user for each policy, one owner, one admin, one All Rows member, one person in no policy, and one guest if you have them. Row count in Domo, row count in Power BI. They match or the cutover waits. Domo's DomoStats reports on row policies, their conditions and their assignments are a good place to build the inventory (they are marked beta).

## A migration *checklist*

1. Export Domo metadata and usage; retire dormant cards and pages.
2. Agree one definition for each duplicated Beast Mode.
3. Translate DataSets and DataFlows into SQL models and pipelines.
4. Design the semantic model: facts, dimensions and a date table.
5. Translate Beast Modes into DAX measures and parity-test them, FIXED filter behavior included.
6. Rebuild pages as reports; map PDP policies, All Rows members and column masking to row-level security roles, workspace roles and object-level security.
7. Run both platforms in parallel, sign off each wave, then cut over.

Sources: Domo's Knowledge Base pages on Personalized Data Permissions and Beast Mode FIXED Functions, and Microsoft Learn's pages on row-level security, object-level security, `ALLEXCEPT` and `ALLSELECTED`, all read on 18 October 2026. Confirm each behavior in your own instance before you rely on it.

See also: [Domo to Power BI migration](/domo-to-power-bi/) · [Domo](/platforms/domo/) · [Power BI](/platforms/power-bi/) · [Full migration](/services/full-migration/) · [Risk & governance](/risk-governance/)
