---
title: "Beast Mode FIXED to DAX: where it bites"
heading: "Beast Mode FIXED to DAX, <em>honestly.</em>"
description: "Domo FIXED functions look like they map straight onto DAX CALCULATE. Here is where the translation changes the number, and how to catch it before cutover."
author: amy-loomis
image: /assets/img/og/beast-mode-fixed-to-dax.png
---

A Domo Beast Mode that uses FIXED is the one most likely to look right after migration and be wrong. It returns a number. The number is plausible. It just answers a slightly different question than the old card did.

The reason is that FIXED and DAX describe the same idea from opposite ends. FIXED says "compute this at a grain I name, whatever the card is grouped by." DAX says "start from whatever filters are in play, then tell me which ones to drop." Translate one into the other mechanically and you get the same formula shape with a different meaning.

## What FIXED actually *says*

Domo's documentation describes FIXED functions as level of detail expressions: they calculate against the DataSet rather than row by row, and they need two aggregations, because you are aggregating over an aggregated expression. The documented forms are:

```
SUM(SUM(`Total Sales`) FIXED ())                 total for the whole DataSet
SUM(SUM(`Total Sales`) FIXED (BY `Region`))      total per region
MAX(SUM(`Total Sales`) FIXED (ADD `City`))       card grain plus city
... FIXED (REMOVE `City`)                        card grain minus city
```

The first two are the ones people reach for, usually to build a share of total: this region's sales divided by all sales.

## The DAX version, and the part that *changes*

The tidy translation of a share of total looks like this:

```dax
Region share =
DIVIDE(
    SUM(Sales[Total Sales]),
    CALCULATE(SUM(Sales[Total Sales]), ALL(Sales))
)
```

`ALL(Sales)` removes every filter on the Sales table, including the ones a report reader sets in a slicer. Whether the Domo card did the same depends on where its filters were applied, and that is the question to answer per card, not per formula. If the old card's page filters narrowed the DataSet before FIXED ran, the denominator was the filtered total. With `ALL`, the denominator is the unfiltered total, and every share in the report is now too small. Nothing errors. The percentages simply stop adding up to 100.

The fix is usually `ALLSELECTED` or `ALLEXCEPT`, and the choice is a decision about intent, not syntax. That is why I'd argue this pattern should never be converted without a person looking at the card's filters first.

## Two smaller ways it goes *wrong*

**Division by zero.** `DIVIDE(numerator, denominator)` returns BLANK when the denominator is zero, and you can pass an alternate result as a third argument, though it has to be a constant. If the old Beast Mode produced a zero or an error in that case, the card now shows an empty cell instead. Check what the source returns for empty groups, then choose the alternate result on purpose.

**ADD and REMOVE.** These are relative to the card's own grain, so the same Beast Mode means different things on different cards. DAX measures have no card grain to be relative to. The honest translation is one measure per distinct grain, which is why a Domo estate with one shared Beast Mode can become several measures.

## How to *catch* it

Don't review these by eye. Pick the slices the card is actually used with: the default view, each page filter combination, and one slice that returns almost nothing. Run the old card and the new measure against each and compare. For a share of total, include a check that the shares sum to 1 at every slice. That single assertion catches the `ALL` problem on the first run.

This is the same approach behind [proving parity](/insights/proving-parity/) after any migration, and it is where a [Domo to Power BI migration](/domo-to-power-bi/) spends more of its time than the formula count suggests. Our automated migration tool converts the bulk of an estate. The cards that need a human decision, like these, are worth writing down in [open specifications](/open-specifications/) so the intent survives the next platform change.
