---
title: Discover and govern APIs with Service Catalog
content_type: how_to
description: Learn how to discover APIs in AWS API Gateway, SwaggerHub, GitHub, and Gateway Manager with Service Catalog and govern them with scorecards.
products:
  - service-catalog
works_on:
  - konnect
tools:
  - konnect-api
tags:
  - integrations
  - aws
related_resources:
  - text: Service Catalog
    url: /service-catalog/
  - text: Integrations
    url: /service-catalog/integrations/
  - text: AWS API Gateway reference
    url: /service-catalog/integrations/aws-api-gateway/
automated_tests: false
tldr:
  q: placeholder
  a: placeholder
prereqs:
  inline:
    - title: "{{site.konnect_short_name}} roles"
      include_content: prereqs/service-catalog-integration-role
      icon_url: /assets/icons/kogo-white.svg
    - title: IAM role in AWS for Service Catalog
      include_content: prereqs/service-catalog-iam
      icon_url: /assets/icons/aws.svg
    - title: SwaggerHub API key
      content: |
        You must have a [SwaggerHub API key](https://app.swaggerhub.com/settings/apiKey) to authenticate your SwaggerHub account with {{site.konnect_short_name}}. 
        Additionally, you'll need an [API version](https://support.smartbear.com/swaggerhub/docs/en/manage-apis/versioning.html?sbsearch=API%20Versions0) in SwaggerHub to pull into {{site.konnect_short_name}} as a resource.
      icon_url: /assets/icons/third-party/swaggerhub.svg
    - title: GitHub access
      content: |
        To integrate GitHub with Service Catalog, you need the following:
        * Sufficient permissions in GitHub to authorize third-party applications and install the {{site.konnect_short_name}} GitHub App
        * A GitHub organization
        * A repository that you want to pull in to {{site.konnect_short_name}}. You can grant access to either all repositories or selected repositories during the authorization process. 
        
        The {{site.konnect_short_name}} app can be managed in your GitHub account under **Applications > GitHub Apps**.
      icon_url: /assets/icons/github.svg
    
---

## Authorize the AWS API Gateway integration

1. In the {{site.konnect_short_name}} sidebar, click **Service Catalog**.
1. In the Service Catalog sidebar, click **[Integrations](https://cloud.konghq.com/us/service-catalog/integrations)**. 
1. Click **AWS API Gateway**.
1. Click **Add AWS API Gateway instance**.
1. From the **AWS region** dropdown, select your AWS region.
1. In the **IAM role ARN** field, enter the [IAM role you configured for Service Catalog](#configure-an-iam-role-in-aws-for-service-catalog).
1. In the **Display name** field, enter a name for your AWS API Gateway instance.
1. In the **Instance name** field, enter a unique identifier for your AWS API Gateway instance.
1. Click **Save**.

## Install and authorize the GitHub integration

1. From the **Service Catalog** in {{site.konnect_short_name}}, select **[Integrations](https://cloud.konghq.com/us/service-catalog/integrations)**. 
2. Click **GitHub**, then click **Add GitHub Instance**.
3. Authorize the GitHub integration. This will take you to GitHub, where you can grant {{site.konnect_short_name}} access to either **All Repositories** or **Select repositories**. 
1. Enter `github` as your instance name.

The {{site.konnect_short_name}} application can be managed from GitHub as a [GitHub Application](https://docs.github.com/en/apps/using-github-apps/authorizing-github-apps).

## Authenticate the SwaggerHub integration

1. From the **Service Catalog** in {{site.konnect_short_name}}, select **[Integrations](https://cloud.konghq.com/service-catalog/integrations)**. 
2. Select **Add SwaggerHub Instance**.
3. Add your Swaggerhub API key and name the instance.

## Create a Service Catalog service and map the API resources

1. In the {{site.konnect_short_name}} sidebar, click [**Service Catalog**](https://cloud.konghq.com/service-catalog/).
1. Click **New service**.
1. In the **Display Name** field, enter `APIs`.
1. In the **Name** field, enter `apis`.
1. Click **Create**.
1. Click **Map Resources**.
1. Map the resources.....
1. Click **Map Resources**.

## Govern the APIs with scorecards

1. In the {{site.konnect_short_name}} sidebar, click [**Service Catalog**](https://cloud.konghq.com/service-catalog/).
1. In the Service Catalog sidebar, click **Scorecards**.
1. Click **New scorecard**.
1. From the **Scorecard template** dropdown menu, select "Service Documentation".
1. In the Services settings, select **Custom selection**.
1. In the **Custom selection** dropdown menu, select "APIs". 
1. Click **Create**. 



