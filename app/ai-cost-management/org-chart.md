---
title: "Org chart in {{site.ai_cost_management}}"
content_type: reference
layout: reference

products:
  - ai-cost-management
  - ai-gateway

min_version:
  ai-gateway: '2.3'

works_on:
  - konnect

breadcrumbs:
  - /ai-management/
  - /ai-cost-management/

tags:
  - ai
  - governance
  - cost-management

description: "The org chart in {{site.ai_cost_management}} lists the teams and people that AI spend is attributed to. Learn how to upload an org structure CSV file, browse teams and users, and set spend limits on them."

faqs:
  - q: Why can't I edit a team or add a user to a team?
    a: |
      Teams and their members come only from the org structure file.
      To change them, upload an updated file.
  - q: Why did a user become inactive after I uploaded a file?
    a: |
      An upload makes the org structure match the file.
      Users that were imported before and that the new file doesn't list are deactivated.
      The upload doesn't delete them, so their usage history stays.
  - q: Why is the **Import** button disabled?
    a: |
      {{site.konnect_short_name}} checks the file before it imports anything.
      **Import** is disabled when the check finds errors, or when everyone in the file is already up to date.
      Fix the listed errors and choose the file again.
  - q: Why is the cost center **Unattributed**?
    a: |
      A user's spend stays unattributed until the user has a cost center.
      Add a `cost_center` column to the org structure file, or set the cost center in the user's details.

related_resources:
  - text: Attribution in {{site.ai_cost_management}}
    url: /ai-cost-management/attribution/
  - text: Budgets in {{site.ai_cost_management}}
    url: /ai-cost-management/budgets/
  - text: Users and teams in access management
    url: /ai-access-management/concepts/#users
---

