Delete the subscription:

<!--vale off-->
{% konnect_api_request %}
url: /v1/notifications/configurations/organization/devportal_developer.registration_pending/subscriptions/$SUBSCRIPTION_ID
method: DELETE
status_code: 204
region: global
{% endkonnect_api_request %}
<!--vale on-->

Delete the destination. This also deletes its signing keys and delivery history, and can't be undone:

<!--vale off-->
{% konnect_api_request %}
url: /v1/notifications/destinations/$DESTINATION_ID
method: DELETE
status_code: 204
region: global
{% endkonnect_api_request %}
<!--vale on-->

If you created a {{site.dev_portal}} for this tutorial, delete it:

<!--vale off-->
{% konnect_api_request %}
url: /v3/portals/$PORTAL_ID
method: DELETE
status_code: 204
{% endkonnect_api_request %}
<!--vale on-->
