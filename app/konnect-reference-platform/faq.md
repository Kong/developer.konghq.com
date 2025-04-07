---
title: Konnect Reference Platform - FAQ
content_type: reference
layout: reference

products:
    - api-ops
works_on:
  - konnect

description: |
    Provides a complete guide for platform builders to integrate {{site.konnect_product_name}} into 
    their engineering organization and API delivery process. 

breadcrumbs:
  - /konnect-reference-platform/

related_resources:
- text: Reference Platform - Home
  url: /konnect-reference-platform/
- text: Reference Platform - FAQ
  url: /konnect-reference-platform/faq/
- text: Reference Platform - Kong Air
  url: /konnect-reference-platform/kong-air/
- text: Reference Platform - How-To
  url: /konnect-reference-platform/how-to/
- text: Reference Platform - APIOps
  url: /konnect-reference-platform/apiops/
---

## What is the Konnect Reference Platform?
The [Konnect Reference Platform](/konnect-reference-platform/) is a technical guide for users looking to integrate 
the [{{site.konnect_product_name}}](https://konghq.com/products/kong-konnect) API Management platform into their API delivery process and broader 
engineering organization’s technology stack.

## Who can benefit from the reference platform?
The Reference Platform is designed for software Architects, API platform builders, DevOps engineers, and Service Application 
teams who are looking to implement a Federated API Management platform with Konnect.

## What are the components of the Reference Platform?
<u>Konnect reference usage</u>: 
A sample reference implementation of Konnect including organization design and resource configuration. The reference implementation
is deployed via the Konnect Orchestrator.

<u>The Konnect Orchestrator</u>:
A software tool that reconciles declarative configuration with your Konnect organization(s) and manages APIOps code in a _platform Team_ repository.

<u>Kong Air Example Organization</u>:
A complete example demonstrating the reference platform usage, including team structures, service applications, and automated workflows.

<u>Documentation</u>:
This documentation includes design trade-offs, sample configurations, FAQs, and a how-to guide for utilizing the platform and {{site.konnect_product_name}}.

<u>Service Application Team - Self-Service</u>:
A self-service portal for developer teams to onboard their own services to the platform.

## What is the Konnect Orchestrator?
The [Konnect Orchestrator](https://github.com/Kong/konnect-orchestrator) is a _Go_ based software tool that reconciles a declarative configuration with your 
Konnect organization and manages APIOps code in a _Platform Team_ repository. The tool can be ran as a single use CLI command or 
continuously similar to how Kubernetes based controllers work (commonly referred to as a reconciliation loop).

## What are the main Konnect Orchestrator concepts?

<u>Declarative Config</u>:
The orchestrator accepts YAML files that make up its declarative configuration, which it reads and reconciles to Konnect organizations.

<u>Platform Team</u>:
The Platform Team is a special team within KO that represents a typical Platform Team that own the API Platform / API Delivery system 
within a broader engineering organization. KO accepts a distinct Platform Team Git repository configuration where much of the configuration is 
written to and the APIOps processes work from.

<u>Organizations</u>:
KO can manage 1-n organizations which define the intersection of the Developer Teams and their Application Services, to 
Konnect Organizations and the resources defined inside them.

<u>Teams</u>:
Developer Teams / Application Teams

<u>Service Applications</u>:
These are the Service Applications owned by the Developer Teams. Otherwise known as “Backend Services” or “Upstream Applications”

## Where can I find an example of the Reference Platform in action?
The example organization, _Kong Airlines_, provides a fictional airline engineering solution made up of a 
set of teams and service applications that support common airline concepts (flights, bookings, etc…) and a Platform
team that manages the API delivery process. The example provides a sample declarative configuration and utilizes the
API Delivery process in the platform repository. 

[Kong Airlines is available on GitHub](https://github.com/KongAirlines).

## How does the Konnect Orchestrator work?
The orchestrator follows the below general pattern:

* Read the input declarative configuration from file(s)
* Manage the APIOps Workflows within the Platform repository by staging Pull Requests that keep API delivery workflow automation up to date
* Directly adds or modifies Konnect resources in one or more Konnect organizations based on the input configuration
* Read API Specifications (OpenAPI files) from Service Application repositories and stage them into the Platform repository via Pull Requests

## What Konnect resources are managed by the Konnect Orchestrator?
* Teams, Roles, and Users including invitations and user -> team mappings
* IdP configuration including Konnect Built-in, OIDC, SAML, and IdP Group to Konnect Team mappings
* Control Planes and Control Plane RBAC policies for managed Teams
* Developer Portals and APIs including API specifications and API Implementations
* Analytics Custom Reports
* Notification Hub configurations 

## What is the specific role of the Platform Team in the Reference Platform?
The Reference Platform operates off of a central code repository, the _Platform Team_ repository. This is by design, such that organizations
can on-board application teams without having to "inject" and code or process into the application team code, repositories or engineering workflows.

All APIOps workflows are stored and execute within the Platform repository. Application team API specifications are read from their repositories
and copied into the Platform team repository for staging, before delivery to {{site.konnect_product_name}}.

In the future, the reference platform may evolve to support a more decentralized approach, where Application teams can own more of the API delivery 
pipeline and take advantage of {{site.base_gateway}} capabilities directly.

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

Each organization defined in the `organizations` section, maps to a Konnect Organization. For each organization, you define 
authorization configurations and environments. Each environment will result in a set of configured resources with specific naming, 
metadata, and access control policies.

## What are Environments?
Environments may be any conceptual grouping of resources the user desires. Typical examples include "dev" or "prod" engineering stages,
but you may also desire to form environments around business units or products. 

Konnect does not natively support the concept of environments. The orchestrator manages environments synthetically by 
prefixing resource names, applying labels, and setting different access control policies based on well known environment types. 
The orchestrator currently supports 2 environment types, DEV and PROD. Various resource configuration decisions are encoded into the Environment type, 
for example RBAC and portal settings. Environments also require a region configuration which must map to a Konnect supported geographic region.

## What specific Konnect resource are managed by the Konnect Orchestrator?
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


## What Konnect Organization design should I follow?

{{site.konnect_product_name}}'s design centers around the concept of an organization. An organization is an isolated tenant of Konnect resources with 
its own configuration and set of teams, users, API Gateways, APIs, Developer Portals, and other resources. Konnect users may decide between a 
single or multi-organization design when implementing their Konnect usage. The Konnect Orchestrator can manage resources in multiple organizations, 
but there is no coordination or connectivity between organizations at the Konnect level. Choosing your organization design is an important
consideration before proceeding with your Konnect implementation. Here are some factors that may determine which design to choose:

<u>Multiple Organizations</u>:

* Data between organizations is isolated, limiting the ability of Konnect applications to provide visibility into the full usage of the platform
* Some Business may have strict compliance requirements requiring strong isolation of data between business units or products which multiple organizations can provide
* It may be desired to strongly isolate critical API runtime configurations between business units

<u>Single Organization</u>:

* One organization allows Konnect applications full visibility across your businesses usage of the platform enabling deeper insights, analytics, and capabilities
* A single Konnect Service Catalog allows for a true central catalog of service applications running across your business
* Data and analytics cannot be shared across organizations. A single organization provides a single accurate view of your businesses usage of the Konnect platform
* A single organization provides better visibility into your businesses usage of the platform which will provide better 
  information regarding billing and contractual usage of the platform
* Single organization can eliminate redundant configuration of key shared resources successfully as network settings, authorization integrations, 
  audit logging, and more

## How is the API Delivery process accomplished in the platform repository?
The reference platform uses a GitOps-style automation process for API delivery from the _platform repository_.
The Konnect Orchestrator installs APIOps workflows in your platform repository which use a common pattern for
API delivery. The Kong [decK](https://docs.konghq.com/deck/) tool is used to apply declarative configurations to your Konnect organizations
following a PR based workflow.

## What are the specific GitHub workflow steps implemented in the API Delivery process?

The APIOps workflows supported by the reference platform are detailed in the dedicated [APIOps page](/konnect-reference-platform/apiops).

## Why do I see the warning message "Found 0 services for API ... Cannot create API implementation relation..."

The reference platform uses the {{site.konnect_short_name}} Developer Portal product, which is used to publish the API specifications
to a catalog for API consumers to discover and review. The Developer Portal model is based on an _API_ resource which is managed by the
orchestrator during the reconciliation loop. Those API resources can be associated with gateway services (called an _implementations_). 

In order for the orchestrator to successfully associate an _API_ with a gateway service, the service must exist in the control plane. 
There is a chicken and egg problem, because the services are managed by the APIOps workflows, which execute independently of the orchestrator
reconciliation loop.

During the APIOps workflows, gateway services are tagged with API names. During the reconciliation loop, the orchestrator looks for these
tags in order to associate the API with the service. Once the APIOps workflows have executed once, the gateway services will be tagged and
the next reconciliation loop will associate the API with the service properly.

