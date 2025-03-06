---
title: "GitHub"
content_type: reference
layout: reference

products:
    - gateway
breadcrumbs:
  - /service-catalog/
  - /service-catalog/service-catalog-integrations/

works_on:
    - konnect
description: The GitHub integration allows you to associate your Service Catalog Service to one or more GitHub repositories. 

related_resources:
  - text: "Service Catalog"
    url: /service-catalog/
discovery_support: true
bindable_entities: "Repositories"
---

The GitHub integration allows you to associate your Service Catalog service to one or more GitHub repositories.

For each linked repository, the UI can show a **Repository Summary** with simple data pulled from the GitHub API, such as the number of open issues, open pull requests, most recently closed pull requests, languages, and more.

## Authorize the GitHub integration

1. From the **Service Catalog** in {{site.konnect_short_name}}, select **[Integrations](https://cloud.konghq.com/us/service-catalog/integrations)**. 
2. Select **GitHub**, then **Install Github**.
3. Select **Authorize**. 


This will take you to GitHub, where you can grant {{site.konnect_short_name}} access to either **All Repositories** or **Select repositories**. 

The {{site.konnect_short_name}} application can be managed from GitHub as a [GitHub Application](https://docs.github.com/en/apps/using-github-apps/authorizing-github-apps).

## Resources

Available GitHub entities:


Entity  | Description
-------|-------------
Repository | A GitHub repository relating to the Service Catalog Service

## Events

This integration supports events.

You can view the following event types for linked repositories from the {{site.konnect_short_name}} UI:

* Open pull request
* Merge pull request
* Close pull request


## Discovery information

<!-- vale off-->

{% include_cached service-catalog/service-catalog-discovery.html 
   discovery_support=page.discovery_support
   discovery_default=page.discovery_default
   bindable_entities=page.bindable_entities
   mechanism=page.mechanism %}

<!-- vale on-->