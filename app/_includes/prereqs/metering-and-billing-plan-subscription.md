Create the entities you'll apply tax codes to in this guide.

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

1. Create a feature:

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

1. Create a plan with a rate card:

   <!--vale off-->
   {% konnect_api_request %}
   url: /v3/openmeter/plans
   method: POST
   status_code: 201
   body:
     name: Example Plan
     key: example_plan
     currency: USD
     billing_cadence: P1M
     phases:
       - name: default
         key: default
         rate_cards:
           - name: API requests
             key: api_requests
             feature:
               id: $FEATURE_ID
             price:
               type: unit
               amount: "1"
             entitlement:
               type: boolean
   capture:
     - variable: PLAN_ID
       jq: ".id"
   {% endkonnect_api_request %}
   <!--vale on-->

1. Publish the plan:

   <!--vale off-->
   {% konnect_api_request %}
   url: /v3/openmeter/plans/$PLAN_ID/publish
   method: POST
   status_code: 200
   {% endkonnect_api_request %}
   <!--vale on-->

1. Create a customer:

   <!--vale off-->
   {% konnect_api_request %}
   url: /v3/openmeter/customers
   method: POST
   status_code: 201
   body:
     name: Acme Inc
     key: acme-inc
     usage_attribution:
       subject_keys:
         - acme-inc
   capture:
     - variable: CUSTOMER_ID
       jq: ".id"
   {% endkonnect_api_request %}
   <!--vale on-->

1. Start a subscription:

   <!--vale off-->
   {% konnect_api_request %}
   url: /v3/openmeter/subscriptions
   method: POST
   status_code: 201
   body:
     customer:
       id: $CUSTOMER_ID
     plan:
       key: example_plan
   capture:
     - variable: SUBSCRIPTION_ID
       jq: ".id"
   {% endkonnect_api_request %}
   <!--vale on-->
