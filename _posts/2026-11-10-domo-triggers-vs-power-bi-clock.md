---
title: "Domo runs when the data arrives. Power BI runs on a clock."
heading: "Domo runs when the data <em>arrives</em>. Power BI runs on a clock."
description: "A Domo DataFlow can start when its input data lands. A scheduled Power BI refresh starts at a slot, capped per day. Decide each dashboard's freshness first."
author: amy-loomis
image: /assets/img/og/domo-triggers-vs-power-bi-clock.png
---

A Domo DataFlow does not have to run at 6 a.m. It can run when the data it needs shows up. Nobody mentions this in a migration plan, because nobody thinks of it as a feature. It is just how the dashboard has always been fresh.

Power BI does not work that way by default. A scheduled refresh on an Import model fires at a time slot. Move a dashboard across and the question "when does this update?" changes from "when the upstream load finishes" to "at the next slot on the clock". If no one asks it out loud, no one answers it.

## What Domo lets you say

Domo's page on advanced DataFlow triggering defines the idea plainly: triggering is "the process of initiating ETL operations to refresh or update data within a DataFlow." The options live in the DataFlow's settings tab. A trigger can fire on a schedule, or when selected DataSets update. Conditions sit on top: that DataSets have updated since the last successful run, or within a set interval of each other, or that the current time or day falls in a window you choose. Domo's help article says a DataFlow can carry up to three triggers, each independent of the others.

Think about what that does to a flow with three inputs. A CRM extract lands at 2:10, a billing extract at 2:40, a finance file at some point after the controller wakes up. A clock-based flow has to guess a time late enough for all three. A trigger-based flow, with the "updated since the last successful run" condition set on all three, waits for the last one and goes. Nobody had to choose a time. The dashboard was as fresh as the slowest input allowed.

I haven't run these triggers myself, since I have no Domo instance to test on, so I'm describing what the page says, not how it behaves under load.

## What Power BI lets you say

Microsoft's documentation on scheduled refresh sets the shape of the clock:

- A Pro semantic model can refresh up to 8 times a day. Premium Per User and capacity-backed models can go up to 48.
- A refresh starts within 15 minutes of its slot, and a delay of up to an hour is possible.
- After four consecutive failures, the schedule is deactivated. After two months with no one viewing a report on the model, it is paused.

There is a second path. You can trigger a refresh through the REST API, from your pipeline, the moment the last load finishes. That gets you close to Domo's behavior. The catch is in the data refresh article: on shared capacity, the limit of eight a day covers scheduled and API refreshes together. On Premium, PPU and Fabric capacity there is no fixed API limit, but refreshes are throttled by what the capacity can handle. The same article notes that failure emails are not sent for refreshes started through the API or Power Automate, so the pipeline has to do its own alerting.

## So what changes on the dashboard

Three things, none of which show up in a row-count comparison.

**The freshness promise.** A Domo card that updated minutes after the billing load now updates at 3:00, or 3:15, or an hour later. For a finance report nobody reads before 9, fine. For an operations board someone watches at 2:45, it is a regression, and no parity test will flag it because the numbers match when they finally arrive.

**The ceiling.** An estate with many DataFlows on event triggers has no daily count in its head. In Power BI, every Import model competes for a limited number of slots per day or for capacity. Whether that is a problem depends on the plan, and it is much cheaper to find out in week one than in week twelve.

**Who gets told.** Whatever alerting the team relies on in Domo does not travel. A schedule that deactivates after four failures, or an API refresh that fails without an email, is silent in a new way.

## Decide it per dashboard

Before cutover, put one line next to each dashboard:

1. **How fresh must it be?** In minutes, hours, or "by the time the owner opens it". Ask the owner, not the builder.
2. **What starts the refresh today?** A schedule, or an upstream update. List the inputs that gate it.
3. **What will start it after?** A slot on the clock, an API call from the pipeline, or a storage mode that reads the source at query time instead of holding a copy. (I wrote about the [trade-offs in storage mode](/insights/power-bi-storage-mode-before-migrating/) separately.)
4. **Which capacity runs it?** Shared capacity with a cap of eight, or something with room.
5. **Who is told when it fails?**

The dashboards where the answer to 1 is "hours" can sit on the clock and never think about it again. The few where it is "minutes" are the ones that need an API trigger, a bigger capacity, or a different storage mode, and they should be named in the plan, with an owner.

This is the same discipline as [testing an automated migration](/insights/test-an-automated-domo-migration/), where one item on the checklist is a dataset with a scheduled refresh. And it belongs next to [parity](/insights/proving-parity/): a dashboard can match to the cent and still be wrong, because it was right three hours ago.

If your estate is Domo, our [Domo to Power BI migration](/domo-to-power-bi/) page describes how DataFlows are handled. Whoever rebuilds yours, tool or person, should be able to tell you what became of each trigger condition. "We put it on a schedule" is an acceptable answer for some flows. It should be an answer someone gave on purpose.
