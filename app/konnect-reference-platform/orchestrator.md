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

The Konnect Orchestrator is a software tool provided as part of the [{{site.konnect_short_name}} Reference Platform](/konnect-reference-platform/).
The orchestrator's job is to enable an API Management Platform for you by integrating [{{site.konnect_product_name}}](https://konghq.com/products/kong-konnect)
with your existing engineering source code repositories and software delivery workflows.

## What does the Orchestrator do?

The tool performs the following functions:

* Accepts a declarative configuration as input, specifying a centralized platform team repository and a set of service application 
  repositories organized as teams.
* Reconciles the configuration into one or more [{{site.konnect_product_name}}](https://konghq.com/products/kong-konnect) 
  organizations, applying an opinionated set of resource configurations based on the configuration provided 
* Maintains APIOps workflows (GitHub actions) in a _platform repository_
* Hosts an API service which provides data for a self-service UI to onboard teams to your platform
* Stages versions of service application specifications in a _platform repository_ for delivery to {{site.konnect_short_name}} via the
  APIOps workflows

## How do I install the Orchestrator?

MacOS users can install the orchestrator using Homebrew:

```shell
brew install kong/konnect-orchestrator/koctl
```

On Linux or Windows, install the orchestrator directly from the releases page on GitHub:

[Releases - Kong/konnect-orchestrator](https://github.com/Kong/konnect-orchestrator/releases)

## How do I run the Orchestrator?

Currently, the orchestrator is ran from the command line on your development machine. You create a declarative configuration 
file and pass it to the command as a argument. We are exploring other ways for the orchestrator to operate, such as
running it within a CI/CD pipeline. 

The most up-to-date instructions for running the orchestrator are found in the step-by-step [how-To](/konnect-reference-platform/how-to/) 
guide. 

## Where can I see the Orchestrator source?

The orchestrator is open source and the code can be found in the GitHub repository:

[https://github.com/Kong/konnect-orchestrator](https://github.com/Kong/konnect-orchestrator)

## Where can I get more information?

Additional questions may be answered in the [FAQ](/konnect-reference-platform/faq/) page. If your
question is not answered there, please feel free to reach out on the 
[Kong Nation](https://discuss.konghq.com/) discussion forums.