The org chart is the structure of your organization in {{site.konnect_short_name}}: the people in it, the teams they belong to, and who reports to whom.
{{site.ai_cost_management}} uses it to attribute AI spend to teams and people.
You can set a [spend limit](#set-a-spend-limit-on-a-team-or-user) on any team or user from the org chart.

You build the org chart by uploading your org structure as a CSV file.
{{site.konnect_short_name}} creates teams from the reporting lines in the file.
Teams and team membership change only when you upload a file.

To open the org chart:

1. In the {{site.konnect_short_name}} sidebar, click **Cost Management**.
1. Click **Org Chart**.

Only organization admins can upload an org structure or set spend limits.

## Org structure file

The org structure file is a CSV file of up to 10 MB and 50,000 rows, with one row per user.
The first row is a header with the following columns:

{% table %}
columns:
  - title: Column
    key: column
  - title: Description
    key: description
rows:
  - column: "`external_id`"
    description: "A unique ID for the person in your HR system. {{site.konnect_short_name}} uses it to match users across uploads."
  - column: "`email`"
    description: "The user's email address."
  - column: "`given_name`"
    description: "The user's first name."
  - column: "`family_name`"
    description: "The user's last name."
  - column: "`manager_external_id`"
    description: "The `external_id` of the person this user reports to. {{site.konnect_short_name}} uses it to build the teams."
  - column: "`cost_center` (optional)"
    description: "The user's [cost center](#cost-centers)."
{% endtable %}

{{site.konnect_short_name}} matches column names without regard to case, and ignores any other column.
Leave `manager_external_id` empty for the one user at the top of the org.

You can download a sample file from the upload dialog by clicking **Download sample CSV**.

## Upload an org structure

1. In the {{site.konnect_short_name}} sidebar, click **Cost Management**, then click **Org Chart**.
1. Click **Upload org structure**.
1. Drop your CSV file in the dialog, or choose one.
   {{site.konnect_short_name}} checks the file and shows a preview without changing anything.
1. Review the summary:
   * The number of users and teams to create, update, deactivate, or delete.
   * Any errors, listed by row and column.
     Fix them and choose the file again.
   * Any warnings.
     For example, if a team name is already taken, the new team gets a number after its name, like "Platform (2)".
1. Click **Import**.

If the org structure changes between the preview and the import, {{site.konnect_short_name}} rejects the file and applies nothing.

### Update an org chart

An upload makes the org structure match the file, so upload an updated org structure file whenever people or reporting lines change.
An upload applies the following changes:

* {{site.konnect_short_name}} uses `external_id` to find each person who is already in the org chart.
  If a row's `external_id` matches an existing user, the upload replaces that person's email, name, and manager with the values in the file.
  If it doesn't match, the upload creates a new user.
* {{site.konnect_short_name}} deactivates users that the file no longer lists.
  They're not deleted.
* An upload never reactivates an inactive user, even if the file lists them.
  This applies whether you deactivated the user manually or an earlier upload deactivated them.
  The preview shows a warning for each of these users.
  To reactivate a user, click **Reactivate** in the users table or on the user's details page.
* Teams and team memberships follow the reporting lines in the file.

An upload can delete existing teams witho no members in the new upload. An upload can also replace existing items, for example: the manager's name change, so the upload only renames the team, which keeps the same ID. 

You can't delete the whole org chart.

## Browse the org chart

The org chart shows each team and user in a table.
Expand a team to see its people and sub-teams.
Deactivated users have an **Inactive** badge.

Select a team or user to see its details:
* For a team, the direct users and sub-teams. The counts don't include members of sub-teams.
* For a user, their ID and cost center, and a link to the user's details.

### Cost centers

A cost center is where a user's spend is charged.
You set it per user, either with the optional `cost_center` column in the org structure file or in the [user's details](/ai-access-management/concepts/#users).
Until a user has one, the user's spend shows as **Unattributed**.
Teams don't have cost centers, only individual users.

The `cost_center` column works as follows:
* If a row matches an existing user, the upload replaces that user's cost center with the value in the file.
  This includes a cost center you set in the user's details.
* If the cell is blank, the upload clears the user's cost center.
* If the file has no `cost_center` column, the upload leaves every cost center as it is.

## Set a spend limit on a team or user

A spend limit is a [budget](/ai-cost-management/budgets/) scoped to a single team or user.

To set a spend limit from the org chart:

1. Select a team or user in the org chart.
1. In the details, click **Set spend limit**.
1. In the **Monthly spend limit** field, enter an amount in US dollars greater than zero, with at most two decimals.
1. Click **Set limit**.

The details show the amount spent, the limit, and what remains of it.
To change the amount later, click **Edit spend limit**, then click **Save limit**.

The following rules apply to limits set from the org chart:
* The limit uses a monthly [budget window](/ai-cost-management/budgets/#limit-and-budget-window).
* The org chart can't remove a limit or change its period.
  Use the details page of the user or [group](/ai-access-management/concepts/#groups) instead.
  Both pages offer daily, weekly, and monthly periods and **Remove limit**.
* The org chart shows only the limit set directly on the selected team or user. It doesn't show limits that apply through a parent team, a group, or an organization-wide budget.
* If several limits apply to a user, the lowest limit applies.
* Like any budget, a spend limit tracks spend and sends notifications, but it doesn't block requests. See [Budgets in {{site.ai_cost_management}}](/ai-cost-management/budgets/).

### Team scope in budgets

When you set a spend limit in the org chart, {{site.konnect_short_name}} creates a [budget](/ai-cost-management/budgets/) for you.
The budget's [scope](/ai-cost-management/budgets/#budget-scope) has one filter that selects the team or user:

{% table %}
columns:
  - title: Selected in the org chart
    key: selected
  - title: Filter field
    key: field
  - title: Filter value
    key: value
rows:
  - selected: "Team"
    field: "`team`"
    value: "`principal/UUID`, where `UUID` is the team's ID"
  - selected: "User"
    field: "`subject`"
    value: "`principal/UUID`, where `UUID` is the user's ID"
{% endtable %}

The budget has one [pooled limit](/ai-cost-management/budgets/#pooled-and-individual-limits) shared by all the usage that matches the filter.
You can create the same budget with the [API](/api/konnect/ai-cost-management/).

A usage event counts toward a team's budget when the event lists that team in its `teams` field.
See [Groups and teams](/ai-cost-management/attribution/#groups-and-teams) to learn how events get their teams.

## Limitations

The org chart has the following limitations:
* You can't create teams or change team membership manually. Teams change only when you upload a file.
* The file supports only the columns listed in [Org structure file](#org-structure-file).
* An organization has one org chart.
* The org chart doesn't roll up spend or member counts from sub-teams into a parent team.
