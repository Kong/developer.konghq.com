---
title: "{{site.konnect_short_name}} Orchestrator"
content_type: reference
layout: reference

products:
  - konnect-reference-platform

works_on:
  - konnect

description: What is the Konnect Orchestrator and how is it used?

breadcrumbs:
  - /konnect-reference-platform/

related_resources:
  - text: About {{site.konnect_short_name}} Reference Platform
    url: /konnect-reference-platform/
  - text: About Kong Air
    url: /konnect-reference-platform/kong-air/
  - text: How to deploy
    url: /konnect-reference-platform/how-to/
  - text: Reference Platform FAQ
    url: /konnect-reference-platform/faq/
---

The {{site.konnect_short_name}} Orchestrator is a software tool provided as part of the 
[{{site.konnect_short_name}} Reference Platform](/konnect-reference-platform/).
The tool is a [Go based project](https://github.com/Kong/konnect-orchestrator) and released 
as a binary named `koctl`. We will refer to the tool by the `koctl` name in this document.

`koctl` is a multi-purpose CLI tool you can use to setup a git repository 
to support an API management platform, configure the repository to support your development teams,
and apply declarative configurations to your [{{site.konnect_saas}}](https://konghq.com/products/kong-konnect)
organizations.

## What Konnect resources are managed by the Konnect Orchestrator?
* Teams, Roles, and Users including invitations and user -> team mappings
* IdP configuration including Konnect Built-in, OIDC, SAML, and IdP Group to Konnect Team mappings
* Control Planes and Control Plane RBAC policies for managed Teams
* Developer Portals and APIs including API specifications and API Implementations
* Analytics Custom Reports
* Notification Hub configurations 

## What can `koctl` do?

The `koctl` tool is specifically designed to enable and apply the concepts for the 
[{{site.konnect_short_name}} Reference Platform](/konnect-reference-platform/). Specifically,
the following functions are provided to support the reference platform features:

* Initialize a central platform team git repository that supports the API management platform
* Configure the platform repository with new organizations and environments 
* Run an API server and web based UI application to enable self-service onboarding for 
  developer teams and their service applications
* Stage service application API specifications to the platform repository preparing them to be 
  delivered to {{site.konnect_short_name}}
* Apply declarative configuration within the platform repository CICD pipeline to 
  {{site.konnect_short_name}} organizations

## How do I install `koctl`?

macOS users can install the orchestrator using Homebrew:

```shell
brew install kong/konnect-orchestrator/koctl
```

On Linux or Windows, install the orchestrator directly from the releases page on GitHub:

[Releases - Kong/konnect-orchestrator](https://github.com/Kong/konnect-orchestrator/releases)

## How do I use `koctl`?

For the complete instructions for running the orchestrator as part of building an API management platform,
see the step-by-step [how-To](/konnect-reference-platform/how-to/) guide. 

## Where can I see `koctl` source?

`koctl` is an open source project and the code can be found in the public GitHub repository:

[https://github.com/Kong/konnect-orchestrator](https://github.com/Kong/konnect-orchestrator)

## What are environments?
Environments may be any conceptual grouping of resources that you want. Typical examples include "dev" or "prod" engineering stages,
but you could also form environments around business units or products. 

Konnect does not natively support the concept of environments. The orchestrator manages environments synthetically by 
prefixing resource names, applying labels, and setting different access control policies based on well known environment types. 
The orchestrator currently supports 2 environment types, DEV and PROD. Various resource configuration decisions are encoded into the Environment type, 
for example RBAC and portal settings. Environments also require a region configuration which must map to a Konnect supported geographic region.

<!-- 
## What is the format for the Konnect Orchestrator configuration?
The full [JSON schema for the orchestrator configuration is available in the Konnect Orchestrator repository](https://github.com/Kong/konnect-orchestrator).
The high-level structure of the configuration follows these main sections:

`platform`

The `platform` configuration defines the _platform team_ repository, including git remote and authorization configurations. The platform team
repository is the central repository for API specifications and APIOps workflows and execution.

`teams`

The `teams` configuration defines the engineering group's developer teams and their application repositories. Every team defined 
here will correspond to a Konnect Team resource within the organization. Each service application repository defined here will have its 
API specifications read and staged into the Platform repository. Simple user management can be accomplished in this section if IdP is 
not utilized. Providing email addresses for teams will invite users to the Konnect organization.

`organizations`

Each organization defined in the `organizations` section maps to a Konnect Organization. For each organization, you define 
authorization configurations and environments. Each environment will result in a set of configured resources with specific naming, 
metadata, and access control policies.

## What specific Konnect resources are managed by the Konnect Orchestrator?
The Konnect Orchestrator does not manage a straight mapping from the input declarative configuration into Konnect resources. 
Instead, the input configuration is generally an expression of the engineering organization design, and the orchestrator 
maps that to opinionated configurations for the Konnect resources it manages. The following shows the general configuration
of Konnect resources managed by the orchestrator:

* For each configured organization in the `organizations` configuration
    * For every team in the `teams` configuration
        * A Konnect Team is created 
            * For every User in the `users` configuration, a Konnect User is created 
            * Each User is added to the Konnect Team
        * For every environment in the `environments` configuration
            * A Konnect Control Plane is created
            * A Konnect Developer Portal is created
            * For every service in the `services` configuration
                * A Konnect API is created
                * The service specification is added to the API

Depending on the environment type, different configurations are applied to various resources.

* For `PROD` environment types:
    * APIs are created with complete service name as the API name
    * Developer Portals default to `public` visibility for pages and APIs
    * The application teams are given `Control Plane Viewer` role for the team`s production control plane
* For `DEV` environment types:
    * APIs are created with a postfix of `-dev` to the API name
    * Developer Portals default to `private` visibility for pages and APIs
    * The application teams are given `Control Plane Admin` role for the team`s development control plane
-->

## Where can I get more information?

Additional questions may be answered in the [FAQ](/konnect-reference-platform/faq/) page. If your
question is not answered there, please feel free to reach out on the 
[Kong Nation](https://discuss.konghq.com/) discussion forums.
