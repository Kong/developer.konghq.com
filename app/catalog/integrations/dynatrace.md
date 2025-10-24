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

You need to configure the following in Dynatrace:
* A [classic service-level object in Dynatrace](https://docs.dynatrace.com/docs/deliver/service-level-objectives-classic/configure-and-monitor-slo). This will be ingested by {{site.konnect_short_name}}.
* Your Dynatrace URL. For example: `https://whr42363.apps.dynatrace.com`
* A [Dynatrace personal access token](https://docs.dynatrace.com/docs/manage/identity-access-management/access-tokens-and-oauth-clients/access-tokens/personal-access-token) with read SLO (`slo.read`) permissions.

## Authenticate the Datadog integration

{% navtabs "datadog-integration" %}
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
{% navtab "Terraform" %}
Use the [`konnect_integration_instance`](https://github.com/Kong/terraform-provider-konnect/blob/main/examples/resources/integration_instance.tf) and [`konnect_integration_instance_auth_credential`](https://github.com/Kong/terraform-provider-konnect/blob/main/examples/resources/integration_instance_auth_credential.tf) resources:
```hcl
echo '
resource "konnect_integration_instance" "my_integrationinstance" {
  name         = "dynatrace"
  display_name = "Dynatrace"

  integration_name = "dynatrace"
  config = jsonencode({
    datadog_region       = "'$DATADOG_REGION'"
    datadog_webhook_name = "konnect-service-catalog"
  })
}

resource "konnect_integration_instance_auth_credential" "my_integrationinstanceauthcredential" {
  integration_instance_id = konnect_integration_instance.my_integrationinstance.id
  multi_key_auth = {
    config = {
      "headers": [
        {
          "name": "DD-API-KEY",
          "key": "'$DATADOG_API_KEY'"
        },
        {
          "name": "DD-APPLICATION-KEY",
          "key": "'$DATADOG_APPLICATION_KEY'"
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

Available Datadog resources:

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

{% include_cached catalog/service-catalog-discovery.html 
   discovery_support=page.discovery_support
   discovery_default=page.discovery_default
   bindable_entities=page.bindable_entities
   mechanism=page.mechanism %}

<!-- vale on-->



