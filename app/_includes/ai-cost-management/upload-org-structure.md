{{site.ai_cost_management}} matches each automatically provisioned principal against your organization's reporting structure. Upload an org chart before you send a request.

In production, you'll export an org chart file from your HR system, such as Workday.
The file must be in CSV format and a maximum of 10 MB.

For this example, we'll create a small CSV file directly.
Create a file named `org-structure.csv`:

<!--vale off-->
{% validation custom-command %}
command: |
  cat <<EOF > org-structure.csv
  external_id,email,given_name,family_name,manager_external_id,cost_center
  EMP1001,jordan.lee@example.com,Jordan,Lee,,ENG-100
  EMP1002,alex.morgan@example.com,Alex,Morgan,EMP1001,ENG-100
  EMP1003,sam.rivera@example.com,Sam,Rivera,EMP1001,ENG-100
  EMP1004,taylor.kim@example.com,Taylor,Kim,EMP1001,ENG-100
  EMP1005,casey.nguyen@example.com,Casey,Nguyen,EMP1001,ENG-100
  EOF
expected:
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

Apply the CSV to the default {{site.identity}} directory:

<!--vale off-->
{% validation custom-command %}
command: |
  kongctl import identity org-chart \
    --pat "$KONNECT_TOKEN" \
    --file org-structure.csv \
    --execute \
    --report-output-dir ./import-reports
expected:
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

You can set `--dry-run` instead of `--execute` to preview the import without changing any existing users or teams.
See [Org chart in {{site.ai_cost_management}}](/ai-cost-management/org-chart/) for the full column reference and import behavior.
