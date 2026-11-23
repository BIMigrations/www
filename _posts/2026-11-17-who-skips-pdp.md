---
title: "Who skips your Domo row policies?"
heading: "Before you migrate PDP, list who <em>skips</em> it."
description: "Domo owners, admins and All Rows see every row. Power BI row-level security skips workspace Admins, Members and Contributors. Map who skips first."
author: amy-loomis
image: /assets/img/og/who-skips-pdp.png
---

Everyone who migrates row-level security starts with the filters. West sales sees West. The region manager sees two regions. Fine. Those are the easy rules, because somebody wrote them down on purpose.

The harder question is who the filters never apply to. In Domo that is a longer list than most people think, and in Power BI it is a different list, built by a different mechanism. If nobody maps one onto the other, the migration will pass every role test you write and still leak.

## In Domo, the unfiltered people are quiet

Domo's Personalized Data Permissions let you filter a DataSet by row for the users and groups you name. A card, [an alert](/insights/domo-alerts-are-shared/) or a DataFlow powered by that DataSet then shows each person only their rows. The knowledge base is direct about who is not in that picture: "DataSet owners and admins have access to all data in a DataSet." Every DataSet also has a default policy called All Rows, which gives other users and groups the same level of access.

That second group grows without anyone deciding it should. The documentation says why. A DataFlow built on a DataSet only keeps running after PDP is switched on if its owner is an Admin, or has the Manage DataFlow grant, or owns the input DataSet, or sits in the All Rows policy. Domo's impact review even has a Fix It button that adds the owners of affected assets to All Rows so their flows don't break. Reasonable. Also how an All Rows list quietly becomes "everybody who ever built something on this data".

Two details make this hard to audit. Owners and admins are implicit, so they appear in no policy list. And Domo's PDP reports, which are in beta, show the All Rows policy only when someone has been explicitly assigned to it. So the full set of people who see every row is the admins, plus the owners, plus whatever the assignments report shows. Three places, none of them labeled "who sees everything".

One more rule matters for the filtered people. Separate policies on the same DataSet combine with OR: add someone to a product-line policy and an order-method policy and they see rows that match either. Two values in one policy combine with AND. A person's real access is the union of everything they were added to.

## In Power BI, the unfiltered people are a workspace role

Microsoft's documentation is just as direct, and the mechanism is different. Row-level security "only restricts data access for users with Viewer permissions. It doesn't apply to workspace Admin, Member, or Contributor roles." Those roles have edit permission on the semantic model, so the filters are skipped for them. Giving a Viewer Build permission doesn't change that: RLS still applies.

So the line between filtered and unfiltered is where you put people in the workspace. It is a property of who can edit, not of who is on a list. An analyst who needs to build a report on the model needs a role above Viewer, and from that moment the row filters stop applying to them.

Role membership has its own edges. You add users, or Microsoft Entra security groups, distribution groups and mail-enabled groups, in the Power BI service. Microsoft 365 groups aren't supported for role membership, and groups created inside Power BI can't be added. A user can be in several roles, and the roles are additive, the same union as Domo's OR. Domo's groups are Domo's own, so every group a PDP policy used has to be matched to something Power BI accepts.

## Where the two lists fail to match

Here is the mapping problem in four lines.

1. A Domo user on the All Rows policy because their DataFlow broke once. In Power BI they need to be a Viewer in a role that lets them through, or an editor who skips RLS entirely. Which one did anyone decide?
2. A Domo admin sees everything, expected. A Power BI workspace Contributor sees everything too, and usually nobody thinks of Contributor as an admin role.
3. A person who in Domo could view all rows but not build, through the Magic ETL workaround Domo documents for exactly that case. In Power BI the closest thing I can think of is a Viewer in a role with no restricting filter. I haven't built that, so test it before you promise it.
4. A person who in Domo could build but only on their own region, because they weren't on All Rows. In Power BI, they cannot build in the workspace that holds the model and stay filtered. That is a design choice for you to make, not a setting to find.

A role-by-role test, where you log in as West sales and check the rows, covers none of these. It covers the filtered people. The leak lives with the unfiltered ones, and nothing fails when it happens.

## What I would do before the first role is written

- List every DataSet with row policies on, and for each one: who is the owner, who is an admin, and who is on All Rows. The impact view and the policy assignments report give you part of it. The rest you read off the people directory.
- Write the Power BI workspace layout first. Which workspace holds the semantic model, who is a Viewer there, who is an editor. Keep the editor list short and deliberate, because every name on it is someone the filters skip.
- Decide each unfiltered person's destination on purpose: editor who skips RLS, or Viewer in a role. Write it next to their name.
- Test as people, not as roles. Microsoft notes that Test as role uses your own identity for dynamic rules, so sign in as a real Viewer, and as a real Contributor to watch the filter disappear.
- Ask the DataSet owner whether the All Rows list is what they think it is. It rarely is.

I have no Domo instance to try any of this on. This is built from what the two vendors document, read on the day I wrote it, and I would expect the details in your estate to be messier than the documentation.

It is also why I keep saying the estate is more than its dashboards. The [Domo to Power BI migration page](/domo-to-power-bi/) says PDP policies are rebuilt as row-level security roles and tested one role at a time, and the [checklist for testing an automated migration](/insights/test-an-automated-domo-migration/) says to test security as people. Both are right. Whoever does your migration, tool or person, should also be able to hand you the list of everyone who skips the filters, on both sides, before you sign off. If they can only show you the filters, they've shown you the part that was already written down.
