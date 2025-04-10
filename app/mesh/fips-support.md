---
title: "FIPS Support"
description: "Learn how {{site.mesh_product_name}} supports FIPS 140-2 compliance using Envoy’s BoringSSL FIPS mode for secure environments."
content_type: reference
layout: reference
products:
  - mesh

tags:
  - fips
  - security

related_resources:
  - text: "Enterprise Features"
    url: /gateway_entities/rbac/
  - text: "Enterprise Features"
    url: /mesh/enterprise/
  - text: "Verify signatures for signed images"
    url: /mesh/signed-images/
---

With version 1.2.0, {{site.mesh_product_name}} provides built-in support for the Federal Information Processing Standard (FIPS-2). Compliance with this standard is typically required for working with U.S. federal government agencies and their contractors.

FIPS support is provided by implementing Envoy's FIPS-compliant mode for BoringSSL. For more information about how it works, see Envoy's [FIPS 140-2 documentation](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/security/ssl#fips-140-2).

{:.important}
> FIPS compliance is not supported on macOS.
