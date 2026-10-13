---
title: "Tableau table calculations live in the view. DAX measures live in the model."
heading: "A Tableau table calculation has no <em>address</em> of its own."
description: "Tableau table calculations take their meaning from the sheet they sit on. Moving one to DAX means deciding the partition and the order the old view supplied for free."
author: amy-loomis
image: /assets/img/og/tableau-table-calcs-live-in-the-view.png
---

Open a Tableau workbook and find a running total. Now ask where the definition of "running" is stored. It isn't in the calculation. The calculation says something like `RUNNING_SUM(SUM([Sales]))` and stops there. Running across what? Restarting when? That answer lives in the sheet: in which fields sit on the rows and columns, and in a dialog most people clicked through once and forgot.

That is the whole difficulty of migrating table calculations to Power BI. The formula is short. The meaning is somewhere else.

## Where the meaning hides

Tableau's documentation splits every table calculation into two jobs. Partitioning fields define the scope of the data: the view is cut into groups, and the calculation runs separately inside each one. Addressing fields set the direction, the path the calculation takes through the marks in each partition.

You can choose these yourself with Specific Dimensions. Most people don't. They pick Compute Using, and Tableau, in its own words, identifies some dimensions as addressing and others as partitioning automatically. It decides from what is currently in the visualization.

So the same calculated field can mean "running total per region, in date order" on one sheet and "running total down the whole table" on another, with no change to the formula. Someone drags a field onto the view and the numbers change. Nobody edited a calculation.

## What DAX asks for instead

A DAX measure has no sheet to borrow from. It sits in the model and gets evaluated in whatever filter context a report throws at it. So the things Tableau worked out from layout have to be written down.

Microsoft's `WINDOW` function shows what that looks like. It takes the start and end of the window, a relation, an `ORDERBY` clause for how each partition is sorted, and a `PARTITIONBY` clause for how the relation is split. Microsoft's own running-sum example restarts every fiscal year because the measure says so: `PARTITIONBY ( 'Date'[Fiscal Year] )`. Nothing is inferred from a visual.

Written out, the old running total becomes something like this:

```dax
Running Sales =
SUMX (
    WINDOW (
        1, ABS,
        0, REL,
        ALLSELECTED ( 'Date'[Fiscal Year], 'Date'[Month Number Of Year] ),
        PARTITIONBY ( 'Date'[Fiscal Year] )
    ),
    [Total Sales]
)
```

That is adapted from Microsoft's example, and it does exactly one thing: monthly, restarting each fiscal year. If a Tableau sheet used the same calculated field with a different layout, you need a second measure, or a decision that the second sheet was wrong.

There is a middle route. Visual calculations in Power BI work on the shape of the visual, and `WINDOW` accepts an axis and a `reset` argument there. That feels closest to how Tableau behaves. It also brings back the same trap: the answer depends on the visual again. Fine when you want that. A problem when you wanted a number a second report can reuse.

## Three things to check before you trust the port

**One field, many meanings.** Count how many sheets use each table calculation and how each one is configured. A field that is set up three different ways is three measures, and the translation work is mostly in deciding which of the three people actually meant.

**Order.** `WINDOW` sorts each partition by `ORDERBY`. If you leave it out and it can't tell rows apart, it appends columns on its own to make rows unique, or returns an error. Tableau sorted by whatever was on the axis. Say what the order is, in the measure.

**Gaps.** Microsoft's three-day average example is blunt about it: the window is three days on which the product had sales, not three consecutive calendar days. A Tableau moving average over a view with missing dates may or may not have behaved the same way. Test it on a product with a sales gap.

None of this is exotic. All of it is the kind of difference that survives a quick check of the grand total and shows up in a director's quarterly deck.

## Prove it per sheet, not per field

The temptation is to test the calculation once and call it done. The calculation was never the unit. The sheet was. Compare the output for each place it's used, for the same slices, and keep the Tableau numbers until each sheet matches. That is the approach in [proving parity after a BI migration](/insights/proving-parity/), and table calculations are where it earns its keep. The same logic applies to the Domo functions in [Beast Mode FIXED to DAX](/insights/beast-mode-fixed-to-dax/): a formula that looks portable usually has a context attached.

If you're planning a move, the [Tableau calculations to DAX guide](/migration-guides/tableau-to-power-bi/) maps the functions, and our [Tableau to Power BI migration](/tableau-to-power-bi/) page describes how we handle it. Either way, begin the inventory with the sheets. The formulas will look innocent. The layouts will tell you what they meant.
