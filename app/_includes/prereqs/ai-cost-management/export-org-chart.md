In production, export your org chart from your human resources information system (HRIS) as a CSV file.
The export must include your whole org, with active people and people on leave, and exactly one person at the top with no manager.

If you are testing or don't have an HRIS, skip this prerequisite. The guide provides a sample CSV file.

Choose your HRIS and follow the export instructions:

{% navtabs "hris" %}
{% navtab "Workday" %}

Create an **Advanced** custom report on the **All Workers** data source (primary business object: Worker).
Use **Employee ID** as the key (the `external_id` column).

{:.info}
> Check the following before you export:
>
> * **A supervisory organization with two managers**: Workday puts both IDs in one cell, which {{site.konnect_short_name}} rejects with `must be a single manager`. Use a calculated field (**Extract Single Instance**) to pick one manager.
> * **Vacant managers**: When an organization's manager position is vacant, its workers export without a manager. Assign an interim manager, or use a calculated field that falls back to the manager of the superior organization.
> * **No ready-made Manager ID field**: Some tenants don't include one. If yours doesn't, create a calculated field that returns the Employee ID of the worker's manager.

1. Add the following fields to the report. For each one, set **Column Heading Override** and **Column Heading Override XML Alias** to the {{site.konnect_short_name}} column name:

{% capture workday_fields %}
{% table %}
columns:
  - title: {{site.konnect_short_name}} column
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

   Add an **Effective as of Date** prompt that defaults to today.
   All Workers includes contingent workers. Keep them if contractors should get budgets in {{site.konnect_short_name}}.

1. Run the report, export it to Excel, and save it as **CSV UTF-8**.

   {:.success}
   > To automate the export, turn on **Enable As Web Service** and fetch the report with an integration system user:
   >
   > ```
   > https://YOUR_WORKDAY_HOST/ccx/service/customreport2/<tenant>/<report-owner>/<Report_Name>?format=csv
   > ```
   > {:.wrap}

1. Open the CSV file and confirm that line 1 contains the {{site.konnect_short_name}} column names, that exactly one person has no manager, and that the file is saved as UTF-8.

{% endnavtab %}
{% navtab "SAP SuccessFactors" %}

Build a **Story** report in Report Center on the Employee Central schema. Use **User ID** as the key (the `external_id` column), because the Supervisor field on Job Information stores the manager's User ID. User IDs can't be changed later.
To use Person ID External instead, map each manager's User ID to it before you export.

{:.info}
> Check the following before you export:
>
> * **Multiple employments and global assignments**: These give one person several User IDs and rows. Keep only the primary employment.
> * **Inactive supervisors**: A person's Supervisor can still be someone who has left. Update those people in Employee Central.
> * **Tenant differences**: Field labels in Query Designer depend on your Employee Central configuration. Check whether your export uses calculated column names as headers. Also check whether your release can deliver scheduled Story exports to SFTP, because older releases only offered offline delivery.

1. Get the following fields for each worker:

{% capture sap_fields %}
{% table %}
columns:
  - title: {{site.konnect_short_name}} column
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

   Choose one of the following options:

   * **Story (recommended):** Go to **Reporting** (Report Center), choose **New > Story**, and build the query in **Query Designer** with the fields in the table.

     Keep the time filter at **As of Date** (today), so each person gets one current Job Information row.
     Matrix and custom managers are stored in Job Relationships. Don't join that table, or people will appear once for each relationship.

   * **OData v2 API (small organizations only):** The API returns the same data from `EmpJob` (`userId`, `managerId`, `costCenter`) and `User` (`email`). Effective-dated queries default to today.

1. Filter **Employee Status** to the active statuses: `A` (Active), `U` (Unpaid Leave), `P` (Paid Leave), and `S` (Suspended).

   In a Story, leave **Include inactive users in the data** cleared in the scope filter, and run the report as an admin with access to the whole population.

1. In a Story, choose **Preview Query > Export** and set **File Type** to CSV. The download is a zip file.
   Unzip it and rename the headers to the {{site.konnect_short_name}} column names, or add calculated columns that already have those names.
   
   {:.success}
   > To automate the export, use **Action > New Schedule**. Choose **Data Source in Story** and CSV, and deliver the file to SFTP.

1. The top person often has the literal value `NO_MANAGER` in the `manager_external_id` column instead of an empty value. Clear that cell, or {{site.konnect_short_name}} reports `does not match a row in the file`.

1. Open the CSV file and confirm that line 1 contains the {{site.konnect_short_name}} column names, that exactly one person has no manager, and that the file is saved as UTF-8.

{% endnavtab %}
{% navtab "Oracle Fusion Cloud HCM" %}

