---
title: "`no matches for kind` error in Kong Ingress Controller logs when a required CRD is missing"
content_type: support
description: "The Kong Ingress Controller crash-loops with a `no matches for kind` error when a required CRD, such as `IngressClassParameters`, is missing. Apply the missing CRD from the Kong Helm chart repository to resolve it."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: CRD Reference
    url: https://github.com/Kong/charts/blob/main/charts/kong/crds/custom-resource-definitions.yaml#L2-L52
tldr:
  q: Why does the Kong Ingress Controller log a `no matches for kind` error and crash-loop?
  a: |
    The error means a required CRD is missing — for example `IngressClassParameters`. Confirm with `kubectl get crd | grep kong`, then apply the missing CRD definition from the Kong Helm chart's `custom-resource-definitions.yaml` and restart the Kong Ingress Controller. The same steps apply to any missing Kong CRD.
---

## Problem

We had a working environment and now the ingress controller container is running into a crashbackoop error and won't start up successfully.

When we view the logs we see the following error being repeated:

```
time="2026-11-03T13:36:49Z" level=error msg="if kind is a CRD, it should be installed before calling Start" error="no matches for kind \"IngressClassParameters\" in version \"configuration.konghq.com/v1alpha1\"" kind="{\"Group\":\"configuration.konghq.com\",\"Kind\":\"IngressClassParameters\"}" logger=controller-runtime.source
```

## Cause

This error indicates that the CRD in reference is missing and is required. In this case the CRD `IngressClassParameters` is not available.

## Solution

First, let's verify that the CRD itself is missing.

Run the command:

```bash
kubectl get crd | grep kong
```

Output should look something like this:

```
kongclusterplugins.configuration.konghq.com         2026-09-19T20:10:17Z
kongconsumers.configuration.konghq.com              2026-09-19T20:10:17Z
kongingresses.configuration.konghq.com              2026-09-19T20:10:17Z
kongplugins.configuration.konghq.com                2026-09-19T20:10:17Z
tcpingresses.configuration.konghq.com               2026-09-19T20:10:17Z
udpingresses.configuration.konghq.com               2026-09-19T20:10:17Z
```

We can see there is no `IngressClassParameters` in this CRD section. It is safe to apply the CRD.

Can you grab the highlighted portion of the link above. Save it to a file (`ingressClassParameters.yaml`) and apply the CRD to your environment. Then restart the KIC and that specific error should be resolved.

```bash
kubectl apply -f ingressClassParameters.yaml
```

Once complete we can view the CRDs again:

```
Command:
k get crd | grep ingressclass

Output:
ingressclassparameterses.configuration.konghq.com   2026-11-03T19:37:46Z
```

The same procedure can be followed for any missing Kong CRD.
