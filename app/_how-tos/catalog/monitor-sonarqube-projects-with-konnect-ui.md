---
title: Monitor SonarQube projects in Catalog with the {{site.konnect_short_name}} UI
permalink: /how-to/monitor-sonarqube-projects-with-konnect-ui/
content_type: how_to
description: Learn how to connect a SonarQube project to your {{site.konnect_catalog}} service in {{site.konnect_short_name}} using the UI.
products:
  - catalog
works_on:
  - konnect
tags:
  - integrations
  - sonarqube
search_aliases:
  - project
  - service catalog
related_resources:
  - text: "{{site.konnect_catalog}}"
    url: /catalog/
  - text: Integrations
    url: /catalog/integrations/
  - text: SonarQube reference
    url: /catalog/integrations/sonarqube/
  - text: "Monitor SonarQube projects {{site.konnect_catalog}} with the {{site.konnect_short_name}} API"
    url: /how-to/monitor-sonarqube-projects-with-konnect-api/
automated_tests: false
tldr:
  q: How do I monitor SonarQube projects in {{site.konnect_short_name}}?
  a: Install the SonarQube integration in {{site.konnect_short_name}} and authorize access with your SonarQube personal access token, then link a project to your {{site.konnect_catalog}} service.
prereqs:
  inline:
    - title: "{{site.konnect_short_name}} roles"
      include_content: prereqs/service-catalog-integration-role
      icon_url: /assets/icons/kogo-white.svg
    - title: SonarQube
      content: |
        You need to configure the following in [SonarQube Cloud](https://www.sonarsource.com/products/sonarcloud/):
        * A [SonarQube personal access token](https://docs.sonarsource.com/sonarqube-cloud/managing-your-account/managing-tokens).

        {:.warning}
        > SonarQube Server isn't supported.
      icon_url: /assets/icons/third-party/sonarqube.svg
---

## Configure the SonarQube integration

Before you can discover [SonarQube projects](https://docs.sonarsource.com/sonarqube-cloud/managing-your-projects) in {{site.konnect_catalog}}, you must configure the SonarQube integration.

1. In the {{site.konnect_short_name}} sidebar, click **Catalog**.
1. In the Catalog sidebar, click **[Integrations](https://cloud.konghq.com/us/service-catalog/integrations)**. 
1. Click **SonarQube**.
1. Click **Add SonarQube instance**.
1. In the **SonarQube API key** field, enter your SonarQube personal access token.
1. In the **Display name** field, enter `SonarQube`.
1. In the **Instance name** field, enter `sonarqube`.
1. Click **Save**.

## Create a {{site.konnect_catalog}} service and map the SLO resources

Now that your integration is configured, you can create a {{site.konnect_catalog}} service to map the ingested projects.

{:.info}
> In this tutorial, we'll refer to your ingested SonarQube project as `billing-project`.

1. In the {{site.konnect_short_name}} sidebar, click [**{{site.konnect_catalog}}**](https://cloud.konghq.com/service-catalog/).
1. In the Catalog sidebar, click **Services**.
1. Click **New service**.
1. In the **Display Name** field, enter `Billing Service`.
1. In the **Name** field, enter `billing-service`.
1. Click **Create**.
1. Click **Map Resources**.
1. Select `billing-project`. 
1. Click **Map 1 Resource**.

Your integration projects are now discoverable from one {{site.konnect_catalog}} service.

{:.info}
> You may need to manually sync your SonarQube integration for resources to appear. From the {{site.konnect_short_name}} UI by navigating to the SonarQube integration you just installed and selecting **Sync Now** from the **Actions** dropdown menu.

## Validate the mapping

To confirm that the SonarQube resource is now mapped to the intended service, navigate to the service:

1. In the {{site.konnect_short_name}} sidebar, click [**{{site.konnect_catalog}}**](https://cloud.konghq.com/service-catalog/).
1. In the {{site.konnect_catalog}} sidebar, click **Services**.
1. Click the **Billing Service** service.
1. Click the **Resources** tab.

You should see the `billing-project` resource listed.
