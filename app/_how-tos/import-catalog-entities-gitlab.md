---
title: Import and map GitLab entities
content_type: how_to
description: Learn how to connect a GitLab project to your {{site.konnect_catalog}} service in {{site.konnect_short_name}}.
permalink: /service-catalog/import-map-gitlab-entities
products:
  - service-catalog
  - gateway
works_on:
  - konnect
tags:
  - integrations
  - gitlab
related_resources:
  - text: Catalog
    url: /service-catalog/
  - text: GitLab reference
    url: /service-catalog/integrations/gitlab/
tldr:
  q: How do I connect a GitLab project to my {{site.konnect_catalog}} service?
  a: Authorize the GitLab integration in {{site.konnect_short_name}} using either the SaaS or self-hosted setup, then link your project to display metadata and enable event tracking.
prereqs:
  inline:
    - title: GitLab access
      content: |
        You must have the **Owner** role in the GitLab group to authorize the integration. Only [GitLab.com subscriptions](https://docs.gitlab.com/ee/subscriptions/gitlab_com/) are currently supported.

        If you're using a self-hosted GitLab instance, it must be accessible from the public internet or is otherwise reachable by {{site.konnect_short_name}}.
      icon_url: /assets/icons/gitlab.svg
---

## Authorize the GitLab integration

Choose one of the following authorization flows depending on whether you use GitLab SaaS or self-managed GitLab:

{% navtabs "Authorization" %}
{% navtab "SaaS" %}
### SaaS GitLab

1. In {{site.konnect_short_name}}, go to **{{site.konnect_catalog}} > Integrations**.
2. Click **GitLab**, then **Install GitLab**.
3. Click **Authorize** to connect your GitLab account.

{% endnavtab %}
{% navtab "Self-managed" %}
### Self-managed GitLab

1. [Create a group-owned application](https://docs.gitlab.com/integrations/oauth_provider/) in your GitLab instance.
   - Set the redirect URI to:  
     `https://cloud.konghq.com/$KONNECT_REGION/service-catalog/integration/gitlab`
   - Ensure the app has the `api` scope.
2. In {{site.konnect_short_name}}, go to the [GitLab integration config page](https://cloud.konghq.com/service-catalog/integrations/gitlab/configuration).
3. Fill in the following fields using values from your GitLab OAuth app:
   - **GitLab API Base URL**: e.g., `https://gitlab.example.com/api/v4`
   - **Application ID**
   - **Application Secret**
   - **Token Endpoint**: `https://$GITLAB_HOST/oauth/token`
   - **Authorization Endpoint**: `https://$GITLAB_HOST/oauth/authorize`
4. Click **Authorize** to complete the connection.
{% endnavtab %}
{% endnavtabs %}

## Import entities

<!--vale off-->
{% konnect_api_request %}
url: /v2/catalog/???
status_code: 201
region: global
method: POST
headers:
  - 'Accept: application/json'
  - 'Content-Type: application/json'
body:
  name: us-east-2 vpc peering
  cidr_blocks:
    - $AWS_VPC_CIDR
  transit_gateway_attachment_config:
    kind: aws-vpc-peering-attachment
    peer_account_id: $AWS_ACCOUNT_ID
    peer_vpc_id: $AWS_VPC_ID
    peer_vpc_region: $AWS_REGION
{% endkonnect_api_request %}
<!--vale on-->

## Map Entities

<!--vale off-->
{% konnect_api_request %}
url: /v2/catalog/???
status_code: 201
region: global
method: POST
headers:
  - 'Accept: application/json'
  - 'Content-Type: application/json'
body:
  name: us-east-2 vpc peering
  cidr_blocks:
    - $AWS_VPC_CIDR
  transit_gateway_attachment_config:
    kind: aws-vpc-peering-attachment
    peer_account_id: $AWS_ACCOUNT_ID
    peer_vpc_id: $AWS_VPC_ID
    peer_vpc_region: $AWS_REGION
{% endkonnect_api_request %}
<!--vale on-->


## Validate

Once mapped, return to your {{site.konnect_catalog}} service in the UI and confirm that repository metadata is displayed. You should see:

- Repository name and language breakdown
- Number of open issues and pull requests
- Most recent merged or closed pull request
- Real-time GitHub events, such as:
  - Open pull request
  - Merge pull request
  - Close pull request


<!--vale off-->
{% konnect_api_request %}
url: /v2/cloud-gateways/networks/$KONNECT_NETWORK_ID/transit-gateways
status_code: 200
region: global
method: GET
{% endkonnect_api_request %}
<!--vale on-->