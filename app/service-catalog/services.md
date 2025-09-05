---
title: "Service Catalog services"
content_type: reference
layout: reference

products:
    - service-catalog
works_on:
  - konnect

description: Learn about services in Service Catalog and how to configure them.

breadcrumbs:
  - /service-catalog/

related_resources:
  - text: "Service Catalog"
    url: /service-catalog/
  - text: Scorecards
    url: /service-catalog/scorecards/
  - text: Traceable integration
    url: /service-catalog/integrations/traceable/
  - text: GitHub integration
    url: /service-catalog/integrations/github/
  - text: GitLab integration
    url: /service-catalog/integrations/gitlab/
  - text: SwaggerHub integration
    url: /service-catalog/integrations/swaggerhub/
  - text: Datadog integration
    url: /service-catalog/integrations/datadog/
  - text: PagerDuty integration
    url: /service-catalog/integrations/pagerduty/
faqs:
  - q: What's the difference between a Gateway Service and a Service Catalog service?
    a: |
      A [Gateway Service](/gateway/entities/service/) is a {{site.base_gateway}} entity that represents an upstream service in your system and is the business logic component that's responsible for responding to requests. A Service Catalog service is a collection of one or more resources from Service Catalog integrations.
---

A Service Catalog service is a collection of one or more resources from integrations.

A Service Catalog service represents the following:
* A unit of software that is typically owned by a single team
* Exposes one or more APIs 
* May be dependent on other Service Catalog services (as either upstream or downstream)  

Service Catalog services allow you to gain visibility into all resources in your organization, including what teams or people own them. 

To create a Service Catalog service, do one of the following:

{% navtabs "service" %}
{% navtab "UI" %}
1. In the {{site.konnect_short_name}} UI, navigate to **Service Catalog** > **Services** in the sidebar. 
1. Click **New service** and configure the details about your service. 
1. Map the service to an integration: 
   1. Click the service.
   1.  Select "Map resources" from the **Action** dropdown menu.
{% endnavtab %}
{% navtab "API" %}
1. Create a Service Catalog service by sending a POST request to the [`/catalog-services` endpoint](/api/konnect/service-catalog/v1/#/operations/create-catalog-service):
<!--vale off-->
{% capture service %}
{% konnect_api_request %}
url: /v1/catalog-services
method: POST
status_code: 201
region: us
body:
  name: billing
  display_name: Billing Service
{% endkonnect_api_request %}
{% endcapture %}

{{ service | indent: 3 }}
<!--vale on-->

1. Map a resource to the service by sending a POST request to the [`/resource-mappings` endpoint](/api/konnect/service-catalog/v1/#/operations/create-resource-mapping):
<!--vale off-->
{% capture resource %}
{% konnect_api_request %}
url: /v1/resource-mappings
method: POST
status_code: 201
region: us
body:
  service: billing
  resource: $INTEGRATION_RESOURCE_ID
{% endkonnect_api_request %}
{% endcapture %}

{{ resource | indent: 3 }}
<!--vale on-->
{% endnavtab %}
{% navtab "Terraform" %}
Use the [`konnect_catalog_service`](https://github.com/Kong/terraform-provider-konnect/blob/main/examples/resources/catalog_service.tf) resource:
```hcl
echo '
resource "konnect_catalog_service" "my_catalogservice" {
  name         = "billing"
  display_name = "Billing Service"
  description  = "Billing Service for the app"
  custom_fields = jsonencode({
    "cost_center" : "eng",
    "owner" : "Amal",
    "product_manager" : "Ariel",
    "dashboard" : {
      "name" : "Example Dashboard",
      "link" : "https://app.example.com/dashboard/123",
    },
    "git_repo" : {
      "name" : "example-repo",
      "link" : "https://github.com/example/repo",
    },
    "jira_project" : null,
    "slack_channel" : {
      "name" : "test-channel",
      "link" : "https://example.slack.com/archives/C098WKDB020"
    },
  })

  labels = {
    key = "value"
  }
}
' >> main.tf
```
{% endnavtab %}
{% endnavtabs %}

