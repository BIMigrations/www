---
title: "About us (variant 1: with history)"
heading: "Built so nobody has to <em>migrate twice.</em>"
description: We started BI Migrations because migrations keep being run the same expensive way: analysts rebuilding dashboards by eye, one screen at a time.
permalink: /about-v1/
noindex: true
sitemap: false
beliefs:
  - title: Open, not opaque
    text: Your estate should end up as plain SQL, Python, JSON and YAML that you own, not locked inside our tool or the next vendor's.
  - title: Retire before you move
    text: The cheapest dashboard to migrate is the one nobody opens. Usage data decides what makes the trip.
  - title: Prove, don't promise
    text: Every metric is parity-tested against the source before cutover. If the numbers don't match, it doesn't ship.
  - title: Read-only by default
    text: We start from a metadata export. Any access to your platforms is scoped, minimal and agreed up front.
---

## Why we *exist*

BI estates usually outlive the platform they were built on. Prices change, strategies change, companies merge, and the analysis inside the old platform is stuck in a proprietary format.

The usual answer is a hand rebuild. Analysts open the old dashboard, work out what each number is meant to mean, and build it again somewhere else. It's slow and expensive. Worse, it produces a new estate that's locked into the new platform just as tightly as the old one was locked into the last.

We think the analysis should be separated from the platform once, and then kept that way. That's what BI Migrations does.

## Our *story*

<p class="placeholder-note"><strong>Placeholder history.</strong> Everything in this section is invented to show the layout and length. Dates, places, events and people are stand-ins. Replace every line with the real history before this page goes anywhere near production.</p>

<ol class="timeline">
  <li>
    <span class="timeline-when">[Year] · Placeholder</span>
    <strong>The migration that went the long way</strong>
    <p>[Placeholder] Two of us were on a BI migration that took far longer than planned. Most of the time went on working out what old calculations were meant to mean, then rebuilding them by hand.</p>
  </li>
  <li>
    <span class="timeline-when">[Year] · Placeholder</span>
    <strong>The first translator</strong>
    <p>[Placeholder] We wrote a small tool that read one platform's metadata and wrote out plain SQL and JSON. It handled a fraction of an estate. It also showed the analysis could be separated from the platform.</p>
  </li>
  <li>
    <span class="timeline-when">[Year] · Placeholder</span>
    <strong>Parity before promises</strong>
    <p>[Placeholder] After a cutover where the numbers did not match, we made parity testing a gate rather than a courtesy. A metric that has not passed does not go live.</p>
  </li>
  <li>
    <span class="timeline-when">[Year] · Placeholder</span>
    <strong>BI Migrations LLC</strong>
    <p>[Placeholder] We formed the company to do migrations this way full time, starting with Domo to Power BI.</p>
  </li>
  <li>
    <span class="timeline-when">[Year] · Placeholder</span>
    <strong>More routes, more targets</strong>
    <p>[Placeholder] Tableau, Qlik and Looker joined as sources. Power BI, Tableau, Looker, Sigma and Superset became targets.</p>
  </li>
</ol>

## What we *believe*

{% include cards.html items=page.beliefs %}

## How we *work*

Automation does the heavy lifting. Our automated migration tool reads an estate, translates it into open specifications and regenerates it natively on the target BI platform. Experienced BI and data engineers handle the rest: edge cases, business logic nobody wrote down, and the conversations about what "revenue" should really mean.

We work directly with data and analytics teams, and alongside the consultancies and systems integrators they already trust.

## Get in *touch*

- Planning a migration? [Start with a free estate scan](/#scan).
- Want to work with us? See [careers](/careers/).
- A consultancy or platform team? See [partners](/partners/).
- Anything else? [Contact us](/contact/).
