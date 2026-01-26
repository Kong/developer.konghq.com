The following describes the predefined roles for Analytics:

{% table %}
columns:
  - title: Role
    key: role
  - title: Description
    key: description
rows:
  - role: "`Dashboard viewer`"
    description: >-
      Users can view the [Analytics](/observability/) summary and report data.<br>
      - Cannot edit dashboards<br>
      - Can apply temporary filters during a session<br>
      - Can only see dashboards they are explicitly granted access to
  - role: "`Dashboard creator`"
    description: |
      Can create new dashboards and automatically becomes an Admin of the dashboard created.
  - role: "`Dashboard admin`"
    description: |
      * Can edit, share, and delete.
      * Can also access “Explorer”. Users must have appropriate roles to see data though. Otherwise, they will see a warning message.
      * Can only see their dashboards.

  - role: "`Dashboard editor`"
    description: |
      * Can only edit an existing dashboard.
      * Can also access “Explorer”. Users must have appropriate roles to see data though. Otherwise, they will see a warning message.
      * Can only see their dashboards. 

  - role: "`Report viewer`"
    description: |
      Can only view reports that they have been granted access to.
  - role: "`Report creator`"
    description: |
      Can create new reports and automatically becomes an Admin of the report created.
  - role: "`Report admin`"
    description: |
      * Can edit, share, and delete.
      * Can also access “Explorer”.
      * Can only see their reports.

  - role: "`Report editor`"
    description: |
      * Can only edit an existing report.
      * Can also access “Explorer”.
      * Can only see their reports. 

{% endtable %}