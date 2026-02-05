---
title: "Dynatrace"
content_type: reference
layout: reference
icon: /assets/icons/third-party/dynatrace.png

products:
    - catalog
    - gateway

tags:
  - integrations
  - dynatrace
search_aliases:
  - service catalog
breadcrumbs:
  - /catalog/
  - /catalog/integrations/

works_on:
    - konnect
description: The Dynatrace integration lets you connect Dynatrace classic service-level objects directly to your {{site.konnect_catalog}} services.
discovery_support: true
bindable_entities: "Classic service-level object"

related_resources:
  - text: "{{site.konnect_catalog}}"
    url: /catalog/
  - text: "Monitor Dynatrace SLOs {{site.konnect_catalog}} with the {{site.konnect_short_name}} UI"
    url: /how-to/monitor-dynatrace-slos-with-konnect-ui/
  - text: "Monitor Dynatrace SLOs {{site.konnect_catalog}} with the {{site.konnect_short_name}} API"
    url: /how-to/monitor-dynatrace-slos-with-konnect-api/
  - text: Set up Dynatrace with OpenTelemetry
    url: /how-to/set-up-dynatrace-with-otel/
---

The Dynatrace integration lets you connect Dynatrace classic service-level objects directly to your {{site.konnect_catalog}} services.
{% include /catalog/multi-resource.md %}

For a complete tutorial, see the following:
* [Monitor Dynatrace SLOs {{site.konnect_catalog}} with the {{site.konnect_short_name}} UI](/how-to/monitor-dynatrace-slos-with-konnect-ui/)
* [Monitor Dynatrace SLOs {{site.konnect_catalog}} with the {{site.konnect_short_name}} API](/how-to/monitor-dynatrace-slos-with-konnect-api/)

## Prerequisites

You need to configure the following in Dynatrace SaaS:
* A [classic service-level object in Dynatrace](https://docs.dynatrace.com/docs/deliver/service-level-objectives-classic/configure-and-monitor-slo). This will be ingested by {{site.konnect_short_name}}.
* Your Dynatrace URL. For example: `https://whr42363.apps.dynatrace.com`
* A [Dynatrace personal access token](https://docs.dynatrace.com/docs/manage/identity-access-management/access-tokens-and-oauth-clients/access-tokens/personal-access-token) with read SLO (`slo.read`) permissions.

{:.warning}
> Dynatrace ActiveGate isn't supported.

## Authenticate the Dynatrace integration

{% navtabs "dynatrace-integration" %}
{% navtab "UI" %}
1. In the {{site.konnect_short_name}} sidebar, click **Catalog**.
1. In the Catalog sidebar, click **[Integrations](https://cloud.konghq.com/us/service-catalog/integrations)**. 
1. Click **Dynatrace**.
1. Click **Add Dynatrace instance**.
1. In the **Dynatrace API Base URL** field, enter your Dynatrace URL without the trailing `/`. For example: `https://whr42363.apps.dynatrace.com`
1. In the **Dynatrace API key** field, enter your Dynatrace personal access token.
1. In the **Display name** field, enter a name for your Dynatrace instance.
1. In the **Instance name** field, enter a unique identifier for your Dynatrace instance.
1. Click **Save**.
{% endnavtab %}
{% navtab "API" %}
First, install the Dynatrace integration:

<!--vale off-->
{% konnect_api_request %}
url: /v1/integration-instances
method: POST
status_code: 201
region: us
body:
  integration_name: dynatrace
  name: dynatrace
  display_name: Dynatrace
  config:
    base_url: $DYNATRACE_URL
{% endkonnect_api_request %}
<!--vale on-->

Export the ID of your Dynatrace integration:

```sh
export DYNATRACE_INTEGRATION_ID='YOUR-INTEGRATION-ID'
```

Next, authorize the Dynatrace integration with your Dynatrace personal access token:

<!--vale off-->
{% konnect_api_request %}
url: /v1/integration-instances/$DYNATRACE_INTEGRATION_ID/auth-credential
method: POST
status_code: 201
region: us
body:
  type: multi_key_auth
  config:
    headers:
      - name: authorization
        key: $DYNATRACE_PAT
{% endkonnect_api_request %}
<!--vale on-->
{% endnavtab %}
{% navtab "Terraform" %}
Use the [`konnect_integration_instance`](https://github.com/Kong/terraform-provider-konnect/blob/main/examples/resources/integration_instance.tf) and [`konnect_integration_instance_auth_credential`](https://github.com/Kong/terraform-provider-konnect/blob/main/examples/resources/integration_instance_auth_credential.tf) resources:
```hcl
echo '
resource "konnect_integration_instance" "my_integrationinstance" {
  name         = "dynatrace"
  display_name = "Dynatrace"

  integration_name = "dynatrace"
  config = jsonencode({
    base_url = "'$DYNATRACE_URL'"
  })
}

resource "konnect_integration_instance_auth_credential" "my_integrationinstanceauthcredential" {
  integration_instance_id = konnect_integration_instance.my_integrationinstance.id
  multi_key_auth = {
    config = {
      "headers": [
        {
          "name": "authorization",
          "key": "'$DYNATRACE_PAT'"
        }
      ]
    }
  }
}
' >> main.tf
```
{% endnavtab %}
{% endnavtabs %}

## Resources

Available Dynatrace resources:

<!--vale off-->
{% table %}
columns:
  - title: Entity
    key: entity
  - title: Description
    key: description
rows:
  - entity: "A direct mapping to a [Dynatrace classic service-level object](https://docs.dynatrace.com/docs/deliver/service-level-objectives-classic/slo-basics)"
    description: Provides visibility into your SLO's current status, error budget, burn rate, target, warning, the number of open problems, and the SLO evaluation timeframe. 
{% endtable %}
<!--vale on-->

## Discovery information

<!-- vale off-->

{% include_cached catalog/service-catalog-discovery.md 
   discovery_support=page.discovery_support
   discovery_default=page.discovery_default
   bindable_entities=page.bindable_entities
   mechanism=page.mechanism %}

<!-- vale on-->



