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
  - /catalog-classic/
  - /catalog/integrations/

works_on:
    - konnect

description: The GitLab integration allows you to associate your {{site.konnect_catalog}} Classic Service to one or more GitLab projects
search_aliases:
  - service catalog
related_resources:
  - text: "{{site.konnect_catalog}} Classic"
    url: /catalog-classic/
  - text: Integrations
    url: /catalog/integrations/
  - text: Import and map SaaS GitLab resources in {{site.konnect_catalog}}
    url: /how-to/install-and-map-gitlab-saas-resources/
faqs:
  - q: |
      {% include faqs/gitlab-self-managed-removed.md section='question' %}
    a: |
      {% include faqs/gitlab-self-managed-removed.md section='answer' %}
discovery_support: true
bindable_entities: "Projects"
---

{% include_cached catalog/catalog-classic-banner.md %}

The GitLab integration allows you to associate your {{site.konnect_catalog}} Classic service to one or more [GitLab projects](https://docs.gitlab.com/ee/user/get_started/get_started_projects.html).
{% include /catalog/multi-resource.md %}

For each linked project, the UI can show a **Project Summary** with simple data pulled from the GitLab API, such as the number of open issues, open merge requests, contributors, languages, and latest releases.

For a complete tutorial using the {{site.konnect_short_name}} API, see [Import and map SaaS GitLab resources in {{site.konnect_catalog}} Classic](/how-to/install-and-map-gitlab-saas-resources/).

## Prerequisites

* You need the [Owner GitLab role](https://docs.gitlab.com/ee/user/permissions.html) to authorize the integration. This is required for event ingestion.
* Only [GitLab.com subscriptions](https://docs.gitlab.com/ee/subscriptions/gitlab_com/) are supported. Self-managed GitLab isn't supported.

## Authorize the GitLab integration

1. From the **Catalog** in {{site.konnect_short_name}}, select **Integrations**. 
1. Select **GitLab**, then **Install GitLab**.
1. Click **Authorize**. 

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
    description: "Organizes all the data for a specific development project that relates to a {{site.konnect_catalog}} Classic service."
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
