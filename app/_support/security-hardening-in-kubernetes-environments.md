---
title: Security Hardening in Kubernetes Environments
content_type: support
description: As a guide on pod security, we recommend the official Kubernetes guide as a reference.
products:
  - kic
works_on:
  - on-prem
  - konnect
related_resources:
  - text: Pod Security Admission
    url: https://kubernetes.io/docs/concepts/security/pod-security-admission/
  - text: Pod Security Standards
    url: https://kubernetes.io/docs/concepts/security/pod-security-standards/
  - text: OPA Gatekeeper
    url: https://open-policy-agent.github.io/gatekeeper/website/docs/
  - text: Kyverno
    url: https://kyverno.io/
tldr:
  q: What does Kong recommend for hardening pod security in Kubernetes now that `PodSecurityPolicy` is deprecated?
  a: |
    `PodSecurityPolicy` is deprecated (Kubernetes 1.21) and removed (Kubernetes 1.25), so the Kong Helm chart's legacy `podSecurityPolicy` section should stay disabled on current clusters. Use Kubernetes' built-in Pod Security Admission or a policy engine like OPA Gatekeeper or Kyverno instead.
---

## Problem

It's unclear how to implement a Kubernetes pod security policy to harden the default K8S security model for a cluster running Kong.

`PodSecurityPolicy` was deprecated in Kubernetes 1.21 and removed entirely in Kubernetes 1.25. On any currently supported Kubernetes cluster, the `PodSecurityPolicy` API no longer exists, so applying a PSP manifest fails outright.

## Solution

The Kong Helm chart still contains a legacy `podSecurityPolicy` section for backward compatibility, but it should be left disabled (`enabled: false`, the default) on any Kubernetes 1.25+ cluster, since enabling it renders a manifest for an API that no longer exists and will fail to apply.

For pod security hardening on current Kubernetes versions, we recommend one of the following instead:

- Pod Security Admission, Kubernetes' built-in replacement for PSP, which enforces the Pod Security Standards via namespace labels (for example, `pod-security.kubernetes.io/enforce: restricted`).
- A policy engine such as OPA Gatekeeper or Kyverno, for more granular or custom policy enforcement than Pod Security Admission alone provides.

Kong does not have any off the shelf step-by-step guides on this type of work as it is on a per-requirement basis and this will change depending on your organization. However, we hope the above guide will provide a basis to start this type of customization.
