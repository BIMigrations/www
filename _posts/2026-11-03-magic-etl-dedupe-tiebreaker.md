---
title: "Magic ETL never told you which duplicate it kept"
heading: "A Domo flow keeps one row. The <em>rule</em> was never written down."
description: "Magic ETL's Remove Duplicates, Rank & Window and Group By first/last all pick one row. Domo's docs don't say how ties resolve. A SQL rebuild has to, and a parity check can pass by luck."
author: amy-loomis
image: /assets/img/og/magic-etl-dedupe-tiebreaker.png
---

Most Domo estates of any age have a dataflow that says "keep the latest record per customer." The usual build is three tiles: rank by date, filter to rank 1, move on. It runs every night, and the numbers look right, so nobody opens it.

Here is the question to ask of it. If two rows for the same customer carry the same date, which one survives? Domo's documentation for these tiles does not say. In SQL, the answer has to be written down or the query will not run. That gap is where a clean migration quietly goes wrong.

## Three ways Magic ETL keeps one row

**Remove Duplicates.** You pick the columns that define a duplicate. Domo's article says a row is removed only if all the selected columns match, and that key columns are case-sensitive by default. It does not say which of the matching rows is kept. A community thread I read says you cannot control it, which fits the article's silence, but I haven't tested it and neither should you take my word for it.

**Rank & Window, then Filter.** The tile ranks by one column, with an optional partition. Row Number gives each row in the partition a number. If two rows tie on the ordering column, the documentation does not describe a tiebreaker. Rank gives both the same number, which means a filter on rank 1 keeps both. Row Number gives them different numbers, so the filter keeps one and drops the other, for reasons you cannot see.

**Group By with First value or Last value.** The aggregation list includes first value, last value, and first and last non-null values. First in what order? The article doesn't define one.

Each of these works because the flow's author never had to specify the rule. The tile picked one, consistently enough that nobody noticed.

## What SQL makes you say

Microsoft's `ROW_NUMBER` documentation is plain about it. The `ORDER BY` clause is required. Without unique values in the ordering columns, there is "no guarantee" the rows come back in the same order on each run, and the function is described as nondeterministic. A rebuilt flow that orders by `modified_date` alone has copied the ambiguity, not removed it. It just fails in a different place: Tuesday's load might keep one row and Wednesday's might keep the other.

So the rewrite has a decision in it. Add a second ordering column that is unique, such as a record ID or load timestamp. Decide what "latest" means when two rows tie, and write that choice where the next person can read it. That is a business rule that used to live in nobody's head.

## The case-sensitivity trap

The Remove Duplicates default is case-sensitive, so `Acme Corp` and `ACME CORP` are two customers in the flow. Whether they are two customers in the SQL depends on the collation of the column. Microsoft's documentation lists `SQL_Latin1_General_CP1_CI_AS` as the default collation for an English (United States) SQL Server setup, and `CI` means case-insensitive. A `GROUP BY` or `DISTINCT` on a column like that treats the two spellings as one.

Picture a customer table where the same account arrives in two spellings from two source systems. The old flow kept both. The new query keeps one, and every downstream count drops by a little. Nothing errors. Which behavior is right is a data question, and it is the owner's call, but the migration should make the change on purpose.

## How to find these before cutover

1. **Inventory every dedupe.** List each Remove Duplicates tile, each Rank & Window followed by a filter on 1, and each Group By using first or last. These are the tiles with hidden rules.
2. **Plant a tie.** Add two rows with the same key and the same ordering value but different payloads to a test input. See which one comes out of Domo. Then see which one comes out of the rebuilt SQL, on several runs.
3. **Plant a case difference.** Same key, different capitalization. Count the output rows on both sides.
4. **Compare on more than one day.** A single snapshot can match by luck. Run the comparison across several loads, or against a deliberately shuffled input.
5. **Write the rule down.** For each dedupe, one sentence: what makes rows duplicates, and which one wins. Put it in the model's documentation or next to the query.

This is the same point I made in the [checklist for testing an automated migration](/insights/test-an-automated-domo-migration/): ask what happens to Magic ETL, and ask for the reasoning, not only the output. And it is why [parity has to be proven on cases, not on totals](/insights/proving-parity/). A matching row count today says the tie did not happen today.

If your estate is Domo, our [Domo to Power BI migration](/domo-to-power-bi/) page describes how Magic ETL is handled. Whoever rebuilds your flows, tool or person, should be able to show you the list of rules they had to invent. If the list is empty, the rules were not found. They were guessed.
