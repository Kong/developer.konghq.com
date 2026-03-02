For this tutorial, you’ll need a Dev Portal pre-configured. These settings are essential for Dev Portal to function, but configuring them isn’t the focus of this guide. If you don't have these settings already configured, follow these steps to pre-configure them:

1. [Create a Dev Portal](/api/konnect/portal-management/v3/#/operations/create-portal):
   <!--vale off-->
{% capture portal %}
{% konnect_api_request %}
url: /v3/portals
status_code: 201
method: POST
body:
    name: MyDevPortal
    authentication_enabled: false
    auto_approve_applications: false
    auto_approve_developers: false
    default_api_visibility: public
    default_page_visibility: public
{% endkonnect_api_request %}
{% endcapture %}
{{ portal | indent: 3 }}
   <!--vale on-->
1. Export your Dev Portal ID and URL from the output:

   ```sh
   export PORTAL_ID='YOUR-DEV-PORTAL-ID'
   export PORTAL_URL='YOUR-DEV-PORTAL-DOMAIN'
   ```

1. [Create a page in your Dev Portal](/api/konnect/portal-management/v3/#/operations/create-portal-page) so published APIs will display:
<!--vale off-->
{% capture pages %}
{% konnect_api_request %}
url: /v3/portals/$PORTAL_ID/pages
status_code: 201
method: POST
body:
    title: My Page
    slug: /apis
    description: A custom page about developer portals
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
{{ pages | indent: 3 }}
   <!--vale on-->