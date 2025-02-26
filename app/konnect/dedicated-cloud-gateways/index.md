---
title: "Dedicated Cloud Gateway"
content_type: reference
layout: reference
description: | 
    Serverless Gateways are lightweight data plane nodes that are fully managed by {{site.konnect_short_name}}.

no_version: true
products:
    - gateway
works_on:
    - konnect
api_specs:
    - konnect/control-planes-config
faqs:
  - q: Will a new Serverless Gateway be provisioned in the same region as {{site.konnect_short_name}}?
    a: Deployment on the same region is not guaranteed.
  - q: What {{site.base_gateway}} version do Serverless Gateways run?
    a: The default is always `latest` and will be automatically upgraded.
  - q: Can Control Planes contain both Serverless Gateway Data Planes and self-managed Data Planes?
    a: No. Control Planes that utilize Serverless Gateways can't mix types of Data Planes.
  - q: Does Serverless Gateway support private networking?
    a: No, Serverless Gateways only supports public networking. There are currently no capabilities for private networking between your data centers and hosted Kong data planes. For use cases where private networking is required, [Dedicated Cloud Gateways](/konnect/dedicated-cloud-gateway/) configured with AWS is a better choice.

related_resources:
  - text: Konnect Advanced Analytics
    url: /konnect/advanced-analytics/
---

@TODO