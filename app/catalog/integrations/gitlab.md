---
title: GitLab
content_type: reference
layout: reference

products:
    - catalog
    - gateway
tags:
  - integrations
  - gitlab

breadcrumbs:
  - /catalog/
  - /catalog/integrations/

works_on:
    - konnect

description: The GitLab integration allows you to associate your {{site.konnect_catalog}} Service to one or more GitLab projects
search_aliases:
  - service catalog
related_resources:
  - text: "{{site.konnect_catalog}}"
    url: /catalog/
  - text: Integrations
    url: /catalog/integrations/
  - text: Import and map self-managed GitLab resources in {{site.konnect_catalog}}
    url: /how-to/install-and-map-gitlab-resources/
  - text: Import and map SaaS GitLab resources in {{site.konnect_catalog}}
    url: /how-to/install-and-map-gitlab-saas-resources/
discovery_support: true
bindable_entities: "Projects"
---
The GitLab integration allows you to associate your {{site.konnect_catalog}} service to one or more [GitLab projects](https://docs.gitlab.com/ee/user/get_started/get_started_projects.html).
{% include /catalog/multi-resource.md %}

For each linked project, the UI can show a **Project Summary** with simple data pulled from the GitLab API, such as the number of open issues, open merge requests, contributors, languages, and latest releases.

For a complete tutorial using the {{site.konnect_short_name}} API, see the following:
* [Import and map self-managed GitLab resources in {{site.konnect_catalog}}](/how-to/install-and-map-gitlab-resources/)
* [Import and map SaaS GitLab resources in {{site.konnect_catalog}}](/how-to/install-and-map-gitlab-saas-resources/)

## Prerequisites

* You need the [Owner GitLab role](https://docs.gitlab.com/ee/user/permissions.html) to authorize the integration. This is required for event ingestion.
* Only [GitLab.com subscriptions](https://docs.gitlab.com/ee/subscriptions/gitlab_com/) are supported at this time.
* If you're using a self-hosted GitLab instance, it must be accessible from the public internet or is otherwise reachable by {{site.konnect_short_name}}. For more information, review the {{site.konnect_short_name}} hostnames [documentation](/konnect-platform/network/#hostnames)

## Authorize the GitLab integration
{% navtabs "Authorize" %}
{% navtab "Self-Managed" %}
To use the GitLab integration in a self-hosted environment:

1. [Create a group-owned application](https://docs.gitlab.com/integration/oauth_provider/#create-a-group-owned-application) in your GitLab instance. This is required to enable OAuth access for your organization.
   * Set the redirect URI in GitLab to `https://cloud.konghq.com/$KONNECT_REGION/service-catalog/integrations/gitlab`
   * Make sure the application has the `api` scope.
1. In the {{site.konnect_short_name}} UI, navigate to the [GitLab integration](https://cloud.konghq.com/service-catalog/integrations/gitlab/configuration)
1. In the **GitLab API Base URL** field, enter the full URL to your GitLab API, ending in `/api/v4`.  
   For example: `https://gitlab.example.com/api/v4`
1. Fill out the authorization fields using the values from your GitLab OAuth application:
   * Application ID: The Application ID from your GitLab app
   * Application Secret: The secret associated with your GitLab app
   * Token Endpoint: `https://$GITLAB_HOST/oauth/token`
   * Authorization Endpoint: `https://$GITLAB_HOST/oauth/authorize`
1. Click **Authorize** to complete the connection.
{% endnavtab %}
{% navtab "SaaS" %}
1. From the **Catalog** in {{site.konnect_short_name}}, select **[Integrations](https://cloud.konghq.com/us/service-catalog/integrations)**. 
1. Select **GitLab**, then **Install GitLab**.
1. Click **Authorize**. 
{% endnavtab %}
{% endnavtabs %}
## Resources

<!--vale off-->
{% table %}
columns:
  - title: Entity
    key: entity
  - title: Description
    key: description
rows:
  - entity: Projects
    description: "Organizes all the data for a specific development project that relates to a {{site.konnect_catalog}} service."
{% endtable %}
<!--vale on-->

## Events

This integration supports events.

You can view the following event types for linked projects from the {{site.konnect_short_name}} UI:

* Opened merge requests
* Merged merge requests


## Discovery information

<!-- vale off-->

{% include_cached catalog/service-catalog-discovery.md 
   discovery_support=page.discovery_support
   discovery_default=page.discovery_default
   bindable_entities=page.bindable_entities
   mechanism=page.mechanism %}

<!-- vale on-->
