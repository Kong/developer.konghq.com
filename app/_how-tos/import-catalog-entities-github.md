---
title: Import and map GitHub entities
content_type: how_to
description: Learn how to connect a GitHub repository to your {{site.konnect_catalog}} service in {{site.konnect_short_name}}.
permalink: /service-catalog/import-map-github-entities
products:
  - service-catalog
  - gateway
works_on:
  - konnect
tags:
  - integrations
  - github
related_resources:
  - text: Catalog
    url: /service-catalog/
  - text: GitHub reference
    url: /service-catalog/integrations/github/
tldr:
  q: How do I connect a GitHub repository to my {{site.konnect_catalog}} service?
  a: Install the GitHub integration in {{site.konnect_short_name}} and authorize access to one or more repositories, then link a repository to your {{site.konnect_catalog}} service to display metadata and enable event tracking.
prereqs:
  inline:
    - title: GitHub access
      content: |
        You must have sufficient permissions in GitHub to authorize third-party applications and install the {{site.konnect_short_name}} GitHub App.

        You can grant access to either all repositories or selected repositories during the authorization process. The {{site.konnect_short_name}} app can be managed in your GitHub account under **Applications > GitHub Apps**.
      icon_url: /assets/icons/github.svg
---

## Authorize the GitHub integration

1. In {{site.konnect_short_name}}, go to **{{site.konnect_catalog}} > Integrations**.
2. Click **GitHub**, then **Install GitHub**.
3. Click **Authorize** to connect your GitHub account.

You'll be redirected to GitHub, where you can choose to authorize access to **All Repositories** or to **Select repositories**.

Once authorized, you can manage the {{site.konnect_short_name}} GitHub App from your GitHub account:  
[Manage GitHub Applications](https://docs.github.com/en/apps/using-github-apps/authorizing-github-apps)

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
  name: my-github-repo
  type: github
  metadata:
    org: my-org
    repo: my-repo
{% endkonnect_api_request %}
<!--vale on-->

## Map entities

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
  catalog_entity: my-service
  github_repo: my-org/my-repo
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