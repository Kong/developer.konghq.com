---
title: Monitor SonarQube projects in Catalog with the Konnect API
permalink: /how-to/monitor-sonarqube-projects-with-konnect-api/
content_type: how_to
description: Learn how to connect a SonarQube project to your {{site.konnect_catalog}} service in {{site.konnect_short_name}} using the API.
products:
  - catalog
works_on:
  - konnect
tools:
  - konnect-api
tags:
  - integrations
  - sonarqube
search_aliases:
  - projects
  - service catalog
related_resources:
  - text: "{{site.konnect_catalog}}"
    url: /catalog/
  - text: Integrations
    url: /catalog/integrations/
  - text: SonarQube reference
    url: /catalog/integrations/sonarqube/
  - text: "Monitor SonarQube projects {{site.konnect_catalog}} with the {{site.konnect_short_name}} UI"
    url: /how-to/monitor-sonarqube-projects-with-konnect-ui/
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

        Export your SonarQube personal access token:
        ```sh
        export SONARQUBE_PAT='YOUR SONARQUBE PERSONAL ACCESS TOKEN'
        ```
      icon_url: /assets/icons/third-party/sonarqube.svg
---

## Configure the SonarQube integration

Before you can discover [SonarQube projects](https://docs.sonarsource.com/sonarqube-cloud/managing-your-projects) in {{site.konnect_catalog}}, you must configure the SonarQube integration.

First, install the SonarQube integration:

<!--vale off-->
{% konnect_api_request %}
url: /v1/integration-instances
method: POST
status_code: 201
region: us
body:
  integration_name: sonarqube
  name: sonarqube
  display_name: SonarQube
  config: {}
{% endkonnect_api_request %}
<!--vale on-->

Export the ID of your SonarQube integration:

```sh
export SONARQUBE_INTEGRATION_ID='YOUR-INTEGRATION-ID'
```

Next, authorize the SonarQube integration with your SonarQube personal access token:

<!--vale off-->
{% konnect_api_request %}
url: /v1/integration-instances/$SONARQUBE_INTEGRATION_ID/auth-credential
method: POST
status_code: 201
region: us
body:
  type: multi_key_auth
  config:
    headers:
      - name: authorization
        key: $SONARQUBE_PAT
{% endkonnect_api_request %}
<!--vale on-->

Once authorized, resources from your SonarQube account will be discoverable in the UI.

## Create a service in {{site.konnect_catalog}}

Create a service that you'll map to your SonarQube resources:

<!--vale off-->
{% konnect_api_request %}
url: /v1/catalog-services
method: POST
status_code: 201
region: us
body:
  name: billing
  display_name: Billing Service
{% endkonnect_api_request %}
<!--vale on-->

Export the service ID:

```sh
export SONARQUBE_SERVICE_ID='YOUR-SERVICE-ID'
```

## List SonarQube resources

Before you can map your SonarQube resources to a service in {{site.konnect_catalog}}, you first need to find the resources that are pulled in from SonarQube:

<!--vale off-->
{% konnect_api_request %}
url: /v1/resources?filter%5Bintegration.name%5D=sonarqube
method: GET
region: us
status_code: 200
{% endkonnect_api_request %}
<!--vale on-->

{:.info}
> You may need to manually sync your SonarQube integration for resources to appear. From the {{site.konnect_short_name}} UI by navigating to the SonarQube integration you just installed and selecting **Sync Now** from the **Actions** dropdown menu.

Export the resource ID you want to map to the service:

```sh
export SONARQUBE_RESOURCE_ID='YOUR-RESOURCE-ID'
```

## Map resources to a service

Now, you can map the SonarQube resource to the service:

<!--vale off-->
{% konnect_api_request %}
url: /v1/resource-mappings
method: POST
status_code: 201
region: us
body:
  service: billing
  resource: $SONARQUBE_RESOURCE_ID
{% endkonnect_api_request %}
<!--vale on-->


## Validate the mapping

To confirm that the SonarQube resource is now mapped to the intended service, list the service’s mapped resources:

<!--vale off-->
{% konnect_api_request %}
url: /v1/catalog-services/$SONARQUBE_SERVICE_ID/resources
method: GET
status_code: 200
region: us
{% endkonnect_api_request %}
<!--vale on-->
