---
title: APIOps
description: Manage {{ site.base_gateway }} declaratively

content_type: reference
layout: reference

works_on:
  - on-prem
  - konnect

tools:
  - deck

breadcrumbs:
  - /deck/

tags:
  - kongair
  - reference-platform

related_resources:
  - text: Federated configuration with decK
    url: /deck/apiops/federated-configuration/
  - text: Continuous integration with decK
    url: /deck/apiops/continuous-integration/
---

APIOps is the practice of managing your API management configuration declaratively. It follows GitOps principles such as version control, CI/CD, and pull request reviews, and applies them to APIm.

{{ site.base_gateway }} is 100% APIOps compatible thanks to decK, which enables APIOps by providing a tool with varied commands that can be coordinated to build API delivery automations.

## An APIOps example

Let's explore how [KongAir](https://github.com/Kong/KongAir), an imaginary airline, leverages decK to streamline its API management processes. 

### Governance rules
The KongAir API Community of Practice has established a set of governance rules to ensure uniformity and efficiency across all API teams:

- Every API team within KongAir, including those responsible for the Flights and Routes APIs, adopts OpenAPI specifications to define their API contracts.
- These teams maintain the flexibility to employ Kong's transformation and validation plugins to enhance their APIs. They manage these plugins' configurations through modular decK state files, promoting autonomy and customization.
- The KongAir API Community of Practice has also embraced a comprehensive set of API Design Guidelines to standardize API development. These guidelines are implemented and monitored through a linting file overseen by the dedicated API Platform Team, ensuring adherence to best practices.
- The API Platform Team assumes a pivotal role in configuring critical plugins related to observability, security, and traffic control within Kong, centralizing expertise and governance for these essential aspects.
- Furthermore, this team is tasked with the management of environment-specific variables, ensuring seamless deployment and operation across different stages of the development lifecycle.

You can check out the [KongAir demo app](https://github.com/Kong/KongAir) yourself to see how it all comes together in reality.

### KongAir's approach to deploying decK
The following steps delineate KongAir's structured approach to deploying decK, steered by their established governance protocols:
1. The Flights API team initiates the process by converting their OpenAPI Specification into a decK state file using the [`deck file openapi2kong`](/deck/file/openapi2kong/) command.
2. Next, they enhance the state file by integrating transformation plugins (such as [Request Transformer Advanced](/plugins/request-transformer-advanced/) and [Correlation ID](/plugins/correlation-id/)) and validation plugins (like [OAS Validation](/plugins/oas-validation/)) using the [`deck file add-plugins`](/deck/file/manipulation/plugins/) command.
3. To track the configuration's creation time, they apply relevant tags using [`deck file add-tags`](/deck/file/manipulation/tags/).
4. The state file undergoes a quality check against a predefined linting ruleset with [`deck file lint`](/deck/file/lint/), ensuring adherence to best practices.
5. Environment-specific adjustments, including upstream API URLs, are made using the [`deck file patch`](/deck/file/manipulation/patch/) command.
6. The Platform Team then merges global plugins for observability, authentication, authorization, and traffic control into the main state file with [`deck file merge`](/deck/file/merge/).
7. At this stage, a comprehensive state file for the Flights API is ready. This file is combined with the Routes API's state file using [`deck file render`](/deck/file/render/), creating a unified configuration.
8. The final state file is subjected to an offline validation through [`deck file validate`](/deck/file/validate/).
9. The state file is deployed to the chosen runtime.

### Deploying the state file

The process for deploying the decK state file differs depending on the runtime:

{% navtabs "apiops-deck" %}
{% navtab "Konnect or Gateway" %}
For {{site.konnect_product_name}} or {{site.base_gateway}} deployments, the process involves:

1. Ensuring connectivity with the Admin API via `deck gateway ping`.
2. Performing an online validation with [`deck gateway validate`](/deck/gateway/validate/).
3. Backing up the current Kong state with [`deck gateway dump`](/deck/gateway/dump/).
4. Previewing changes with [`deck gateway diff`](/deck/gateway/diff/).
5. Applying the new configuration with [`deck gateway sync`](/deck/gateway/sync/).

{% endnavtab %}
{% navtab "KIC" %}

For {{site.kic_product_name}} deployments, the sequence is:

1.  Transforming the decK state file into Kubernetes manifests using [`deck file kong2kic`](/deck/file/kong2kic/).
2.  Deploying the configuration with `kubectl apply`.

{% endnavtab %}
{% endnavtabs %}

### APIOps KongAir diagram

The following diagram helps you visualize the process defined above:

<!--vale off-->

{% mermaid %}
flowchart TB
subgraph KongAir Flights API Team
oas_flights[[Open API Specification]]
trans_plugins_flights[[Transformation Plugins]]
validation_plugins_flights[[Validation Plugins]]
end
subgraph KongAir API Platform Team
obs_plugins_platform[[Observability Plugins]]
auth_plugins_platform[[AuthN/AuthZ Plugins]]
traffic_plugins_platform[[Traffic Control Plugins]]
linting_platform[[Linting rules]]
env_vars[[Environment Variables]]
end
subgraph KongAir Routes API Team
routes_api[[Routes API Kong Conf]]
end
oas_flights_o2k([deck file openapi2kong])
deck_flights_plugins([deck file add-plugins])
oas_flights --> oas_flights_o2k
oas_flights_o2k --> flights_kong_config[[Flights API Kong Conf]]
flights_kong_config --> deck_flights_plugins
trans_plugins_flights --> deck_flights_plugins
validation_plugins_flights --> deck_flights_plugins
deck_flights_plugins --> flights_plugins[[Flights API Kong Conf]]
flights_plugins --> deck_flights_tags([deck file add-tags])
deck_flights_tags --> flights_plugins_tags[[Flights API Kong Conf]]
flights_plugins_tags --> deck_flights_lint([deck file lint])
linting_platform --> deck_flights_lint
deck_flights_lint --> flights_linted[[Flights API Kong Conf]]
flights_linted --> deck_flights_patch([deck file patch])
env_vars --> deck_flights_patch
deck_flights_patch --> flights_patched[[Flights API Kong Conf]]
flights_patched --> deck_flights_merge([deck file merge])
obs_plugins_platform --> deck_flights_merge
auth_plugins_platform --> deck_flights_merge
traffic_plugins_platform --> deck_flights_merge
deck_flights_merge --> flights_merged[[Flights API Kong Conf]]
flights_merged --> deck_flights_render([deck file render])
routes_api --> deck_flights_render
deck_flights_render --> kongair_complete[[KongAir APIs Kong Conf]]
kongair_complete --> deck_complete_validate([deck file validate])
deck_complete_validate --> kongair_valid[[KongAir APIs Kong Conf]]
kongair_valid --> target_platform
target_platform{Target<br/>Platform}
target_platform -->|Kong Admin API| deck_ping([deck gateway ping])
deck_ping --> deck_validate([deck gateway validate])
deck_validate --> deck_dump([deck gateway dump])
deck_dump --> deck_diff([deck gateway diff])
deck_diff --> deck_sync([deck gateway sync])
target_platform -->|Kubernetes API| deck_kic([deck file kong2kic])
deck_kic --> k8s_manifests[[KongAir APIs K8s Manifests]]
k8s_manifests --> kubectl([kubectl apply])

{% endmermaid %}

<!--vale on-->
