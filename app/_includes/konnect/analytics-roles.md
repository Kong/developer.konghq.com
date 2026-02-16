The following describes the predefined roles for Analytics:

{% table %}
columns:
  - title: Role
    key: role
  - title: Description
    key: description
rows:
  - role: "`Dashboard viewer`"
    description: |
      - Can view the [Analytics](/observability/) summary and report data.
      - Cannot edit dashboards.
      - Can apply temporary filters during a session.
      - Can only see dashboards that they are explicitly granted access to.
  - role: "`Dashboard creator`"
    description: |
      Can create new dashboards, and automatically become an Admin of the created dashboard.

      To access the underlying data of the dashboard, you'll also need to assign users with `Dashboard creator` roles to the [`Analytics Viewer` pre-built team](/konnect-platform/teams-and-roles/#predefined-teams).
  - role: "`Dashboard admin`"
    description: |
      * Can edit, share, and delete dashboards.
      * Can access Explorer if they are also assigned to the [Analytics Viewer pre-defined team](/konnect-platform/teams-and-roles/#predefined-teams).
      * Can only see the dashboards that they've been granted access to.

  - role: "`Dashboard editor`"
    description: |
      * Can edit an existing dashboard only.
      * Can access Explorer if they are also assigned to the [Analytics Viewer pre-defined team](/konnect-platform/teams-and-roles/#predefined-teams).
      * Can only see the dashboards that they've been granted access to.

  - role: "`Report viewer`"
    description: |
      Can only view reports that they were granted access to.
  - role: "`Report creator`"
    description: |
      Can create new reports and automatically becomes an admin of the created report.

      To access the underlying data of the report, you'll also need to assign users with `Report creator` roles to the [`Analytics Viewer` pre-built team](/konnect-platform/teams-and-roles/#predefined-teams).
  - role: "`Report admin`"
    description: |
      * Can edit, share, and delete reports.
      * Can access Explorer.
      * Can only see the reports that they've been granted access to.

  - role: "`Report editor`"
    description: |
      * Can only edit an existing report.
      * Can access Explorer.
      * Can only see the reports that they've been granted access to.

{% endtable %}