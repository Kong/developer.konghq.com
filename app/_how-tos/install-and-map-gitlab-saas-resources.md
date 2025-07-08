---
title: Install and map SaaS GitLab resources in Service Catalog
content_type: how_to
description: Learn how to connect a SaaS GitLab project to your Service Catalog service in {{site.konnect_short_name}}.
products:
  - service-catalog
  - gateway
works_on:
  - konnect
tags:
  - integrations
  - gitlab
related_resources:
  - text: Catalog
    url: /service-catalog/
  - text: GitLab reference
    url: /service-catalog/integrations/gitlab/
tldr:
  q: How do I connect a SaaS GitLab project to my {{site.konnect_catalog}} service?
  a: Authorize the SaaS GitLab integration in {{site.konnect_short_name}}, then link your project to display metadata and enable event tracking.
prereqs:
  inline:
    - title: SaaS GitLab access
      content: |
        You must have a [GitLab.com subscriptions](https://docs.gitlab.com/ee/subscriptions/gitlab_com/) and the **Owner** role in the GitLab group to authorize the integration. You need a project in GitLab that you want to pull in to {{site.konnect_short_name}}.
      icon_url: /assets/icons/gitlab.svg
---

## Authorize the GitLab integration

1. From the **Service Catalog** in {{site.konnect_short_name}}, select **[Integrations](https://cloud.konghq.com/us/service-catalog/integrations)**.
2. Click **GitLab**, then click **Add GitLab instance**.
3. Select **GitLab (SaaS)**, authorize GitLab to connect your account, and enter `gitlab` for your instance name.

## Create a service in Service Catalog

Create a service that you'll map to your GitLab resources:

<!--vale off-->
{% konnect_api_request %}
url: /v1/service-catalog/services
method: POST
status_code: 201
region: us
headers:
  - 'Accept: application/json, application/problem+json'
  - 'Content-Type: application/json'
body:
  name: billing
  display_name: Billing Service
{% endkonnect_api_request %}
<!--vale on-->

Export the service ID:

```sh
export GITLAB_SERVICE_ID='YOUR-SERVICE-ID'
```

## List GitLab resources

Before you can map your GitLab resources to a service in Service Catalog, you first need to find the resources that are pulled in from GitLab:

<!--vale off-->
{% konnect_api_request %}
url: /v1/service-catalog/resources?filter%5Bintegration.name%5D=gitlab
method: GET
region: us
status_code: 200
headers:
  - 'Accept: application/json, application/problem+json'
  - 'Content-Type: application/json'
{% endkonnect_api_request %}
<!--vale on-->

Export the resource ID you want to map to the service:

```sh
export GITLAB_RESOURCE_ID='YOUR-RESOURCE-ID'
```

## Map resources to a service

Now, you can map the GitLab resource to the service:

<!--vale off-->
{% konnect_api_request %}
url: /v1/service-catalog/resource-mappings
method: POST
status_code: 201
region: us
headers:
  - 'Accept: application/json, application/problem+json'
  - 'Content-Type: application/json'
body:
  service: billing
  resource: $GITLAB_RESOURCE_ID
{% endkonnect_api_request %}
<!--vale on-->


## Validate the mapping

To confirm that the GitLab resource is now mapped to the intended service, list the service’s mapped resources:

<!--vale off-->
{% konnect_api_request %}
url: /v1/service-catalog/services/$GITLAB_SERVICE_ID/resources
method: GET
status_code: 200
region: global
headers:
  - 'Accept: application/json'
{% endkonnect_api_request %}
<!--vale on-->
