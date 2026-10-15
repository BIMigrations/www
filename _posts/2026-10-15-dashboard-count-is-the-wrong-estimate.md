---
title: "Why counting dashboards gives you the wrong migration estimate"
heading: "Dashboards are the <em>cheap</em> part of a migration."
description: "A dashboard count looks like a measure of migration effort. It is mostly a measure of how many times the same logic was copied. Estimate from calculations, security and sources instead."
author: amy-loomis
image: /assets/img/og/dashboard-count-is-the-wrong-estimate.png
---

The usual first question in a BI migration is "how many dashboards do we have?" It is a reasonable thing to ask, because it is the number someone can get in a minute. The answer then gets multiplied by a number of days, and the result goes into a budget.

I think that number tells you almost nothing about the work. It tells you how big the estate looks from the outside, and the outside is the cheap part.

## What a dashboard count actually measures

A dashboard is a surface. Underneath it sit the things that took someone months to get right: the calculated fields, the joins, the row-level rules about who may see which rows, the refresh schedules, the odd filter that exists because of one executive's request years ago.

Two estates with 400 dashboards each can be wildly different. In one, 400 dashboards read from thirty well-built datasets and share a handful of definitions. In the other, each dashboard carries its own copy of the logic, slightly different every time. The first is a modest project. The second is an archaeology project with a dashboard count that happens to match.

The count also rewards the wrong behavior. If effort is priced per dashboard, retiring a dead dashboard looks like lost revenue for the vendor and a lost line item for the project manager, when it is the cheapest saving on the table. The case for doing it first is in [Retire before you migrate](/insights/retire-before-you-migrate/).

## What to count instead

Dashboards are an output. Count the inputs that drive effort:

- **Distinct calculations.** Not calculated fields in total, but distinct ones after you collapse the copies. A hundred copies of one margin formula is one problem. Ten different "margin" formulas is ten, and a [definitions question](/insights/metric-definitions-live-in-the-model/) before it is a translation question.
- **Hard-to-translate constructs.** Every platform has a few expressions with no neat equivalent in the target. [Domo Beast Modes that use FIXED](/insights/beast-mode-fixed-to-dax/) and [Tableau table calculations](/insights/tableau-table-calculations-live-in-the-view/) are two examples. A short list of these decides more of the schedule than the other thousand simple ones.
- **Security rules.** Row-level and column-level access is where a migration can quietly go wrong, because a mistake produces no error. It produces a correct-looking report that shows someone the wrong rows. Count the rules, and count the people whose access depends on each one.
- **Data sources and their owners.** A source nobody owns cannot be signed off. Each one needs a person to say the migrated numbers are right.
- **Usage.** How many of these objects did anyone open last quarter? The honest estate is often smaller than the listed one.

None of these is hard to collect. Most platforms expose metadata for all of them. They just take longer than counting rows in the dashboard list, which is probably why the shortcut survives.

## Why this matters before the contract, not after

An estimate built from a dashboard count fails in a predictable way. The simple 80 percent goes quickly, the schedule looks ahead of plan, and then the remaining objects turn out to be the ones nobody scoped. The project doesn't slip evenly. It stalls on a few objects that were always going to be slow.

If you can see those objects in advance, you can plan for them, split them into their own wave, or decide they are not worth moving. If you can't, you learn about them in week nine.

## What I'd ask a vendor

Whoever quotes your migration, ask what the number is based on. If the answer is a dashboard count, ask what happens to the price when it turns out half of them are copies, and what happens when the security rules turn out to be more complicated than the layouts. A good answer names the inputs above and says which ones were measured and which were assumed.

That is how we approach it at BI Migrations: the [estate assessment](/services/estate-assessment/) measures the inventory, the usage, and the complexity of each object before anyone writes a plan, and the free scan gives you the headline numbers from a read-only metadata export. You can use the method with or without us. The point is to put a budget against something measured.
