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
      - Can view the [Analytics](/observability/) summary and report data
      - Cannot edit dashboards
      - Can apply temporary filters during a session
      - Can only see dashboards they are explicitly granted access to
  - role: "`Dashboard creator`"
    description: |
      Can create new dashboards, and automatically become an Admin of the created dashboard.
  - role: "`Dashboard admin`"
    description: |
      * Can edit, share, and delete dashboards
      * Can access Explorer. Users must have appropriate roles to see data though. Otherwise, they will see a warning message.
      * Can only see their dashboards

  - role: "`Dashboard editor`"
    description: |
      * Can edit an existing dashboard only
      * Can access Explorer. Users must have appropriate roles to see data though. Otherwise, they will see a warning message.
      * Can only see their dashboards

  - role: "`Report viewer`"
    description: |
      Can only view reports that they were granted access to
  - role: "`Report creator`"
    description: |
      Can create new reports and automatically becomes an Admin of the created report.
  - role: "`Report admin`"
    description: |
      * Can edit, share, and delete reports
      * Can access Explorer
      * Can only see their reports

  - role: "`Report editor`"
    description: |
      * Can only edit an existing report
      * Can access Explorer
      * Can only see their reports

{% endtable %}