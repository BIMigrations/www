---
title: "Choose a Power BI storage mode before you migrate"
heading: "Storage mode is not a speed setting. It is a <em>decision about ownership.</em>"
description: "Import, DirectQuery or Direct Lake decides where data prep lives, how row-level security behaves and what you license. Settle it before a BI migration."
author: amy-loomis
image: /assets/img/og/power-bi-storage-mode-before-migrating.png
---

Most Power BI storage mode advice is about speed. Import is fast, DirectQuery is fresh, Direct Lake is both if you have the capacity. It reads like a dial you turn when a report feels slow.

In a migration it is the opposite. It is one of the first things to settle, because it quietly answers three questions nobody put on the plan: where does the data preparation live, how does row-level security survive, and what do you have to license. Pick it late and you will find out you answered all three by accident.

## Data prep needs a *home*

Storage mode is a property of each table in a semantic model, and the modes differ in who is allowed to change the data. Microsoft's Direct Lake documentation is direct about it: Direct Lake "depends on data preparation being done in the data lake," with Spark jobs, T-SQL, dataflows or pipelines doing the work upstream. Import tables use Power Query, which is "defined as part of the semantic model." The same page notes that a self-service analyst who cannot write to a lakehouse managed by IT may be better served by Import tables for exactly that reason.

That is a statement about ownership, not performance. And it matters most if you are leaving a tool that bundled the preparation into the BI layer. Domo does this. Magic ETL flows and SQL DataFlows sit beside the dashboards, built by whoever needed the number. When you leave, those flows have to land somewhere, and the storage mode you choose decides where by default:

- **Import with Power Query** keeps the logic inside the model, owned by the person who builds the report. It is the closest thing to how the estate works today, and it carries the same weakness: the same logic copied into several places, drifting apart.
- **Direct Lake or DirectQuery on a warehouse** pushes the logic upstream, once, where engineers can test and reuse it. It also means someone has to own that warehouse work, and it has to exist before the first dashboard works.

Neither is wrong. [Where metric definitions live](/insights/metric-definitions-live-in-the-model/) is already the hardest argument in most migrations. The storage mode is where that argument gets settled in practice, whether or not anyone had it.

## Security does not move on its own

This is the part I would test first. Domo's row-level restrictions have to be rebuilt as Power BI row-level security, and Microsoft's capability table shows the storage mode changes what that means.

For Import tables, SQL-side row-level security in the source has to be duplicated in the semantic model: the docs say you "must duplicate permissions with semantic model RLS." For Direct Lake on OneLake, the docs say the opposite problem exists. When the SQL analytics endpoint enforces row-level security, queries "will succeed, and SQL based RLS is not applied," because Direct Lake on OneLake reads the files, and file access does not observe SQL-based rules. Microsoft recommends semantic model RLS with a fixed identity connection for these models.

Read that as a migration risk. A team that assumes "the warehouse already restricts rows" can move to Direct Lake on OneLake and find the restriction is not there, with every query succeeding and nothing erroring. The numbers look right. They are just visible to the wrong people.

That is a parity failure, and the way to catch it is the one in [Proving parity after a BI migration](/insights/proving-parity/): run the same report as a restricted user and compare against the source, not as an administrator.

## Cost and reversibility

Two more things hide in the choice.

**Licensing.** Per the capability table, Direct Lake needs a Fabric capacity subscription, while Import and DirectQuery work with any Fabric or Power BI license. Direct Lake also has per-table guardrails by capacity size. On the smaller SKUs (F2 to F32) the limit is 300 million rows per table; at F64 it is 1.5 billion. For Direct Lake on OneLake, exceeding a guardrail does not degrade gracefully: refresh fails and the model cannot be queried until the Delta tables are optimized. Count your largest tables before you pick a capacity, not after.

**Reversibility.** Some moves are one way. A DirectQuery table can be switched to Import, but the docs say you cannot set it back to DirectQuery (the web modeling experience and live editing in Desktop are the exceptions, because they keep version history). Direct Lake on OneLake tables can be converted to Import with semantic link labs in a Fabric notebook. Know which door you are walking through.

## What to decide, and when

Before you build anything, go through the datasets and make four calls, table by table, since storage mode is set per table and a model can mix them:

1. Where does each group of Domo transformations land: in the warehouse or lake, or in Power Query inside a model?
2. Which tables are large enough that Import refresh or capacity limits will bite?
3. Where is row-level security written, and who tests it as a non-admin?
4. Which of these choices can you undo cheaply, and which can you not?

Then build one prototype. Microsoft recommends a proof of concept before committing to Direct Lake, and the advice generalizes. Also re-read the docs on the day you decide: the Direct Lake page says its capabilities and limitations are "evolving rapidly," and the rows I quoted here may have moved.

## Where this *fits*

The reason an [estate assessment](/services/estate-assessment/) inventories transformations and permissions alongside dashboards is that those are the inputs to this decision. Our [Domo to Power BI migration](/domo-to-power-bi/) turns DataFlows into SQL models and pipelines, usually in your warehouse, or into Power Query where that is the better fit, and the choice between those two is one to make deliberately with your own data team. Whichever way it goes, write it down in an [open specification](/open-specifications/) so the next platform change starts from a documented estate instead of a guess. The [Power BI platform page](/platforms/power-bi/) has the target-side detail.
