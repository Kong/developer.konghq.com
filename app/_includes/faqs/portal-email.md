To customize the reply-to and from, do the following in the {{site.konnect_short_name}} UI:
1. Set up a [custom domain](/dev-portal/custom-domains/) in {{site.dev_portal}}.
1. In the Portal Editor, navigate to the email settings.
1. Click **Email notification settings**.
1. Enter your from name and email.
    Reply-to email is optional.

Alternatively, you can use the {{site.dev_portal}} API:
1. Send a POST request to the [`/portals/{portalId}/custom-domain` endpoint](/api/konnect/portal-management/v3/#/operations/create-portal-custom-domain):
{% capture create_custom_domain %}  
{% konnect_api_request %}
url: /v3/portals/$DEV_PORTAL_ID/custom-domain
method: POST
body:
    hostname: example.com
    enabled: true
    ssl: {}
{% endkonnect_api_request %}
{% endcapture %}
{{ create_custom_domain | indent: 3 }}

2. Send a POST request to the [`/portals/{portalId}/email-config` endpoint](/api/konnect/portal-management/v3/#/operations/create-portal-email-config).
{% capture create_email_config %}
{% konnect_api_request %}
url: /v3/portals/$DEV_PORTAL_ID/email-config
method: POST
body:
  domain_name: example.com
  from_name: KongAir
  from_email: user@example.com
  reply_to_email: admin@example.com
{% endkonnect_api_request %}
{% endcapture %}
{{ create_email_config | indent: 3 }}