Oracle recommends **HCM Extracts** for bulk exports. Use **Person Number** as the key (the `external_id` column).

{:.info}
> Check the following before you export:
>
> * **Several people without a line manager**: Many tenants have more than one. Assign line managers to everyone except the top person.
> * **Departments and cost centers are separate**: Departments map to cost centers in different ways in each tenant. Send whichever one your finance team uses for budgets.
> * **Tenant differences**: Oracle doesn't document which OTBI column holds the line manager's Person Number, so prefer HCM Extracts or REST for that field. Check how your extract names the header row, and test the `q` filter on the child resource before you depend on it.

1. Export the following attributes for each worker. The REST field column applies only if you use the REST API:

{% capture oracle_fields %}
{% table %}
columns:
  - title: {{site.konnect_short_name}} column
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
     Set **Output Type** to CSV, which doesn't need a BI Publisher template, and name the attributes with the {{site.konnect_short_name}} column names.
     Schedule it with delivery to SFTP or WebCenter Content.

     An OTBI analysis on **Workforce Management - Worker Assignment Real Time** also works for a one-off export. That subject area returns current assignments only.
     OTBI's manager folders depend on the **Refresh Manager Hierarchy** process, so run it before the export.

   * **REST API (small organizations only):** `publicWorkers` returns active workers. Oracle advises against REST for bulk pulls, so use it only for small organizations.

     ```sh
     GET /hcmRestApi/resources/11.13.18.05/publicWorkers
         ?expand=assignments.managers&onlyData=true&limit=500&offset=0
     REST-Framework-Version: 4
     ```

1. Filter to one row per current worker.
   * Keep only the worker's overall primary assignment (`PrimaryFlag = true`) so that each worker has one row.
   Don't use `PrimaryAssignmentFlag` for this. It marks the primary assignment within only one work relationship, so it can still return two rows for one person.
   * Keep only the manager with the `LINE_MANAGER` manager type. A worker has one line manager at a time but can also have project or HR managers.
   * For REST, add `q=assignments.PrimaryFlag=true` to the request, and filter the managers to `LINE_MANAGER` in your script.
   * Worker type `C` marks contingent workers. Keep them if contractors should get budgets in {{site.konnect_short_name}}.

1. Open the CSV file and confirm that line 1 contains the {{site.konnect_short_name}} column names, that exactly one person has no manager, and that the file is saved as UTF-8.

{% endnavtab %}
{% navtab "ADP Workforce Now" %}

Build a custom report keyed on **Associate ID** (the `external_id` column), which identifies the person. Don't use Position ID or File Number, which identify a position.
ADP stores the reporting line on each position, so take the manager from the primary position.

{:.info}
> Check the following before you export:
> 
> * **Mixed ID types**: Reports To Position ID doesn't match an Associate ID. Use **Reports To Associate ID** in the manager column.
> * **Vacant or terminated managers**: The reporting line is tied to a position, so it can point to a vacant position or to someone who has left. Fix those people in ADP.
> * **Tenant differences**: ADP's help for Custom Reports is available only to signed-in customers. Check the exact field labels (especially **Reports To Associate ID** and the primary-position filter) and whether your report can rename column headers.

1. Get the following fields for each worker. The Workers API path column applies only if you use the Workers API:

{% capture adp_fields %}
{% table %}
columns:
  - title: {{site.konnect_short_name}} column
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

   Choose one of the following options:

   * **Custom report (recommended):** Go to **Reports & Analytics > Custom Reports > Set Up New**, name the report, and add the fields in the table under **Select Fields**.

   * **Workers API:** `GET https://api.adp.com/hr/v2/workers` returns the same fields. Page with `$top` and `$skip` until it returns HTTP 204.

1. Filter to one row per current worker.
   In a custom report, filter on **Position Status** to include Active and Leave, and keep only primary positions, because people with several positions appear once for each position.

   In the Workers API, filter to active workers with `$filter=workers/workAssignments/assignmentStatus/statusCode/codeValue eq 'A'`, and take `reportsTo` from the assignment where `primaryIndicator` is true.

1. For a custom report, choose **Save + Run** and export to CSV. Rename the headers to the {{site.konnect_short_name}} column names, and delete the **Report Totals** row if ADP adds one.
   
   {:.success}
   > To automate the export, use **Schedule To Run**. SFTP delivery needs ADP's Automatic Export Service.

1. Open the CSV file and confirm that line 1 contains the {{site.konnect_short_name}} column names, that exactly one person has no manager, and that the file is saved as UTF-8.

{% endnavtab %}
{% endnavtabs %}

_Don't see your HRIS? Looking for more integrations? Reach out to [Kong Support](https://support.konghq.com/)._
