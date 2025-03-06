---
title: GitLab
content_type: reference
layout: reference

products:
    - gateway
breadcrumbs:
  - /service-catalog/
  - /service-catalog/integrations/

works_on:
    - konnect
description: The GitLab integration allows you to associate your Service Catalog Service to one or more [GitLab projects](https://docs.gitlab.com/ee/user/get_started/get_started_projects.html). 

related_resources:
  - text: "Service Catalog"
    url: /service-catalog/
discovery_support: true
bindable_entities: "Projects"
---
The GitLab integration allows you to associate your Service Catalog service to one or more [GitLab projects](https://docs.gitlab.com/ee/user/get_started/get_started_projects.html).

For each linked project, the UI can show a **Project Summary** with simple data pulled from the GitLab API, such as the number of open issues, open merge requests, contributors, languages, and latest releases.

## Prerequisites

* You need the [Owner GitLab role](https://docs.gitlab.com/ee/user/permissions.html) to authorize the integration. This is required for event ingestion.
* Only [GitLab.com subscriptions](https://docs.gitlab.com/ee/subscriptions/gitlab_com/) are supported at this time.

## Authorize the GitLab integration

1. From the **Service Catalog** in {{site.konnect_short_name}}, select **[Integrations](https://cloud.konghq.com/us/service-catalog/integrations)**. 
2. Select **GitLab**, then **Install GitLab**.
3. Click **Authorize**. 

## Resources

Entity  | Description
-------|-------------
Projects | Organizes all the data for a specific development project that relates to a Service Catalog Service.

## Events

This integration supports events.

You can view the following event types for linked projects from the {{site.konnect_short_name}} UI:

* Opened merge requests
* Merged merge requests


## Discovery information

<!-- vale off-->

{% include_cached service-catalog/service-catalog-discovery.html 
   discovery_support=page.discovery_support
   discovery_default=page.discovery_default
   bindable_entities=page.bindable_entities
   mechanism=page.mechanism %}

<!-- vale on-->