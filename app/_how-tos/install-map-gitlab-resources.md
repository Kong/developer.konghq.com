---
title: Install and map GitLab entities
content_type: how_to
description: Learn how to connect a GitLab project to your Service Catalog service in {{site.konnect_short_name}}.
permalink: /service-catalog/integration/install-map-gitlab-entities
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
  q: How do I connect a GitLab project to my {{site.konnect_catalog}} service?
  a: Authorize the GitLab integration in {{site.konnect_short_name}} using either the SaaS or self-hosted setup, then link your project to display metadata and enable event tracking.
prereqs:
  inline:
    - title: GitLab access
      content: |
        You must have the **Owner** role in the GitLab group to authorize the integration. Only [GitLab.com subscriptions](https://docs.gitlab.com/ee/subscriptions/gitlab_com/) are currently supported.

        If you're using a self-hosted GitLab instance, it must be accessible from the public internet or is otherwise reachable by {{site.konnect_short_name}}.
      icon_url: /assets/icons/gitlab.svg
---

## Authorize the GitLab integration

Choose one of the following authorization flows depending on whether you use GitLab SaaS or self-managed GitLab:

{% navtabs "Authorization" %}
{% navtab "SaaS" %}
### SaaS GitLab

1. In {{site.konnect_short_name}}, go to **{{site.konnect_catalog}} > Integrations**.
2. Click **GitLab**, then **Install GitLab**.
3. Click **Authorize** to connect your GitLab account.

{% endnavtab %}
{% navtab "Self-managed" %}
### Self-managed GitLab

1. [Create a group-owned application](https://docs.gitlab.com/integrations/oauth_provider/) in your GitLab instance.
   - Set the redirect URI to:  
     `https://cloud.konghq.com/$KONNECT_REGION/service-catalog/integration/gitlab`
   - Ensure the app has the `api` scope.
2. In {{site.konnect_short_name}}, go to the [GitLab integration config page](https://cloud.konghq.com/service-catalog/integrations/gitlab/configuration).
3. Fill in the following fields using values from your GitLab OAuth app:
   - **GitLab API Base URL**: e.g., `https://gitlab.example.com/api/v4`
   - **Application ID**
   - **Application Secret**
   - **Token Endpoint**: `https://$GITLAB_HOST/oauth/token`
   - **Authorization Endpoint**: `https://$GITLAB_HOST/oauth/authorize`
4. Click **Authorize** to complete the connection.
{% endnavtab %}
{% endnavtabs %}

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
  service: datadog
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
