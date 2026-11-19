---
title: "Tableau converters quote a percentage. Of what?"
heading: "A migration tool says <em>80%.</em> Of what?"
description: "Tableau to Power BI migration tools quote 60 to 90 percent automation. Here is what eight vendor pages say, what they leave out, and the questions that make the numbers comparable."
author: amy-loomis
image: /assets/img/og/tableau-converter-claims.png
---

Open three Tableau to Power BI migration listings in three tabs and you will see three numbers. One promises "75–90% migration." One "automates 60-80% of the migration process." One "automates 80% of the conversion work." They look comparable. They are not, because none of them says what the percentage is a percentage of.

I read eight vendor pages and listings, plus Microsoft's own migration guidance. Here is what they say, and what a buyer should ask before any of those numbers goes into a business case.

## What are the claims, side by side?

Quotes are exact. I read every page below on 24 and 25 October 2026 and re-checked the figures on 18 November. Listings change, so check the date.

| Approach | The headline claim | What the page says it converts | Price |
|---|---|---|---|
| Pulse Convert | "One-click 75–90% migration Guaranteed" | A .twbx file in, a Power BI file out. LOD, table calcs, parameters and security: not stated | Not stated; offers a free proof of concept on 5 dashboards |
| DataFactZ migration agent | "automates 60-80% of the migration process" and "75% automated calculation accuracy on first pass" | PBIP/TMDL artifacts and semantic models; AI-assisted DAX for LOD, table calcs and parameters. Layout and security: not stated | Not stated |
| Kanerika FLIP | "automates 80% of the conversion work" | Connections, relationships, calculated fields to DAX, dashboards with matching charts and filters | Not stated; says large estates with complex calculated fields "can take 3 to 5 months" |
| MAQ Software | No percentage | An assessment that inventories workbooks and converts LOD measures to DAX, plus a base report that mirrors the Tableau layout and a gap summary | Assessment described as free |
| KPI Partners | "Up to 70% reduction in cost" | Sorts content into 100% migrated, partially migrated or unsupported, without saying which objects fall in which bucket | Assessment free |
| Genpact | "Eliminates the need for manual conversion" | "Reports", with no detail on calculations, LOD, parameters or security | Not stated |
| BIChart | "Lower migration project costs by up to 80%" | Workbooks, data sources, dashboards, visuals. Calculations and security: not mentioned | Contact the vendor |
| Manual rebuild, per Microsoft's guidance | None | A staged plan: requirements, proof of concept, build, then validate data accuracy, security, functionality and performance | Your team's time |

Two things stand out. The percentages measure different things: steps automated, calculations converted, effort saved, cost cut. And the cells that would let you judge a tool (what happens to a level-of-detail expression, a table calculation, row-level security) are mostly blank.

## Why isn't "80% automated" a number you can plan with?

Because the hard 20% is not spread evenly. Microsoft's own migration guidance rates calculations such as LOD expressions and window functions as the complex end of the work, and says Tableau to Power BI "is not a one-click effort." Its lessons-from-customers page admits that "not every individual report could be faithfully replicated."

If a tool converts 80% of your calculated fields and the other 20% are the ones your CFO's dashboard depends on, the project is not 80% done. It is done on the easy part. A table calculation that works on whatever is in the view has no one-line DAX twin, which is the argument in [Tableau table calculations live in the view](/insights/tableau-table-calculations-live-in-the-view/).

One of the eight, Inforiver, sells visuals rather than a converter, and its own page says that "a direct, automated conversion of Tableau reports and dashboards to Power BI is generally not possible." That is the other end of the range, and it is also unquantified.

Percentages also say nothing about whether the numbers match afterward. Microsoft's validation stage is about data accuracy, security and performance. I did not find a parity test described on any of the pages.

## What should you ask a vendor instead?

Four questions turn a percentage into something you can compare.

1. **Percent of what, counted how?** Calculated fields, worksheets, dashboards, hours? Ask for the count from a scan of your estate, not a slide.
2. **What lands in the "unsupported" bucket?** Ask for the list by object type: LOD, table calculations, parameters, sets, row-level security, extracts.
3. **How is a converted number proven right?** A converter's output is a claim. Ask what is compared against what, on which rows, and who signs it off.
4. **Who owns the model afterward?** Microsoft's guidance warns that copying Tableau workbooks one for one produces duplicated logic and conflicting KPIs, and recommends a central semantic model. Ask whether the output is one model or a pile of per-workbook copies.

Start with the free assessments. Two of the eight (MAQ Software and KPI Partners) offer one, and a count of your own estate is the one number in this process that is yours.

## Where does BI Migrations fit?

Not in the table. Our Tableau work is a service that starts with a free scan of your estate, and I am not claiming our tooling automates Tableau. The questions above are the ones I would put to us, too. The [Tableau to Power BI guide](/migration-guides/tableau-to-power-bi/) walks through the steps in the order a project runs them.

An honest tool is one that tells you where it stops. The best sentence on any of these pages is "flags conversion edge cases." It is also the least quoted.
