
The time frame selector controls the time frame of data visualized, which indirectly controls the
granularity of the data. For example, the “5M” selection displays five minutes in
one-second resolution data, while longer time frames display minute, hour, or days resolution data.

* **Relative** time frames are dynamic and the report captures a snapshot of data
relative to when a user views the report.
* **Custom** time frames are static and the report captures a snapshot of data
during the specified time frame. You can see the exact range below
the time frame selector. For example:

   ```
   Jan 26, 2023 12:00 AM - Feb 01, 2023 12:00 AM (PST)
   ```
   {:.no-copy-code}

The following table describes the time intervals you can select:

<!--vale off-->
{% table %}
columns:
  - title: "Interval"
    key: "interval"
  - title: "Aggregation increment frequency"
    key: "aggregation_increment_frequency"
  - title: "Notes"
    key: "notes"
rows:
  - interval: "Last 15 minutes"
    aggregation_increment_frequency: "1 minute"
    notes: "Data is aggregated in one minute increments."
  - interval: "Last hour"
    aggregation_increment_frequency: "1 minute"
    notes: "Data is aggregated in one minute increments."
  - interval: "Last six hours"
    aggregation_increment_frequency: "1 minute"
    notes: "Data is aggregated in one minute increments."
  - interval: "Last 12 hours"
    aggregation_increment_frequency: "1 hour"
    notes: "Data is aggregated in one hour increments."
  - interval: "Last 24 hours"
    aggregation_increment_frequency: "1 hour"
    notes: "Data is aggregated in one hour increments."
  - interval: "Last seven days"
    aggregation_increment_frequency: "1 hour"
    notes: "Data is aggregated in one hour increments."
  - interval: "Last 30 days"
    aggregation_increment_frequency: "Daily"
    notes: "Data is aggregated in daily increments."
  - interval: "Current week"
    aggregation_increment_frequency: "1 hour"
    notes: "Logs any traffic in the current calendar week."
  - interval: "Current month"
    aggregation_increment_frequency: "1 hour"
    notes: "Logs any traffic in the current calendar month."
  - interval: "Previous week"
    aggregation_increment_frequency: "1 hour"
    notes: "Logs any traffic in the previous calendar week."
  - interval: "Previous month"
    aggregation_increment_frequency: "Daily"
    notes: "Logs any traffic in the previous calendar month."
{% endtable %}
<!--vale on-->
