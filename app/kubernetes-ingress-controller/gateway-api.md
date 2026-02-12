---
title: Gateway API

description: |
  Learn about support for Gateway API resources such as Gateway and GatewayClass in {{ site.kic_product_name }}

content_type: reference
layout: reference
breadcrumbs:
  - /kubernetes-ingress-controller/
products:
  - kic

works_on:
  - on-prem
  - konnect

related_resources:
  - text: Ingress
    url: /kubernetes-ingress-controller/ingress/
  - text: Install KiC
    url: /kubernetes-ingress-controller/install/

faqs:
  - q: |
      Error: `One of publish services defined in Gateway's "konghq.com/publish-service" annotation didn't match controller manager's configuration`
    a: |
      To resolve this error, manually change the `konghq.com/publish-service` annotation on the Gateway to the value of `--publish-service`.

      When an unmanaged Gateway is reconciled by KIC, it gets annotated with `konghq.com/publish-service` equal to a Service’s namespaced name configured in the `--publish-service` (and optionally in `--publish-service-udp`) CLI flag. The annotation value is used by the Gateway controller to determine its Listeners’ statuses.

      Once the Gateway's `konghq.com/publish-service` annotation is assigned, it will no longer be auto-updated by {{site.kic_product_name}}. If the `--publish-service` flag changes after the annotation is assigned, the Gateway controller will not be able to determine the Gateway's Listeners' statuses. Manual intervention will be required to update the annotation to match the CLI flag.

---


[Gateway API](https://gateway-api.sigs.k8s.io/) is a set of resources for configuring networking in Kubernetes. It expands on [Ingress](/kubernetes-ingress-controller/ingress/) to configure additional types of routes such as TCP, UDP, and TLS in addition to HTTP/HTTPS, and to support backends other than Service, and manage the proxies that implement routes.

{:.info}
> Gateway API resources will only be reconciled when the Gateway API CRDs are installed in your cluster _before_ {{ site.kic_product_name }} is started. See the [getting started](/kubernetes-ingress-controller/install/) page for installation instructions.

## Gateway management

A [Gateway resource](https://gateway-api.sigs.k8s.io/concepts/api-overview/#gateway) describes an application or cluster feature that can handle Gateway API routing rules, directing inbound traffic to Services by following the rules provided. For Kong's implementation, a Gateway corresponds to a Kong Deployment managed by the Ingress controller.

Typically, Gateway API implementations manage the resources associated with a Gateway on behalf of users for creating a Gateway resource triggers automatic provisioning of Deployments, Services, and others with configuration by matching the Gateway's listeners and addresses. Kong's implementation does _not_ automatically manage Gateway provisioning.

Because the Kong Deployment and its configuration are not managed automatically, listeners and address configuration are not set for you. You must configure your Deployment and Service to match your Gateway's configuration.  

For example, with the following Gateway:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: example
spec:
  gatewayClassName: kong
  listeners:
  - name: proxy
    port: 80
    protocol: HTTP
  - name: proxy-ssl
    port: 443
    protocol: HTTPS
    hostname: kong.example.com
    tls:
      mode: Terminate
      certificateRefs:
        - kind: Secret
          name: kong-example-com-cert
  - name: proxy-tcp-9901
    port: 9901
    protocol: TCP
  - name: proxy-udp-9902
    port: 9902
    protocol: UDP
  - name: proxy-tls-9903
    port: 9903
    protocol: TLS
```

It requires a proxy Service that includes all the requested listener ports:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: proxy
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 8000
  - port: 443
    protocol: TCP
    targetPort: 8443
  - port: 9901
    protocol: TCP
    targetPort: 9901
  - port: 9902
    protocol: UDP
    targetPort: 9902
  - port: 9903
    protocol: TCP
    targetPort: 9903
```

You must also configure {{site.base_gateway}}'s [`proxy_listen`](/gateway/configuration/#proxy-listen) and [`stream_listen`](/gateway/configuration/#stream-listen) configuration parameters in the container environment:

```console
KONG_PROXY_LISTEN="0.0.0.0:8000 reuseport backlog=16384, 0.0.0.0:8443 http2 ssl reuseport backlog=16384 http2"
KONG_STREAM_LISTEN="0.0.0.0:9901 reuseport backlog=16384, 0.0.0.0:9902 reuseport backlog=16384 udp", 0.0.0.0:9903 reuseport backlog=16384 ssl"
```

The Service, `proxy_listen`, and `stream_listen` configurations are managed via [the Helm chart](https://github.com/Kong/charts/tree/main/charts/kong) using the `proxy` configuration block.

```yaml
proxy:
  http:
    enabled: true
    servicePort: 80
    containerPort: 8000

  tls:
    enabled: true
    servicePort: 443
    containerPort: 8443

  stream:
    - containerPort: 9901
      servicePort: 9901
      protocol: TCP
    - containerPort: 9902
      servicePort: 9902
      protocol: UDP
    - containerPort: 9903
      servicePort: 9903
      protocol: TCP
      parameters:
        - "ssl"
```

Ports missing appropriate Kong-side configuration results in an error condition in the Gateway's status.

```text
message: no Kong listen with the requested protocol is configured for the requested port
reason: PortUnavailable
```

### Listener compatibility and handling multiple Gateways

Each {{ site.kic_product_name }} can be provided with a controller name. If no controller name is provided through the `--gateway-api-controller-name` field (or `CONTROLLER_GATEWAY_API_CONTROLLER_NAME` environment variable), the default `konghq.com/kic-gateway-controller` is used. 

Every `GatewayClass` referencing such a controller in the `controllerName` field is reconciled by the {{ site.kic_product_name }}. Similarly, every `Gateway` referencing a `GatewayClass` that specifies a matching `controllerName` is reconciled.

### Binding {{site.base_gateway}} to a Gateway resource

To configure {{site.kic_product_name}} to reconcile the Gateway resource, you must:
* Set the `konghq.com/gatewayclass-unmanaged=true` annotation in your GatewayClass resource.
* Configure `spec.controllerName` in your GatewayClass, as explained in the section on [listener compatibility](#listener-compatibility-and-handling-multiple-gateways).
* Ensure the `spec.gatewayClassName` value in your Gateway resource matches the value in `metadata.name` from your `GatewayClass`.

You can confirm if {{site.kic_product_name}} has updated the Gateway by inspecting the list of associated addresses. 

```bash
kubectl get gateway kong -o=jsonpath='{.status.addresses}' | jq
```
If an IP address is shown, the `Gateway` is being managed by Kong:
```json
[
  {
    "type": "IPAddress",
    "value": "10.96.179.122"
  },
  {
    "type": "IPAddress",
    "value": "172.18.0.240"
  }
]
```

## Unmanaged Gateways

Using {{ site.kic_product_name }} without [{{ site.operator_product_name }}](/operator/) results in all `Gateway` resources associated with `GatewayClass` resources with the same `spec.controllerName` being merged into a single configuration. {{ site.base_gateway }} deployments are created externally to {{ site.kic_product_name }}, which means that we cannot dynamically control the configuration in response to `Gateway` listeners.

When using _unmanaged_ mode, Routes from all `Gateway` instances are merged together and sent to all {{ site.base_gateway }} instances being managed by the single {{ site.kic_product_name }}.
