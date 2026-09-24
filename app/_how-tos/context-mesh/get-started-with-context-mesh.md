---
title: "Deploy an MCP server with {{site.context_mesh}} and {{site.operator_product_name}}"
permalink: /context-mesh/get-started/
content_type: how_to
description: "Deploy a Context Mesh-backed MCP server with the Konnect API onto an Operator-managed data plane"
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
  a: "Install {{site.operator_product_name}} {{site.data.operator_latest.release}} with the `mcp-server` feature gate, create a Konnect-managed control plane and data plane, then create and deploy the MCP server with the Konnect API."

tools:
  - operator
  - konnect-api

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
           export KONNECT_CONTROL_PLANE_URL='us.api.konghq.com'
           ```
      icon_url: /assets/icons/gateway.svg
    - title: Kubernetes cluster
      position: before
      content: |
        Set up a local Kubernetes cluster. This example uses [minikube](https://minikube.sigs.k8s.io/docs/start/?arch=%2Fmacos%2Farm64%2Fstable%2Fbinary+download):

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
        Stop the MCP server by deleting its control plane mapping, then delete the MCP server and its source:

        ```sh
        curl -X DELETE "https://us.api.konghq.com/v1/context-interfaces/$MCP_SERVER_ID/control-plane-mappings/$CP_MAPPING_ID" \
             --no-progress-meter --fail-with-body \
             -H "Authorization: Bearer $KONNECT_TOKEN"

        curl -X DELETE "https://us.api.konghq.com/v1/context-interfaces/$MCP_SERVER_ID" \
             --no-progress-meter --fail-with-body \
             -H "Authorization: Bearer $KONNECT_TOKEN"

        curl -X DELETE "https://us.api.konghq.com/v1/context-sources/$SOURCE_ID" \
             --no-progress-meter --fail-with-body \
             -H "Authorization: Bearer $KONNECT_TOKEN"
        ```
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

## Get the control plane ID

You attach the MCP server to the `context-mesh-demo` control plane that {{site.operator_product_name}} created, which the API references by ID:

<!--vale off-->
{% konnect_api_request %}
url: /v2/control-planes?filter%5Bname%5D%5Beq%5D=context-mesh-demo
status_code: 200
method: GET
extract_body:
  - name: data[0].id
    variable: CONTROL_PLANE_ID
capture:
  - variable: CONTROL_PLANE_ID
    jq: ".data[0].id"
{% endkonnect_api_request %}
<!--vale on-->

## Add the OpenWeather API as a source

A source holds the OpenAPI specification that {{site.context_mesh}} generates the MCP server from.
The specification is sent as a single JSON string, so build the request body from the file you downloaded:

<!--vale off-->
{% validation custom-command %}
command: |
  jq -n --rawfile spec openweathermap.json '{
    "name": "openweathermap",
    "display_name": "OpenWeatherMap Current Weather API",
    "description": "Current weather data from OpenWeatherMap",
    "labels": {},
    "type": "api",
    "source": {
      "type": "raw",
      "config": {"spec": $spec}
    }
  }' > source.json
expected:
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->

Create the source:

<!--vale off-->
{% konnect_api_request %}
url: /v1/context-sources
status_code: 201
method: POST
body_cmd: $(cat source.json)
extract_body:
  - name: id
    variable: SOURCE_ID
capture:
  - variable: SOURCE_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

The `name` must be unique within your organization and can only contain lowercase letters, digits, periods, and hyphens.

## Create the MCP server


Create the MCP server:

<!--vale off-->
{% konnect_api_request %}
url: /v1/context-interfaces
status_code: 201
method: POST
body:
    name: openweather-service
    display_name: OpenWeather Service
    description: Code Mode MCP server for the OpenWeatherMap API
    labels: {}
extract_body:
  - name: id
    variable: MCP_SERVER_ID
capture:
  - variable: MCP_SERVER_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

The MCP server has no sources yet. Map the OpenWeather source to it:

<!--vale off-->
{% konnect_api_request %}
url: /v1/context-interfaces/$MCP_SERVER_ID/context-source-mappings
status_code: 201
method: POST
body:
    context_source_id: $SOURCE_ID
extract_body:
  - name: id
    variable: SOURCE_MAPPING_ID
capture:
  - variable: SOURCE_MAPPING_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

To expose more than one API or MCP server through the same MCP server, repeat this call for each source.

## Deploy the MCP server

Mapping the MCP server to a control plane deploys it. Set `mode` to `basic` to let {{site.konnect_short_name}} manage the underlying Kubernetes workload with its defaults:

<!--vale off-->
{% konnect_api_request %}
url: /v1/context-interfaces/$MCP_SERVER_ID/control-plane-mappings
status_code: 201
method: POST
body:
    control_plane_id: $CONTROL_PLANE_ID
    mode: basic
extract_body:
  - name: id
    variable: CP_MAPPING_ID
capture:
  - variable: CP_MAPPING_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

## Wait for the MCP server to be healthy

Check the deployment status:

<!--vale off-->
{% konnect_api_request %}
url: /v1/context-interfaces/$MCP_SERVER_ID/status
status_code: 200
method: GET
{% endkonnect_api_request %}
<!--vale on-->

The status is one of the following:

{% table %}
columns:
  - title: Status
    key: status
  - title: Description
    key: description
rows:
  - status: "`pending`"
    description: No deployment status has been reported yet.
  - status: "`deploying`"
    description: A single version is running, and the desired replicas aren't fully ready.
  - status: "`healthy`"
    description: A single version is running with no failing pods.
  - status: "`upgrading`"
    description: Multiple versions are running with no failing pods.
  - status: "`unhealthy`"
    description: One or more pods are failing across any version.
{% endtable %}

Poll until the status is `healthy`:

```sh
until [ "$(curl -s "https://us.api.konghq.com/v1/context-interfaces/$MCP_SERVER_ID/status" \
  -H "Authorization: Bearer $KONNECT_TOKEN" | jq -r '.status')" = "healthy" ]; do
  sleep 5
done
```

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

Verify that the local `context-mesh-weather` MCP is in your list:

```sh
/mcp
```

If the MCP appears as `disabled`, select it and enable it. You might need to input your sudo password on [the minikube tunnel terminal for this step](#kubernetes-cluster).

Try a prompt in Claude Code:

```
Tell me the weather in Hawaii.
```
