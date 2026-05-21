---
title: SwaggerHub
content_type: reference
layout: reference

products:
    - catalog
    - gateway

tags:
  - integrations
  - swaggerhub

breadcrumbs:
  - /catalog/
  - /catalog/integrations/
search_aliases:
  - service catalog
works_on:
    - konnect
description: The SwaggerHub integration lets you connect SwaggerHub API specs directly to your {{site.konnect_catalog}} services.
related_resources:
  - text: "{{site.konnect_catalog}}"
    url: /catalog/
  - text: Import and map SwaggerHub resources in {{site.konnect_catalog}}
    url: /how-to/install-and-map-swaggerhub-resources/
discovery_support: true
bindable_entities: "SwaggerHub API version"
---

The SwaggerHub integration lets you connect SwaggerHub API specs directly to your {{site.konnect_catalog}} services.
{% include /catalog/multi-resource.md %}

For a complete tutorial using the {{site.konnect_short_name}} API, see [Import and map SwaggerHub resources in {{site.konnect_catalog}}](/how-to/install-and-map-swaggerhub-resources/).

## Prerequisites

You need a [SwaggerHub API key](https://swagger.io/docs/specification/v3_0/authentication/api-keys/) to authenticate your SwaggerHub account with {{site.konnect_short_name}}.


## Authenticate the SwaggerHub integration

{% navtabs "swaggerhub-integration" %}
{% navtab "UI" %}
1. From the **Catalog** in {{site.konnect_short_name}}, select **[Integrations](https://cloud.konghq.com/service-catalog/integrations)**. 
2. Select **Add SwaggerHub Instance**.
3. Add your Swaggerhub API key and name the instance.
{% endnavtab %}
{% navtab "Terraform" %}
Use the [`konnect_integration_instance`](https://github.com/Kong/terraform-provider-konnect/blob/main/examples/resources/integration_instance.tf) and [`konnect_integration_instance_auth_credential`](https://github.com/Kong/terraform-provider-konnect/blob/main/examples/resources/integration_instance_auth_credential.tf) resources:
```hcl
echo '
resource "konnect_integration_instance" "my_integrationinstance" {
  name             = "swaggerhub"
  display_name     = "SwaggerHub"
  integration_name = "swaggerhub"

  config = jsonencode({})
}

resource "konnect_integration_instance_auth_credential" "my_integrationinstanceauthcredential" {
  integration_instance_id = konnect_integration_instance.my_integrationinstance.id

  multi_key_auth = {
    config = {
      headers = [
        {
          name = "authorization"
          key  = "$SWAGGERHUB_API_KEY"
        }
      ]
    }
  }
}
' >> main.tf
```
{% endnavtab %}
{% endnavtabs %}

This will take you to SwaggerHub, where you can use your SwaggerHub API key to grant {{site.konnect_short_name}} access to your account.

## Resources

<!--vale off-->
{% table %}
columns:
  - title: Entity
    key: entity
  - title: Description
    key: description
rows:
  - entity: "{{page.bindable_entities}}"
    description: 
      A [SwaggerHub API version](https://support.smartbear.com/swaggerhub/docs/en/manage-apis/versioning.html?sbsearch=API%20Versions), which is the unique version identifier for a specific API spec.
{% endtable %}
<!--vale on-->


## Discovery information

{:.info}
> This integration will discover both public and private SwaggerHub APIs in the linked account.

<!-- vale off-->

{% include_cached catalog/service-catalog-discovery.md 
   discovery_support=page.discovery_support
   discovery_default=page.discovery_default
   bindable_entities=page.bindable_entities
   mechanism=page.mechanism %}

<!-- vale on-->



