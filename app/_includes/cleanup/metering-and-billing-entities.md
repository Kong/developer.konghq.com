Delete the {{site.metering_and_billing}} entities that you created in this guide. Cancelling a subscription that has usage creates an invoice, and you can't delete a customer until their invoices are deleted or in a final state.

Cancel the subscription:

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/subscriptions/$SUBSCRIPTION_ID/cancel
status_code: 200
method: POST
body:
  timing: immediate
section: cleanup
{% endkonnect_api_request %}
<!--vale on-->

Find and delete the customer's invoice:

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/billing/invoices?filter[customer_id]=$CUSTOMER_ID
status_code: 200
method: GET
capture:
  - variable: INVOICE_ID
    jq: ".data[0].id"
section: cleanup
{% endkonnect_api_request %}

{% konnect_api_request %}
url: /v3/openmeter/billing/invoices/$INVOICE_ID
status_code: 204
method: DELETE
section: cleanup
{% endkonnect_api_request %}
<!--vale on-->

Delete the customer, plan, feature, and meter:

<!--vale off-->
{% konnect_api_request %}
url: /v3/openmeter/customers/$CUSTOMER_ID
status_code: 204
method: DELETE
section: cleanup
{% endkonnect_api_request %}

{% konnect_api_request %}
url: /v3/openmeter/plans/$PLAN_ID/archive
status_code: 200
method: POST
section: cleanup
{% endkonnect_api_request %}

{% konnect_api_request %}
url: /v3/openmeter/plans/$PLAN_ID
status_code: 204
method: DELETE
section: cleanup
{% endkonnect_api_request %}

{% konnect_api_request %}
url: /v3/openmeter/features/$FEATURE_ID
status_code: 204
method: DELETE
section: cleanup
{% endkonnect_api_request %}

{% konnect_api_request %}
url: /v3/openmeter/meters/$METER_ID
status_code: 204
method: DELETE
section: cleanup
{% endkonnect_api_request %}
<!--vale on-->
