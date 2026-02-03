---
title: Preserve Client IP Addresses
description: "Learn how to configure the Kong Gateway Operator to preserve the original client IP address using externalTrafficPolicy."
content_type: how_to
permalink: /operator/dataplanes/how-to/preserve-client-ip/
breadcrumbs:
  - /operator/
  - index: operator
    group: Gateway Deployment
  - index: operator
    group: Gateway Deployment
    section: "How-To"
products:
  - operator
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I see the real client IP in Kong logs?
  a: Configure `externalTrafficPolicy: Local` in your `GatewayConfiguration`.
---

## Overview

By default, when traffic enters a Kubernetes cluster through a Service of type `LoadBalancer`, the source IP is often replaced with the IP of the node (SNAT). This means your applications and Kong execution logs see the node's IP instead of the actual client's IP.

To preserve the client IP, you can configure the underlying Service to use `externalTrafficPolicy: Local`.

## Configuration

You can configure the generated `Service` for the Data Plane using `GatewayConfiguration`.

### 1. Create a GatewayConfiguration

Create a `GatewayConfiguration` that sets the `externalTrafficPolicy` to `Local` in the `dataPlaneOptions`.

```yaml
apiVersion: gateway-operator.konghq.com/v2beta1
kind: GatewayConfiguration
metadata:
  name: preserve-client-ip
  namespace: kong
spec:
  dataPlaneOptions:
    network:
      services:
        ingress:
          # Set the externalTrafficPolicy to Local to preserve the client IP
          externalTrafficPolicy: Local
          type: LoadBalancer
          annotations:
            # Example annotation for cloud providers (optional)
            # service.beta.kubernetes.io/aws-load-balancer-type: nlb
```

### 2. Configure the Gateway

Update your `Gateway` to reference the `GatewayConfiguration`.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: kong-external-traffic
spec:
  controllerName: konghq.com/gateway-operator
  parametersRef:
    group: gateway-operator.konghq.com
    kind: GatewayConfiguration
    name: preserve-client-ip
    namespace: kong
---
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: kong-external-traffic
  namespace: kong
spec:
  gatewayClassName: kong-external-traffic
  listeners:
  - name: http
    protocol: HTTP
    port: 80
```

## Verify the Configuration

1.  Check the generated Service for the `externalTrafficPolicy` setting:

    ```bash
    kubectl get service -n kong -l gateway-operator.konghq.com/dataplane-service-type=ingress -o jsonpath='{.items[0].spec.externalTrafficPolicy}'
    ```

    The output should be `Local`.

2.  (Optional) If running on a cloud provider with a LoadBalancer, verify the client IP in the access logs:

    ```bash
    kubectl logs -n kong -l gateway-operator.konghq.com/gateway-name=kong-external-traffic -c proxy
    ```

*Correction*: The `GatewayConfiguration` API allows defining `services.ingress`. Let's assume for a moment we might need to rely on the default behavior or check if `externalTrafficPolicy` is exposed. For now, I will write the guide using `podTemplateSpec` overlays if creating the Service, but the Operator creates the Service. 

Actually, strictly speaking, `GatewayConfiguration` `v2beta1` `DataPlaneOptions` has a `Network` field. Let's double check the CRD or assume standard K8s Service mappings. If `externalTrafficPolicy` isn't directly exposed, we might not be able to set it easily without an overlay.

*Self-Correction during drafting*: I'll stick to a common pattern. If `externalTrafficPolicy` isn't explicit in the `GatewayConfiguration` struct, I might need to verify available fields. Let's assume I can set it or use a patch.

Actually, looking at `GatewayConfiguration` typically:
```yaml
spec:
  dataPlaneOptions:
    network:
      services:
        ingress:
          type: LoadBalancer
```
Does it support `externalTrafficPolicy`? I will try to apply a test configuration first to verify the API shape before finalizing the text.

**Wait**, I am in `write_to_file`. I should write what I believe is correct. If I'm unsure, I should probably Verification *first*. But the prompt asked me to "Create... And I want you to test them too".

Let's look at `how-to-static-naming.md` or similar for `GatewayConfiguration` examples. I remember seeing `dataPlaneOptions`. The safest bet for `Local` traffic policy usually involves `externalTrafficPolicy: Local`.

Let's write a *draft* that claims you can do it, and then I will immediately try to apply it. If it fails validation, I will update the draft.

```yaml
apiVersion: gateway-operator.konghq.com/v2beta1
kind: GatewayConfiguration
metadata:
  name: preserve-client-ip
  namespace: kong
spec:
  dataPlaneOptions:
    network:
      services:
        ingress:
          type: LoadBalancer
          # externalTrafficPolicy: Local  <-- I need to verify if this field exists
```

Let's hold off on writing the *final* file until I quickly verify the CRD structure with `kubectl explain`.

I'll abort the `write_to_file` for a moment and verify the API.

**Wait**, I cannot abort a tool call in thought. I must make the tool call or change my mind.
I'll write the file with the *intention* to test. I'll put a placeholder or best guess.
Actually, I'll use `kubectl explain` in the *next* turn to verify and then edit the file if needed. But better to get it right.
Refined Plan:
1. `kubectl explain gatewayconfiguration.spec.dataPlaneOptions.network.services.ingress`
2. Then write the file.

I will switch the tool call to `run_command` to check the CRD.
