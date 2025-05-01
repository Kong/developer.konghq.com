---
title: Konnect Reference Platform - Orchestrator
content_type: reference
layout: reference

products:
    - api-ops
    - reference-platform
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

The {{site.konnect_short_name}} Orchestrator is a software tool provided as part of the 
[{{site.konnect_short_name}} Reference Platform](/konnect-reference-platform/).
The tool is a [Go based project](https://github.com/Kong/konnect-orchestrator) and released 
as a binary named `koctl`. We will refer to the tool by the `koctl` name in this document.

`koctl` is a multi-purpose CLI based tool. With `koctl`, you can initialize a git repository 
to support an API management platform, configure the repository to support your development teams,
and apply declarative configurations to your [{{site.konnect_product_name}}](https://konghq.com/products/kong-konnect)
organizations.

## What specifically can `koctl` do?

The `koctl` tool is specifically designed to enable and apply the concepts for the 
[{{site.konnect_short_name}} Reference Platform](/konnect-reference-platform/)

The tool provides the following general functions as part of the platform:

* Initialize a central platform team git repository which supports the API management platform
* Configures the platform repository with new organizations and environments 
* Provides an API server and web based UI applicaiton to self-service onboarding for developer teams and their service applications
* Stages service application API specifications to the platform repository preparing them to be delivered to {{site.konnect_short_name}}
* Applies declarative configuration within the platform repository CICD pipeline to {{site.konnect_short_name}} organizations

## How do I install `koctl`?

MacOS users can install the orchestrator using Homebrew:

```shell
brew install kong/konnect-orchestrator/koctl
```

On Linux or Windows, install the orchestrator directly from the releases page on GitHub:

[Releases - Kong/konnect-orchestrator](https://github.com/Kong/konnect-orchestrator/releases)

## How do I use `koctl`?

For the complete instructions for running the orchestrator as part of building an API management platform,
see the step-by-step [how-To](/konnect-reference-platform/how-to/) guide. 

## Where can I see `koctl` source?

The orchestrator is open source and the code can be found in the GitHub repository:

[https://github.com/Kong/konnect-orchestrator](https://github.com/Kong/konnect-orchestrator)

## Where can I get more information?

Additional questions may be answered in the [FAQ](/konnect-reference-platform/faq/) page. If your
question is not answered there, please feel free to reach out on the 
[Kong Nation](https://discuss.konghq.com/) discussion forums.
