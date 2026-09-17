---
title: Qlik migration
crumb: Qlik
heading: "Unpack Qlik. <em>Line by line.</em>"
description: Qlik Sense and QlikView load scripts, QVDs, set analysis and Section Access — translated into open specifications and regenerated natively on your next BI platform.
permalink: /platforms/qlik/
accent: amber
related:
  - label: Migration guide
    title: Qlik to Power BI
    text: From load scripts and set analysis to star schemas and DAX.
    url: /migration-guides/qlik-to-power-bi/
    link: Read the guide
  - label: Service
    title: Estate assessment
    text: Inventory every app and document, and see which ones are still opened.
    url: /services/estate-assessment/
  - label: Resource
    title: Risk & governance
    text: How Section Access becomes tested row-level security.
    url: /risk-governance/
---

A lot of the business logic in a Qlik estate lives in load scripts, so it's hidden from anyone who only looks at the sheets. A migration that starts from the screens misses it. We start from the scripts.

## What we *read*

- **Load scripts** — `LOAD` and `SQL SELECT` statements, joins, mapping tables, `ApplyMap` and incremental-load logic.
- **QVDs** — what each file contains, what produces it and what consumes it.
- **Data models** — associations, synthetic keys and link tables.
- **Master items** — dimensions and measures, including set analysis and `Aggr()`.
- **Variables** — including expressions expanded with `$(...)`.
- **Sheets and objects** — charts, filter panes and bookmarks.
- **Section Access** — who can see which rows.
- **Usage** — which apps and documents are still opened.

Both **Qlik Sense** apps and **QlikView** documents are supported.

## How it *translates*

| Qlik | Open specification | On the target (e.g. Power BI) |
|---|---|---|
| Load script | SQL models, Airflow and Python | Warehouse pipeline or Power Query |
| QVD | SQL model (materialised) | Warehouse table |
| Associative model | Model relationships (YAML) | Star schema with relationships |
| Master measure / set analysis | Metric definition (YAML) | DAX measure |
| Variable | Parameter or metric definition | Measure or parameter |
| Sheet and objects | Dashboard definition (JSON) | Report page and visuals |
| Section Access | Access policy (YAML) | Row-level security role |

## Where the *care* goes

- **Associative behaviour.** Qlik's green, white and grey selection states have no direct equivalent elsewhere. We model the questions people actually ask with them.
- **Synthetic keys and link tables.** These are reshaped into a star schema with clear grain.
- **Complex set analysis.** Modifiers such as `P()`, `E()` and nested sets are translated into explicit filter logic and parity-tested.
- **Alternate states.** Comparison analyses are rebuilt with the target's own patterns.

{% include cards.html items=page.related %}
