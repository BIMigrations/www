---
title: "Your Domo renewal needs an exit price"
heading: "The exit has a <em>price.</em>"
description: "Progress has bought Domo and has not said what changes for customers. Before your renewal, find out what leaving would cost. Here is how to get that number."
author: amy-loomis
image: /assets/img/og/domo-renewal-exit-price.png
---

If your company runs on Domo, someone has probably asked you by now whether you should be worried about Progress. It is a fair question and the wrong first one.

Here is what is actually on the record. Progress's own announcement says it "has completed its acquisition of substantially all of the assets of Domo," with a note on the page saying it was updated on September 22, 2026 to reflect completion. That is all it says about the deal's status. It speaks of customers only in general terms. It says nothing about contracts, pricing, support or the product roadmap. Its search snippet still says Progress "announces its intent to acquire," and at least one vendor comparison article I found still describes the deal as pending, with a close expected by November 30. Check the date on anything you read.

So nobody outside Progress knows what changes for you. Anyone who tells you prices will jump or the product will be retired is guessing. I would be guessing too, so I won't.

## The better question

What would it cost to leave?

That is not the same as wanting to leave. A renewal is a negotiation with two possible endings, sign or walk, and the second one only exists if you can say what it costs. If you can't, you have one option and the other side knows it. Most teams find out their exit cost on the worst possible day: a few weeks before the renewal date, with a quote on the table and no inventory.

The number is useful even if the answer is that you stay. If leaving is cheap, you negotiate from a real position. If it is expensive, you know to renew carefully and to start reducing that cost now, because the same work that shrinks an exit bill also shrinks the Domo bill.

## How to get the number

Not by counting dashboards. I made the case [last week](/insights/dashboard-count-is-the-wrong-estimate/) that the dashboard count mostly measures how many times the same logic was copied. The cost sits underneath:

- **Calculations.** Every Beast Mode is a formula that has to be understood and rebuilt, and [Beast Modes do not translate to DAX one for one](/insights/beast-mode-fixed-to-dax/). Duplicates that drifted apart count several times.
- **Pipelines.** Domo is also where data gets shaped. Magic ETL flows and SQL DataFlows need a new home, usually in a warehouse. A BI tool alone does not replace them.
- **Security.** Personalized Data Permissions have to become row-level security that someone tests, role by role.
- **Usage.** For every object above: does anyone open it? Anything dormant is cost you can delete before it ever becomes migration cost. That is the argument in [retire before you migrate](/insights/retire-before-you-migrate/).

Put a row against each object type: how many, how many are used, who owns them. That table is the exit price, roughly. It will be wrong at the edges, but it will be wrong by a margin you can reason about, which a dashboard count never is.

## And read the contract

Find the renewal date, and find how much notice non-renewal requires. Ask whoever handles your contracts what the agreement says about the vendor transferring it to another owner, and about price changes at renewal. I am not a lawyer and this is not legal advice; the point is only that those two answers are in a document you already have, and they decide how much time the inventory has to be done in.

## The date that matters

It is not July 23, when Progress posted its announcement, or September 22, when Progress said it completed, or any closing date in an article. It is your renewal date. Work backwards from it, leave time to measure, and the headline stops being something that happens to you.

If you want the inventory without building it yourself, the [estate assessment](/services/estate-assessment/) starts with a free scan that works from a read-only metadata export: what you have, and how much of it anyone still opens. The [Domo to Power BI page](/domo-to-power-bi/) shows what the move involves if the number comes back low enough to be an option.
