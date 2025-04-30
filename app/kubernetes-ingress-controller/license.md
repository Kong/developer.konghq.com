---
title: "Apply an Enterprise License with {{ site.kic_product_name }}"

description: |
  Learn how to apply a {{ site.base_gateway }} enterprise license using the `KongLicense` CRD or Kubernetes secrets
breadcrumbs:
  - /kubernetes-ingress-controller/
content_type: reference
layout: reference

products:
  - kic
related_resources:
  - text: Failure modes
    url: /kubernetes-ingress-controller/troubleshooting/failure-modes/
works_on:
  - on-prem
  - konnect
---

This page explains how to apply an enterprise license to {{ site.kic_product_name }} managed {{ site.base_gateway }} instances.
## Applying a license using the KongLicense CRD {% new_in 3.1 %}

{{ site.kic_product_name }} v3.1 introduced a `KongLicense` CRD [reference](/kubernetes-ingress-controller/reference/custom-resources/#konglicense) that applies a license to {{ site.base_gateway }} using the Admin API.

1. Create a file named `license.json` containing your {{site.base_gateway}} license.

1. Create a `KongLicense` object with the `rawLicenseString` field set to your license:

   ```bash
   echo "
   apiVersion: configuration.konghq.com/v1alpha1
   kind: KongLicense
   metadata:
     name: kong-license
   rawLicenseString: '$(cat ./license.json)'
   " | kubectl apply -f -
   ```

1. Verify that {{ site.kic_product_name }} is using the license:

   ```bash
   kubectl describe konglicense kong-license
   ```

   The results should look like this, including the `Programmed` condition with `True` status:

   ```text
   Name:         kong-license
   Namespace:
   Labels:       <none>
   Annotations:  <none>
   API Version:  configuration.konghq.com/v1alpha1
   Enabled:      true
   Kind:         KongLicense
   Metadata:
    Creation Timestamp:  2024-02-06T15:37:58Z
    Generation:          1
    Resource Version:    2888
   Raw License String:   <your-license-string>   
   Status:
    Controllers:
     Conditions:
      Last Transition Time:  2024-02-06T15:37:58Z
      Message:
      Reason:                PickedAsLatest
      Status:                True
      Type:                  Programmed
     Controller Name:        konghq.com/kong-ingress-controller/5b374a9e.konghq.com
   ```

All {{ site.base_gateway }} instances that are configured by the {{ site.kic_product_name }} will have the license provided in `KongLicense` applied to them.
To update your license, update the `KongLicense` resource and {{ site.kic_product_name }} will dynamically propagate across all {{site.base_gateway}} instances with no downtime.
There is no need to restart your Pods when updating a license.

## Applying a static license

An alternative option is to use a static license Secret that will be used to populate {{ site.base_gateway }}'s `KONG_LICENSE_DATA` environment variable. This option allows you to store the license in Kubernetes secrets, but requires a Pod restart when the value of the secret changes.

1. Create a file named `license.json` containing your {{site.base_gateway}} license and store it in a Kubernetes secret:

    ```bash
    kubectl create namespace kong
    kubectl create secret generic kong-enterprise-license --from-file=license=./license.json -n kong
    ```

1. Create a `values.yaml` file:

    ```yaml
    gateway:
      image:
        repository: kong/kong-gateway
      env:
        LICENSE_DATA:
          valueFrom:
            secretKeyRef:
              name: kong-enterprise-license
              key: license
    ```

1. Install {{site.kic_product_name}} and {{ site.base_gateway }} with Helm:

    ```bash
    helm upgrade --install kong kong/ingress -n kong --create-namespace --values ./values.yaml
    ```
