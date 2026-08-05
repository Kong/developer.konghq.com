Create a meter to count events and a feature to make that usage billable.

1. Create a meter:

   <!--vale off-->
   {% konnect_api_request %}
   url: /v3/openmeter/meters
   method: POST
   status_code: 201
   body:
     name: API requests total
     key: api_requests_total
     event_type: request
     aggregation: COUNT
   {% endkonnect_api_request %}
   <!--vale on-->

1. Create a feature linked to the meter:

   <!--vale off-->
   {% konnect_api_request %}
   url: /v3/openmeter/features
   method: POST
   status_code: 201
   body:
     name: API requests
     key: api_requests
     meter:
       key: api_requests_total
   capture:
     - variable: FEATURE_ID
       jq: ".id"
   {% endkonnect_api_request %}
   <!--vale on-->
