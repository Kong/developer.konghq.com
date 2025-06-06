---
title: Migrating from Ingress to Gateway

description: |
  How to migrate from Ingress API to Gateway API

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

---

## Prerequisites

Download the [Kong preview](https://github.com/kong/ingress2gateway) of the [kubernetes-sigs/ingress2Gateway](https://github.com/kubernetes-sigs/ingress2gateway) CLI tool:

```bash
mkdir ingress2gateway && cd ingress2gateway
curl -L https://github.com/Kong/ingress2gateway/releases/download/v0.1.0/ingress2gateway_$(uname)_$(uname -m).tar.gz | tar -xzv
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
    for file in $SOURCE_DIR/*.yaml; do ingress2gateway print --input-file ${file} -A --providers=kong --all-resources > $DEST_DIR/$(basename -- $file); done
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

## Delete the previous configuration

After all the Gateways have been correctly deployed and are programmed, you can delete the ingress resources. In other words the Gateways should have the status condition `Programmed` set, and status field set to `True` before you delete the ingress resources. delete the ingress resources.

> **Note**: It is a best practice to not delete all the ingress resources at once, but instead iteratively delete one ingress at a time, verify that no connection is lost, then continue.