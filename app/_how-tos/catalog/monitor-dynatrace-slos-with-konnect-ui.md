---
title: Monitor Dynatrace classic SLOs in Catalog with the Konnect UI
permalink: /how-to/monitor-dynatrace-slos-with-konnect-ui/
content_type: how_to
description: Learn how to connect a Dynatrace classic SLO to your {{site.konnect_catalog}} service in {{site.konnect_short_name}} using the UI.
products:
  - catalog
works_on:
  - konnect
tags:
  - integrations
  - dynatrace
search_aliases:
  - classic service-level object
  - SLO
  - service catalog
related_resources:
  - text: "{{site.konnect_catalog}}"
    url: /catalog/
  - text: Integrations
    url: /catalog/integrations/
  - text: Dynatrace reference
    url: /catalog/integrations/dynatrace/
  - text: "Monitor Dynatrace classic SLOs {{site.konnect_catalog}} with the {{site.konnect_short_name}} API"
    url: /how-to/monitor-dynatrace-slos-with-konnect-api/
  - text: Set up Dynatrace with OpenTelemetry
    url: /how-to/set-up-dynatrace-with-otel/
automated_tests: false
tldr:
  q: How do I monitor Dynatrace classic service-level objects in {{site.konnect_short_name}}?
  a: Install the Dynatrace integration in {{site.konnect_short_name}} and authorize access with your Dynatrace URL and personal access token (with `slo.read` permissions), then link an SLO to your {{site.konnect_catalog}} service.
prereqs:
  inline:
    - title: "{{site.konnect_short_name}} roles"
      include_content: prereqs/service-catalog-integration-role
      icon_url: /assets/icons/kogo-white.svg
    - title: Dynatrace
      content: |
        You need to configure the following in Dynatrace SaaS:
        * A [classic service-level object in Dynatrace](https://docs.dynatrace.com/docs/deliver/service-level-objectives-classic/configure-and-monitor-slo). This will be ingested by {{site.konnect_short_name}}.
        * Your Dynatrace URL. For example: `https://whr42363.apps.dynatrace.com`
        * A [Dynatrace personal access token](https://docs.dynatrace.com/docs/manage/identity-access-management/access-tokens-and-oauth-clients/access-tokens/personal-access-token) with read SLO (`slo.read`) permissions.

        {:.warning}
        > Dynatrace ActiveGate isn't supported.
      icon_url: /assets/icons/third-party/dynatrace.png
---

## Configure the Dynatrace integration

Before you can discover APIs in {{site.konnect_catalog}}, you must configure the Dynatrace integration.

1. In the {{site.konnect_short_name}} sidebar, click **Catalog**.
1. In the Catalog sidebar, click **[Integrations](https://cloud.konghq.com/us/service-catalog/integrations)**. 
1. Click **Dynatrace**.
1. Click **Add Dynatrace instance**.
1. In the **Dynatrace API Base URL** field, enter your Dynatrace URL without the trailing `/`. For example: `https://whr42363.apps.dynatrace.com`
1. In the **Dynatrace API key** field, enter your Dynatrace personal access token.
1. In the **Display name** field, enter `Dynatrace`.
1. In the **Instance name** field, enter `dynatrace`.
1. Click **Save**.

## Create a {{site.konnect_catalog}} service and map the SLO resources

Now that your integration is configured, you can create a {{site.konnect_catalog}} service to map the ingested SLOs.

{:.info}
> In this tutorial, we'll refer to your ingested Dynatrace SLO as `billing-slo`.

1. In the {{site.konnect_short_name}} sidebar, click [**{{site.konnect_catalog}}**](https://cloud.konghq.com/service-catalog/).
1. In the Catalog sidebar, click **Services**.
1. Click **New service**.
1. In the **Display Name** field, enter `Billing Service`.
1. In the **Name** field, enter `billing-service`.
1. Click **Create**.
1. Click **Map Resources**.
1. Select `billing-slo`. 
1. Click **Map 1 Resource**.

Your integration SLOs are now discoverable from one {{site.konnect_catalog}} service.

{:.info}
> You might need to manually sync your Dynatrace integration for resources to appear. From the {{site.konnect_short_name}} UI by navigating to the Dynatrace integration you just installed and selecting **Sync Now** from the **Actions** dropdown menu.

## Validate the mapping

To confirm that the Dynatrace resource is now mapped to the intended service, navigate to the service:

1. In the {{site.konnect_short_name}} sidebar, click [**{{site.konnect_catalog}}**](https://cloud.konghq.com/service-catalog/).
1. In the {{site.konnect_catalog}} sidebar, click **Services**.
1. Click the **Billing Service** service.
1. Click the **Resources** tab.

You should see the `billing-slo` resource listed.
