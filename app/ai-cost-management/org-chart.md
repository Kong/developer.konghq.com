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

tools:
  - kongctl

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

You build the org chart by uploading your org structure as a CSV file, typically exported from your HR system (HRIS).
{{site.konnect_short_name}} creates teams from the reporting lines in the file.
Teams and team membership change only when you upload a file.

To open the org chart:

1. In the {{site.konnect_short_name}} sidebar, click **Cost Management**.
1. Click **Org Chart**.

Only organization admins can upload an org structure or set spend limits.

## Org structure file

The org structure file is a CSV file of up to 10 MB and 50,000 rows, with one row per user and a reporting chain at most 200 levels deep.
Save the file as UTF-8. {{site.konnect_short_name}} removes the byte-order mark that Excel adds.
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

### Avoiding common import failures

Most failed imports have the same causes.
Keep the following in mind when you build the export:
* Export the whole org every time. {{site.konnect_short_name}} treats the file as the complete org chart and deactivates anyone from an earlier import who isn't in the new file.
* Include one row per person. Filter out duplicate rows for people with multiple jobs, positions, or employments.
* Use the same ID type in `external_id` and `manager_external_id`. For example, if `external_id` is an employee number, `manager_external_id` must be an employee number too, not a position ID or a name.
* Include active people and people on leave, since their direct reports still need them as a manager. Exclude terminated people and future hires.
* Don't filter out managers. If a filter removes a manager, every direct report of that manager fails to import.
* Only the person at the top of the org should have no manager. A vacant manager position can leave other people without one too, so assign those people an interim manager before you export.

### Import errors

If any row has a problem, {{site.konnect_short_name}} rejects the whole file and changes nothing.
The following are the most common import errors and their usual causes:

{% table %}
columns:
  - title: Column
    key: column
  - title: Problem
    key: problem
  - title: Cause and fix
    key: fix
rows:
  - column: "`external_id`"
    problem: is required
    fix: "The person has no ID in the export. Filter to rows that have one, or add it in your HR system."
  - column: "`external_id`"
    problem: is duplicated within the file
    fix: "The export has more than one row for this person, for example one per job, position, or employment. Filter to the primary one."
  - column: "`email`"
    problem: is required
    fix: "A new hire doesn't have a work email yet. Add the email in your HR system, or import after it's created."
  - column: "`email`"
    problem: must be a valid email address
    fix: "The value isn't in the form `name@domain`. Fix the address in your HR system."
  - column: "`email`"
    problem: is duplicated within the file
    fix: "Two people share a mailbox, or one person has two rows. Give each person their own address, and keep one row per person."
  - column: "`email`"
    problem: already exists in this directory
    fix: "A different principal in this directory already has this email address. Give each person a unique email, or update the other principal's identity first."
  - column: "`given_name`, `family_name`"
    problem: both are empty
    fix: "{{site.konnect_short_name}} builds the display name from `given_name` and `family_name`, and at least one of them must have a value."
  - column: "`given_name`, `family_name`"
    problem: exceed 255 characters combined
    fix: "{{site.konnect_short_name}} builds the display name from `given_name` and `family_name`. Together, they can be at most 255 characters."
  - column: "`cost_center`"
    problem: must be at most 255 characters
    fix: "The value is longer than 255 characters. Shorten it in your HR system."
  - column: "`manager_external_id`"
    problem: does not match a row in the file
    fix: |
      There's a mismatch due to one of the following reasons:
      * The manager isn't in the file, because of a filter or because they left.
      * The manager ID is of a different type, such as a position ID.
  - column: "`manager_external_id`"
    problem: must be a single manager
    fix: "The cell has several IDs separated by a comma or semicolon. Pick one manager in the export."
  - column: "`manager_external_id`"
    problem: only one person may have no manager
    fix: "People under a vacant manager position have no manager. Assign them an interim manager."
  - column: "`manager_external_id`"
    problem: never reaches a person with no manager
    fix: "The reporting chain is a loop, such as two people who are each other's manager, or it's more than 200 levels deep."
  - column: file
    problem: 'duplicate column "`<name>`" in the CSV header'
    fix: "Two columns in the header have the same name. The error names the duplicate. Rename or remove one of them."
  - column: file
    problem: wrong number of fields
    fix: "A row has more or fewer cells than the header. Common causes are an unquoted comma in a name, a title line above the header, or a totals row at the end. The error names the line number."
{% endtable %}

## Upload an org structure

