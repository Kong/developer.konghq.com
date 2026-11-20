If you're running in production and want to use a real org chart, export your org chart from your Human Resource Information System (HRIS) into a CSV file. If you don't have one or are testing the functionality, the tutorial provides a sample CSV file to demo the org chart capability.

Choose your HRIS and follow the export instructions:

{% navtabs "hris" %}
{% navtab "Workday" %}

Create an **Advanced** custom report on the **All Workers** data source (primary business object: Worker).
Use **Employee ID** as the key.

1. Add the following fields to the report. For each one, set **Column Heading Override** and **Column Heading Override XML Alias** to the Konnect name:

{% capture workday_fields %}
{% table %}
columns:
  - title: Konnect column
    key: konnect
  - title: Workday field
    key: field
  - title: Heading override and XML alias
    key: alias
rows:
  - konnect: "`external_id`"
    field: Employee ID
    alias: "`external_id`"
  - konnect: "`email`"
    field: Email - Work
    alias: "`email`"
  - konnect: "`given_name`"
    field: First Name
    alias: "`given_name`"
  - konnect: "`family_name`"
    field: Last Name
    alias: "`family_name`"
  - konnect: "`manager_external_id`"
    field: Manager ID (the manager's Employee ID)
    alias: "`manager_external_id`"
  - konnect: "`cost_center`"
    field: Cost Center (or Cost Center - ID for codes only)
    alias: "`cost_center`"
{% endtable %}
{% endcapture %}

{{ workday_fields | indent: 3 }}

   A UI export takes column names from the headings, and a web service takes them from the XML aliases.
   When both are set, both exports produce a file that {{site.konnect_short_name}} accepts.

1. Filter to current workers:

   ```
   (Active Status (Date As Of) = Yes OR On Leave = Yes)
   AND Hire Date ≤ Report Effective Date
   ```

1. Add an **Effective as of Date** prompt that defaults to today.
   All Workers includes contingent workers. Keep them if contractors should get budgets in {{site.konnect_short_name}}.

1. Run the report, export it to Excel, and save it as **CSV UTF-8**. Make sure line 1 is the header row.

   To automate the export, turn on **Enable As Web Service** and fetch the report with an integration system user:

   ```
   https://YOUR_WORKDAY_HOST/ccx/service/customreport2/<tenant>/<report-owner>/<Report_Name>?format=csv
   ```

**Watch out for:**

* **A supervisory organization with two managers**: Workday puts both IDs in one cell, which {{site.konnect_short_name}} rejects with `must be a single manager`. Use a calculated field (**Extract Single Instance**) to pick one manager.
* **Vacant managers**: When an organization's manager position is vacant, its workers export with no manager. Assign an interim manager, or use a calculated field that falls back to the manager of the superior organization.
* **No ready-made Manager ID field**: Some tenants don't have a manager ID field. If yours doesn't, create a calculated field that returns the Employee ID of the worker's manager.

{% endnavtab %}
{% navtab "SAP SuccessFactors" %}

Build a **Story** report in Report Center on the Employee Central schema. Use **User ID** as the key, because the Supervisor field on Job Information stores the manager's User ID. User IDs can't be changed later.
To use Person ID External instead, map each manager's User ID to it before you export.

1. Go to **Reporting** (Report Center), choose **New > Story**, and build the query in **Query Designer** with the following fields:

{% capture sap_fields %}
{% table %}
columns:
  - title: Konnect column
    key: konnect
  - title: Employee Central field
    key: field
  - title: Table
    key: table
rows:
  - konnect: "`external_id`"
    field: User ID
    table: Job Information
  - konnect: "`email`"
    field: Email Address (business)
    table: Business Email Information
  - konnect: "`given_name`"
    field: First Name
    table: Personal Information
  - konnect: "`family_name`"
    field: Last Name
    table: Personal Information
  - konnect: "`manager_external_id`"
    field: Supervisor (the manager's User ID)
    table: Job Information
  - konnect: "`cost_center`"
    field: Cost Center, with the name from the Cost Center table
    table: Job Information, Cost Center
{% endtable %}
{% endcapture %}

{{ sap_fields | indent: 3 }}

   Keep the time filter at **As of Date** (today), so each person gets one current Job Information row.

1. Filter **Employee Status** to the active statuses: `A` (Active), `U` (Unpaid Leave), `P` (Paid Leave), and `S` (Suspended).
   Leave **Include inactive users in the data** cleared in the scope filter, and run the report as an admin with access to the whole population.

1. Choose **Preview Query > Export** and set **File Type** to CSV. The download is a zip file.
   Unzip it and rename the headers to the Konnect names, or add calculated columns that already have those names.
   To automate the export, use **Action > New Schedule**. Choose **Data Source in Story** and CSV, and deliver the file to SFTP.

   For small orgs, the OData v2 API returns the same data from `EmpJob` (`userId`, `managerId`, `costCenter`) and `User` (`email`). Effective-dated queries default to today.

**Watch out for:**

* **`NO_MANAGER` at the top**: The top person often has the literal value `NO_MANAGER` instead of an empty value. Clear that cell before you upload, or {{site.konnect_short_name}} reports "does not match a row in the file".
* **Multiple employments and global assignments**: These give one person several User IDs and rows. Keep the primary employment only.
* **Matrix and custom managers**: Those relationships are stored in Job Relationships. Don't join that table, or people appear once for each relationship.
* **Inactive supervisors**: A person's Supervisor can still be someone who has left. Update those people in Employee Central before you export.
* **Tenant differences**: Field labels in Query Designer depend on your Employee Central configuration. Check whether your export uses calculated column names as headers. Also check whether your release can deliver scheduled Story exports to SFTP, because older releases only offered offline delivery.

{% endnavtab %}
{% navtab "Oracle Fusion Cloud HCM" %}

Oracle recommends **HCM Extracts** for bulk exports. Use **Person Number** as the key, and take the manager from the **line manager** of the worker's **primary** assignment.

1. Export the following attributes for each worker. The REST field column applies only if you use the REST API:

{% capture oracle_fields %}
{% table %}
columns:
  - title: Konnect column
    key: konnect
  - title: Oracle attribute
    key: attribute
  - title: REST `publicWorkers` field
    key: rest
rows:
  - konnect: "`external_id`"
    attribute: Person Number
    rest: "`PersonNumber`"
  - konnect: "`email`"
    attribute: Work email
    rest: "`WorkEmail`"
  - konnect: "`given_name`"
    attribute: First Name
    rest: "`FirstName`"
  - konnect: "`family_name`"
    attribute: Last Name
    rest: "`LastName`"
  - konnect: "`manager_external_id`"
    attribute: Line manager's Person Number
    rest: "`assignments.managers.ManagerPersonNumber`, where `ManagerType = LINE_MANAGER`"
  - konnect: "`cost_center`"
    attribute: Department name, or your cost center attribute
    rest: "`assignments.DepartmentName`"
{% endtable %}
{% endcapture %}

{{ oracle_fields | indent: 3 }}

   Choose one of the following options:

   * **HCM Extract (recommended):** Create an HCM Extract with one record per worker and the attributes in the table.
     Set **Output Type** to CSV, which doesn't need a BI Publisher template, and name the attributes with the Konnect column names.
     Schedule it with delivery to SFTP or WebCenter Content.

     An OTBI analysis on **Workforce Management - Worker Assignment Real Time** also works for a one-off export. That subject area returns current assignments only.

   * **REST API (small orgs only):** `publicWorkers` returns active workers as of today. Oracle advises against REST for bulk pulls, so use it only for small orgs.

     ```sh
     GET /hcmRestApi/resources/11.13.18.05/publicWorkers
         ?q=assignments.PrimaryFlag=true
         &expand=assignments.managers&onlyData=true&limit=500&offset=0
     REST-Framework-Version: 4
     ```

1. Filter to one row per current worker. Keep the worker's overall primary assignment (`PrimaryFlag = true`). The REST request already applies this filter.
   `PrimaryAssignmentFlag` marks the primary assignment within only one work relationship, so it can still return two rows for one person.

   Keep only the `LINE_MANAGER` manager type. A worker has one line manager at a time but can also have project or HR managers.
   In a REST response, filter the managers to `LINE_MANAGER` in your script.

   Worker type `C` marks contingent workers.

**Watch out for:**

* **Several people without a line manager**: Real tenants often have more than one. Assign line managers to everyone except the top person.
* **A stale manager hierarchy in OTBI**: OTBI's manager folders depend on the **Refresh Manager Hierarchy** process. Run it before the export, or use HCM Extracts.
* **Departments and cost centers are separate**: Departments map to cost centers in different ways in each tenant. Send whichever one your finance team uses for budgets.
* **Tenant differences**: Oracle doesn't document which OTBI column holds the line manager's Person Number, so prefer HCM Extracts or REST for that field. Check how your extract names the header row, and test the `q` filter on the child resource before you depend on it.

{% endnavtab %}
{% navtab "ADP Workforce Now" %}

Build a custom report keyed on **Associate ID**, which identifies the person. Don't use Position ID or File Number, which identify a position.
ADP stores the reporting line on each position, so take the manager from the primary position.

1. Go to **Reports & Analytics > Custom Reports > Set Up New**, name the report, and add the following fields under **Select Fields**. The Workers API path column applies only if you use the Workers API:

{% capture adp_fields %}
{% table %}
columns:
  - title: Konnect column
    key: konnect
  - title: Report field
    key: field
  - title: Workers API path
    key: api
rows:
  - konnect: "`external_id`"
    field: Associate ID
    api: "`workerID.idValue`"
  - konnect: "`email`"
    field: "Work Contact: Work Email"
    api: "`businessCommunication.emails[].emailUri`"
  - konnect: "`given_name`"
    field: First Name
    api: "`person.legalName.givenName`"
  - konnect: "`family_name`"
    field: Last Name
    api: "`person.legalName.familyName1`"
  - konnect: "`manager_external_id`"
    field: Reports To Associate ID
    api: "`workAssignments[].reportsTo[].workerID.idValue`"
  - konnect: "`cost_center`"
    field: Home Cost Number Code, or Home Department
    api: "`workAssignments[].homeOrganizationalUnits[].nameCode`"
{% endtable %}
{% endcapture %}

{{ adp_fields | indent: 3 }}

1. Filter on **Position Status** to include Active and Leave.
   Keep only primary positions, because people with several positions appear once for each position.

1. Choose **Save + Run** and export to CSV. Rename the headers to the Konnect names, and delete the **Report Totals** row if ADP adds one.
   To automate the export, use **Schedule To Run**. SFTP delivery needs ADP's Automatic Export Service.

   The Workers API (`GET https://api.adp.com/hr/v2/workers`) returns the same fields.
   Filter to active workers with `$filter=workers/workAssignments/assignmentStatus/statusCode/codeValue eq 'A'`, page with `$top` and `$skip` until it returns HTTP 204, and take `reportsTo` from the assignment where `primaryIndicator` is true.

**Watch out for:**

* **Mixed ID types**: Reports To Position ID doesn't match an Associate ID. Use **Reports To Associate ID** in the manager column.
* **Vacant or terminated managers**: The reporting line is tied to a position, so it can point to a vacant position or to someone who has left. Fix those people in ADP before you export.
* **Tenant differences**: ADP's help for Custom Reports is available only to signed-in customers. Check the exact field labels (especially **Reports To Associate ID** and the primary-position filter) and whether your report can rename column headers.

{% endnavtab %}
{% endnavtabs %}

_Don't see your HRIS? Looking for more integrations? Reach out to [Kong Support](https://support.konghq.com/)._
