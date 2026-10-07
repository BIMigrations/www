---
title: "Where metric definitions should live"
heading: "Metrics belong <em>below</em> the dashboard."
description: "Most BI estates define the same metric many times, once per card. A migration is the cheapest moment to decide where definitions live, and to stop copying them."
author: amy-loomis
image: /assets/img/og/metric-definitions-live-in-the-model.png
---

Ask three people in a company for last quarter's revenue and you can get three numbers. Nobody is lying. Each of them opened a different dashboard, and each dashboard carries its own idea of what "revenue" means: gross or net, with or without the refunds, booked or recognized.

That is the quiet cost of building metrics inside the dashboard layer. The definition is real, it just lives in a place nobody reviews, copied card by card. A migration is the first time anyone is forced to read all of those copies in one sitting.

## Where definitions *hide*

In most BI tools a metric is whatever the person building the card typed into a calculation box. Domo calls it a Beast Mode. Tableau calls it a calculated field. Power BI calls it a measure, but a measure can sit in a model one report uses or in a model built for a single report.

Picture an estate with 400 dashboards. Revenue is defined in the shared model, again in a card someone cloned two years ago, and once more in a spreadsheet export that finance trusts more than either. The three agree most of the time. When they stop agreeing, nobody can say which one was right, because none of them was ever written down as the answer.

Moving that estate tool to tool, one card at a time, carries every copy across. You pay to rebuild the disagreement.

## What Microsoft's model layer *offers*

Power BI gives you a place to put a definition once. Microsoft's documentation describes a semantic model as a source of data that is ready for reporting, built on Analysis Services tabular technology, with relationships, calculations and row-level security attached to the model rather than to any one report.

That matters because the definition and the permissions travel together. A measure defined in the model is the same measure for every report that connects to it. A report that wants a different revenue has to say so out loud, in a different measure with a different name.

The warehouse side has its own version of the argument. dbt's documentation on MetricFlow describes the problem plainly: analysts working on the same data, each with their own query, produce confusion and inconsistency. Its answer is to define metrics once in YAML and commit them to git, so the people who own the numbers can see and approve them. Whether you use that tool or not, the principle is the useful part. A definition that lives in version control can be reviewed. A definition that lives in a card cannot.

## The question to ask *during* the move

Here is what I'd argue: a migration should not preserve every metric. It should force one decision per metric, which is where this definition lives from now on. There are three honest answers.

1. **In the warehouse**, as a column or a view, when the logic is row-level and everything downstream should agree.
2. **In the shared model**, as a measure, when the logic depends on how the viewer slices the data.
3. **In the card**, only when it is truly one-off, and then it should say so in its name.

My bet is that a small set of metrics carries most of the weight, and that those are the ones defined several times. Start there. Retire the cards nobody opens first ([we've written about how](/insights/retire-before-you-migrate/)), so you aren't deciding where to house a metric that no one reads.

The hard cases are the ones where the translation changes the meaning, not just the syntax. [Domo's FIXED functions against DAX filter context](/insights/beast-mode-fixed-to-dax/) are a good example. Those are the definitions worth writing down before they move, not after.

## What we do with *this*

When we migrate an estate, the definitions are the part we capture first. For the [Domo to Power BI migration](/domo-to-power-bi/), our automated migration tool inventories the estate and rebuilds transformations as warehouse SQL, and the result is documented in [open specifications](/open-specifications/) that you own. That is what lets a metric have one address, in your hands, rather than a copy in every card.

Ask each team a short question before cutover: if this number changed tomorrow, who would be told? If the answer is a shrug, you have found a definition that has been living without an owner. [Power BI](/platforms/power-bi/) will happily host it. It won't give it one.
