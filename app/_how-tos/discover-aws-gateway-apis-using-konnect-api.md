---
title: Discover AWS Gateway APIs in Service Catalog with the {{site.konnect_short_name}} API
content_type: how_to
description: Learn how to connect an AWS Gateway API to your {{site.konnect_catalog}} service in {{site.konnect_short_name}} using the API.
products:
  - service-catalog
works_on:
  - konnect
tools:
  - konnect-api
tags:
  - integrations
  - aws
related_resources:
  - text: Service Catalog
    url: /service-catalog/
  - text: Integrations
    url: /service-catalog/integrations/
  - text: AWS API Gateway reference
    url: /service-catalog/integrations/aws-api-gateway/
  - text: "Discover AWS Gateway APIs in Service Catalog with the {{site.konnect_short_name}} UI"
    url: /how-to/discover-aws-gateway-apis-using-konnect-ui/
  - text: Discover and govern APIs with Service Catalog
    url: /how-to/discover-and-govern-apis-with-service-catalog/
automated_tests: false
tldr:
  q: How do I discover AWS API Gateway API in {{site.konnect_short_name}}?
  a: Install the AWS API Gateway integration in {{site.konnect_short_name}} and authorize access with your Service Catalog role ARN, then link an API to your {{site.konnect_catalog}} service.
prereqs:
  inline:
    - title: "{{site.konnect_short_name}} roles"
      include_content: prereqs/service-catalog-integration-role
      icon_url: /assets/icons/kogo-white.svg
    - title: AWS API Gateway
      include_content: prereqs/service-catalog-iam
      icon_url: /assets/icons/aws.svg
---

## Configure the AWS API Gateway integration

Before you can discover APIs in Service Catalog, you must configure the AWS API Gateway integration.

{% include /service-catalog/aws-api-gateway-integration.md %}

## Create a service in Service Catalog

Create a service that you'll map to your AWS API Gateway resources:

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

Export the service ID:

```sh
export AWS_SERVICE_ID='YOUR-SERVICE-ID'
```

## List AWS API Gateway resources

Before you can map your AWS API Gateway resources to a service in Service Catalog, you first need to find the resources that are pulled in from AWS API Gateway:

<!--vale off-->
{% konnect_api_request %}
url: /v1/resources?filter%5Bintegration.name%5D=aws-api-gateway
method: GET
region: us
status_code: 200
{% endkonnect_api_request %}
<!--vale on-->

{:.info}
> You might need to manually sync your AWS API Gateway integration for resources to appear. From the {{site.konnect_short_name}} UI by navigating to the AWS API Gateway integration you just installed and selecting **Sync Now** from the **Actions** dropdown menu.

Export the resource ID you want to map to the service:

```sh
export AWS_RESOURCE_ID='YOUR-RESOURCE-ID'
```

## Map resources to a service

Now, you can map the AWS API Gateway resource to the service:

<!--vale off-->
{% konnect_api_request %}
url: /v1/resource-mappings
method: POST
status_code: 201
region: us
body:
  service: billing
  resource: $AWS_RESOURCE_ID
{% endkonnect_api_request %}
<!--vale on-->


## Validate the mapping

To confirm that the AWS API Gateway resource is now mapped to the intended service, list the service’s mapped resources:

<!--vale off-->
{% konnect_api_request %}
url: /v1/catalog-services/$AWS_SERVICE_ID/resources
method: GET
status_code: 200
region: us
{% endkonnect_api_request %}
<!--vale on-->
