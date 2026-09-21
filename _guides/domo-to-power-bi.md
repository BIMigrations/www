---
title: "Domo to Power BI Mapping: Beast Modes to DAX"
crumb: Domo to Power BI mapping
heading: "Domo to Power BI, <em>mapped.</em>"
description: How Domo DataSets, DataFlows, Beast Modes, cards and PDP policies map onto Power BI concepts — and the places a migration needs the most care.
from: Domo
to: Power BI
order: 1
---

This guide is the detailed companion to our [Domo to Power BI migration](/domo-to-power-bi/) service. Domo and Power BI organise analytics differently. Domo keeps data preparation, calculations and visuals close together around each DataSet. Power BI centres on the semantic model: tables, relationships and measures shared by many reports. A good migration doesn't copy one into the other. It reshapes the estate around the model.

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

Domo's date grains and fiscal calendar settings should become an explicit date table in Power BI, marked as a date table and related to every fact table.

### DataSet grain

Domo cards often read wide, denormalised DataSets. In Power BI, reshaping these into facts and dimensions gives smaller models and simpler DAX. Check the grain before building relationships.

## A migration *checklist*

1. Export Domo metadata and usage; retire dormant cards and pages.
2. Agree one definition for each duplicated Beast Mode.
3. Translate DataSets and DataFlows into SQL models and pipelines.
4. Design the semantic model: facts, dimensions and a date table.
5. Translate Beast Modes into DAX measures and parity-test them.
6. Rebuild pages as reports; map PDP policies to row-level security roles.
7. Run both platforms in parallel, sign off each wave, then cut over.

See also: [Domo to Power BI migration](/domo-to-power-bi/) · [Domo](/platforms/domo/) · [Power BI](/platforms/power-bi/) · [Full migration](/services/full-migration/)
