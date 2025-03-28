---
title: Konnect Reference Platform - Orchestrator
content_type: reference
layout: reference

products:
    - api-ops
works_on:
  - konnect

description: What is the Konnect Orchestrator and how is it used?

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
---

The Konnect Orchestrator is a software tool provided as part of the {{site.konnect_short_name}} Reference Platform.
The tool performs the following functions:

* Reconciles a declarative configuration into one or more of you {{site.konnect_short_name}} organizations
* Maintains APIOps workflows in a Platform Team repository
* Connects your service application repositories with a platform team repository by application API specifications

It is used to manage the state of the {{site.konnect_short_name}} deployment and API delivery pipeline.

## How does the Orchestrator work?

Questions on how the orchestrator works are answered in the reference platform [FAQ page](/konnect-reference-platform/faq/).

## How do I run the Orchestrator?

The of the reference platform has options for how to use the orchestrator. Initially, you may choose to run the tool
as a simple CLI applying a configuration to a new {{site.konnect_short_name}} to evaluate the capabilities of the platform.
You can may also choose to run the tool continuously to monitor changes to the input declarative configuration, as well as
provide a self-service UI tool for service application onboarding.

## Where can I see the Orchestrator source?

The source code for the orcehstrator is open source and can be found in the GitHub repository:

https://github.com/Kong/konnect-orchestrator
