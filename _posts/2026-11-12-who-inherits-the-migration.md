---
title: "Who inherits your BI migration?"
heading: "Pick who runs the migration by who <em>keeps</em> it."
description: "Cost and speed decide most BI migration vendor choices. The better question is who will understand the result in six months, and where that is written down."
author: amy-loomis
image: /assets/img/og/who-inherits-the-migration.png
---

Most people choose who will run their BI migration the way they choose a contractor for a kitchen. Price, speed, references. Those matter. But a migration is not a kitchen. When the kitchen is finished, it works whether or not you ever meet the builder again.

A migrated BI estate does not work that way. In month six somebody will ask why the margin figure on the regional dashboard is lower than last quarter's deck. Someone has to open the model and answer. So here is my position: choose who runs the migration by who will own the result, and pay attention to where the understanding goes when the project closes.

## Understanding is made *during* the work

A migration is the one time a team reads every calculation in the estate. Someone opens each measure and asks what it was meant to do, why it filters on that field, and who still looks at it. The answers are the real product. The rebuilt dashboards are the part you can see.

Those answers get created in a few people's heads, in the middle of the work, usually in a chat thread. If the people doing the work leave at cutover, the answers leave with them. You keep the dashboards and lose the reasons.

Picture a mid-sized company that hires a team to deliver everything end to end. Cutover goes smoothly. Eight months later an analyst finds that one measure ignores returns and asks the obvious question: was that deliberate? Nobody on the client side knows. The people who knew have moved on to the next project. The analyst now has to reverse-engineer a decision from a formula.

That is not a failure of the vendor. It is what happens when the knowledge has nowhere to live.

## Four ways to run it, four places the knowledge goes

Our [engagement models](/services/engagement-models/) describe four arrangements: an assessment only, a delivered migration, co-delivery with your team or a consultancy, and a tool-assisted model where your team runs our migration tool with our engineers on hand. They differ in who does the work. For this question they differ in a more important way: where the understanding accumulates.

- **Delivered.** The doers understand it best, and they are not you. That is fine if the handover is a real artifact and not a meeting.
- **Co-delivery.** Your people sit next to the work. Understanding spreads while it is made. It is slower to start and cheaper to own.
- **Tool-assisted.** Your team or partner runs the tool, so your people are the ones at the keyboard. Ours are on hand for the hard cases and parity review. Ask which of those conversations end up written down.
- **Assessment only.** You get a plan and a number, and the learning starts when you start.

None of these is the right answer in general. A small team with no appetite to run a project should buy the delivered model and insist on a handover that works. A team with a strong analyst bench and a year of runway might prefer co-delivery, because it turns the migration into training. The wrong move is to choose by price alone and treat the handover as an afterthought.

## What a handover has to *contain*

A handover meeting is not a handover. A handover is something you can open later without calling anyone. For a BI migration I would want three things.

First, the definitions: for each metric, what it means, which filters it obeys and who approved it. Second, the exceptions: every place the new model deliberately differs from the old one, with the reason. Third, the checks: the parity report the owners signed, kept somewhere that survives the project.

This is the reason we write the estate out as [open specifications](/open-specifications/) the client owns. SQL, Python, JSON and YAML can be read by a person who was not in the room and diffed by a tool. They are not a substitute for judgment, but they hold the record that judgment produced. And it is why I keep saying nobody should [migrate twice](/insights/nobody-should-migrate-twice/): a result that only its builders understand is a lock-in with friendlier branding.

## Ask the question *before* you sign

When you talk to any vendor, consultancy or your own team, ask one thing early: in month six, who answers the question about why this number is what it is, and where do they look?

If the answer is a name, ask what happens when that person is unavailable. If the answer is a document, ask to see an example from a past project, redacted as needed. If the answer is "we will be around," ask how that is written into the contract.

It is also worth knowing that models can change between waves. A team can start with a delivered wave to get moving and bring its own people in for the next, so the understanding moves across as the project goes. That is cheaper than discovering in month six that you rented the knowledge.

The cheapest migration is the one you never have to explain twice.
