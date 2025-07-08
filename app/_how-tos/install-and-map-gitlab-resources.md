---
title: Install and map self-hosted GitLab resources in Service Catalog
content_type: how_to
description: Learn how to connect a GitLab project to your Service Catalog service in {{site.konnect_short_name}}.
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
        You must have the **Owner** role in the GitLab group to authorize the integration. If you're using a self-hosted GitLab instance, it must be accessible from the public internet or is otherwise reachable by {{site.konnect_short_name}}.

        1. [Create a group-owned application](https://docs.gitlab.com/integrations/oauth_provider/) in your GitLab instance.
           - Set the redirect URI to:  
          `https://cloud.konghq.com/$KONNECT_REGION/service-catalog/integration/gitlab`
           - Ensure the app has the `api` scope.

        1. Export your self-hosted GitLab variables:
           ```sh
           export GITLAB_BASE_URL='YOUR-BASE-URL'
           export GITLAB_APP_ID='YOUR-APP_ID
           export GITLAB_APP_SECRET='YOUR-APP_SECRET
           export GITLAB_TOKEN_ENDPOINT='YOUR-TOKEN_ENDPOINT'
           export GITLAB_AUTH_ENDPOINT='YOUR-AUTH_ENDPOINT'
           ```
           They should be in the following format:
           * **Base URL**: `https://$GITLAB_HOST/api/v4`
           * **Token Endpoint**: `https://$GITLAB_HOST/oauth/token`
           * **Authorization Endpoint**: `https://$GITLAB_HOST/oauth/authorize`
      icon_url: /assets/icons/gitlab.svg
---

## Authorize the Self-managed GitLab integration

Before you can ingest resources from GitLab, you must first install and authorize the GitLab integration.

First, install the GitLab integration:

<!--vale off-->
{% konnect_api_request %}
url: /v1/service-catalog/integration-instances
method: POST
status_code: 201
region: us
headers:
  - 'Accept: application/json'
  - 'Content-Type: application/json'
body:
  integration_name: gitlab
  name: gitlab-self-managed
  display_name: GitLab
  config:
    base_url: $GITLAB_BASE_URL
{% endkonnect_api_request %}
<!--vale on-->

Export the ID of your GitLab integration:

```sh
export GITLAB_INTEGRATION_ID='YOUR-INTEGRATION-ID'
```

Next, authorize the GitLab integration with your GitLab API key:

<!--vale off-->
{% konnect_api_request %}
url: /v1/service-catalog/integration-instances/$GITLAB_INTEGRATION_ID/auth-config
method: PUT
status_code: 201
region: us
headers:
  - 'Accept: application/json, application/problem+json'
  - 'Content-Type: application/json'
body:
  type: oauth
  client_id: $GITLAB_APP_ID
  client_secret: $GITLAB_APP_SECRET
  authorization_endpoint: $GITLAB_AUTH_ENDPOINT
  token_endpoint: $GITLAB_TOKEN_ENDPOINT
{% endkonnect_api_request %}
<!--vale on-->

Once authorized, resources from your GitLab account will be discoverable in the UI.

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
