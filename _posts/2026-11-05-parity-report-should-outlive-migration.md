---
title: "The parity report should outlive the migration"
heading: "Parity is not a gate. It is a <em>contract.</em>"
description: "A parity test compares the new BI platform to the old one, then the old one is switched off. Freeze the signed-off numbers and keep testing them."
author: amy-loomis
image: /assets/img/og/parity-report-should-outlive-migration.png
---

A parity test has a strange property. It works by comparing the new platform to the old one, and then the old one is switched off.

Think about the month after cutover. The report said the numbers matched. Everyone signed. Then the source tool is retired, someone changes a join in the model, and the revenue figure quietly moves. There is nothing left to compare it to. The sign-off still exists, but nothing enforces it.

I think of parity as a gate, and that is the mistake. A gate is something you walk through once. What the business actually signed was a set of numbers, and a set of numbers is a contract.

## What the sign-off really *says*

[Proving parity](/insights/proving-parity/) argues that owners should approve a report showing every metric tested, at which slices, with what result. We do that for every wave of a migration, and the [risk and governance](/risk-governance/) page says business owners approve each wave against its parity report.

Read that sentence again as a promise. The finance lead did not approve "the revenue measure." They approved revenue for March, by region, equal to a specific figure. Those figures are the most carefully checked numbers in the whole estate, and most teams file them in a PDF and never look at them again.

## Keep the numbers, *test* them

The cheap move is to freeze the agreed values for closed periods and run them as tests every time the model changes.

If your warehouse work lives in dbt, the machinery already exists. dbt's documentation describes a data test as an assertion about your models: a query that looks for failing rows, and if it "returns zero failing rows, it passes." Seeds are CSV files in the project that dbt loads into the warehouse, which makes a small table of signed-off values version controlled and reviewable. The seeds page is explicit that they suit static data that changes infrequently, which is exactly what a closed month is.

A singular test over that table is a few lines:

```sql
-- tests/assert_signed_off_revenue_still_matches.sql
select e.period, e.region, e.expected_revenue, a.revenue
from {% raw %}{{ ref('signed_off_revenue') }}{% endraw %} as e
left join {% raw %}{{ ref('fct_revenue_by_period_region') }}{% endraw %} as a
  on a.period = e.period and a.region = e.region
where a.revenue is null
   or abs(a.revenue - e.expected_revenue) > 0.005
```

It returns a row for every signed-off figure that has moved or vanished. A half-cent tolerance means currency is compared to the cent, which is the rule parity tests should follow anyway: exact for counts and money, explicit for anything else.

If you are not on dbt, the idea survives without it. Keep the agreed values in a table or a file under version control, and run a query against the model on a schedule. The tool is not the point. Having something that can say no is.

## The failure is the *feature*

There is an objection, and it is a fair one. Numbers change for good reasons. A late invoice lands in a closed month. Finance restates a quarter. A definition is corrected because the old one was wrong.

Good. Each of those should fail the test, and the fix should be a visible edit to the expected value, with a name on the commit and a sentence about why. That is the whole benefit. Without the frozen table, the same change arrives as a silent drift that someone notices in a board meeting. With it, a changed number becomes a decision somebody made, not an accident somebody discovers.

Two rules keep it honest. Freeze closed periods only, because open ones are supposed to move. And keep the set small: the metrics and slices the owners actually signed, not every cell the tool could produce. A thousand-row contract that nobody reads is another PDF.

## While both platforms are still *alive*

One more place the warehouse helps, and it is before cutover. The dbt-audit-helper package exists for exactly this comparison: its documentation frames it for checking that a refactored model matches the original, including when moving off a legacy system, and its classify macros report added, removed, identical and modified rows rather than a bare pass or fail. Use it while the old tool is still running to find the rows that differ. Then freeze the result you agreed on.

## Where this sits in a *migration*

The parity report is the one artifact of a migration that is about the business's numbers rather than the tool's mechanics, so it is a shame to throw it away. In our [full migrations](/services/full-migration/) it is delivered per wave and signed by the owners. What happens to it afterward is a choice, and my advice is to put it in version control next to the model it protects, and to name the person who will read it when a number moves. [Who inherits your BI migration](/insights/who-inherits-the-migration/) is about choosing that person before the project closes.

The same instinct sits behind our [open specifications](/open-specifications/): write down what each number means while someone still remembers, so the next change, or the next platform, starts from a record and not a guess.
