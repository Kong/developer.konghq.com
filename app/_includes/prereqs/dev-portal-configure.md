For this tutorial, you’ll need a Dev Portal and some Dev Portal settings pre-configured. These settings are essential for Dev Portal to function but configuring them isn’t the focus of this guide. If you don't have these settings already configured, follow these steps to pre-configure them:

1. [Create a Dev Portal](/api/konnect/portal-management/v3/#/operations/create-portal):
   <!--vale off-->
{% capture portal %}
{% control_plane_request %}
url: /v3/portals
status_code: 201
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
    - 'Authorization: Bearer $DECK_KONNECT_TOKEN'
body:
    name: MyDevPortal
    authentication_enabled: true
    auto_approve_applications: true
    auto_approve_developers: true
    default_api_visibility: public
    default_page_visibility: public
{% endcontrol_plane_request %}
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
{% control_plane_request %}
url: /v3/portals/$PORTAL_ID/pages
status_code: 201
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
    - 'Authorization: Bearer $DECK_KONNECT_TOKEN'
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
{% endcontrol_plane_request %}
{% endcapture %}

{{ pages | indent: 3 }}
   <!--vale on-->
