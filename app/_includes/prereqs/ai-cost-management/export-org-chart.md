In production, export your org chart from your HRIS as a CSV file with one row per person and the columns `external_id`, `email`, `given_name`, `family_name`, `manager_external_id`, and `cost_center`.
The export must include your whole org, with one row per active person (including people on leave), and exactly one person at the top with no manager.

Select your HRIS for export instructions:

{% navtabs "hris" %}
{% navtab "Workday" %}

Create an **Advanced** custom report on the **All Workers** data source (primary business object: Worker). Use **Employee ID** as the key.

| Konnect column | Workday field | Heading override and XML alias |
| --- | --- | --- |
| `external_id` | Employee ID | `external_id` |
| `email` | Email - Work | `email` |
| `given_name` | First Name | `given_name` |
| `family_name` | Last Name | `family_name` |
| `manager_external_id` | Manager ID (the manager's Employee ID) | `manager_external_id` |
| `cost_center` | Cost Center (or Cost Center - ID for codes only) | `cost_center` |

1. **Add the fields and rename them.**
   For each column, set **Column Heading Override** and **Column Heading Override XML Alias** to the Konnect name.
   A UI export takes column names from the headings, and a web service takes them from the XML aliases.
   When both are set, both exports produce a file that {{site.konnect_short_name}} accepts.

1. **Filter to current workers.**

   ```
   (Active Status (Date As Of) = Yes  OR  On Leave = Yes)
   AND Hire Date ≤ Report Effective Date
   ```

   Add an **Effective as of Date** prompt that defaults to today.
   All Workers includes contingent workers. Keep them if contractors should get budgets in {{site.konnect_short_name}}.

1. **Export.**
   Run the report, export it to Excel, and save it as **CSV UTF-8**. Make sure line 1 is the header row.
   To automate the export, turn on **Enable As Web Service** and fetch the report with an integration system user:

   ```
   https://<workday-host>/ccx/service/customreport2/<tenant>/<report-owner>/<Report_Name>?format=csv
   ```

**Watch out for:**

* **A supervisory organization with two managers.** Workday puts both IDs in one cell, which {{site.konnect_short_name}} rejects with "must be a single manager". Use a calculated field (**Extract Single Instance**) to pick one manager.
* **Vacant managers.** When an organization's manager position is vacant, its workers export with no manager. Assign an interim manager, or use a calculated field that falls back to the manager of the superior organization.
* **No ready-made Manager ID field.** Some tenants don't have one. If yours doesn't, create a calculated field that returns the Employee ID of the worker's manager.

{% endnavtab %}
{% navtab "SAP SuccessFactors" %}

Build a **Story** report in Report Center on the Employee Central schema. Use **User ID** as the key, because the Supervisor field on Job Information stores the manager's User ID. User IDs can't be changed later.
To use Person ID External instead, map each manager's User ID to it before you export.

| Konnect column | Employee Central field | Table |
| --- | --- | --- |
| `external_id` | User ID | Job Information |
| `email` | Email Address (business) | Business Email Information |
| `given_name` | First Name | Personal Information |
| `family_name` | Last Name | Personal Information |
| `manager_external_id` | Supervisor (the manager's User ID) | Job Information |
| `cost_center` | Cost Center, with the name from the Cost Center table | Job Information, Cost Center |

1. **Create the story.**
   Go to **Reporting** (Report Center), choose **New > Story**, and build the query in **Query Designer** from the tables in the previous table.
   Keep the time filter at **As of Date** (today), so each person gets one current Job Information row.

1. **Filter to current workers.**
   Filter **Employee Status** to the active statuses: `A` (Active), `U` (Unpaid Leave), `P` (Paid Leave), and `S` (Suspended).
   Leave **Include inactive users in the data** cleared in the scope filter, and run the report as an admin with access to the whole population.

1. **Export.**
   Choose **Preview Query > Export** and set **File Type** to CSV. The download is a zip file.
   Unzip it and rename the headers to the Konnect names, or add calculated columns that already have those names.
   To automate the export, use **Action > New Schedule**. Choose **Data Source in Story** and CSV, and deliver the file to SFTP.

   For small orgs, the OData v2 API returns the same data from `EmpJob` (`userId`, `managerId`, `costCenter`) and `User` (`email`). Effective-dated queries default to today.

**Watch out for:**

* **`NO_MANAGER` at the top.** The top person often has the literal value `NO_MANAGER` instead of an empty value. Clear that cell before you upload, or {{site.konnect_short_name}} reports "does not match a row in the file".
* **Multiple employments and global assignments.** These give one person several User IDs and rows. Keep the primary employment only.
* **Matrix and custom managers.** Those relationships are stored in Job Relationships. Don't join that table, or people appear once for each relationship.
* **Inactive supervisors.** A person's Supervisor can still be someone who has left. Update those people in Employee Central before you export.
* **Tenant differences.** Field labels in Query Designer depend on your Employee Central configuration. Check whether your export uses calculated column names as headers. Also check whether your release can deliver scheduled Story exports to SFTP, because older releases only offered offline delivery.

{% endnavtab %}
{% navtab "Oracle Fusion Cloud HCM" %}

Oracle recommends **HCM Extracts** for bulk exports. Use **Person Number** as the key, and take the manager from the **line manager** of the worker's **primary** assignment.

| Konnect column | Oracle attribute | REST `publicWorkers` field |
| --- | --- | --- |
| `external_id` | Person Number | `PersonNumber` |
| `email` | Work email | `WorkEmail` |
| `given_name` | First Name | `FirstName` |
| `family_name` | Last Name | `LastName` |
| `manager_external_id` | Line manager's Person Number | `assignments.managers.ManagerPersonNumber`, where `ManagerType = LINE_MANAGER` |
| `cost_center` | Department name, or your cost center attribute | `assignments.DepartmentName` |

1. **Build the extract.**
   Create an HCM Extract with one record per worker and the attributes in the previous table.
   Set **Output Type** to CSV, which doesn't need a BI Publisher template, and name the attributes with the Konnect column names.
   Schedule it with delivery to SFTP or WebCenter Content.

   An OTBI analysis on **Workforce Management - Worker Assignment Real Time** also works for a one-off export. That subject area returns current assignments only.

1. **Filter to one row per current worker.**
   Keep the worker's overall primary assignment (`PrimaryFlag = true`).
   `PrimaryAssignmentFlag` marks the primary assignment within only one work relationship, so it can still return two rows for one person.
   Keep only the `LINE_MANAGER` manager type. A worker has one line manager at a time but can also have project or HR managers.
   Worker type `C` marks contingent workers.

1. **Or use REST for a small org.**
   `publicWorkers` returns active workers as of today. Oracle advises against REST for bulk pulls, so use it only for small orgs.

   ```
   GET /hcmRestApi/resources/11.13.18.05/publicWorkers
       ?q=assignments.PrimaryFlag=true
       &expand=assignments.managers&onlyData=true&limit=500&offset=0
   REST-Framework-Version: 4
   ```

   Filter the managers to `LINE_MANAGER` in your script.

**Watch out for:**

* **Several people without a line manager.** Real tenants often have more than one. Assign line managers to everyone except the top person.
* **A stale manager hierarchy in OTBI.** OTBI's manager folders depend on the **Refresh Manager Hierarchy** process. Run it before the export, or use HCM Extracts.
* **Departments and cost centers are separate.** Departments map to cost centers in different ways in each tenant. Send whichever one your finance team uses for budgets.
* **Tenant differences.** Oracle doesn't document which OTBI column holds the line manager's Person Number, so prefer HCM Extracts or REST for that field. Check how your extract names the header row, and test the `q` filter on the child resource before you depend on it.

{% endnavtab %}
{% navtab "ADP Workforce Now" %}

Build a custom report keyed on **Associate ID**, which identifies the person. Don't use Position ID or File Number, which identify a position.
ADP stores the reporting line on each position, so take the manager from the primary position.

| Konnect column | Report field | Workers API path |
| --- | --- | --- |
| `external_id` | Associate ID | `workerID.idValue` |
| `email` | Work Contact: Work Email | `businessCommunication.emails[].emailUri` |
| `given_name` | First Name | `person.legalName.givenName` |
| `family_name` | Last Name | `person.legalName.familyName1` |
| `manager_external_id` | Reports To Associate ID | `workAssignments[].reportsTo[].workerID.idValue` |
| `cost_center` | Home Cost Number Code, or Home Department | `workAssignments[].homeOrganizationalUnits[].nameCode` |

1. **Create the report.**
   Go to **Reports & Analytics > Custom Reports > Set Up New**, name the report, and add the fields in the previous table under **Select Fields**.

1. **Filter to one row per current worker.**
   Filter on **Position Status** to include Active and Leave.
   Keep only primary positions, because people with several positions appear once for each position.

1. **Export.**
   Choose **Save + Run** and export to CSV. Rename the headers to the Konnect names, and delete the **Report Totals** row if ADP adds one.
   To automate the export, use **Schedule To Run**. SFTP delivery needs ADP's Automatic Export Service.

   The Workers API (`GET https://api.adp.com/hr/v2/workers`) returns the same fields.
   Filter to active workers with `$filter=workers/workAssignments/assignmentStatus/statusCode/codeValue eq 'A'`, page with `$top` and `$skip` until it returns HTTP 204, and take `reportsTo` from the assignment where `primaryIndicator` is true.

**Watch out for:**

* **Mixed ID types.** Reports To Position ID doesn't match an Associate ID. Use **Reports To Associate ID** in the manager column.
* **Vacant or terminated managers.** The reporting line is tied to a position, so it can point to a vacant position or to someone who has left. Fix those people in ADP before you export.
* **Tenant differences.** ADP's help for Custom Reports is available only to signed-in customers. Check the exact field labels (especially **Reports To Associate ID** and the primary-position filter) and whether your report can rename column headers.

{% endnavtab %}
{% endnavtabs %}

Don't see your HRIS? Looking for more integrations? Reach out to [Kong Support](https://support.konghq.com/).
