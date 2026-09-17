---
title: "Proving parity: how to know the numbers still match"
heading: "Proving <em>parity.</em>"
description: A migrated dashboard that looks right isn't finished. Here's how automated parity tests show the numbers really match before anyone cuts over.
---

The fastest way to lose trust in a new BI platform is for someone to spot a number that doesn't match the old one. After that, every figure is doubted, and people keep the old dashboards open "just to check". Parity testing exists to make sure that moment never happens.

## Looking right isn't *enough*

A rebuilt dashboard can look identical and still be wrong. Common causes:

- A calculation evaluated in a different context — per row instead of per group, or across a join that fans out.
- A filter applied at a different stage.
- Nulls, rounding or time zones handled differently.
- Row-level security that's slightly more or less permissive than before.

None of these show up in a visual check of one screen with one set of filters.

## What a parity test *does*

For each migrated metric, a parity test asks the source and the target the same question, across the same slices, and compares the answers:

1. **Choose the slices** the dashboards actually use — by period, region, product and so on.
2. **Query both platforms** for the metric at each slice.
3. **Compare** the results within an agreed tolerance: exact for counts and currency, explicit for anything else.
4. **Report** every result, and block cutover for anything that fails.

Because the tests are automated, they can be run after every change, not just once before go-live.

## Test the *permissions* too

Parity isn't only about values. For each security role, check that a user in that role sees the same rows on both platforms. A migration that shows the right numbers to the wrong people isn't a success.

## Make it part of *sign-off*

Parity reports work best as the basis for business sign-off. Instead of "does this look right to you?", owners are asked to approve a report showing every metric that was tested, at which slices, and with what result. That's a much easier conversation — and a much more defensible one.

Parity testing is built into every [full migration](/services/full-migration/). Read more about [risk and governance](/risk-governance/).
