---
title: Migrating from Ingress to Gateway API

description: |
  How to migrate from deprecated Ingress API resources (including TCPIngress and UDPIngress) to the Gateway API

content_type: reference
layout: reference
breadcrumbs:
  - /kubernetes-ingress-controller/
products:
  - kic

works_on:
  - on-prem
  - konnect

tags:
  - migration

related_resources:
  - text: Ingress to Gateway FAQ
    url: /kubernetes-ingress-controller/faq/migrate-ingress-to-gateway/
  - text: KongIngress Migration
    url: /kubernetes-ingress-controller/migrate/kongingress/

---

{:.warning}
> **Important: TCPIngress and UDPIngress Deprecation Notice**
>
> `TCPIngress` and `UDPIngress` custom resources are **deprecated** as of {{site.kic_product_name}} 3.5 and will be **completely removed in Kong Operator 2.0.0**. These resources were created to address limitations of the traditional Kubernetes Ingress API, but since the Gateway API has reached maturity and widespread adoption, they are now redundant and cause confusion for users.
>
> **Migration is required** before upgrading to Kong Operator 2.0.0. Use this guide to migrate your existing `TCPIngress` and `UDPIngress` resources to their Gateway API equivalents:
>
> - `TCPIngress` → `Gateway` + `TCPRoute` + `TLSRoute`
> - `UDPIngress` → `Gateway` + `UDPRoute`
>
> Gateway API provides a more standardized, feature-rich, and future-proof approach to configuring network traffic in Kubernetes.

## Why migrate to Gateway API?

The Gateway API offers several advantages over the legacy Ingress resources:

- **Standardization**: Gateway API is an official Kubernetes networking standard, ensuring better interoperability and community support.
- **Enhanced expressiveness**: Gateway API provides more flexible routing capabilities including advanced matching rules, traffic splitting, and policy attachment.
- **Protocol support**: Native support for HTTP/HTTPS, TCP, UDP, and TLS protocols without requiring custom resources.
- **Role-based separation**: Clear separation of concerns between infrastructure operators and application developers.
- **Future-proof**: Active development and continuous improvement by the Kubernetes community.

## Prerequisites

### Enable GatewayAlpha feature gate

{:.important}
> **Required**: To use `TCPRoute`, `UDPRoute`, and `TLSRoute` resources in Kong Ingress Controller, you must enable the `GatewayAlpha` feature gate.

You can enable the `GatewayAlpha` feature gate in one of the following ways:

**If using Helm:**

```bash
helm upgrade --install kong kong/kong \
  --set controller.ingressController.env.feature_gates="GatewayAlpha=true"
```

**If using a deployment manifest:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kong-controller
spec:
  template:
    spec:
      containers:
      - name: controller
        env:
        - name: CONTROLLER_FEATURE_GATES
          value: "GatewayAlpha=true"
