---
title: "SonarQube"
content_type: reference
layout: reference
icon: /assets/icons/third-party/sonarqube.svg

products:
    - catalog
    - gateway

tags:
  - integrations
  - sonarqube
search_aliases:
  - service catalog
breadcrumbs:
  - /catalog/
  - /catalog/integrations/

works_on:
    - konnect
description: The SonarQube integration lets you connect SonarQube SaaS projects directly to your {{site.konnect_catalog}} services.
discovery_support: true
bindable_entities: "Projects"

related_resources:
  - text: "{{site.konnect_catalog}}"
    url: /catalog/
  - text: "Monitor SonarQube projects {{site.konnect_catalog}} with the {{site.konnect_short_name}} UI"
    url: /how-to/monitor-sonarqube-projects-with-konnect-ui/
  - text: "Monitor SonarQube projects {{site.konnect_catalog}} with the {{site.konnect_short_name}} API"
    url: /how-to/monitor-sonarqube-projects-with-konnect-api/
---

The SonarQube integration lets you connect [SonarQube projects](https://docs.sonarsource.com/sonarqube-cloud/managing-your-projects) directly to your {{site.konnect_catalog}} services.
{% include /catalog/multi-resource.md %}

For a complete tutorial, see the following:
* [Monitor SonarQube projects {{site.konnect_catalog}} with the {{site.konnect_short_name}} UI](/how-to/monitor-sonarqube-projects-with-konnect-ui/)
* [Monitor SonarQube projects {{site.konnect_catalog}} with the {{site.konnect_short_name}} API](/how-to/monitor-sonarqube-projects-with-konnect-api/)

## Prerequisites

You need to configure the following in SonarQube SaaS:
* A [SonarQube personal access token](https://docs.sonarsource.com/sonarqube-cloud/managing-your-account/managing-tokens).

{:.warning}
> SonarQube Server isn't supported.

## Authenticate the SonarQube integration

{% navtabs "sonarqube-integration" %}
{% navtab "UI" %}
1. In the {{site.konnect_short_name}} sidebar, click **Catalog**.
1. In the Catalog sidebar, click **[Integrations](https://cloud.konghq.com/us/service-catalog/integrations)**. 
1. Click **SonarQube**.
1. Click **Add SonarQube instance**.
1. In the **SonarQube API key** field, enter your SonarQube personal access token.
1. In the **Display name** field, enter a name for your SonarQube instance.
1. In the **Instance name** field, enter a unique identifier for your SonarQube instance.
1. Click **Save**.
{% endnavtab %}
{% navtab "API" %}
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
  config:
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
{% endnavtab %}
{% navtab "Terraform" %}
Use the [`konnect_integration_instance`](https://github.com/Kong/terraform-provider-konnect/blob/main/examples/resources/integration_instance.tf) and [`konnect_integration_instance_auth_credential`](https://github.com/Kong/terraform-provider-konnect/blob/main/examples/resources/integration_instance_auth_credential.tf) resources:
```hcl
echo '
resource "konnect_integration_instance" "my_integrationinstance" {
  name         = "sonarqube"
  display_name = "SonarQube"

  integration_name = "sonarqube"
}

resource "konnect_integration_instance_auth_credential" "my_integrationinstanceauthcredential" {
  integration_instance_id = konnect_integration_instance.my_integrationinstance.id
  multi_key_auth = {
    config = {
      "headers": [
        {
          "name": "authorization",
          "key": "'$SONARQUBE_PAT'"
        }
      ]
    }
  }
}
' >> main.tf
```
{% endnavtab %}
{% endnavtabs %}

## Resources

Available SonarQube resources:

<!--vale off-->
{% table %}
columns:
  - title: Entity
    key: entity
  - title: Description
    key: description
rows:
  - entity: "A direct mapping to a [SonarQube project](https://docs.sonarsource.com/sonarqube-cloud/administering-sonarcloud/resources-structure/projects)"
    description: Provides visibility into code issues for public or private repositories linked to SonarQube Cloud projects. 
{% endtable %}
<!--vale on-->

## Discovery information

<!-- vale off-->

{% include_cached catalog/service-catalog-discovery.md 
   discovery_support=page.discovery_support
   discovery_default=page.discovery_default
   bindable_entities=page.bindable_entities
   mechanism=page.mechanism %}

<!-- vale on-->



