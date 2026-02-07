---
title: Install and map GitHub resources in Catalog
permalink: /how-to/install-and-map-github-resources/
content_type: how_to
description: Learn how to connect a GitHub repository to your {{site.konnect_catalog}} service in {{site.konnect_short_name}}.
products:
  - catalog
works_on:
  - konnect
tools:
  - konnect-api
search_aliases:
  - service catalog
tags:
  - integrations
  - github
related_resources:
  - text: "{{site.konnect_catalog}}"
    url: /catalog/
  - text: Integrations
    url: /catalog/integrations/
  - text: GitHub reference
    url: /catalog/integrations/github/
automated_tests: false
tldr:
  q: How do I connect a GitHub repository to my {{site.konnect_catalog}} service?
  a: Install the GitHub integration in {{site.konnect_short_name}} and authorize access to one or more repositories, then link a repository to your {{site.konnect_catalog}} service to display metadata and enable event tracking.
prereqs:
  inline:
    - title: "{{site.konnect_short_name}} roles"
      include_content: prereqs/service-catalog-integration-role
      icon_url: /assets/icons/kogo-white.svg
    - title: GitHub access
      content: |
        To integrate GitHub with {{site.konnect_catalog}}, you need the following:
        * Sufficient permissions in GitHub to authorize third-party applications and install the {{site.konnect_short_name}} GitHub App
        * A GitHub organization
        * A repository that you want to pull in to {{site.konnect_short_name}}. You can grant access to either all repositories or selected repositories during the authorization process. 
        
        The {{site.konnect_short_name}} app can be managed in your GitHub account under **Applications > GitHub Apps**.
      icon_url: /assets/icons/github.svg
---

## Install and authorize the GitHub integration

1. From the **Catalog** in {{site.konnect_short_name}}, select **[Integrations](https://cloud.konghq.com/us/service-catalog/integrations)**. 
2. Click **GitHub**, then click **Add GitHub Instance**.
3. Authorize the GitHub integration. This will take you to GitHub, where you can grant {{site.konnect_short_name}} access to either **All Repositories** or **Select repositories**. 
1. Enter `github` as your instance name.

The {{site.konnect_short_name}} application can be managed from GitHub as a [GitHub Application](https://docs.github.com/en/apps/using-github-apps/authorizing-github-apps).

## Create a service in {{site.konnect_catalog}}

Create a service that you'll map to your GitHub resources:

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
export GITHUB_SERVICE_ID='YOUR-SERVICE-ID'
```

## List GitHub resources

Before you can map your GitHub resources to a service in {{site.konnect_catalog}}, you first need to find the resources that are pulled in from GitHub:

<!--vale off-->
{% konnect_api_request %}
url: /v1/resources?filter%5Bintegration.name%5D=github
method: GET
region: us
status_code: 200
{% endkonnect_api_request %}
<!--vale on-->

{:.info}
> You might need to manually sync your GitHub integration for resources to appear. From the {{site.konnect_short_name}} UI by navigating to the GitHub integration you just installed and selecting **Sync Now** from the **Actions** dropdown menu.

Export the resource ID you want to map to the service:

```sh
export GITHUB_RESOURCE_ID='YOUR-RESOURCE-ID'
```

## Map resources to a service

Now, you can map the GitHub resource to the service:

<!--vale off-->
{% konnect_api_request %}
url: /v1/resource-mappings
method: POST
status_code: 201
region: us
body:
  service: billing
  resource: $GITHUB_RESOURCE_ID
{% endkonnect_api_request %}
<!--vale on-->


## Validate the mapping

To confirm that the GitHub resource is now mapped to the intended service, list the service’s mapped resources:

<!--vale off-->
{% konnect_api_request %}
url: /v1/catalog-services/$GITHUB_SERVICE_ID/resources
method: GET
status_code: 200
region: us
{% endkonnect_api_request %}
<!--vale on-->
