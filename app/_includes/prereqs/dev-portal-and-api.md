1. [Create a Dev Portal](/api/konnect/portal-management/v3/#/operations/create-portal):
   <!--vale off-->
{% capture create-portal %}
{% konnect_api_request %}
url: /v3/portals
status_code: 201
method: POST
body:
    name: MyDevPortal
    authentication_enabled: true
    auto_approve_applications: true
    auto_approve_developers: true
    default_api_visibility: public
    default_page_visibility: public
{% endkonnect_api_request %}
{% endcapture %}
{{ create-portal | indent: 3 }}
   <!--vale on-->
   Export your Dev Portal ID and URL from the response:

   ```sh
   export PORTAL_ID='YOUR-DEV-PORTAL-ID'
   export PORTAL_URL='YOUR-DEV-PORTAL-DOMAIN'
   ```

1. [Create a page](/api/konnect/portal-management/v3/#/operations/create-portal-page) so the portal is accessible and published APIs are visible:
   <!--vale off-->
{% capture create-page %}
{% konnect_api_request %}
url: /v3/portals/$PORTAL_ID/pages
status_code: 201
method: POST
body:
    title: My Page
    slug: /
    visibility: public
    status: published
    content: |
     # Welcome to My Dev Portal
     Explore the available APIs below:
     ::apis-list
     ---
     persist-page-number: true
     cta-text: "View APIs"
     ---
{% endkonnect_api_request %}
{% endcapture %}
{{ create-page | indent: 3 }}
   <!--vale on-->

1. [Create an API](/api/konnect/api-builder/v3/#/operations/create-api):
   <!--vale off-->
{% capture create-api %}
{% konnect_api_request %}
url: /v3/apis
status_code: 201
method: POST
body:
    name: MyAPI
{% endkonnect_api_request %}
{% endcapture %}
{{ create-api | indent: 3 }}
   <!--vale on-->
   Export the ID of your API from the response:

   ```sh
   export API_ID='YOUR-API-ID'
   ```

1. [Publish the API to your Dev Portal](/api/konnect/api-builder/v3/#/operations/publish-api-to-portal):
   <!--vale off-->
{% capture publish-api %}
{% konnect_api_request %}
url: /v3/apis/$API_ID/publications/$PORTAL_ID
status_code: 201
method: PUT
body:
    visibility: public
{% endkonnect_api_request %}
{% endcapture %}
{{ publish-api | indent: 3 }}
   <!--vale on-->
