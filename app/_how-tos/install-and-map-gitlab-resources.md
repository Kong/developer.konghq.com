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
  q: How do I view a self-hosted GitLab project in Service Catalog?
  a: Authorize the GitLab integration in the {{site.konnect_short_name}} UI using self-hosted setup. Create a Service Catalog service and associate it with your project resource to display metadata and enable event tracking.
prereqs:
  inline:
    - title: GitLab access
      content: |
        You must have the **Owner** role in the GitLab group to authorize the integration. If you're using a self-hosted GitLab instance, it must be accessible from the public internet or is otherwise reachable by {{site.konnect_short_name}}.

        1. [Create a group-owned application](https://docs.gitlab.com/integrations/oauth_provider/) in your GitLab instance.
           * Set the redirect URI to:  
          `https://cloud.konghq.com/$KONNECT_REGION/service-catalog/integrations/gitlab`
           * Ensure the app has the `api` scope.
           * Be sure to copy your application ID and secret to use in {{site.konnect_short_name}}.

        1. Copy and save your GitLab self-hosted base URL, token endpoint, and auth endpoint. They should be in the following format:
           * **Base URL**: `https://$GITLAB_HOST/api/v4`
           * **Token Endpoint**: `https://$GITLAB_HOST/oauth/token`
           * **Authorization Endpoint**: `https://$GITLAB_HOST/oauth/authorize`
      icon_url: /assets/icons/gitlab.svg
---

## Authorize the self-managed GitLab integration

1. In the {{site.konnect_short_name}} UI, navigate to the [GitLab integration](https://cloud.konghq.com/service-catalog/integrations/gitlab/instances) and click **Add GitLab instance**.
1. Select **GitLab Dedicated or Self-managed**, and enter the full URL to your GitLab API in the **GitLab API Base URL** field, ending in `/api/v4`.  For example: `https://$GITLAB_HOST/api/v4`
1. Fill out the authorization fields using the values from your GitLab OAuth application:
   * Application ID: The Application ID from your GitLab app
   * Application Secret: The secret associated with your GitLab app
   * Token Endpoint: `https://$GITLAB_HOST/oauth/token`
   * Authorization Endpoint: `https://$GITLAB_HOST/oauth/authorize`
1. Click **Authorize** to complete the connection.
1. Name your instance `gitlab`.

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
