---
title: Konnect Reference Platform - Kong Air
content_type: reference
layout: reference

products:
    - api-ops
works_on:
  - konnect

description: Provides an example usage of the Konnect Reference Platform 

breadcrumbs:
  - /konnect-reference-platform/

related_resources:
- text: Reference Platform - Home
  url: /konnect-reference-platform/
- text: Reference Platform - FAQ
  url: /konnect-reference-platform/faq/
- text: Reference Platform - Orchestrator
  url: /konnect-reference-platform/orchestrator/
- text: Reference Platform - How-To
  url: /konnect-reference-platform/how-to/
---

The [{{site.konnect_short_name}} Reference Platform](/konnect-reference-platform) can be used to onboard your 
engineering team to {{site.konnect_product_name}}. A full [how-to guide](/konnect-reference-platform/how-to/) 
is available to help you through the setup process. An alternative to implementing the reference platform is to 
evaluate an example usage of it, pulling relevant technical solutions from it and applying them to your 
own use case as needed. [_Kong Air_](https://github.com/KongAirlines) is one of these examples.

![Kong Air](/assets/images/reference-platform/kong-air.png)

Kong Air is a fictional airline used to demonstrate how engineering organizations can use {{site.konnect_product_name}} to build 
API Management solutions. The organization is made up of multiple teams responsible for a different parts of the airline's 
software infrastructure and APIs. Teams own repositories that contain the code and configuration for their services, 
while the platform team is responsible for managing the {{site.base_gateway}} and other shared services.

## How do I use Kong Air?

[Kong Air is a public GitHub organization](https://github.com/KongAirlines) owned by Kong. 
All the repositories in the organization are public allowing you to view the various solutions to determine 
how it could be applied to your own use case. Specifically the [platform team](https://github.com/KongAirlines/platform)
repository contains [GitHub Action workflows](https://github.com/KongAirlines/platform/tree/main/.github/workflows) that 
enable APIOps delivery for the organization.

## How does Kong Air work?

The organization holds a set of service application repositories that mimic a real-world airline company. The organization
is also comprised of a set of teams who own the repositories and are responsible for the development and delivery of the services.
Kong Air uses the Konnect Reference platform and the [Konnect Orchestrator](/konnect-reference-platform/orchestrator/) to manage the 
state of the {{site.konnect_short_name}} deployment and API delivery pipeline. 
This solution centers around a [platform team repository](https://github.com/KongAirlines/platform) 
which the orchestrator uses to stage API specifications for delivery to {{site.konnect_short_name}}.

Currently there are the following application teams and service repositories:

* `customer-data`, which owns the [bookings](https://github.com/KongAirlines/bookings) and 
  [customers](https://github.com/KongAirlines/customer) services.
* `flight-data` which owns the [flights](https://github.com/KongAirlines/flights) and
  [destinations](https://github.com/KongAirlines/destinations) services.

Each service repository holds an OpenAPI specification that describes the API contract for the service. 

For example, the `flights` service OpenAPI specification is found in the [`openapi.yaml`](https://github.com/KongAirlines/flights/blob/main/openapi.yaml) 
file located in the root of the `flights` repository. The orchestrator is configured to monitor this repository in the `teams` configuration, 
and detects changes to be copied to the `platform` repository in preparation for delivery to {{site.konnect_short_name}}. 
You can see the corresponding file in the platform repository in the environment and service specification location. 

[`konnect/KongAirlines/envs/prd/teams/flight-data/services/KongAirlines/flights/openapi.yaml`](https://github.com/KongAirlines/platform/blob/main/konnect/KongAirlines/envs/prd/teams/flight-data/services/KongAirlines/flights/openapi.yaml)

## What's next?

* See the [FAQ page](/konnect-reference-platform/faq) for more Q&A on the reference platform.
* Follow the [How-To guide](/konnect-reference-platform/how-to) for step-by-step instructions on setting up the reference platform for your organization
* Check out the [APIOps workflows page](/konnect-reference-platform/apiops/) to learn about the API Delivery automations built into the reference platform
