---
title: "Qlik's {1} ignores selections, not the axis"
heading: "Set analysis edits the <em>selection.</em> CALCULATE edits everything."
description: "Qlik set analysis to DAX looks like a one-to-one swap until a set sits under a chart axis. Here is where {1} and a plain modifier change meaning, and how to test it."
author: amy-loomis
image: /assets/img/og/qlik-set-analysis-identifier.png
---

Here is a Qlik measure that migrates badly while looking like the easiest thing in the app: `Sum({1} Sales)`. Put it in a chart by region and it returns each region's sales, ignoring whatever the user has selected. Qlik's documentation puts it as total sales "disregarding selections but not the dimension."

Port it the way most checklists say to, as `CALCULATE(SUM(Sales[Amount]), ALL(Sales))`, and the visual may show the grand total on every row. Or it may show the right regional figures. Which one you get depends on where the Region column lives in the model, and nothing in the Qlik expression tells you.

## What does a set expression actually have?

Two layers. The first is the identifier, which names a starting set of records. `1` is every record in the app, `$` is the current selection, `$1` is the previous selection, and a bookmark name points at a saved one. The second is the modifiers in angle brackets, which edit that set: `{$<Year={2021}>}` means the current selection with Year changed to 2021.

Then the chart does its own thing. Each row of a chart is a dimension value, and the aggregation runs over the set intersected with that value. Selections, set, dimension: three separate inputs.

Power BI has one input. A slicer, a row header and a column header all arrive as filters on the same filter context, and `CALCULATE` edits that context. Microsoft's description of the filter modifiers shows how it thinks about the job: `REMOVEFILTERS` and `ALL` work on columns or tables, `ALLEXCEPT` removes everything but the columns you name, `KEEPFILTERS` adds a filter without removing the existing ones on the same column. None of them is described in terms of where a filter came from.

That is the whole migration problem in one sentence. Qlik lets you say "ignore the selections." DAX makes you say which columns.

## Where does it change meaning?

Three places, none of them exotic.

**`{1}` under an axis.** Qlik drops the selections and keeps the axis. `ALL` on a table drops every filter on that table's columns, axis included, if the axis column is one of them. If Region sits in a separate dimension table that is related to Sales, `ALL(Sales)` leaves the axis filter alone and the result looks right. Rearrange the model, move the column, or put a different field on the axis, and it silently changes. The safe version names what to clear: `REMOVEFILTERS` on the columns the slicers use, or `ALLEXCEPT` with the columns the visual groups by. Both need someone to decide which columns those are.

**A plain modifier under an axis.** `{$<Year={2021}>}` replaces the Year selection. The direct DAX translation, `CALCULATE(SUM(Sales[Amount]), 'Date'[Year] = 2021)`, replaces the Year filter too, and Microsoft's documentation says that when the column is already in the filter context, the existing filters "are overwritten by the new filters." Put Year on the axis and every row shows 2021. If the Qlik chart behaves the other way for your measure, the one that respects the axis, the DAX that matches it is `KEEPFILTERS('Date'[Year] = 2021)`. I have only Qlik's sentence about `{1}` to go on, so run this case against your own app and compare before you pick.

**`ALLSELECTED` as a stand-in.** It is the function people reach for, because the name sounds like selections. Microsoft's definition is close to the reverse of `{1}`: it ignores filters applied inside the query (the rows and columns of the visual) and keeps filters that come from outside it, such as slicers. Qlik's `{1}` drops the selections and keeps the axis. `ALLSELECTED` drops the axis and keeps the slicers. It has a proper use, visual totals and percent of visible total. It is not the translation of `{1}`.

One more category has no clean target. Set operators can build sets like `{1-$}`, everything except the current selection. Qlik's own documentation says a set like that cannot always be defined by a selection, and that a measure built on it cannot always be attributed to the right dimension value when the data model has many tables. If the source behavior is that loosely defined, a literal port will not be exact either. Rewrite those from the business question, not the expression.

## How do you test it?

Not on a clean app. This is the part I would underline. With nothing selected, `{1}` and `{$}` return the same records, so an unfiltered comparison between the Qlik chart and the Power BI visual passes even when the translation is wrong. The difference only exists once someone picks a value.

Build the test around that:

1. List every measure with a set expression. Record the identifier, the fields it modifies, and every chart where it is used with its dimensions.
2. For each, pick a selection that should matter (a region, a year, a product line) and one that should not.
3. Export the Qlik chart grouped by its real dimensions, with the selection on. Do the same from Power BI with the equivalent slicer on.
4. Compare cell by cell, not by grand total. A total can match while every row is off, because rows that are wrong in opposite directions cancel.

That is the argument in [proving parity after a BI migration](/insights/proving-parity/), applied to one construct. The same habit catches the calculation differences in [Tableau table calculations](/insights/tableau-table-calculations-live-in-the-view/), where the problem is also that the meaning lived in the view, not the formula.

Our [Qlik to Power BI guide](/migration-guides/qlik-to-power-bi/) says simple set expressions translate directly to `CALCULATE`, and for the modifier that is true. The identifier and the axis are the part that is not direct, and they are the part to put in the plan. The [Qlik platform page](/platforms/qlik/) lists what else needs care.

Qlik's model lets a user say "ignore my selections." Power BI makes you name the columns. The names are the work.
