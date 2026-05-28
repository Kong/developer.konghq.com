---
title: "Deploy an MCP server with Context Mesh and Kong Operator"
permalink: /context-mesh/get-started-with-context-mesh/
content_type: how_to
description: "Deploy a Context Mesh-backed MCP server from the Konnect UI onto an Operator-managed data plane"
breadcrumbs:
  - /mcp/

products:
  - gateway
  - ai-gateway

works_on:
  - konnect

min_version:
  gateway: '3.13'

plugins:
  - ai-mcp-proxy

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - mcp
  - kubernetes

tldr:
  q: "How do I deploy a Context Mesh MCP server from the Konnect UI?"
  a: "Install the nightly {{site.kong_operator}} chart with the `mcp-server` feature gate, create a Konnect-managed `DataPlane`, then use the Konnect UI to create an MCP server against that control plane."

tools:
  - kubectl
  - helm

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI MCP Proxy
    url: /plugins/ai-mcp-proxy/

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
---

{:.warning}
> Context Mesh and the `mcp-server` feature gate are currently available only in nightly builds of {{site.kong_operator}}. Do not use this setup in production.

## Install {{site.kong_operator}}

Look up a current nightly tag from the [`kong/nightly-kong-operator`](https://hub.docker.com/r/kong/nightly-kong-operator/tags) Docker Hub page. The version string below is an example and changes daily.

```shell
helm upgrade --install kong-operator \
  oci://registry-1.docker.io/kong/nightly-kong-operator-chart \
  --version 0.0.0-nightly.20260505.sha.26d3afa \
  --set image.repository=kong/nightly-kong-operator \
  --set image.tag=sha-26d3afa \
  --set env.FEATURE_GATES=mcp-server \
  --set env.ENABLE_CONTROLLER_KONNECT=true \
  --create-namespace \
  --namespace kong-system
```

Confirm the Operator pod is running:

```shell
kubectl get pods -n kong-system
```

## Create the Konnect-managed control plane and data plane

Apply the manifest below. It creates a `KonnectAPIAuthConfiguration` holding your token, a `KonnectGatewayControlPlane` that the Operator mirrors into {{site.konnect_short_name}}, a `KonnectExtension` linking the data plane to that control plane, and a `DataPlane` running three {{site.base_gateway}} replicas.

```shell
kubectl apply -f - <<EOF
kind: KonnectAPIAuthConfiguration
apiVersion: konnect.konghq.com/v1alpha1
metadata:
  name: konnect-api-auth
  namespace: default
spec:
  type: token
  token: ${KPAT}
  serverURL: us.api.konghq.com
---
kind: KonnectGatewayControlPlane
apiVersion: konnect.konghq.com/v1alpha2
metadata:
  name: test
  namespace: default
spec:
  createControlPlaneRequest:
    name: context-mesh-demo
    labels:
      app: context-mesh-demo
  konnect:
    authRef:
      name: konnect-api-auth
---
kind: KonnectExtension
apiVersion: konnect.konghq.com/v1alpha2
metadata:
  name: my-konnect-config
  namespace: default
spec:
  konnect:
    controlPlane:
      ref:
        type: konnectNamespacedRef
        konnectNamespacedRef:
          name: test
---
apiVersion: gateway-operator.konghq.com/v1beta1
kind: DataPlane
metadata:
  name: dataplane
  namespace: default
spec:
  extensions:
  - kind: KonnectExtension
    name: my-konnect-config
    group: konnect.konghq.com
  deployment:
    replicas: 3
    podTemplateSpec:
      spec:
        containers:
        - name: proxy
          image: kong/kong-gateway:3.13
EOF
```

{:.info}
> For the EU or AU {{site.konnect_short_name}} region, set `serverURL` to `eu.api.konghq.com` or `au.api.konghq.com`.

Wait for the data plane to reach `Ready`:

```shell
kubectl wait --timeout=3m dataplane dataplane --for=condition=Ready
```

## Create the OpenWeather MCP server

This example uses the public OpenWeather API. You need an OpenWeather API key and the OpenWeather OpenAPI spec.

1. Create an account and API key at [openweathermap.org](https://home.openweathermap.org/users/sign_in). The key can take several hours to activate.
1. Download `openweathermap.json` from the Context Mesh API testing assets.

   {:.info}
   > Check internally for the current location of this file.

1. In {{site.konnect_short_name}}, go to **MCP Servers** and select **Create new MCP server**.
1. Name the server `openweather-service`.
1. Under **Add existing API**, open the **Upload new** tab and upload `openweathermap.json`.
1. Select the same Operator-managed control plane (`context-mesh-demo`).
1. Submit and wait for the server status to become **Healthy**.

The MCP runtime is exposed at `/mcp/openweather-service`.

### Connect an agent to the OpenWeather MCP server

1. Export your OpenWeather API key:

   ```shell
   export OPENWEATHERMAP_API_KEY=<your-api-key>
   ```

1. Follow the [client installation guide](/context-mesh/client-installation/) for your MCP client, using:
   - **Server name**: `context-mesh-weather`
   - **Server URL**: `http://localhost/mcp/openweather-service`
   - **Header**: `X-Upstream-Api-Key: ${OPENWEATHERMAP_API_KEY}`

1. Try a prompt:

   ```
   Tell me the weather in Hawaii.
   ```
   {:.no-copy-code}

## Undeploy the MCP servers

To remove an MCP server, open it in the {{site.konnect_short_name}} UI and undeploy it. This disassociates the MCP server from its control plane but keeps the {{site.konnect_short_name}} record.

To tear down the cluster-side resources:

```shell
kubectl delete dataplane dataplane -n default
kubectl delete konnectextension my-konnect-config -n default
kubectl delete konnectgatewaycontrolplane test -n default
kubectl delete konnectapiauthconfiguration konnect-api-auth -n default
helm uninstall kong-operator -n kong-system
kubectl delete namespace kong-system
```

Deleting the `KonnectGatewayControlPlane` removes the control plane from {{site.konnect_short_name}} as well.