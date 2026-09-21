---
title: "Deploy an MCP server with {{site.context_mesh}} and {{site.operator_product_name}}"
permalink: /context-mesh/get-started/
content_type: how_to
description: "Deploy the OpenWeather {{site.context_mesh}} MCP server from the Konnect UI"
breadcrumbs:
  - /context-mesh/

products:
  - context-mesh
  - gateway

works_on:
  - konnect

min_version:
  gateway: '3.13'

published: true
tags:
  - ai
  - mcp
  - kubernetes

tldr:
  q: "How do I deploy the OpenWeather {{site.context_mesh}} MCP server?"
  a: "Install {{site.operator_product_name}} {{site.data.operator_latest.release}} with the `mcp-server` feature gate, create a Konnect-managed control plane and data plane, then create the MCP server from the Konnect UI."

tools:
  - operator

prereqs:
  skip_product: true
  inline:
    - title: Konnect personal access token
      position: before
      content: |
        1. Create a new personal access token by opening the [Konnect PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**.

        2. Export the token and the Konnect API URL for your region:

           ```sh
           export KONNECT_TOKEN='YOUR_KONNECT_PAT'
           export KONNECT_CONTROL_PLANE_URL='https://us.api.konghq.com'
           ```
      icon_url: /assets/icons/gateway.svg
    - title: Kubernetes cluster
      position: before
      content: |
        Set up a local Kubernetes cluster:

        ```bash
        minikube start
        ```

        Once started, open a separate terminal window, and activate load balancing on your cluster:

        ```sh
        minikube tunnel
        ```

        Type your password when prompted. Leave this window open on the side as you follow this guide.

      icon_url: /assets/icons/kubernetes.svg
    - title: Claude Code
      include_content: prereqs/claude-code
      icon_url: /assets/icons/third-party/claude.svg
    - title: OpenWeatherMap account and API key
      content: |
        1. Create an account at [openweathermap.org](https://home.openweathermap.org/users/sign_in)
        2. Generate an API key (may take several hours to activate)

        ```sh
        export OPENWEATHERMAP_API_KEY='<your-api-key'
        ```
    - title: OpenWeather OpenAPI spec
      content: |
        Download the OpenWeatherMap OpenAPI specification. You upload this file to
        {{site.konnect_short_name}} later in this guide:

        ```sh
        curl -O {{site.links.web}}/assets/context-mesh/openweathermap.json
        ```

cleanup:
  inline:
    - title: Delete the MCP server
      content: |
        In the {{site.konnect_short_name}} UI, open the MCP server and delete it. This disassociates the MCP server from the control plane.
      icon_url: /assets/icons/gateway.svg
    - title: Delete the control plane and data plane
      content: |
        ```bash
        kubectl delete -n default dataplane dataplane
        kubectl delete -n default konnectextension my-konnect-config
        kubectl delete -n default konnectgatewaycontrolplane test
        kubectl delete -n default konnectapiauthconfiguration konnect-api-auth
        ```

        Deleting the `KonnectGatewayControlPlane` also deletes the `context-mesh-demo` control plane in {{site.konnect_short_name}}. Run this step even if you plan to repeat the guide: control plane names must be unique within an organization, so a leftover `context-mesh-demo` makes the next run fail with a `409 Conflict` and the data plane never becomes ready.
      icon_url: /assets/icons/kubernetes.svg
    - title: Uninstall {{site.operator_product_name}}
      content: |
        ```bash
        helm uninstall kong-operator -n kong
        kubectl delete namespace kong
        ```
      icon_url: /assets/icons/kubernetes.svg
---

## Add the Kong Helm repository

Map the name `kong` to the Kong Helm charts URL and download the latest chart index:

```shell
helm repo add kong https://charts.konghq.com
helm repo update
```

## Install {{site.operator_product_name}}

{{site.base_gateway}} needs {{site.operator_product_name}} to run a {{site.context_mesh}} MCP server:

```shell
helm upgrade --install kong-operator kong/kong-operator -n kong \
  --create-namespace \
  --set image.tag={{ site.data.operator_latest.release }} \
  --set env.ENABLE_CONTROLLER_KONNECT=true \
  --set env.FEATURE_GATES=mcp-server
```

This command creates the `kong` namespace containing:

* The operator itself (`kong-operator-kong-operator-controller-manager`).
* CustomResourceDefinitions (CRDs) that add resource types such as `DataPlane` to your Kubernetes cluster.
* Role-based access control (RBAC) rules that let the operator manage those resources on your behalf.
* Webhook configurations that validate the resources before they're applied.

Wait for the {{site.operator_product_name}} deployment to become available before you create any {{site.konnect_short_name}} resources:

```shell
kubectl -n kong wait --for=condition=Available=true --timeout=120s \
  deployment/kong-operator-kong-operator-controller-manager
```

## Deploy a {{site.konnect_short_name}} control plane and data plane

The following manifest creates the four resources that {{site.operator_product_name}} needs to run a {{site.konnect_short_name}}-managed data plane in your cluster:

* `KonnectAPIAuthConfiguration`: Authenticates {{site.operator_product_name}} against the {{site.konnect_short_name}} API with your personal access token. The `serverURL` is read from `KONNECT_CONTROL_PLANE_URL`, so it points at whichever region your account uses.
* `KonnectGatewayControlPlane`: Creates a control plane named `context-mesh-demo` in {{site.konnect_short_name}}. This is the control plane you attach the MCP server to in a later step.
* `KonnectExtension`: Links the cluster to that control plane and provisions the mTLS certificates the data plane uses to connect to it.
* `DataPlane`: Deploys three {{site.base_gateway}} {{site.data.gateway_latest.release}} proxy replicas. The `KonnectExtension` reference configures them to run in hybrid mode and pull their configuration from `context-mesh-demo`.

Apply the manifest:

```shell
kubectl apply -f - <<EOF
kind: KonnectAPIAuthConfiguration
apiVersion: konnect.konghq.com/v1alpha1
metadata:
  name: konnect-api-auth
  namespace: default
spec:
  type: token
  token: ${KONNECT_TOKEN}
  serverURL: ${KONNECT_CONTROL_PLANE_URL}
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
          image: kong/kong-gateway:{{ site.data.gateway_latest.release }}
EOF
```

## Wait for the data plane to be ready

```shell
kubectl wait --timeout=3m dataplane dataplane -n default --for=condition=Ready
```

## Create the OpenWeather {{site.context_mesh}} server

1. In the {{site.konnect_short_name}} sidebar, click **{{site.context_mesh}}**.
1. In the {{site.context_mesh}} sidebar, click **Sources**.
1. In **New source**, select **API**.
1. Click the **Upload new** tab.
1. Upload `openweathermap.json`.
1. Click **Add Source**.
1. In the {{site.context_mesh}} sidebar, click **MCP Servers**.
1. Click **New MCP server**.
1. In **Sources**, select **OpenWeatherMap Current Weather API**.
1. In the **Name** field, enter `openweather-service`.
1. Click **Create server**.
1. In **Deploy**, select the `context-mesh-demo` control plane.
1. Click **Deploy and finish**.
1. Wait for the server status to become **Healthy**.

The MCP runtime is now exposed at `/mcp/openweather-service`.

## Add the OpenWeather MCP server to Claude

Connect the MCP server to an agent:

```shell
claude mcp add --transport http context-mesh-weather http://localhost/mcp/openweather-service \
  --header "X-Upstream-Api-Key: ${OPENWEATHERMAP_API_KEY}"
```

## Validate

Start Claude Code:

```sh
claude
```

Try a prompt in Claude Code:

```
Tell me the weather in Hawaii.
```
