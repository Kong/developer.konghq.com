---
title: Discover and govern APIs with Catalog
permalink: /how-to/discover-and-govern-apis-with-service-catalog/
content_type: how_to
description: Learn how to discover APIs in AWS API Gateway, SwaggerHub, and GitHub with {{site.konnect_catalog}} and govern them with scorecards.
products:
  - catalog
works_on:
  - konnect
tags:
  - integrations
  - aws
entities: 
  - service
search_aliases:
  - service catalog
related_resources:
  - text: "{{site.konnect_catalog}}"
    url: /catalog/
  - text: Integrations
    url: /catalog/integrations/
  - text: AWS API Gateway reference
    url: /catalog/integrations/aws-api-gateway/
  - text: Package APIs with Dev Portal
    url: /how-to/package-apis-with-dev-portal/
automated_tests: false
tldr:
  q: How do I discover and govern third-party APIs in {{site.konnect_short_name}}?
  a: |
    {{site.konnect_catalog}} allows you to find and centrally view all APIs from these integrations and map them to a {{site.konnect_catalog}} service. First, authorize the integrations in {{site.konnect_catalog}} for AWS API Gateway, GitHub, and SwaggerHub. Then, create a {{site.konnect_catalog}} service and map resources from the integrations to the service. Finally, add a service documentation scorecard to your service to govern API documentation standards.
prereqs:
  inline:
    - title: "{{site.konnect_short_name}} roles"
      content: |
        To configure {{site.konnect_catalog}} integrations, services, and scorecards, you need the following [roles in {{site.konnect_short_name}}](/konnect-platform/teams-and-roles/#service-catalog):
        * Integration Admin
        * Scorecard Admin
        * Service Admin
      icon_url: /assets/icons/kogo-white.svg
    - title: AWS API Gateway
      include_content: prereqs/service-catalog-iam
      icon_url: /assets/icons/aws.svg
    - title: SwaggerHub
      content: |
        You must have a [SwaggerHub API key](https://app.swaggerhub.com/settings/apiKey) to authenticate your SwaggerHub account with {{site.konnect_short_name}}. 
        Additionally, you'll need an [API version](https://support.smartbear.com/swaggerhub/docs/en/manage-apis/versioning.html?sbsearch=API%20Versions0) in SwaggerHub to pull into {{site.konnect_short_name}} as a resource. You can name your SwaggerHub API version whatever you'd like. In this tutorial, we'll refer to your SwaggerHub API version as `swaggerhub-api`.
      icon_url: /assets/icons/third-party/swaggerhub.svg
    - title: GitHub
      content: |
        To integrate GitHub with {{site.konnect_catalog}}, you need the following:
        * Sufficient permissions in GitHub to authorize third-party applications and install the {{site.konnect_short_name}} GitHub App
        * A GitHub organization
        * A repository that you want to pull in to {{site.konnect_short_name}}. You can grant access to either all repositories or selected repositories during the authorization process. You can name your GitHub repository whatever you'd like. In this tutorial, we'll refer to your GitHub repository as `github-repo`.
        
        The {{site.konnect_short_name}} app can be managed in your GitHub account under **Applications > GitHub Apps**.
      icon_url: /assets/icons/github.svg
tools:
  - deck
---

## Configure the AWS API Gateway, GitHub, and SwaggerHub integrations

In this tutorial, we'll be discovering APIs and API specs from AWS API Gateway, GitHub, and SwaggerHub in {{site.konnect_catalog}}. {{site.konnect_catalog}} allows you to find and centrally view all APIs from these integrations and map them to a {{site.konnect_catalog}} service. 

Before you can discover APIs in {{site.konnect_catalog}}, you must configure the third-party integrations.

### Configure the AWS API Gateway integration

{% include /catalog/aws-api-gateway-integration.md %}

### Configure the GitHub integration

1. In the {{site.konnect_short_name}} sidebar, click **Catalog**.
1. In the Catalog sidebar, click **[Integrations](https://cloud.konghq.com/us/service-catalog/integrations)**.
2. Click **GitHub**.
1. Click **Add GitHub Instance**.
1. Click **Authorize in GitHub**. This will take you to GitHub, where you can grant {{site.konnect_short_name}} access to either **All Repositories** or **Select repositories**. 
1. In the **Display name** field, enter `GitHub-test`.
1. In the **Instance name** field, enter `github-test`.
1. Click **Save**.

The {{site.konnect_short_name}} application can be managed from GitHub as a [GitHub Application](https://docs.github.com/en/apps/using-github-apps/authorizing-github-apps).

### Configure the SwaggerHub integration

1. In the {{site.konnect_short_name}} sidebar, click **Catalog**.
1. In the Catalog sidebar, click **[Integrations](https://cloud.konghq.com/us/service-catalog/integrations)**.
2. Click **Add SwaggerHub Instance**.
1. In the **SwaggerHub API Key** field, enter your SwaggerHub API key. For example: `04403e83-1a66-4366-9f08-7cecaba73e20`.
1. In the **Display name** field, enter `SwaggerHub-test`.
1. In the **Instance name** field, enter `swaggerhub-test`.
1. Click **Save**. 

## Create a {{site.konnect_catalog}} service and map the API resources

Now that your integrations are configured, you can create a {{site.konnect_catalog}} service to map the ingested APIs.

{:.info}
> In this tutorial, we'll refer to your ingested resources like the following:
* AWS API Gateway API: `aws-api`
* GitHub repository: `github-repo`
* SwaggerHub API version: `swaggerhub-api`

1. In the {{site.konnect_short_name}} sidebar, click [**Catalog**](https://cloud.konghq.com/service-catalog/).
1. In the Catalog sidebar, click **Services**.
1. Click **New service**.
1. In the **Display Name** field, enter `APIs`.
1. In the **Name** field, enter `apis`.
1. Click **Create**.
1. Click **Map Resources**.
1. Select `swaggerhub-api`.
1. Select `aws-api`. 
1. Select `github-repo`. 
1. Click **Map 3 Resources**.

Your integration APIs are now discoverable from one {{site.konnect_catalog}} service.

## Govern the APIs with scorecards

Now that you've discovered and mapped the APIs to a {{site.konnect_catalog}} service, you can govern the service documentation of these ingested APIs with a [scorecard](/catalog/scorecards/). The built-in service documentation scorecard will alert you when your APIs don't adhere to [API documentation best practices](/catalog/scorecards/#service-documentation-linting).

1. In the {{site.konnect_short_name}} sidebar, click [**Catalog**](https://cloud.konghq.com/service-catalog/).
1. In the Catalog sidebar, click **Scorecards**.
1. Click **New scorecard**.
1. From the **Scorecard template** dropdown menu, select "Service Documentation".
1. In the Services settings, select **Custom selection**.
1. In the **Custom selection** dropdown menu, select "APIs". 
1. Click **Create**. 
1. Click the **Criteria** tab.

You'll see the score for your service, how many APIs have documentation, specs, and are passing the linting rulesets.



