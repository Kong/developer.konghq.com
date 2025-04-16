---
title: "Enterprise Features"
description: "Explore the features included with {{site.mesh_product_name}} Enterprise, including mTLS backends, RBAC, FIPS support, and signed container images."
content_type: reference
layout: reference
products:
  - mesh

tags:
  - enterprise

tier: enterprise

related_resources:
  - text: "Vault Policy"
    url: /mesh/vault/
  - text: "Verify signatures for signed images"
    url: /mesh/signed-images/
  - text: "Certificate Manager"
    url: /mesh/cert-manager/
  - text: "ACM Private CA Policy"
    url: /mesh/acm-private-ca-policy/
---



{{site.mesh_product_name}} builds on top of Kuma with the following Enterprise features:

## mTLS policy backends

{{site.mesh_product_name}} supports the following additional backends for the
[mTLS policy](/mesh/policies/mutual-tls/):
* [HashiCorp Vault CA](/mesh/vault/)
* [Amazon Certificate Manager Private CA](/mesh/acm-private-ca-policy/)
* [Kubernetes cert-manager CA](/mesh/cert-manager/)

## Open Policy Agent (OPA) support

You can use [OPA with {{site.mesh_product_name}}](@TODO)
to provide access control for your services.

The agent is included in the data plane proxy sidecar.

## Multi-zone authentication

To add to the security of your deployments, {{site.mesh_product_name}} provides
[authentication of zone control planes](/mesh/kds-auth)
to the global control plane.

Authentication is based on the Zone Token, which is also used to authenticate the zone proxy.

##  FIPS 140-2 support

{{site.mesh_product_name}} provides built-in support for the Federal Information Processing Standard (FIPS-2).
See [FIPS Support](/mesh/fips-support/) for more information.

##  Certificate Authority rotation

{{site.mesh_product_name}} lets you provide secure communication between applications with mTLS.
You can change the mTLS backend with [Certificate Authority rotation](/mesh/ca-rotation/),
to support a scenario such as migrating from the builtin CA to a Vault CA.

## Role-Based Access Control (RBAC)

[Role-Based Access Control (RBAC)](/mesh/rbac) in {{site.mesh_product_name}}
lets you restrict access to resources and actions to specified users or groups based on user roles.
Apply targeted security policies, implement granular traffic control, and much more.

## Red Hat Universal Base Images

{{site.mesh_product_name}} provides images based on the [Red Hat Universal Base Image (UBI)](https://developers.redhat.com/products/rhel/ubi).

{{site.mesh_product_name}} UBI images are distributed with all standard images, but with the `ubi-` prefix.
See the [UBI documentation](/mesh/ubi-images/) for more information.



{% if_version gte:2.7.x %}

## Docker container image signing

Starting with {{site.mesh_product_name}} 2.7.4, Docker container images are signed, and can be verified using `cosign` with signatures published to a Docker Hub repository. Read the [Verify signatures for signed {{site.mesh_product_name}} images](/mesh/features/signed-images/) documentation to learn more.
{% endif_version %}

{% if_version gte:2.8.x %}

## Build provenance

Starting with {{site.mesh_product_name}} 2.8.0, {{site.mesh_product_name}} produces build provenance for Docker container images and binaries and can be verified using `cosign` / `slsa-verifier`.

See the following documentation to learn more:

* [Verify build provenance for signed {{site.mesh_product_name}} images](/mesh/features/provenance-verification-images/)

* [Verify build provenance for signed {{site.mesh_product_name}} binaries](/mesh/features/provenance-verification-binaries/)
{% endif_version %}