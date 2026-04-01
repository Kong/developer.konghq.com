---
title: Install and map SaaS GitLab resources in Catalog
permalink: /how-to/install-and-map-gitlab-saas-resources/
content_type: how_to
description: Learn how to connect a SaaS GitLab project to your {{site.konnect_catalog}} service in {{site.konnect_short_name}}.
products:
  - catalog
works_on:
  - konnect
tools:
  - konnect-api
tags:
  - integrations
  - gitlab
search_aliases:
  - service catalog
related_resources:
  - text: "{{site.konnect_catalog}}"
    url: /catalog/
  - text: Integrations
    url: /catalog/integrations/
  - text: GitLab reference
    url: /catalog/integrations/gitlab/
  - text: Install and map self-hosted GitLab resources in {{site.konnect_catalog}}
    url: /how-to/install-and-map-gitlab-resources/
automated_tests: false
tldr:
  q: How do I view a SaaS GitLab project in {{site.konnect_catalog}}?
  a: Install and authorize the SaaS GitLab integration in the {{site.konnect_short_name}} UI. Create a {{site.konnect_catalog}} service and associate it with your GitLab project to display metadata and enable event tracking.
prereqs:
  inline:
    - title: "{{site.konnect_short_name}} roles"
      include_content: prereqs/service-catalog-integration-role
      icon_url: /assets/icons/kogo-white.svg
    - title: SaaS GitLab access
      content: |
        You must have a [GitLab.com subscriptions](https://docs.gitlab.com/ee/subscriptions/gitlab_com/) and the **Owner** role in the GitLab group to authorize the integration. You need a project in GitLab that you want to pull in to {{site.konnect_short_name}}.
      icon_url: /assets/icons/gitlab.svg
---

## Authorize the GitLab integration

1. From the **Catalog** in {{site.konnect_short_name}}, select **[Integrations](https://cloud.konghq.com/us/service-catalog/integrations)**.
2. Click **GitLab**, then click **Add GitLab instance**.
3. Select **GitLab (SaaS)**, authorize GitLab to connect your account, and enter `gitlab` for your instance name.

## Create a service in {{site.konnect_catalog}}

Create a service that you'll map to your GitLab resources:

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
export GITLAB_SERVICE_ID='YOUR-SERVICE-ID'
```

## List GitLab resources

Before you can map your GitLab resources to a service in {{site.konnect_catalog}}, you first need to find the resources that are pulled in from GitLab:

<!--vale off-->
{% konnect_api_request %}
url: /v1/resources?filter%5Bintegration.name%5D=gitlab
method: GET
region: us
status_code: 200
{% endkonnect_api_request %}
<!--vale on-->

{:.info}
> You might need to manually sync your GitLab integration for resources to appear. From the {{site.konnect_short_name}} UI by navigating to the GitLab integration you just installed and selecting **Sync Now** from the **Actions** dropdown menu.

Export the resource ID you want to map to the service:

```sh
export GITLAB_RESOURCE_ID='YOUR-RESOURCE-ID'
```

## Map resources to a service

Now, you can map the GitLab resource to the service:

<!--vale off-->
{% konnect_api_request %}
url: /v1/resource-mappings
method: POST
status_code: 201
region: us
body:
  service: billing
  resource: $GITLAB_RESOURCE_ID
{% endkonnect_api_request %}
<!--vale on-->


## Validate the mapping

To confirm that the GitLab resource is now mapped to the intended service, list the service’s mapped resources:

<!--vale off-->
{% konnect_api_request %}
url: /v1/catalog-services/$GITLAB_SERVICE_ID/resources
method: GET
status_code: 200
region: us
{% endkonnect_api_request %}
<!--vale on-->
