---
title: Deployment Models
description: 'There are more multiple ways to deploy your APIs, this doc explains the various advantages and trade-offs across the deployment strategies.'
content_type: reference
layout: reference
products:
    - gateway
tools:
    - admin-api
    - konnect-api
    - deck
    - kic
    - terraform
related_resources:
  - text: Gateway Services
    url: /gateway/entities/service/
  - text: Routing in {{site.base_gateway}}
    url: /gateway/routing/
  - text: Workspaces
    url: /gateway/entities/workspace
---


# {{site.base_gateway}} Deployment Models

{{site.base_gateway}} provides multiple solutions to address your API gateway platform requirements. {{site.base_gateway}} Enterprise and Konnect make up the on-premises and SaaS hosted products respectively. This document explains all of the options you have in deploying the components of both products, and discusses trade-offs across various deployment strategies.


## Deployment Topologies 

{{site.base_gateway}} supports a variety of deployment topologies. In some cases, control and Data Planes are run as a single process, but often they are run independently, in **Hybrid Mode**. Hybrid Mode decouples the control and Data Planes, allowing for scale, resiliency, security, and optimized resource usage. How you choose to deploy these components will depend on your specific organization’s priorities and capabilities.

## {{site.base_gateway}} Configuration

The {{site.base_gateway}} configuration (`kong.conf`) is the main system that defines the gateway’s runtime proxying behavior. This configuration includes Services, Routes, Plugins, and other entities that determine the behavior of the gateway while routing client traffic.

In Hybrid Mode, all connected Data Planes receive the full configuration from their connected Control Plane. This design allows the Data Plane nodes to be fungible, meaning any node in the cluster can serve traffic for any client (assuming network connectivity). There are, however, tradeoffs to this design, and how you organize your {{site.base_gateway}} configurations will largely depend on the deployment strategies you choose.

## Tenancy Tradeoffs

{{site.base_gateway}} uses single tenant and multi-tenant designs in the different deployment strategies. It's important to understand the tradeoffs of each before deciding on a deployment strategy.

| **Design**           | **Advantages**                                    | **Disadvantages**                                  |
|----------------------|---------------------------------------------------|----------------------------------------------------|
| **Single Tenancy**    | - Strongest tenant data protection                | - Higher operational burden                        |
|                      | - Prevents unintended exposure of data across tenants | - Potential resource under-utilization             |
| **Multi-Tenancy**     | - Lower operational burden                        | - Weaker tenant data protections                   |
|                      | - Potential resource optimization                 | - "Noisy neighbor" problem                        |

Generally, single-tenant solutions promote stronger data segregation and reduce noisy neighbor concerns at the cost of more operational overhead. Multi-tenant solutions allow for greater resource utilization and potentially reduce operational toil while securely commingling tenant data within the software boundaries. 

## Deployment Strategies

We’re going to look at the different deployment strategies for {{site.base_gateway}}. We’ll break these strategies down by the combination of tenancy in both the control and Data Planes.

| Deployment topology | Control Plane tenant type | Data Plane tenant type |
|--------------------|---------------------------|------------------------|
| Default Model | Single | Single |
| Workspaces Model | Multi | Multi |
| Runtime Group Model | Multi | Single |

### {{site.base_gateway}} Enterprise Default Model

Single tenant control and Data Planes are the default behavior in {{site.base_gateway}}. For single tenancy, designing the gateway configuration is straightforward, as you don’t need to be concerned with logical separation of objects within the configuration. Each configuration supports one tenant, and every deployed Data Plane will receive the full configuration. Every Data Plane node can Route traffic for every client (assuming network connectivity). 

In this model, you’ll be required to manage a full deployment for each tenant in your organization. Every tenant added in this model will incur direct increases in actual compute expense and indirect added expense in operational burden. In return, each tenant will have a full dedicated deployment that includes allocated Data Plane compute and a fully isolated Control Plane configuration.

### {{site.base_gateway}} Enterprise Workspaces Model

In {{site.base_gateway}} Enterprise, multi-tenancy is supported with **Workspaces**. Workspaces provide an isolation of gateway configuration objects while maintaining a unified routing table on the Data Plane to support client traffic.

How you design your Workspaces is largely influenced by your specific requirements and the layout of your organization. You may choose to create Workspaces for teams, business units, environments, projects, or some other aspect of your system.

When pairing Workspaces with **RBAC**, {{site.base_gateway}} Administrators can effectively create tenants within the Control Plane. The gateway Administrator creates Workspaces and assigns Administrators to them. The workspace Administrators have segregated and secure access to only their portion of the gateway configuration in Kong Manager, the Admin API, and the declarative configuration tool **decK**.

When Workspaces are in use, the shared Data Plane routes client traffic based on a unified routing table built from the aggregate of all the tenants' Workspaces. Configuring Kong entities related to routing, such as Services and Routes, may alter the client traffic routing behavior of the Data Plane. {{site.base_gateway}} attempts to ensure that the routing rules don’t contain conflicts before applying them to the Data Plane, but as you’ll see, this isn’t always straightforward.

For example, two separate tenants may desire to have an API Route path matching `/users`. This won’t work with a shared Data Plane — the gateway does not know which upstream Service should receive the traffic to `/users`. When an Administrator attempts to modify a configuration object that will change the routing behavior, {{site.base_gateway}} will first run the internal Router and determine if a conflict exists with any existing Routes or Services. If a conflict exists, the request is rejected prior to modifying the routing rules of the shared Data Plane. 

{{site.base_gateway}} supports routing rules based on regular expressions, which complicates the Route collision detection mechanism when Workspaces are in use. Regular expressions can’t be fully evaluated by the conflict detection algorithm to prevent all collisions. The 
documentation on Workspaces contains details on how conflicts are detected across, and within, Workspaces.



### {{site.konnect_product_name}} Runtime Group Model

{{site.konnect_product_name}} is an end-to-end SaaS API lifecycle management platform. Included in {{site.konnect_product_name}} is **Gateway Manager**, a fully hosted, cloud-native gateway Control Plane management system. Using Gateway Manager, you can provision virtual Control Planes, called **Runtime Groups**, which are lightweight Control Planes that provision instantly and provide segregated management of runtime configurations.

Generally, a multi-tenant Control Plane paired with single-tenant Data Planes allows for centralized control over shared API gateway configurations, while allowing for flexible control over Data Plane deployment and management. A few specific examples include:

- The central operational teams want to relax control over pre-production environments. For example, if there are dozens of pre-production environments spread across multiple development teams, management of pre-prod environments can be delegated to development teams, freeing them of central control for experimentation and testing.
- Central API management is required but, for performance reasons, Data Planes can’t be shared. In high-traffic environments, the noisy neighbor problem for shared Data Planes may not be an acceptable tradeoff. In this model, the Data Plane is single tenant while the Control Plane is multi-tenant.

{{site.konnect_product_name}} allows you to define a management hierarchy


