Create a meter to count events and a feature to make that usage billable.

The first request creates the meter. The second request creates the feature and captures its ID so you can reference it when you create a plan:

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/meters
status_code: 201
method: POST
body:
  name: API requests
  key: api_requests_total
  event_type: request
  aggregation: count
capture:
  - variable: METER_ID
    jq: .id
{% endkonnect_api_request %}

{% konnect_api_request %}
url: /v3/openmeter/features
status_code: 201
method: POST
body:
  name: API requests
  key: api_requests
  meter:
    id: $METER_ID
capture:
  - variable: FEATURE_ID
    jq: .id
{% endkonnect_api_request %}
<!--vale on-->
