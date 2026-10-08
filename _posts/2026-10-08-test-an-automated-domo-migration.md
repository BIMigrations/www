---
title: "How to test an automated Domo to Power BI migration before you buy one"
heading: "Test the migration on your <em>hardest</em> dashboards."
description: "Every vendor can convert a simple chart. A proof of concept should hit Beast Modes, Magic ETL, row-level security and reconciliation. Here is the checklist to hold any vendor to."
author: amy-loomis
image: /assets/img/og/test-an-automated-domo-migration.png
---

"Automated" is the most overloaded word in BI migration. To one vendor it means a script that exports Domo card definitions. To another it means a tool that reads the whole estate and writes a native Power BI model. Both will say it in a sales call, and both will convert a bar chart perfectly.

So don't test the bar chart. Here is how I'd run a proof of concept, whoever you are buying from, including us.

## Pick the dashboards that scare you

Choose five to ten. Include a card built on a Magic ETL flow with several joins, a handful of Beast Modes that you suspect are subtly different from each other, one page with row-level restrictions, and one dataset with a scheduled refresh that people complain about when it is late. A vendor who wants to pick the sample for you is telling you something.

## Ask for these seven things

1. **An inventory.** Before anything converts, you should get a list of what exists: DataSets, DataFlows, Beast Modes, cards, pages, permission policies, and who uses them. If the inventory arrives after the conversion, nobody decided what was worth converting.
2. **Beast Modes as measures, with the reasoning shown.** A Beast Mode is calculated inside one card. A DAX measure is calculated in the filter context of the model. The same formula can return a different number. Ask to see a nested or FIXED-style calculation converted and then explained, not just converted. ([We've written about where this bites.](/insights/beast-mode-fixed-to-dax/))
3. **What happens to Magic ETL.** It can become Power Query, a dataflow, or SQL upstream in the warehouse. Any of those can be right. Ask which one the tool chose for your flow, and why.
4. **Security tested as people, not as syntax.** In Power BI, row-level security is a set of roles whose DAX filters decide which rows a viewer sees. Microsoft's documentation is blunt about the edges: RLS only restricts people with the Viewer role in a workspace, and does not apply to Admins, Members or Contributors. For dynamic RLS, its Test as role feature evaluates your own identity, so it cannot show you what a specific external guest would see. A vendor who says "permissions migrated" should show you a real Viewer account seeing the right rows.
5. **Reconciliation you can read.** Ask for the same metric, for the same slices, from Domo and from Power BI, side by side, with a tolerance and a list of misses. A single "98% match" with no list is not reconciliation.
6. **A documented exception list.** No tool converts everything. The honest answer to "what didn't convert?" is a specific list with an owner for each item. If the answer is "nothing", ask again.
7. **Artifacts you keep.** After the engagement, what do you own and can you read it? Models, SQL, definitions, scripts. If the output only runs inside the vendor's environment, you have migrated platforms and rented a new dependency.

## Score it, not the demo

Give each item a plain pass, partial or fail, and write down the evidence. Two vendors who both say "automated" will separate quickly on items 4, 5 and 6, because those are the ones that cannot be faked with a nice screenshot.

Also watch the ratio. Ask how much of your sample converted without a person touching it, and how much needed an engineer. The honest figure will be neither 100% nor a vague "most".

## Where we stand against this list

I work with BI Migrations, so judge this section accordingly. Our [Domo to Power BI migration](/domo-to-power-bi/) starts from a read-only metadata export that inventories every DataSet, DataFlow, Beast Mode, card, page and permission policy with usage, which is item 1. Every translated Beast Mode is parity-tested against the original card, which is item 5. Engineers handle what the tooling can't convert, which is the beginning of item 6. And the estate lands in [open specifications](/open-specifications/) you keep, which is item 7. Around 78% of an estate is converted by tooling.

Hold us to the list the same way. The [free estate scan](/services/estate-assessment/) is the cheapest place to start, and your hardest ten dashboards are the right test.
