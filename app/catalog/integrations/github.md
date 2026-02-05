---
title: "GitHub"
content_type: reference
layout: reference

products:
    - catalog
    - gateway
    
tags:
  - integrations
  - github

breadcrumbs:
  - /catalog/
  - /catalog/integrations/

works_on:
    - konnect
description: The GitHub integration allows you to associate your {{site.konnect_catalog}} service to one or more GitHub repositories. 
search_aliases:
  - service catalog
related_resources:
  - text: "{{site.konnect_catalog}}"
    url: /catalog/
  - text: Import and map GitHub resources in {{site.konnect_catalog}}
    url: /how-to/install-and-map-github-resources/
discovery_support: true
bindable_entities: "Repositories"
---

The GitHub integration allows you to associate your {{site.konnect_catalog}} service to one or more GitHub repositories.

For each linked repository, the UI can show a **Repository Summary** with simple data pulled from the GitHub API, such as the number of open issues, open pull requests, most recently closed pull requests, languages, and more.
{% include /catalog/multi-resource.md %}

For a complete tutorial using the {{site.konnect_short_name}} API, see [Import and map GitHub resources in {{site.konnect_catalog}}](/how-to/install-and-map-github-resources/).

## Authorize the GitHub integration

1. From the **Catalog** in {{site.konnect_short_name}}, select **[Integrations](https://cloud.konghq.com/us/service-catalog/integrations)**. 
2. Select **GitHub**, then **Add GitHub Instance**.
3. Select **Authorize**. 

This will take you to GitHub, where you can grant {{site.konnect_short_name}} access to either **All Repositories** or **Select repositories**. 

The {{site.konnect_short_name}} application can be managed from GitHub as a [GitHub Application](https://docs.github.com/en/apps/using-github-apps/authorizing-github-apps).

## Resources

Available GitHub entities:

<!--vale off-->
{% table %}
columns:
  - title: Entity
    key: entity
  - title: Description
    key: description
rows:
  - entity: Repository
    description: A GitHub repository relating to the {{site.konnect_catalog}} service.
{% endtable %}
<!--vale on-->

## Events

This integration supports events.

You can view the following event types for linked repositories from the {{site.konnect_short_name}} UI:

* Open pull request
* Merge pull request
* Close pull request


## Discovery information

<!-- vale off-->

{% include_cached catalog/service-catalog-discovery.md 
   discovery_support=page.discovery_support
   discovery_default=page.discovery_default
   bindable_entities=page.bindable_entities
   mechanism=page.mechanism %}

<!-- vale on-->