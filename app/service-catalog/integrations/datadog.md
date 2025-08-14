---
title: "Datadog"
content_type: reference
layout: reference
icon: /assets/icons/plugins/datadog.png

products:
    - service-catalog
    - gateway

tags:
  - integrations
  - datadog

breadcrumbs:
  - /service-catalog/
  - /service-catalog/integrations/

works_on:
    - konnect
description: The Datadog integration lets you connect Datadog entities directly to your Service Catalog services.
discovery_support: true
bindable_entities: "Datadog Monitor, Datadog Dashboard"

related_resources:
  - text: "Service Catalog"
    url: /service-catalog/
  - text: Import and map Datadog resources in Service Catalog
    url: /how-to/install-and-map-datadog-resources/
---

The Datadog integration lets you connect Datadog entities directly to your Service Catalog services.
{% include /service-catalog/multi-resource.md %}

For a complete tutorial using the {{site.konnect_short_name}} API, see [Import and map Datadog resources in Service Catalog](/how-to/install-and-map-datadog-resources/).

## Authenticate the Datadog integration

{% navtabs "datadog-integration" %}
{% navtab "UI" %}
1. From the **Service Catalog** in {{site.konnect_short_name}}, select **[Integrations](https://cloud.konghq.com/service-catalog/integrations)**. 
1. Select **Add Datadog Instance**.
1. Select your Datadog region and enter your [Datadog API and application keys](https://docs.datadoghq.com/account_management/api-app-keys/). 
1. Select **Authorize**. 
{% endnavtab %}
{% navtab "Terraform" %}
Use the [`konnect_integration_instance`](https://github.com/Kong/terraform-provider-konnect/blob/main/examples/resources/integration_instance.tf) and [`konnect_integration_instance_auth_credential`](https://github.com/Kong/terraform-provider-konnect/blob/main/examples/resources/integration_instance_auth_credential.tf) resources:
```hcl
echo '
resource "konnect_integration_instance" "my_integrationinstance" {
  name         = "datadog"
  display_name = "Datadog"

  integration_name = "datadog"
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
  - entity: "A direct mapping to a [Datadog Monitor](https://docs.datadoghq.com/monitors/)"
    description: Provides visibility into performance issues and outages. 
  - entity: "A direct mapping to a [Datadog Dashboard](https://docs.datadoghq.com/dashboards/)"
    description: Provides visibility into the performance and health of systems and applications in your organization.
{% endtable %}
<!--vale on-->

## Discovery information

<!-- vale off-->

{% include_cached service-catalog/service-catalog-discovery.html 
   discovery_support=page.discovery_support
   discovery_default=page.discovery_default
   bindable_entities=page.bindable_entities
   mechanism=page.mechanism %}

<!-- vale on-->



