---
title: Install and map GitHub entities
content_type: how_to
description: Learn how to connect a GitHub repository to your {{site.konnect_catalog}} service in {{site.konnect_short_name}}.
permalink: /service-catalog/integration//install-map-github-entities
products:
  - service-catalog
  - gateway
works_on:
  - konnect
tags:
  - integrations
  - github
related_resources:
  - text: Catalog
    url: /service-catalog/
  - text: GitHub reference
    url: /service-catalog/integrations/github/
tldr:
  q: How do I connect a GitHub repository to my {{site.konnect_catalog}} service?
  a: Install the GitHub integration in {{site.konnect_short_name}} and authorize access to one or more repositories, then link a repository to your {{site.konnect_catalog}} service to display metadata and enable event tracking.
prereqs:
  inline:
    - title: GitHub access
      content: |
        You must have sufficient permissions in GitHub to authorize third-party applications and install the {{site.konnect_short_name}} GitHub App.

        You can grant access to either all repositories or selected repositories during the authorization process. The {{site.konnect_short_name}} app can be managed in your GitHub account under **Applications > GitHub Apps**.
      icon_url: /assets/icons/github.svg
---

## Authorize the GitHub integration

1. In {{site.konnect_short_name}}, go to **{{site.konnect_catalog}} > Integrations**.
2. Click **GitHub**, then **Install GitHub**.
3. Click **Authorize** to connect your GitHub account.

You'll be redirected to GitHub, where you can choose to authorize access to **All Repositories** or to **Select repositories**.

Once authorized, you can manage the {{site.konnect_short_name}} GitHub App from your GitHub account:  
[Manage GitHub Applications](https://docs.github.com/en/apps/using-github-apps/authorizing-github-apps)

## Initialize a Github resource

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
  type: github???
  config:
    id: ???
{% endkonnect_api_request %}
<!--vale on-->

* Replace `{integrationInstanceId}` with the ID of your Datadog integration instance.
* The `type` value must match the Datadog-defined resource type.
* The `config` object must include the identifying metadata for the resource (e.g., `monitor_id`).

## Confirm the Github resource

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
    integration_instance: github???
    type: github??
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

