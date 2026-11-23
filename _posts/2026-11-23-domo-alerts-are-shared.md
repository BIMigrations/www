---
title: "Domo alerts are shared. Power BI dashboard alerts are private."
heading: "A Domo alert can notify a team. A Power BI dashboard alert only <em>notifies you</em>."
description: "Domo alerts go to groups and can trigger a webhook or task. Power BI dashboard alerts are private to their creator. Inventory alerts before you migrate."
author: amy-loomis
image: /assets/img/og/domo-alerts-are-shared.png
---

Open any Domo to Power BI mapping table and you will find a row that reads "Alerts: data alerts and subscriptions". [Ours has one](/domo-to-power-bi/). It is a fair summary and a dangerous one, because it makes two different things sound like the same thing.

The difference is who owns the alert and who hears it.

## A Domo alert is a shared object

When someone sets an alert on a Domo card, they pick a metric, a condition and a value. The condition can be a threshold, or a change: "changes by", "increases by", "decreases by". They pick how often Domo checks: every time the data updates, hourly, daily, weekly or monthly. Then comes the part that matters for a migration. They share it.

Domo's documentation says an alert can be shared with users, with groups and with Buzz conversations, and that those people get a notification every time it triggers. Sharing also gives them access to the card the alert hangs on. The alert can carry an action too: a webhook to a third-party system, a task in Projects & Tasks, a workflow, or a scheduled report.

So one alert can mean "the whole collections team gets an email when overdue balance passes a number, and a task lands in the finance project". Nobody calls that an integration. It is just something a person set up one afternoon.

## A Power BI dashboard alert is private

Microsoft's documentation for dashboard alerts is equally plain: "Only you can see the alerts you set, even if you share your dashboard." The dashboard owner cannot see the alerts you set on your view of their dashboard.

The list of other limits is short and specific. You can only set alerts on tiles pinned from report visuals, and only on gauges, KPIs and cards. They work on numeric data, not on card tiles with date or time measures, and only on refreshed data. Notifications go to your Notification center and, optionally, email. You can create up to 250 alerts across all your models. They are not available in Power BI Desktop. And they do not support co-ownership: to hand one to someone else, you create a new alert, and if it feeds a Power Automate flow, you recreate the flow.

Microsoft does document an integration between data alerts and Power Automate, so the action half is not missing. But the notification half is personal by design.

## The shared version lives somewhere else

Power BI's answer for alerts that more than one person should hear is a different feature. Alerts on **reports** (not dashboards) are created with the Set alert button and stored as rules in Fabric Activator. They can send to Teams or email, to the users you name. The prerequisites are real: a workspace with Fabric capacity enabled, edit access to the report, and a tenant setting your admin has to allow. Two more details to know before you promise a replacement. The alert uses the filters in place when you created it, and changing the visual's filters later has no effect on the alert logic. And once you edit a rule in Activator, you can no longer edit it in the report.

That is a fine feature. It is also a different object, with a different owner, a different place to find it and a different bill of prerequisites from the thing it replaces. "Alerts map to data alerts" is not wrong. It is just the first sentence of the plan.

## What to write down for each alert

Before anything moves, list every Domo alert and record seven things:

1. **The metric and condition.** Threshold, or change? Is it on the card's Summary Number? Some chart types only allow alerts on a Summary Number, which tells you what the alert was really watching.
2. **The owner.** Whoever created it. They may have left.
3. **Who is notified.** Users, groups, Buzz conversations. To share an alert with a group on a PDP-protected DataSet, Domo requires a PDP policy set for that group, so [the security setup](/insights/who-skips-pdp/) is part of the alert.
4. **The attached action.** Webhook, task, workflow, scheduled report, or none.
5. **The frequency**, and whether "keep sending notifications while in a triggered state" is ticked. Power BI's dashboard alerts check at a one hour or 24-hour threshold and do not repeat for an unchanged value, so a Domo alert that kept repeating may behave differently after the move. Alerts also only fire on refreshed data, and [what triggers a refresh changes](/insights/domo-triggers-vs-power-bi-clock/) when you leave Domo.
6. **Filtered or unfiltered.** Domo lets the author choose whether the alert honors the card's filters. Write down which they chose.
7. **Whether anyone would notice if it stopped.** Ask the people on the recipient list. This is the one question nobody can answer from an export.

Then decide, alert by alert, where it lands: a private dashboard alert, an Activator rule on a report, a Power Automate flow, or nowhere because nobody wants it any more. Some will land on "nobody wants it". That is a result, not a failure.

Buzz is the one you will have to decide on by hand. Power BI's documented notification channels for report alerts are Teams and email. Whether a Buzz conversation becomes a Teams channel is a choice about how a team talks, and no mapping table can make it.

## Why this belongs in the estate review

A broken dashboard gets reported. A missing alert does not, because the whole point of an alert is that nobody is looking. The first sign that one was lost is the thing it would have warned about.

I would not count a migration as finished until someone has read the list of alerts aloud to the people on it.
