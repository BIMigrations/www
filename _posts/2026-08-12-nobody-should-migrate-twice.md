---
title: Nobody should migrate twice
heading: "Nobody should <em>migrate</em> twice."
description: Hand-rebuilt migrations lock your analysis into the next platform just as tightly as the last. Open specifications break that cycle.
---

Most BI migrations follow the same pattern. A team picks a new platform. Analysts open each old dashboard, work out what every number means, and build it again. Months later, the new estate is live and the old contract ends.

It feels like progress. But look at what the organisation actually has at the end: the same analysis, now bound to a different vendor's file format. The knowledge gained — what each calculation means, which dashboards matter, where every number comes from — lives in people's heads and in the new platform's proprietary objects.

## The cost comes *back*

Platforms don't last forever. Pricing changes, strategies shift, companies are acquired. When the next move comes, the estate has to be interpreted again from scratch — often by different people, with no guarantee they'll reach the same answers.

That's the real cost of a hand rebuild. It isn't just the first migration. It's that the expensive part — understanding the estate — has to be paid for again every time.

## Split the migration in *two*

There's a better way to structure the work. Split it into two halves:

1. **Translate the estate into open specifications.** Models become SQL, transformations become Airflow and Python, and dashboards become JSON and YAML definitions, with a field-level lineage graph behind them. This half is platform-neutral, and it's where the understanding is captured.
2. **Regenerate natively on the target BI platform.** Our automated migration tool turns the specifications into native artifacts, with calculations rewritten in the target's own language.

Only the second half is specific to a platform. The first is done once, and it doesn't expire.

## What changes

When the estate lives in open specifications in your own repository:

- **Changing platform again** means re-running our automated migration tool, not starting a complete migration project.
- **Reviewing a change** means reading a plain-text diff.
- **Answering "where does this number come from?"** means following the lineage graph, not reading old code.

> The expensive half is done once, and it never expires.

If a migration is on your roadmap, [start with a free estate scan](/#scan) and find out what's actually in your estate.
