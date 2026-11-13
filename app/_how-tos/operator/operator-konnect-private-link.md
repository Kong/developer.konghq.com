---
title: Connect {{ site.operator_product_name }} to {{site.konnect_short_name}} over AWS PrivateLink
description: "Run {{ site.operator_product_name }} and its data planes against {{site.konnect_short_name}} without public internet egress, using an AWS PrivateLink VPC endpoint."
content_type: how_to

permalink: /operator/konnect/how-to/private-link/
breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect

products:
  - operator

works_on:
  - konnect

min_version:
  operator: '2.4'

tldr:
  q: How do I connect {{ site.operator_product_name }} to {{site.konnect_short_name}} over AWS PrivateLink?
  a: |
    Create a VPC endpoint for your {{site.konnect_short_name}} geo with Private DNS enabled, then set the `serverURL` of your `KonnectAPIAuthConfiguration` to the private host with the `/api` path, for example `https://us.svc.konghq.com/api`. {{ site.operator_product_name }} and the data planes it deploys then reach {{site.konnect_short_name}} through the private endpoints.

prereqs:
  inline:
    - title: AWS PrivateLink VPC endpoint
      position: before
      content: |
        Your Kubernetes cluster must run in an AWS VPC that has an interface VPC endpoint for your {{site.konnect_short_name}} geo:

        * Create the endpoint for the PrivateLink service of your geo and AWS region. The service names and DNS names are listed in [Regional PrivateLink service names](/gateway/aws-private-link/#regional-privatelink-service-names).
        * Enable **Private DNS** on the endpoint, so that the geo's private host, for example `us.svc.konghq.com`, resolves to the endpoint inside the VPC.
        * Attach a security group that allows inbound TCP traffic on port `443` from your cluster nodes.

        To manage Dedicated Cloud Gateways over PrivateLink too, create a second endpoint for the global service (`global.svc.konghq.com`), also with Private DNS enabled. See [Manage Dedicated Cloud Gateways over PrivateLink](#manage-dedicated-cloud-gateways-over-privatelink).

        For the AWS steps, see [AWS PrivateLink peering](/gateway/aws-private-link/).
      icon_url: /assets/icons/aws.svg

related_resources:
  - text: AWS PrivateLink peering
    url: /gateway/aws-private-link/
  - text: Status fields
    url: /operator/konnect/troubleshooting/status/
  - text: Reference {{site.konnect_short_name}} authentication across multiple namespaces
    url: /operator/konnect/how-to/auth-cross-namespace-reference/
  - text: Create a Dedicated Cloud Gateway network
    url: /operator/konnect/crd/cloud-gateways/network/

cleanup:
  inline:
    - title: Delete the resources created in this guide
      content: |
        Deleting the `Gateway` also deletes the `KonnectGatewayControlPlane` that {{ site.operator_product_name }}
        created for it, which removes the control plane from {{ site.konnect_short_name }}:

        ```bash
        kubectl delete -n kong --ignore-not-found gateway/kong gatewayconfiguration/gateway-configuration
        kubectl delete -n kong --ignore-not-found konnectgatewaycontrolplane --all
        kubectl delete --ignore-not-found gatewayclass/gateway-class
        kubectl delete -n kong --ignore-not-found konnectapiauthconfiguration/konnect-api-auth-private
        ```
        {: data-test-cleanup="block" }
      icon_url: /assets/icons/kubernetes.svg
---

By default, {{ site.operator_product_name }} and the data planes it deploys reach {{site.konnect_short_name}} through its public hosts. With [AWS PrivateLink](/gateway/aws-private-link/), they can reach {{site.konnect_short_name}} through a VPC endpoint instead, without public internet egress.

The only setting that changes is the `serverURL` of the `KonnectAPIAuthConfiguration`. {{ site.operator_product_name }} uses it to call the {{site.konnect_short_name}} API, and {{site.konnect_short_name}} returns private control plane and telemetry endpoints for the data planes to connect to.

{:.info}
> The private host serves the same publicly trusted certificate as the public one, and {{ site.operator_product_name }} configures data planes to trust the system certificate bundle. You don't need to distribute a CA certificate.

## Choose the server URL

Set `serverURL` to the private host of your geo, followed by the `/api` path:

<!--vale off-->
{% table %}
columns:
  - title: API
    key: api
  - title: Public `serverURL`
    key: public
  - title: PrivateLink `serverURL`
    key: private
rows:
  - api: "Regional API, for example the US geo"
    public: "`https://us.api.konghq.com`"
    private: "`https://us.svc.konghq.com/api`"
  - api: Global API, for Dedicated Cloud Gateways
    public: "`https://global.api.konghq.com`"
    private: "`https://global.svc.konghq.com/api`"
{% endtable %}
<!--vale on-->

Replace `us` with your geo. You always set the regional form in the `KonnectAPIAuthConfiguration`: {{ site.operator_product_name }} derives the global form from it.

{:.warning}
> **The `/api` path is required.** Nothing checks the path when you apply the resource. Without it, the authentication call fails, and the `APIAuthValid` condition of the `KonnectAPIAuthConfiguration` stays `False` with the HTTP error in its message.

The `serverURL` of a `KonnectAPIAuthConfiguration` can't be changed. To move an existing installation from the public hosts to PrivateLink, create a new `KonnectAPIAuthConfiguration` and point your resources at it.

## Create the KonnectAPIAuthConfiguration

Create the `kong` namespace and a `KonnectAPIAuthConfiguration` that uses the private host:

```bash
kubectl create namespace kong --dry-run=client -o yaml | kubectl apply -f -

echo '
kind: KonnectAPIAuthConfiguration
apiVersion: konnect.konghq.com/v1alpha1
metadata:
  name: konnect-api-auth-private
  namespace: kong
spec:
  type: token
  token: '"$KONNECT_TOKEN"'
  serverURL: https://us.svc.konghq.com/api
' | kubectl apply -f -
```
{: data-test-step="block" }

Check that the authentication is valid and that the organization was resolved:

```bash
kubectl get konnectapiauthconfiguration konnect-api-auth-private -n kong \
  -o jsonpath='{.status.conditions[?(@.type=="APIAuthValid")].status} {.status.organizationID}{"\n"}'
```
{: data-test-step="block" }

The command prints `True` followed by your organization ID.

## Create the Gateway

Create a `GatewayConfiguration` that references the `KonnectAPIAuthConfiguration`, then a `GatewayClass` and a `Gateway`. Nothing else differs from a deployment over the public hosts:

```bash
echo '
kind: GatewayConfiguration
apiVersion: gateway-operator.konghq.com/{{ site.operator_gatewayconfiguration_api_version }}
metadata:
  name: gateway-configuration
  namespace: kong
spec:
  konnect:
    authRef:
      name: konnect-api-auth-private
  dataPlaneOptions:
    deployment:
      podTemplateSpec:
        spec:
          containers:
            - name: proxy
              image: kong/kong-gateway:{{ site.data.gateway_latest.release }}
---
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: gateway-class
spec:
  controllerName: konghq.com/gateway-operator
  parametersRef:
    group: gateway-operator.konghq.com
    kind: GatewayConfiguration
    name: gateway-configuration
    namespace: kong
---
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: kong
  namespace: kong
spec:
  gatewayClassName: gateway-class
  listeners:
    - name: http
      port: 80
      protocol: HTTP
' | kubectl apply -f -
```
{: data-test-step="block" }

## Validate

1. Wait for the `KonnectGatewayControlPlane` that {{ site.operator_product_name }} created for the `Gateway` to be programmed:

   ```bash
   kubectl wait --for=condition=Programmed --all -n kong konnectgatewaycontrolplane --timeout=5m
   ```
   {: data-test-step="block" }

1. Check that {{site.konnect_short_name}} returned private endpoints for the control plane:

   ```bash
   kubectl get konnectgatewaycontrolplane -n kong \
     -o jsonpath='{range .items[*]}{.status.konnectEndpoints.controlPlane}{"\n"}{.status.konnectEndpoints.telemetry}{"\n"}{end}'
   ```
   {: data-test-step="block" }

   Both endpoints use the private host, for example:

   ```text
   https://us.svc.konghq.com/cp/<prefix>
   https://us.svc.konghq.com/tp/<prefix>
   ```
   {:.no-copy-code}

1. Check that the data plane is configured with the private endpoints:

   ```bash
   kubectl get deployment -n kong -o yaml \
     | grep -A1 -E 'KONG_CLUSTER_(CONTROL_PLANE|SERVER_NAME|TELEMETRY_ENDPOINT)$'
   ```
   {: data-test-step="block" }

   The values use the private host, for example:

   ```text
   - name: KONG_CLUSTER_CONTROL_PLANE
     value: us.svc.konghq.com/cp/<prefix>
   - name: KONG_CLUSTER_SERVER_NAME
     value: us.svc.konghq.com
   - name: KONG_CLUSTER_TELEMETRY_ENDPOINT
     value: us.svc.konghq.com:443/tp/<prefix>
   ```
   {:.no-copy-code}

## Manage Dedicated Cloud Gateways over PrivateLink

`KonnectCloudGatewayNetwork`, `KonnectCloudGatewayTransitGateway`, and `KonnectCloudGatewayDataPlaneGroupConfiguration` call the global {{site.konnect_short_name}} API. With a PrivateLink `serverURL`, {{ site.operator_product_name }} sends those calls to the private global host, for example `https://global.svc.konghq.com/api` for `https://us.svc.konghq.com/api`.

To manage Dedicated Cloud Gateways over PrivateLink, create a second VPC endpoint for the global service with Private DNS enabled. Without it, the global host doesn't resolve and those resources aren't programmed. You don't need a second `KonnectAPIAuthConfiguration`: reference the same one from these resources, as described in [Create a Dedicated Cloud Gateway network](/operator/konnect/crd/cloud-gateways/network/) and [Configure a Dedicated Cloud Gateway](/operator/konnect/crd/cloud-gateways/configuration/).

PrivateLink covers how {{ site.operator_product_name }} reaches {{site.konnect_short_name}}. It doesn't change how the Dedicated Cloud Gateway proxy is exposed, which you control with the `api_access` setting of the data plane group.

## Egress and network policies

{{ site.operator_product_name }} and the data planes only need outbound HTTPS (TCP port `443`) to the VPC endpoint. They don't need any rule for the public {{site.konnect_short_name}} hosts.

If a Kubernetes `NetworkPolicy` restricts egress from the {{ site.operator_product_name }} or data plane namespaces, allow TCP port `443` to the IP addresses of the VPC endpoint.

## How {{ site.operator_product_name }} protects private connections

{{ site.operator_product_name }} doesn't start a component with a configuration that would send its traffic over the public internet. Instead, it holds the component and reports a condition:

<!--vale off-->
{% table %}
columns:
  - title: Resource
    key: resource
  - title: Condition
    key: condition
  - title: Cause
    key: cause
rows:
  - resource: "`KonnectAPIAuthConfiguration`"
    condition: "`APIAuthValid=False`, reason `Invalid`"
    cause: "The `serverURL` host isn't under an allowed {{site.konnect_short_name}} domain. The allowed domains default to `konghq.com` and `konghq.tech`, and are set with the `--konnect-server-url-domains` flag. The private hosts are under `konghq.com`, so the default allows them."
  - resource: "`KonnectExtension`"
    condition: "`Ready=False`, reason `InvalidEndpoint`"
    cause: "The {{ site.kic_product_name }} in {{site.konnect_short_name}} doesn't support a private endpoint yet. See [Limitations](#limitations)."
  - resource: "`KonnectExtension`"
    condition: "`Ready=False`, reason `EndpointMismatch`"
    cause: "The `serverURL` has a path, but {{site.konnect_short_name}} returned public endpoints."
  - resource: "`AIGatewayDataPlane`"
    condition: "`KonnectAIGatewayResolved=False`, reason `EndpointMismatch`"
    cause: "The {{ site.ai_gateway }} data plane can't use a private endpoint yet. See [Limitations](#limitations)."
  - resource: "`KegDataPlane`"
    condition: "`KonnectEventGatewayResolved=False`, reason `EndpointMismatch`"
    cause: "The `serverURL` has a path. {{ site.event_gateway }} data planes can't use a private endpoint. See [Limitations](#limitations)."
{% endtable %}
<!--vale on-->

A held data plane keeps serving, but {{ site.operator_product_name }} doesn't apply spec, image, or certificate changes to it until the condition clears.

`EndpointMismatch` on a `KonnectExtension` happens when your geo doesn't return private endpoints yet. It clears on its own once {{site.konnect_short_name}} returns them for your geo, and you don't need to change anything in your cluster.

For the full list of status conditions, see [Status fields](/operator/konnect/troubleshooting/status/#private-endpoint-conditions).

## Limitations

The following components can't connect over PrivateLink yet:

* **{{ site.kic_product_name }} in {{site.konnect_short_name}}**: There's no private route for its API, so {{ site.operator_product_name }} holds a `KonnectExtension` for it with `InvalidEndpoint`.
* **{{ site.event_gateway }}**: The {{ site.event_gateway_short }} data plane builds its {{site.konnect_short_name}} host from the region and the domain, and can't use a path. A `KegDataPlane` whose `KonnectEventGateway` uses a private `serverURL` is held with `EndpointMismatch`. Setting `spec.config.konnect.domain` lifts the check, but the data plane then connects over the public internet.
* **{{ site.ai_gateway_name }}**: The {{ site.ai_gateway }} API doesn't return private endpoints yet, so an `AIGatewayDataPlane` is held with `EndpointMismatch`.