```

### Install the ingress2gateway tool

Download the [kubernetes-sigs/ingress2Gateway](https://github.com/kubernetes-sigs/ingress2gateway) CLI tool:

```bash
mkdir ingress2gateway && cd ingress2gateway
curl -L https://github.com/kubernetes-sigs/ingress2gateway/releases/download/v0.4.0/ingress2gateway_$(uname)_$(uname -m).tar.gz | tar -xzv
export PATH=$PATH:$(pwd)
```

## Convert all the YAML files

In order to migrate your resources from `Ingress` API to Gateway API you need all the `Ingress`-based `yaml` manifests. You can use these manifests as the source to migrate to the new API by creating copies that replace the `Ingress` resources with Gateway API resources. Then, use the `ingress2gateway` tool to create new manifests
containing the gateway API configurations.

> **Note**: In this guide the Ingress resources refers to Kubernetes networkingv1 Ingresses, Kong TCPIngresses, and Kong UDPIngresses. This means that **All** these resources should be included in the files used as a source for the conversion.

1. Export your source and destination paths.

    ```bash
    export SOURCE_DIR='YOUR SOURCE DIRECTORY'
    export DEST_DIR='YOUR DESTINATION DIRECTORY'
    ```

1. Convert the manifests and create new files in the destination directory.

    ```bash
    for file in $SOURCE_DIR/*.yaml; do ingress2gateway print --input-file ${file} -A --providers=kong > $DEST_DIR/$(basename -- $file); done
    ```

1. Check the new manifest files have been correctly created in the destination directory.

    ```bash
    ls $DEST_DIR
    ```

1. Copy your annotations from the ingress resources to the Routes. The routes' names use the ingress name as prefix to help you track the route that the ingress generated. All the `konghq.com/` annotations must be copied except for these, that have been natively implemented as Gateway API features.

   1. `konghq.com/methods`
   1. `konghq.com/headers`
   1. `konghq.com/plugins`

## Check the new manifests

The manifests conversion are as follows:

- Ingresses are converted to `Gateway` and `HTTPRoute`s
- TCPIngresses are converted to `Gateway` and `TCPRoute`s and `TLSRoute`s
- UDPIngresses are converted to `Gateway` and `UDPRoute`s

## Migrate from Ingress to Gateway

To migrate from using the ingress resources to the Gateway resources:

1. Apply the new manifest files into the cluster

    ```bash
    kubectl apply -f $DEST_DIR
    ```

1. Wait for all the gateways to be programmed

    ```bash
    kubectl wait --for=condition=programmed gateway -A --all
    ```

## Verify the migration

Before deleting the original resources, verify that your Gateway API resources are working correctly:

1. **Check Gateway status**: Ensure all Gateways have the `Programmed` condition set to `True`:

    ```bash
    kubectl get gateway -A -o wide
    ```

2. **Verify route status**: Check that all routes (HTTPRoute, TCPRoute, UDPRoute) are correctly accepted:

    ```bash
    # Check HTTPRoutes
    kubectl get httproute -A -o custom-columns='NAME:.metadata.name,NAMESPACE:.metadata.namespace,ACCEPTED:.status.parents[0].conditions[0].status'

    # Check TCPRoutes
    kubectl get tcproute -A -o custom-columns='NAME:.metadata.name,NAMESPACE:.metadata.namespace,ACCEPTED:.status.parents[0].conditions[0].status'

    # Check UDPRoutes
    kubectl get udproute -A -o custom-columns='NAME:.metadata.name,NAMESPACE:.metadata.namespace,ACCEPTED:.status.parents[0].conditions[0].status'
    ```

3. **Test connectivity**: Perform connectivity tests to ensure your applications are accessible through the new Gateway API configuration:

    ```bash
    # For HTTP/HTTPS traffic
    curl -H "Host: your-host.example.com" http://<gateway-ip>/your-path

    # For TCP traffic
    telnet <gateway-ip> <tcp-port>

    # For UDP traffic
    nc -u <gateway-ip> <udp-port>
    ```

## Delete the previous configuration

After all the Gateways have been correctly deployed and are programmed, you can delete the legacy ingress resources. **Important**: The Gateways should have the status condition `Programmed` set to `True` before you delete any ingress resources.

{:.warning}
> **Best Practice**: Do not delete all the ingress resources at once. Instead, follow an iterative approach:
> 1. Delete one ingress resource at a time
> 2. Verify that no connectivity is lost
> 3. Monitor application logs and metrics
> 4. Continue with the next resource only after confirming the previous deletion was successful

### Step-by-step deletion process

1. **List all legacy resources** to understand what needs to be removed:

    ```bash
    # List standard Ingresses
    kubectl get ingress -A

    # List deprecated TCPIngresses
    kubectl get tcpingress -A

    # List deprecated UDPIngresses
    kubectl get udpingress -A
    ```

2. **Delete resources one by one**, starting with the least critical:

    ```bash
    # Delete a specific TCPIngress
    kubectl delete tcpingress <tcpingress-name> -n <namespace>

    # Delete a specific UDPIngress
    kubectl delete udpingress <udpingress-name> -n <namespace>

    # Delete a specific Ingress
    kubectl delete ingress <ingress-name> -n <namespace>
    ```

3. **Verify after each deletion** that services remain accessible and functional.