You can build or update an org chart by uploading an org structure file.
To automate imports instead of using the dialog each time, use `kongctl` or the API.

{% navtabs "upload-org-structure" %}
{% navtab "Konnect UI" %}

1. In the {{site.konnect_short_name}} sidebar, click **Cost Management**, then click **Org Chart**.
1. Click **Upload org structure**.
1. Drop your CSV file in the dialog, or choose one.
   {{site.konnect_short_name}} checks the file and shows a preview without changing anything.
1. Review the summary and fix any errors or warnings:
   * The number of users and teams to create, update, deactivate, or delete.
     Everyone with at least one direct report gets a team named after them and their ID.
     For example, the manager `Marcus Lee` with the team code `E003` will have a team named `MarcusLee-E003`.
   * Any errors, listed by row and column.
     See [Import errors](#import-errors) for the most common ones.
   * Any warnings.
     For example, if a team name is already taken, the new team gets a number after its name, like "Platform (2)".
1. Click **Import**.

If the org structure changes between the preview and the import, {{site.konnect_short_name}} rejects the file and applies nothing.

{% endnavtab %}
{% navtab "kongctl" %}

`kongctl import identity org-chart` applies an org structure file against the default {{site.identity}} directory.
Preview the import without changing anything:

```sh
kongctl import identity org-chart \
  --pat "$KONNECT_TOKEN" \
  --file org-structure.csv \
  --dry-run \
  --report-output-dir ./import-reports
```

If the preview looks correct, apply the org chart:

```sh
kongctl import identity org-chart \
  --pat "$KONNECT_TOKEN" \
  --file org-structure.csv \
  --execute \
  --report-output-dir ./import-reports
```

Each run writes a JSON report to `--report-output-dir`, listing the users and teams it created, updated, or deactivated.

{% endnavtab %}
{% navtab "API" %}

Send the file to the import endpoint with `dry_run` set to `true` first.
A dry run returns the counts, errors, and warnings without changing anything:

```bash
curl -X POST "https://us.api.konghq.com/v2/directories/$DIRECTORY_ID/org-chart/import" \
  -H "Authorization: Bearer $KONNECT_TOKEN" \
  -F "file=@org.csv" -F "dry_run=true"
```

If the dry run returns no errors, import the file by sending the same request with `dry_run` set to `false`:

```bash
curl -X POST "https://us.api.konghq.com/v2/directories/$DIRECTORY_ID/org-chart/import" \
  -H "Authorization: Bearer $KONNECT_TOKEN" \
  -F "file=@org.csv" -F "dry_run=false"
```

If you run this on a schedule, have the job stop when `counts.users.inactive` in the dry run is much higher than usual.
A sudden jump usually means the HRIS export was incomplete.

{% endnavtab %}
{% endnavtabs %}

### Update an org chart

A re-upload matches the org structure to the file, so re-upload an updated org structure file whenever people or reporting lines change, for example monthly or after a reorganization.

A re-upload applies the following changes:

* {{site.konnect_short_name}} uses `external_id` to find each person who is already in the org chart.
  If a row's `external_id` matches an existing user, the re-upload replaces that person's email, name, and manager with the values in the file.
  If it doesn't match, the re-upload creates a new user.
* {{site.konnect_short_name}} deactivates users that the file no longer lists.
  They're not deleted.
* A re-upload never reactivates an inactive user, even if the file lists them.
  This applies whether you deactivated the user manually or an earlier re-upload deactivated them.
  The preview shows a warning for each of these users.
  To reactivate a user, click **Reactivate** in the users table or on the user's details page.
* Teams and team memberships follow the reporting lines in the file.
  Managers get the Team Manager role for their team. See [AI Management roles](/ai-management/roles-and-permissions/#roles).
* A re-upload doesn't invite anyone to {{site.konnect_short_name}}. To give people access, [invite them](/ai-management/roles-and-permissions/#invite-a-user-to-ai-management).

A re-upload deletes a team that has no members in the new file.
A re-upload doesn't delete a team that only changed.
For example, if a manager's name changes, the re-upload renames the team and keeps its ID.

Deleting a team doesn't change your budget list.
Budgets that you set on a deleted team still appear in **Cost Management** > **Budgets**.
You can keep them for your records, or [delete them manually](/ai-cost-management/budgets/).
You can't change a budget's scope, so a budget can't move to a different team.
To limit a new team, [create a new budget](/ai-cost-management/budgets/#set-up-a-budget).

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
