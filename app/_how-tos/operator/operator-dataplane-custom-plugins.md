---
title: Deploy custom plugins with {{ site.operator_product_name }}
description: "Package and deploy custom Kong plugins as OCI images using the {{ site.operator_product_name }} and reference them in {{site.base_gateway}} resources."
content_type: how_to

permalink: /operator/dataplanes/how-to/deploy-custom-plugins/
breadcrumbs:
  - /operator/
  - index: operator
    group: Gateway Deployment
  - index: operator
    group: Gateway Deployment
    section: "How-To"

products:
  - operator

tools:
  - operator

works_on:
  - konnect
  - on-prem

prereqs:
  kubernetes:
    gateway_api: true
  entities:
    services:
      - echo-service
    routes:
      - echo
  operator:
    konnect:
      auth: true
      control_plane: true
    controllers:
      - kongplugininstallation

tldr:
  q: How can I deploy a custom plugin using the {{ site.operator_product_name }}?
  a: |
    Build and push a plugin as a container image, then use a `KongPluginInstallation`
    to register it with the operator. Reference it in your `GatewayConfiguration` to
    make it available in Data Planes and configure its behavior using a `KongPlugin` resource.
---

## Plugin distribution using an OCI registry

{{ site.operator_product_name }} can install Kong custom plugins packaged as container images. This guide shows how to package, install, and use a custom plugin in {{site.base_gateway}} instances managed by the {{ site.operator_product_name }}.

{% include_cached plugins/custom-plugin-example.md is_optional=true %}

## Build a container image (Optional)

{:.info}
> This section is optional. The rest of this guide uses a pre-published image, and the following information is provided if you want to package your own custom plugin.

Plugin-related files should be at the root of the image, so the Dockerfile for the plugin would look like this:

```bash
echo 'FROM scratch

COPY myheader /
' > Dockerfile
```

In this example, `myheader` is a directory that contains `handler.lua` and `schema.lua`.

Build the image:

```bash
docker build -t myheader:1.0.0 .
```

Next, push the image to a public or private registry available to the Kubernetes cluster where {{ site.operator_product_name }} is running.

```bash
docker tag myheader:1.0.0 $YOUR_REGISTRY_ADDRESS/myheader:1.0.0
docker push $YOUR_REGISTRY_ADDRESS/myheader:1.0.0
```

In this example, the plugin is available in the public registry (Docker Hub) as `kong/plugin-example:1.0.0`. The following steps use the same source.

{: data-deployment-topology="konnect" }
## Register the plugin schema in Konnect

To see your custom plugin in {{site.konnect_product_name}}, you need to register the schema with your control plane.

First, get your control plane ID:

<!--vale off-->
{% konnect_api_request %}
url: /v2/control-planes?filter%5Bname%5D%5Beq%5D=gateway-control-plane
status_code: 200
method: GET
extract_body:
  - name: data[0].id
    variable: CONTROL_PLANE_ID
capture: CONTROL_PLANE_ID
jq: ".data[0].id"
{% endkonnect_api_request %}
<!--vale on-->

Run the following command to upload your schema file to your {{site.konnect_short_name}} control plane:

```sh
curl -X POST \
  https://us.api.konghq.com/v2/control-planes/$CONTROL_PLANE_ID/core-entities/plugin-schemas \
  --header 'Content-Type: application/json' \
  --header "Authorization: Bearer $KONNECT_TOKEN" \
  --data "{\"lua_schema\": $(jq -Rs . './myheader/schema.lua')}"
```

## Install the plugin

1. Install the plugin using the `KongPluginInstallation` resource. This resource makes the plugin available for instances of {{site.base_gateway}} resources:

   ```yaml
   echo '
   kind: KongPluginInstallation
   apiVersion: gateway-operator.konghq.com/v1alpha1
   metadata:
     name: custom-plugin-myheader
   spec:
     image: kong/plugin-example:1.0.0
   ' | kubectl apply -f -
   ```

   Verify that the plugin is fetched and available by examining the status of the `KongPluginInstallation` resource:

   ```bash
   kubectl get kongplugininstallations.gateway-operator.konghq.com -o jsonpath-as-json='{.items[*].status}'
   ```

   The output should look like this:

   ```json
   [
     {
           "conditions": [
                {
                     "lastTransitionTime": "2024-10-09T19:39:39Z",
                     "message": "plugin successfully saved in cluster as ConfigMap",
                     "observedGeneration": 1,
                     "reason": "Ready",
                     "status": "True",
                     "type": "Accepted"
                }
           ],
           "underlyingConfigMapName": "custom-plugin-myheader-hnzf9"
     }
   ]
   ```

   In case of problems, the respective `conditions` or respective resources will provide more information.

   {:.info}
    > The `KongPluginInstallation` resource creates a `ConfigMap` with the plugin content. Additional `ConfigMap`s are created when a plugin is referenced by other resources. The operator automatically manages the lifecycle of all these `ConfigMap`s.

1. Make the plugin available in a `Gateway` resource by referencing it in the `spec.dataPlaneOptions.spec.pluginsToInstall` field of the `GatewayConfiguration` resource. Plugins can be referenced across namespaces without any additional configuration.

   ```yaml
   echo '
   kind: GatewayConfiguration
   apiVersion: gateway-operator.konghq.com/{{ site.operator_gatewayconfiguration_api_version }}
   metadata:
     name: kong
     namespace: default
   spec:
     dataPlaneOptions:
        deployment:
           replicas: 2
           podTemplateSpec:
             spec:
                containers:
                   - name: proxy
                     image: kong/kong-gateway:{{ site.data.gateway_latest.release }}
        pluginsToInstall:
           - name: custom-plugin-myheader
   ---
   apiVersion: gateway.networking.k8s.io/v1
   kind: GatewayClass
   metadata:
     name: kong
   spec:
     controllerName: konghq.com/gateway-operator
     parametersRef:
        group: gateway-operator.konghq.com
        kind: GatewayConfiguration
        name: kong
        namespace: default
   ' | kubectl apply -f -
   ```

1. Deploy an example service and expose it by configuring `HTTPRoute` with the custom plugin:

   ```bash
   kubectl apply -f {{site.links.web}}/assets/kubernetes-ingress-controller/examples/echo-service.yaml
   ```

   Next, add the `HTTPRoute` with the custom plugin. The configuration of the plugin is provided with the `KongPlugin` CRD, where the
   field `plugin` is set to the name of the `KongPluginInstallation` resource.

   <!--vale off-->
   {% entity_example %}
   type: plugin
   data:
     name: myheader
     plugin: custom-plugin-myheader
     config:
       header_value: my-first-plugin

     service: echo
   indent: 4
   {% endentity_example %}
   <!--vale on-->

## Validate your configuration

Ensure that everything is up and running and make a request to the service.

<!--vale off-->
{% validation request-check %}
url: '/echo'
status_code: 200
expected_headers:
  - "myheader: my-first-plugin"
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
{% endvalidation %}
<!--vale on-->
