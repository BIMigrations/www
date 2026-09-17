---
title: Risk & governance
heading: "Move fast. <em>Prove</em> everything."
description: A migration is only finished when the numbers match and the right people see the right rows. Governance is built into every step, not bolted on at cutover.
permalink: /risk-governance/
parent_title: Platform
controls:
  - title: Parity testing
    text: Every migrated metric is compared with the source before cutover.
  - title: Access mapping
    text: Row-level permissions are carried across and tested role by role.
  - title: Lineage
    text: Every field is traceable from dashboard to source column.
  - title: Controlled cutover
    text: Waves, sign-off, and the source kept live until sign-off.
---

{% include cards.html items=page.controls %}

## Parity *testing*

For every migrated metric, the same question is asked of the source and the target, across the same slices: by period, by region, by whatever dimensions the dashboards use. The results are compared automatically.

- Tolerances are agreed up front — exact for counts and currency, and explicit for anything else.
- Anything outside tolerance is investigated, fixed and re-tested.
- A metric that hasn't passed doesn't go live.
- You receive the full parity report for every wave.

## Access and *row-level security*

Permissions are part of the estate, so they're migrated the same way as everything else. We read the source platform's controls — Domo PDP policies, Qlik Section Access, Looker access filters, Power BI row-level security — into platform-neutral **access policies**, then create the equivalent on the target.

Each role is tested by checking what a user in that role can see on the source and on the target.

## Lineage you can *audit*

The field-level lineage graph connects every dashboard field, through every transformation, to the source columns it depends on. It answers the questions auditors and data owners ask — *where does this number come from?* and *what breaks if this column changes?* — without anyone having to read old code.

## Controlled *cutover*

- **Waves.** The estate moves in groups, so any problem stays small.
- **Parallel running.** The source stays available until each wave is signed off.
- **Sign-off.** Business owners approve each wave against its parity report.
- **A way back.** Until sign-off, users can keep working on the source.

## Change *control*

The open specifications live in your repository, so every change is visible and reviewable. Changes made on the source during the migration are picked up by a re-scan, so nothing drifts silently.

For how we handle access and data during an engagement, see [security](/security/).
