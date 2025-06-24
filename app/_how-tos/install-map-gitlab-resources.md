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

## Initialize a GitLab resource

Create a placeholder resource using the Datadog integration instance. The resource will be hydrated automatically by the integration.

<!--vale off-->
{% konnect_api_request %}
url: /v1/integration-instances/{integrationInstanceId}/resources
method: POST
status_code: 201
region: us
headers:
  - 'Accept: application/json'
  - 'Content-Type: application/json'
body:
  type: GitLab???
  config:
    id: ???
{% endkonnect_api_request %}
<!--vale on-->

* Replace `{integrationInstanceId}` with the ID of your Datadog integration instance.
* The `type` value must match the Datadog-defined resource type.
* The `config` object must include the identifying metadata for the resource (e.g., `monitor_id`).

## Confirm the GitLab resource

After initialization, you can fetch the resource by ID and confirm the `attributes` field is no longer null:

<!--vale off-->
{% konnect_api_request %}
url: /v1/resources/{resourceId}
method: GET
status_code: 200
region: us
headers:
  - 'Accept: application/json'
{% endkonnect_api_request %}
<!--vale on-->

## Map the resource to a service

Once the resource is activated, map it to an existing service in the Service Catalog.

<!--vale off-->
{% konnect_api_request %}
url: /v1/resource-mappings
method: POST
status_code: 201
region: global
headers:
  - 'Accept: application/json'
  - 'Content-Type: application/json'
body:
  service: my-service-name
  resource:
    integration_instance: GitLab???
    type: GitLab??
    config:
      monitor_id: 112233
{% endkonnect_api_request %}
<!--vale on-->

* You can also use the resource's `id` directly instead of providing the config again.


### Validate the mapping

To confirm that the Datadog monitor is now mapped to the intended service, list the service’s mapped resources:

<!--vale off-->
{% konnect_api_request %}
url: /v1/services/{serviceId}/resources
method: GET
status_code: 200
region: global
headers:
  - 'Accept: application/json'
{% endkonnect_api_request %}
<!--vale on-->

