---
title: Traceable
content_type: reference
layout: reference

products:
    - catalog
    - gateway

tags:
  - integrations
  - traceable

breadcrumbs:
  - /catalog/
  - /catalog/integrations/
search_aliases:
  - service catalog
works_on:
    - konnect
description: The Traceable integration lets you connect Traceable entities directly to your {{site.konnect_catalog}} services.

related_resources:
  - text: "{{site.konnect_catalog}}"
    url: /catalog/
  - text: Traceable plugin
    url: /plugins/traceable/
  - text: Import and map Traceable resources in {{site.konnect_catalog}}
    url: /how-to/install-and-map-traceable-resources/
discovery_support: true
bindable_entities: "Traceable Service"
---

The Traceable integration lets you connect Traceable Services directly to your {{site.konnect_catalog}} services.
{% include /catalog/multi-resource.md %}

For a complete tutorial using the {{site.konnect_short_name}} API, see [Import and map Traceable resources in {{site.konnect_catalog}}](/how-to/install-and-map-traceable-resources/).

## Authenticate the Traceable integration

{% navtabs "traceable-integration" %}
{% navtab "UI" %}
1. From the **Catalog** in {{site.konnect_short_name}}, select **[Integrations](https://cloud.konghq.com/us/service-catalog/integrations)**. 
2. Select **Add Traceable Instance**.
3. Configure the instance, add authorization and name the instance. 
{% endnavtab %}
{% navtab "Terraform" %}
Use the [`konnect_integration_instance`](https://github.com/Kong/terraform-provider-konnect/blob/main/examples/resources/integration_instance.tf) and [`konnect_integration_instance_auth_credential`](https://github.com/Kong/terraform-provider-konnect/blob/main/examples/resources/integration_instance_auth_credential.tf) resources:
```hcl
echo '
resource "konnect_integration_instance" "my_integrationinstance" {
  name         = "traceable"
  display_name = "Traceable"

  integration_name = "traceable"
  config = jsonencode({
    include_inactive = false
  })
}
resource "konnect_integration_instance_auth_credential" "my_integrationinstanceauthcredential" {
  integration_instance_id = konnect_integration_instance.my_integrationinstance.id
  multi_key_auth = {
    config = {
      headers = [
        {
          name = "authorization"
          key  = "$TRACEABLE_API_KEY"
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

<!--vale off-->
{% table %}
columns:
  - title: Entity
    key: entity
  - title: Description
    key: description
rows:
  - entity: Traceable Service
    description: 
      A direct mapping to a [Traceable Service](https://docs.traceable.ai/docs/domains-services-backends), which holds groups of Traceable API endpoint resources.
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



