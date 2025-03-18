---
title: "Konnect Reference Platform FAQ"
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
- text: Reference Platform Home
  url: /konnect-reference-platform/
- text: Reference Platform How-To
  url: /konnect-reference-platform/how-to/
---

## What is the Konnect Reference Platform?
The [Konnect Reference Platform](/konnect-reference-platform/) is a technical guide for users looking to integrate 
the [Kong Konnect](https://konghq.com/products/kong-konnect) API Management platform into their API delivery process and broader 
engineering organization’s technology stack.

## Who can benefit from the reference platform?
The Reference Platform is designed for software Architects, API platform builders, DevOps engineers, and Service Application 
teams who are looking to implement a Federated API Management platform with Konnect.

## What are the components of the Reference Platform?
<u>Konnect reference usage</u>: 
A sample reference implemention of Konnect including organization design and resource configuration. The reference implementation
is deployed via the Konnect Orchestrator.

<u>The Konnect Orchestrator</u>:
A software tool that reconciles declarative configuration with your Konnect organization(s) and manages APIOps code in a _platform Team_ repository.

<u>Kong Air Example Organization</u>:
A complete example demonstrating the reference platform usage, including team structures, service applications, and automated workflows.

<u>Documentation</u>:
This documentation includes design trade-offs, sample configurations, FAQs, and a how-to guide for utilizing the platform and Kong Konnect.

<u>Service Application Team - Self-Service</u>:
A self-service portal for developer teams to onboard their own services to the platform.

## What is the Konnect Orchestrator?
The [Konnect Orchestrator](https://github.com/Kong/konnect-orchestrator) is a _Go_ based software tool that reconciles a declarative configuration with your 
Konnect organization and manages APIOps code in a _Platform Team_ repository. The tool can be ran as a single use CLI command or 
continuously similiar to how Kubernetes based controllers work (commonly referred to as a reconciliation loop).

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
* Notification Hub configuraitons

## What is the specific role of the _Platform Team_ in the Reference Platform?
The Reference Platform operates off of a central code repository, the _Platform Team_ repository. This is by design, such that organizations
can on-board application teams without having to "inject" and code or process into the application team code, repositories or engineering workflows.

All APIOps workflows are stored and execute within the Platform repository. Application team API specifications are read from their repositories
and copied into the Platform team repository for staging, before delivery to Kong Konnect.

In the future, the reference platform may evolve to support a more decentrlaized approach, where Application teams can own more of the API delivery 
pipeline and take advantage of Kong Gateway capabilities directly.

## What is the format for the Konnect Orchestrator configuration?
The full [JSON schema for the orchestrator configuration is available in the Konnect Orchestrator repository](https://github.com/Kong/konnect-orchestrator).
The high-level structure of the configuration follows these main sections:

`platform`

The `platform` configuration defines the _platform team_ repository, including git remote and authorization configurations. The platform team
repository is the central repistory for API specifications and APIOps workflows and execution.

`teams`

The `teams` configuraton defines the engineering group's application teams and their service application repositories. Every team defined 
here will coorespond to a Konnect Team resource within the organization. Each service application repository defined here will have its 
API specifications read and staged into the Platform repository. Simple user management can be accomplished in this section if IdP is 
not utilized. Providing email addresses for teams will invite users to the Konnect organization.

`organizations`

Each organization defined in the `organizations` section, maps to a Konnect Organization. 
defines organizations managed in Konnect and the environments within them

## What specific resource configurations decisions are encoded into the Konnect Orchestrator?
TODO

## How is the API Delivery process accomplished in the platform repository?
The reference platform uses a GitOps-style automation process for API delivery from the _platform repository_.
The Konnect Orchestrator installs APIOps workflows in your platform repository which utilize a common pattern for
API delivery. The Kong [decK](https://docs.konghq.com/deck/) tool is used to apply declarative configurations to your Konnect organizations
following a PR based workflow.

## What are the specific steps implemented in the API Delivery process?
TODO: Add steps
TODO: Add diagram
