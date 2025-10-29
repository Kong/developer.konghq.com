---
title: Kong Air
content_type: reference
layout: reference

products:
  - konnect-reference-platform

works_on:
  - konnect

description: "Provides example usage of the {{site.konnect_short_name}} Reference Platform"
  

breadcrumbs:
  - /konnect-reference-platform/

related_resources:
  - text: Reference Platform
    url: /konnect-reference-platform/
  - text: Orchestrator
    url: /konnect-reference-platform/orchestrator/
  - text: How to deploy the Reference Platform
    url: /konnect-reference-platform/how-to/
  - text: Frequently Asked Questions
    url: /konnect-reference-platform/faq/
---

The [{{site.konnect_short_name}} Reference Platform](/konnect-reference-platform/) is a technical
guide for building an API delivery system and integrating with 
[{{site.konnect_saas}}](https://konghq.com/products/kong-konnect/). There are
different ways to use the tools and materials provided. If you want to deploy the full 
platform you can follow the [how-to guide](/konnect-reference-platform/how-to/) 
which provides step-by-step instructions to set up an entire API delivery pipeline. 

Alternatively, you can evaluate an example usage of the platform, pulling relevant technical 
solutions from it and applying them to your own use case as needed. 
The [_Kong Air_](https://github.com/KongAirlines) project is one of these examples.

## What is Kong Air?

Kong Air is a fictional airline used to demonstrate how engineering organizations can use 
{{site.konnect_short_name}} to build an API Management solution. The organization is made up of multiple 
teams responsible for a different parts of the airline's software infrastructure and APIs. 
Teams own repositories that contain the code and configuration for their services, 
while the platform team is responsible for managing {{site.konnect_short_name}} and other shared services.

## How do I use Kong Air?

Kong Air is a public [GitHub organization](https://github.com/KongAirlines) owned by Kong. 
All the repositories in the organization are public, allowing you to view the various solutions to determine 
how it could be applied to your own use case. Specifically, the [platform team repository](https://github.com/KongAirlines/platform)
contains [GitHub Action workflows](https://github.com/KongAirlines/platform/tree/main/.github/workflows) that 
enable APIOps delivery for the organization.

You can also evaluate the {{site.konnect_short_name}} [declarative configuration](https://github.com/KongAirlines/platform/tree/main/konnect) 
used by the [{{site.konnect_short_name}} Orchestrator](/konnect-reference-platform/orchestrator/) to 
apply changes to the {{site.konnect_short_name}} organization.

## How does Kong Air work?

The organization is made up of a set of service application repositories that mimic airline company systems. The organization
is also comprised of a set of fictional teams who own the repositories and are responsible for the development and 
delivery of the services.

Kong Air uses the {{site.konnect_short_name}} Reference platform and the 
[Konnect Orchestrator](/konnect-reference-platform/orchestrator/) to manage the state of the 
{{site.konnect_short_name}} Organization. The solution centers around the 
[platform team repository](https://github.com/KongAirlines/platform) 
which the orchestrator uses to stage API specifications for delivery to {{site.konnect_short_name}}.

Currently there are the following application teams and service repositories:

* `customer-data`, which owns the [bookings](https://github.com/KongAirlines/bookings) and 
  [customers](https://github.com/KongAirlines/customer) services.
* `flight-data` which owns the [flights](https://github.com/KongAirlines/flights) and
  [destinations](https://github.com/KongAirlines/destinations) services.

Each service repository holds an OpenAPI specification that describes the API contract for the service. For example, 
the `flights` service OpenAPI specification is found in the 
[`openapi.yaml`](https://github.com/KongAirlines/flights/blob/main/openapi.yaml) file located in the root of the `flights` repository. 

The orchestrator is configured to monitor this service application repositories and detect changes 
that are copied to the platform repository. Once the specifications are staged in the platform repository, 
the [APIOps workflow](/konnect-reference-platform/apiops/) process kicks in and guides the platform team in 
delivering changes to {{site.konnect_short_name}}. 

![Kong Air decK sync](/assets/images/reference-platform/kong-air-sync.png)

Feel free to explore the Kong Air organization repositories using what's available to build
your own API delivery system. 

## What's next?

* See the [FAQ page](/konnect-reference-platform/faq) for more Q&A on the reference platform.
* Follow the [How-To guide](/konnect-reference-platform/how-to) for step-by-step instructions on setting up the reference platform for your organization
* Check out the [APIOps workflows page](/konnect-reference-platform/apiops/) to learn about the API Delivery automations built into the reference platform
