---
title: Upgrading {{ site.base_gateway }} using Helm

description: |
  What do I need to know when upgrading {{site.base_gateway}} on Kubernetes? DB-backed mode vs DB-less

content_type: reference
layout: reference
breadcrumbs:
  - /kubernetes-ingress-controller/
  - index: kubernetes-ingress-controller
    section: FAQs
products:
  - kic
tags: 
  - helm
  - upgrade
search_aliases: 
  - upgrade gateway helm
works_on:
  - on-prem
  - konnect

related_resources:
  - text: Upgrading {{ site.kic_product_name }}
    url: /kubernetes-ingress-controller/faq/upgrading-ingress-controller/
---

Every {{ site.kic_product_name }} deployment consists of two components that can be upgraded independently (learn more in [deployment methods](/index/kubernetes-ingress-controller/#deployment-topologies)).

- {{ site.kic_product_name }} (a Control Plane),
- {{ site.base_gateway }} (a Data Plane).

To see the available {{ site.base_gateway }} images, see [kong/kong-gateway](https://hub.docker.com/r/kong/kong-gateway/tags) on Docker Hub:

## Prerequisites

- {{ site.kic_product_name }} installed using the `kong/ingress` Helm chart
- Enure your Helm charts repository is up-to-date by running `helm repo update`
- [yq](https://github.com/mikefarah/yq) installed (for YAML processing)
- Check the version of {{ site.base_gateway }} and {{ site.kic_product_name }} you're currently running:

   ```bash
   helm get values --all kong -n kong  | yq '{
     "gateway": .gateway.image.repository + ":" + .gateway.image.tag,
     "controller": .controller.ingressController.image.repository + ":" + .controller.ingressController.image.tag
   }'
   ```

   As an output, you should get the versions of {{ site.base_gateway }} and {{ site.kic_product_name }} deployed in your cluster, for example:

   ```text
   gateway: kong/kong-gateway:{{ site.data.gateway_latest.release }}
   controller: kong/kubernetes-ingress-controller:{{ site.data.kic_latest.release }}
   ```

    To understand which version of {{ site.base_gateway }} is compatible with your version of {{ site.kic_product_name }}, refer to the [compatibility matrix](/kubernetes-ingress-controller/version-compatibility/#kong-gateway).

{:.warning}
>  **Upgrading {{ site.base_gateway }} in DB mode**
>
> There may be database migrations to run when running {{ site.base_gateway }} in DB-backed mode.
> See [Upgrade {{ site.base_gateway }} 3.x.x](/gateway/upgrade/) to learn more about upgrade paths between different versions of {{ site.base_gateway }}.

## Upgrade {{ site.base_gateway }} using Helm

1. Edit or create a `values.yaml` file so that it contains a `gateway.image.tag` entry. Set this value to the version of {{ site.base_gateway }} to be installed.

    ```yaml
    gateway:
      image:
        tag: "{{site.data.gateway_latest.release}}"
    ```

1. Run `helm upgrade` with the `--values` flag.

    ```bash
    helm upgrade -n kong kong kong/ingress --values values.yaml --wait
    ```

    The result should look like this:
    
    ```bash
    Release "kong" has been upgraded. Happy Helming!
    NAME: kong
    LAST DEPLOYED: Fri Nov  3 15:27:49 2023
    NAMESPACE: kong
    STATUS: deployed
    REVISION: 5
    TEST SUITE: None
    ```

    Pass `--wait` to `helm upgrade` to ensure that the command only returns when the rollout finishes successfully. 

1. Verify the upgrade by checking the version of {{ site.base_gateway }} Deployment running in your cluster.

    ```bash
    kubectl get deploy kong-gateway -n kong -ojsonpath='{.spec.template.spec.containers[0].image}'
    ```

    You should see the new version of {{ site.base_gateway }}:

    ```bash
    kong:{{site.data.gateway_latest.release}}
    ```