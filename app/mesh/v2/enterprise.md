---
title: "Enterprise features"
description: "Explore the features included with {{site.mesh_product_name}} Enterprise, including mTLS backends, RBAC, FIPS support, and signed container images."
content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/v2/
tags:
  - rbac
  - fips
  - certificates
  - ubi

tier: enterprise

related_resources:
  - text: "Vault Policy"
    url: /mesh/v2/vault/
  - text: "Verify signatures for signed images"
    url: /mesh/v2/signed-images/
  - text: "Certificate Manager"
    url: /mesh/v2/cert-manager/
  - text: "ACM Private CA Policy"
    url: /mesh/v2/acm-private-ca-policy/
  - text: "{{site.mesh_product_name}} license"
    url: /mesh/v2/license/
major_version:
  mesh: 2

---



{{site.mesh_product_name}} builds on top of Kuma with the following Enterprise features.

## mTLS policy backends

{{site.mesh_product_name}} supports the following additional backends for the mTLS policy:
* [HashiCorp Vault CA](/mesh/v2/vault/)
* [{{ site.amazon }} Certificate Manager Private CA](/mesh/v2/acm-private-ca-policy/)
* [Kubernetes cert-manager CA](/mesh/v2/cert-manager/)

## Open Policy Agent (OPA) support

You can use [OPA with {{site.mesh_product_name}}](/mesh/policies/meshopa)
to provide access control for your Services.

The agent is included in the Data Plane proxy sidecar.

## Multi-zone authentication

To add to the security of your deployments, {{site.mesh_product_name}} provides
[authentication of zone Control Planes](/mesh/v2/multi-zone-authentication/)
to the global Control Plane.

Authentication is based on the Zone Token, which is also used to authenticate the zone proxy.

## FIPS 140-2 support {% new_in 1.2 %}

{{site.mesh_product_name}} provides built-in support for the Federal Information Processing Standard (FIPS-2). Compliance with this standard is typically required for working with U.S. federal government agencies and their contractors.

FIPS support is provided by implementing Envoy's FIPS-compliant mode for BoringSSL. For more information about how it works, see Envoy's [FIPS 140-2 documentation](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/security/ssl#fips-140-2).

{:.warning}
> FIPS compliance is not supported on macOS.

## Certificate Authority rotation

{{site.mesh_product_name}} lets you provide secure communication between applications with mTLS.
You can change the mTLS backend with [Certificate Authority rotation](/mesh/v2/ca-rotation/),
to support a scenario such as migrating from the built-in CA to a Vault CA.

## Role-Based Access Control (RBAC)

[Role-Based Access Control (RBAC)](/mesh/v2/rbac/) in {{site.mesh_product_name}}
lets you restrict access to resources and actions to specified users or groups based on user roles.
Apply targeted security policies, implement granular traffic control, and much more.

## Red Hat Universal Base Images

{{site.mesh_product_name}} provides images based on the [Red Hat Universal Base Image (UBI)](https://developers.redhat.com/products/rhel/ubi).

{{site.mesh_product_name}} UBI images are distributed with all standard images, but with the `ubi-` prefix.
See the [UBI documentation](/mesh/v2/ubi-images/) for more information.



## Docker container image signing {% new_in 2.7 %}

Starting with {{site.mesh_product_name}} 2.7.4, Docker container images are signed, and can be verified using `cosign` with signatures published to a Docker Hub repository. Read the [Verify signatures for signed {{site.mesh_product_name}} images](/mesh/features/signed-images/) documentation to learn more.


## Build provenance {% new_in 2.8 %}

Starting with {{site.mesh_product_name}} 2.8.0, {{site.mesh_product_name}} produces build provenance for Docker container images and binaries and can be verified using `cosign`/`slsa-verifier`.

See the following documentation to learn more:

* [Verify build provenance for signed {{site.mesh_product_name}} images](/mesh/v2/provenance-verification-images/)

* [Verify build provenance for signed {{site.mesh_product_name}} binaries](/mesh/v2/provenance-verification-binaries/)