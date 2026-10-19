---
title: "Looker to Power BI: what symmetric aggregates did"
heading: "Looker did the <em>fan-out</em> math for you."
description: "Looker detects fan-out joins and corrects the sum. Power BI doesn't, so a LookML migration has to rebuild that protection in the model. Here is where it goes."
author: amy-loomis
image: /assets/img/og/looker-symmetric-aggregates.png
---

Here is a sum that is wrong in a way nobody sees. An `orders` table has one row per order and a `total` column. An `order_items` table has one row per line. Join them, group by anything on the items side, and sum `total`. Every order is now repeated once per line item, so every order is counted that many times.

Looker's own documentation uses exactly this case. In its example, the naive join returns 223.44 where the correct figure is 124.84. The documentation notes that an analyst can make that mistake without realizing it. In Looker, they mostly can't. That protection has a name, symmetric aggregates, and it is the thing most Looker to Power BI plans forget they are about to lose.

## What Looker was *doing*

Looker hashes each row's primary key into a large unique number, then uses `SUM DISTINCT` so each parent row is counted once. The pattern, as the documentation gives it, is `SUM(DISTINCT big_unique_number + total) - SUM(DISTINCT big_unique_number)`. It only does this when it detects a join that fans out. Otherwise it writes the plain sum.

Two things have to be true for that to work, and both live in LookML. The join has to declare its `relationship` correctly. Looker's reference says it is important to define the type properly so Looker can calculate accurate measures, and the default is `many_to_one`. And the view has to declare a primary key that really is unique, because the documentation says symmetric aggregates depend on one.

Notice what that gives a business user. Any measure from any view can be dragged next to any dimension from any joined view, and the answer holds. The person building the Look never has to know which table is the "one" side.

## What Power BI asks *instead*

Power BI has no query-time rescue. A model relationship, in Microsoft's description, propagates filters from one table to another. That's all it does. The "one" side is a column with unique values, the "many" side can repeat, and filters flow from one to many by default. Microsoft recommends star schema: fact tables in the middle, dimension tables around them.

So the protection moves from the query to the model's shape. An `orders.total` measure is safe only if the model has a place for it where nothing fans it out. Reproduce the Looker explore as two related tables, orders on the "one" side and order items on the "many" side, and a slicer on an item attribute will not filter the sum of order totals at all, because filters travel from the "one" side to the "many" side and not back. Turn on bi-directional filtering and it will filter. Microsoft's guidance is to use that only where needed, and it warns about performance and about ambiguous filter paths.

Neither outcome is wrong. Each is a different answer to a question the Looker user never had to ask: at what grain does this number live?

## Where the migration *drops* it

A translation that goes view to table, dimension to column, measure to DAX measure, explore to relationships will produce a model that loads and a report that renders. The explore that joined two tables at different grains turns into one relationship with a direction. Nothing marks that as a decision.

Quiet failures cluster in three places.

**Measures on the one side, read by many-side dimensions.** Order totals, account balances, anything that lives on the parent. Count these first. They are the cases symmetric aggregates were silently fixing.

**Primary keys that were never really unique.** Looker's protection hangs on a declared key. If two rows share one, the distinct sum counts them once, and the figure comes out low without an error. Power BI treats the same fault differently: Microsoft says that if a refresh tries to load duplicates into a "one" side column, the whole refresh fails. The Looker version is quiet and the Power BI version is loud. Moving between them can surface data problems that were always there, which is useful, but you want to meet them in testing rather than on a Monday.

**Relationships that don't enforce anything.** Microsoft is explicit that model relationships don't enforce data integrity. A fact row with no matching dimension row shows up under a blank member in the report. Check every grouped report for a blank row before you call a total a match.

## Do this before you model anything

List every explore that joins more than one view, and write down the grain of each view next to the declared `relationship`. Wherever grains differ, list the measures that sit on the coarser view. That list is your fan-out inventory.

For each item, make the decision on purpose. Move the measure to its own fact table at its own grain, relate it to shared dimensions, and let the report combine them. Or restate it at the finer grain, if the business meaning allows. Or allow bi-directional filtering and accept what it costs. Write the choice into the model's documentation, so the next person doesn't find it by accident.

Then test the way the numbers will be used. Take the same grouped results from a Looker explore and from the Power BI model, for the same slices, and compare them cell by cell. A grand total that matches proves little here, since fan-out errors show up as soon as you group by something on the many side. That is the argument in [proving parity after a BI migration](/insights/proving-parity/), and the same discipline applies to the calculation differences in [Tableau table calculations](/insights/tableau-table-calculations-live-in-the-view/).

## The part that isn't in the *code*

LookML is code, so it reads well. It still doesn't say why a join was written the way it was, or which numbers people trusted because Looker was quietly correcting them. Our [Looker to Power BI guide](/migration-guides/looker-to-power-bi/) maps the concepts and lists symmetric aggregates as a care point, and the [Looker platform page](/platforms/looker/) describes what we read from a LookML estate. If you are sizing a move, an [estate assessment](/services/estate-assessment/) is where the fan-out inventory gets built, alongside a count of what anyone actually opens. The same sheet-by-sheet testing sits behind our [Tableau to Power BI migration](/tableau-to-power-bi/) work. Start with the joins. The measures will tell you which ones mattered.
