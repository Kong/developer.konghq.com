---
title: How to temporarily disable KIC Admission Controller
content_type: support
description: How to temporarily disable the KIC Admission Controller for testing and troubleshooting, and re-enable it afterward.
products:
  - kic
works_on:
  - on-prem
  - konnect
related_resources:
  - text: "Admission Controller documentation"
    url: "/kubernetes-ingress-controller/admission-webhook/"
tldr:
  q: How do I temporarily disable the KIC Admission Controller for testing?
  a: |
    Back up the current `kong-kong-validations` `ValidatingWebhookConfiguration` with `kubectl get ... -o yaml > kong-validations.yaml`, then delete it with `kubectl delete validatingwebhookconfigurations.admissionregistration.k8s.io kong-kong-validations` to stop Kubernetes from calling the webhook. Restore it later with `kubectl apply -f kong-validations.yaml`. This only fully disables validation if it's the only matching webhook configuration in the cluster.
---

## Overview

While troubleshooting we might be interested to temporarily disable Kubernetes Ingress Controller Admission Controller. Or in some situations where we get errors connecting the validation service:

```bash

kubectl apply -f repro.yaml 
Error from server (InternalError): error when creating "repro.yaml": Internal error occurred: failed calling webhook "validations.kong.konghq.com": Post "https://kong-kong-validation-webhook.kong.svc:443/?timeout=10s": service "kong-kong-validation-webhook" not found
```

## Steps

To temporarily disable the Admission Controller, for testing and troubleshooting, you can run these commands in your K8s cluster to:

1. Get the current `kong-kong-validations` configuration and save it to a file, `kong-validations.yaml`:

   ```bash
   kubectl get validatingwebhookconfigurations.admissionregistration.k8s.io kong-kong-validations -o yaml > kong-validations.yaml
   ```

2. Delete the `kong-kong-validations` webhook configuration:

   ```bash
   kubectl delete validatingwebhookconfigurations.admissionregistration.k8s.io kong-kong-validations
   ```

To enable the Admission Controller again you can recover from the file created in previous step:

```bash

kubectl apply -f kong-validations.yaml
```

Note: this only fully disables admission control if the deleted `ValidatingWebhookConfiguration` is the only Kong-related one in the cluster. Kubernetes invokes every `ValidatingWebhookConfiguration` that matches a given resource, not just the one belonging to a particular KIC release. If there is more than one KIC installation in the cluster, each with its own webhook configuration, you must delete all of the matching webhook configurations to actually let an otherwise-invalid config through - deleting just one release's configuration will not do it, since the others will still intercept the request.

More information about the Admission Controller can be found in the Admission Controller documentation.
