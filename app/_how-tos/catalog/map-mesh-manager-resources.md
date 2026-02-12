---
title: Map Mesh Manager services in Catalog
permalink: /how-to/map-mesh-manager-resources/
content_type: how_to
description: Learn how to map Mesh Manager resources in {{site.konnect_catalog}} to gain visibility into how the service is deployed across meshes and zones.
products:
  - catalog
works_on:
  - konnect
automated_tests: false
entities: []
search_aliases:
  - service catalog
tldr:
  q: How do I map Mesh Manager services in {{site.konnect_catalog}}?
  a: Create a {{site.konnect_catalog}} service and associate it with your Mesh Manager resources to visualize meshes.
prereqs:
  inline:
    - title: "Mesh Manager services"
      content: |
        You'll need a [Mesh Manager service](https://cloud.konghq.com/mesh-manager) to ingest in {{site.konnect_catalog}} as resources.
      icon_url: /assets/icons/mesh.svg
related_resources:
  - text: "Mesh Manager integration"
    url: /catalog/integrations/mesh-manager/
  - text: "{{site.konnect_catalog}}"
    url: /catalog/
  - text: "{{site.konnect_catalog}} integrations"
    url: /catalog/integrations/
---

## Create a service in {{site.konnect_catalog}}

In this tutorial, you'll map services from Mesh Manager to a service in {{site.konnect_catalog}}. Because the Mesh Manager integration is built-in, you don't need to install or authorize it like other {{site.konnect_catalog}} integrations. 

Create a service that you'll map to your Mesh Manager resources:

<!--vale off-->
{% konnect_api_request %}
url: /v1/catalog-services
method: POST
status_code: 201
region: us
body:
  name: billing
  display_name: Billing Service
{% endkonnect_api_request %}
<!--vale on-->

Export the {{site.konnect_catalog}} service ID:

```sh
export SERVICE_ID='YOUR-SERVICE-ID'
```

## List Mesh Manager resources

Before you can map a resource to {{site.konnect_catalog}}, you first need to find the resources that are pulled in from Mesh Manager:

<!--vale off-->
{% konnect_api_request %}
url: /v1/resources?filter%5Bintegration.name%5D=mesh-manager
method: GET
region: us
status_code: 200
{% endkonnect_api_request %}
<!--vale on-->

Export the resource ID you want to map to the service:

```sh
export MESH_RESOURCE_ID='YOUR-RESOURCE-ID'
```

## Map resources to a {{site.konnect_catalog}} service

Now, you can map the Mesh Manager resource to the service:

<!--vale off-->
{% konnect_api_request %}
url: /v1/resource-mappings
method: POST
status_code: 201
region: us
body:
  service: $SERVICE_ID
  resource: $MESH_RESOURCE_ID
{% endkonnect_api_request %}
<!--vale on-->

## Validate the mapping

To confirm that the Mesh Manager resource is now mapped to the intended service, list the service’s mapped resources:

<!--vale off-->
{% konnect_api_request %}
url: /v1/catalog-services/$SERVICE_ID/resources
method: GET
status_code: 200
region: global
{% endkonnect_api_request %}
<!--vale on-->