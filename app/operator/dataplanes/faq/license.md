---
title: "Enterprise license"
description: "Provide your {{ site.base_gateway }} license using the KongLicense CRD or as an environment variable"
content_type: reference
layout: reference
products:
  - operator
breadcrumbs:
  - /operator/
  - index: operator
    group: Gateway Deployment
  - index: operator
    group: Gateway Deployment
    section: Key Concepts

---

{{ site.gateway_operator_product_name }} can enable enterprise features using the `KongLicense` CRD or by providing your license as an environment variable to your DataPlane pods.

## KongLicense

1. Create a file named `license.json` containing your {{site.ee_product_name}} license.

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
     Controller Name:        konghq.com/kong-gateway-operator
   ```

## Using environment variables

1. Create a Kubernetes secret containing your license:

    ```bash
    kubectl create secret generic kong-enterprise-license --from-file=license=./license.json -n default
    ```

1. Specify the `KONG_LICENSE_DATA` environment variable for your DataPlane pods. This can be provided on the `DataPlane` or `GatewayConfiguration`

### DataPlane

```yaml
apiVersion: gateway-operator.konghq.com/v1beta1
kind: DataPlane
metadata:
  name: dataplane-example
spec:
  deployment:
    podTemplateSpec:
      spec:
        containers:
        - name: proxy
          image: kong/kong-gateway:{{ site.data.gateway_latest.release }}
        env:
        - name: KONG_LICENSE_DATA
          valueFrom:
            secretKeyRef:
              key: license
              name: kong-enterprise-license
```

### GatewayConfiguration

```yaml
kind: GatewayConfiguration
apiVersion: gateway-operator.konghq.com/{{ site.operator_gatewayconfiguration_api_version }}
metadata:
  name: kong
  namespace: default
spec:
  dataPlaneOptions:
    deployment:
      podTemplateSpec:
        spec:
          containers:
          - name: proxy
            image: kong/kong-gateway:{{ site.data.gateway_latest.release }}
          env:
          - name: KONG_LICENSE_DATA
            valueFrom:
              secretKeyRef:
                key: license
                name: kong-enterprise-license
```
