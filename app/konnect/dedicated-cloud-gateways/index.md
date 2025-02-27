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
  - q: Will a new serverless gateway be provisioned in the same region as {{site.konnect_short_name}}?
    a: Deployment on the same region is not guaranteed. 
  - q: What {{site.base_gateway}} version do serverless gateways run?
    a: The default is always `latest` and will be automatically upgraded.
  - q: Can Control Planes contain both serverless gateway Data Planes and self-managed Data Planes?
    a: No. Control Planes that use serverless gateways can't mix types of Data Planes.
  - q: Does Serverless Gateway support private networking?
    a: No, serverless gateways only supports public networking. There are currently no capabilities for private networking between your data centers and Kong-hosted data planes. For use cases where private networking is required, [Dedicated Cloud Gateways](/konnect/dedicated-cloud-gateways/) configured with AWS is a better choice.
  - q: My serverless custom domain attachment failed, how do I troubleshoot it?
    a: |
      If your custom domain attachment fails, check if your domain has a Certificate Authority Authorization (CAA) record restricting certificate issuance. Serverless Gateways use Let's Encrypt CA to provision SSL/TLS certificates. If your CAA record doesn't include the required CA, certificate issuance will fail.

      You can resolve this issue by doing the following:

      1. Check existing CAA records by running `dig CAA yourdomain.com +short`.
      If a CAA record exists but doesn't allow Let's Encrypt (`letsencrypt.org`), update it.   
      2. Update the CAA record, if needed. For example: `yourdomain.com.    CAA    0 issue "letsencrypt.org"`
      3. Wait for DNS propagation and retry attaching your domain.

      If no CAA record exists, no changes are needed. For more information, see the [Let's Encrypt CAA Guide](https://letsencrypt.org/docs/caa/).

related_resources:
  - text: Konnect Advanced Analytics
    url: /konnect/advanced-analytics/
---

@TODO

pull content from https://docs.konghq.com/konnect/gateway-manager/dedicated-cloud-gateways/