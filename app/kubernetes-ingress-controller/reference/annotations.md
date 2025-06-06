---
title: Annotation reference

description: |
  Learn about the annotations {{ site.kic_product_name }} uses and the Kubernetes resources you can annotate.

content_type: reference
layout: reference

products:
  - kic

works_on:
  - on-prem
  - konnect

breadcrumbs:
  - /kubernetes-ingress-controller/
  - index: kubernetes-ingress-controller
    section: Reference
---

{{ site.kic_product_name }} uses annotations to add functionality to various Kubernetes resources. Annotations are used when there isn't a standardized way to configure the required functionality.

Annotations can be added to a route `Ingress` or Gateway API resource such as `HTTPRoute`, `Service` or `KongConsumer`.

The most commonly used annotations are:

* [`konghq.com/plugins`](#konghq-com-plugins): Adds plugins to `Ingress`, `Service`, `HTTPRoute`, `KongConsumer` or `KongConsumerGroup`
* [`konghq.com/strip-path`](#konghq-com-strip-path): Strips the path defined in the Route and then forwards the request to the upstream service
* [`konghq.com/methods`](#konghq-com-methods): Matches specific HTTP methods in the Route
* [`konghq.com/headers.*`](#konghq-com-headers): Requires specific headers in the incoming request to match the defined Route

See below for a complete list of annotations.

## Generic annotations

The following annotations may be added to multiple resources. See each annotation's description for more details.

### kubernetes.io/ingress.class

{:.info}
> Kubernetes versions after 1.18 introduced the new `ingressClassName` field to the Ingress spec and [deprecated the `kubernetes.io/ingress.class` annotation](https://kubernetes.io/docs/concepts/services-networking/ingress/#deprecated-annotation). Ingress resources should now use the `ingressClassName` field. {{site.base_gateway}} resources (KongConsumer, TCPIngress, etc.) still use the `kubernetes.io/ingress.class` annotation.

If you have multiple Ingress controllers in a single cluster, you can pick one by specifying the `ingress.class` annotation. In this Ingress annotation example, it targets the GCE controller, forcing the {{site.kic_product_name}} to ignore it:

```yaml
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: test-1
  annotations:
    kubernetes.io/ingress.class: "gce"
spec:
  rules:
    - host: example.com
      http:
        paths:
          - path: /test1
            backend:
              serviceName: echo
              servicePort: 80
```


On the other hand, an annotation like this targets the {{site.kic_product_name}}, forcing the GCE controller to ignore it.

```yaml
metadata:
  name: test-1
  annotations:
    kubernetes.io/ingress.class: "kong"
```

With the `ingressClassName` field instead of the annotation:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: test-1
spec:
  ingressClassName: kong
  rules:
    - host: example.com
      http:
        paths:
          - path: /test1
            backend:
              serviceName: echo
              servicePort: 80
```

The following resources _require_ this annotation by default:

- Ingress
- KongConsumer
- TCPIngress
- UDPIngress
- KongClusterPlugin
- Secret resources with the `ca-cert` label

The ingress class used by the {{site.kic_product_name}} to filter Ingress resources can be changed using the `CONTROLLER_INGRESS_CLASS` environment variable.

```yaml
spec:
  template:
    spec:
      containers:
        - name: kong-ingress-internal-controller
          env:
            - name: CONTROLLER_INGRESS_CLASS
              value: kong-internal
```

#### Multiple unrelated {{site.kic_product_name}}s {#multiple-unrelated-controllers}

In some deployments, you might use multiple {{site.kic_product_name}}s in the same Kubernetes cluster. For example, one which serves public traffic, and one which serves "internal" traffic. For such deployments, ensure that in addition to different `ingress-class`, the `--election-id` is also different.

In such deployments, `kubernetes.io/ingress.class` annotation can be used on the
following custom resources as well:

- KongPlugin: To configure (global) plugins only in one of the {{site.base_gateway}} clusters.
- KongConsumer: To create different Consumers in different {{site.base_gateway}} clusters.


### konghq.com/plugins

{{site.base_gateway}}'s power comes from its plugin architecture, where [plugins](/gateway/entities/plugin/) can modify the request and response or impose certain policies on the requests as they are proxied to your Service.

With the {{site.kic_product_name}}, plugins can be configured by creating KongPlugin Custom Resources and then associating them with an Ingress, Service, HTTPRoute, KongConsumer, KongConsumerGroup or a combination of those.

This is an example of how to use the annotation:

```yaml
konghq.com/plugins: high-rate-limit, docs-site-cors
```

Here, `high-rate-limit` and `docs-site-cors` are the names of the KongPlugin resources which should be to be applied to the Ingress rules defined in the Ingress resource on which the annotation is being applied.

This annotation can also be applied to a Service resource in Kubernetes, which will result in the plugin being executed at Service-level in {{site.base_gateway}}, meaning the plugin will be executed for every request that is proxied, no matter which Route it came from.

This annotation can also be applied to a KongConsumer resource, which results in plugin being executed whenever the specific Consumer is accessing any of the defined APIs.

Finally, this annotation can also be applied on a combination of the following resources:

- **Ingress and KongConsumer**:
  If an Ingress resource and a KongConsumer resource share a plugin in the `konghq.com/plugins` annotation then the plugin will be created for the combination of those to resources in {{site.base_gateway}}.
- **Service and KongConsumer**:
  Same as the above case, if you would like to give a specific Consumer or client of your service some special treatment, you can do so by applying
  the same annotation to both of the resources.

### konghq.com/tags

This annotation can be used to assign custom tags to [{{site.base_gateway}} entities](/gateway/entities/) generated out of a resource the annotation is applied to. The value of the annotation is a comma-separated list of tags. For example, setting this annotation to `tag1,tag2` will assign the tags `tag1` and `tag2` to the {{site.base_gateway}} entity.

## Ingress annotations

The following annotations are supported on Ingress resources:

{% table %}
columns:
  - title: Annotation name
    key: name
  - title: Description
    key: description
rows:
  - name: "[`kubernetes.io/ingress.class`](#kubernetesioingressclass)"
    description: "Restrict the Ingress rules that {{site.base_gateway}} should satisfy. This annotation is **required**, and its value should match the value of the `--ingress-class` controller argument (`kong` by default)."
  - name: "[`konghq.com/plugins`](#konghq-com-plugins)"
    description: "Run plugins for specific Ingress"
  - name: "[`konghq.com/protocols`](#konghq-com-protocols)"
    description: "Set protocols to handle for each Ingress resource"
  - name: "[`konghq.com/preserve-host`](#konghq-com-preserve-host)"
    description: "Pass the `host` header as is to the upstream service"
  - name: "[`konghq.com/strip-path`](#konghq-com-strip-path)"
    description: "Strip the path defined in Ingress resource and then forward the request to the upstream service"
  - name: "[`ingress.kubernetes.io/force-ssl-redirect`](#ingresskubernetesioforce-ssl-redirect)"
    description: "Force non-SSL requests to be redirected to SSL."
  - name: "[`konghq.com/https-redirect-status-code`](#konghq-com-https-redirect-status-code)"
    description: "Set the HTTPS redirect status code to use when an HTTP request is received"
  - name: "[`konghq.com/regex-priority`](#konghq-com-regex-priority)"
    description: "Set the Route's regex priority"
  - name: "[`konghq.com/regex-prefix`](#konghq-com-regex-prefix)"
    description: "Prefix of path to annotate that the path is a regex match, other than default `/~`"
  - name: "[`konghq.com/methods`](#konghq-com-methods)"
    description: "Set methods matched by this Ingress"
  - name: "[`konghq.com/snis`](#konghq-com-snis)"
    description: "Set SNI criteria for Routes created from this Ingress"
  - name: "[`konghq.com/request-buffering`](#konghq-com-request-buffering)"
    description: "Set request buffering on Routes created from this Ingress"
  - name: "[`konghq.com/response-buffering`](#konghq-com-response-buffering)"
    description: "Set response buffering on Routes created from this Ingress"
  - name: "[`konghq.com/host-aliases`](#konghq-com-hostaliases)"
    description: "Additional hosts for Routes created from this Ingress's rules"
  - name: "[`konghq.com/path-handling`](#konghq-com-pathhandling)"
    description: "Set the path handling algorithm"
  - name: "[`konghq.com/headers.*`](#konghq-com-headers)"
    description: "Set header values required to match rules in this Ingress, default separator for multiple values is `,`"
  - name: "[`konghq.com/headers-separator`](#konghq-com-headers-separator)"
    description: "Separator for header values, other than default `,`"
  - name: "[`konghq.com/rewrite`](#konghq-com-rewrite)"
    description: "Rewrite the path of a URL"
  - name: "[`konghq.com/tags`](#konghq-com-tags)"
    description: "Assign custom tags to {{site.base_gateway}} entities generated out of this Ingress"
{% endtable %}

### konghq.com/protocols

This annotation sets the list of acceptable protocols for the all the rules defined in the Ingress resource. The protocols are used for communication between the {{site.base_gateway}} and the external client/user of the Service.

You usually want to set this annotation for the following two use cases:

- You want to redirect HTTP traffic to HTTPS, in which case you will use
  `konghq.com/protocols: "https"`
- You want to define gRPC routing, in which case you should use
  `konghq.com/protocols: "grpc,grpcs"`


### konghq.com/preserve-host

This annotation can be applied to an Ingress resource and can take two values:

- `"true"`: If set to true, the `host` header of the request will be sent as is to the Service in Kubernetes.
- `"false"`: If set to false, the `host` header of the request is not preserved.

{:.info}
> **Note**: The quotes (`"`) around the boolean value are required.

Sample usage:

```yaml
konghq.com/preserve-host: "true"
```


### konghq.com/strip-path

This annotation can be applied to an Ingress resource and can take two values:

- `"true"`: If set to true, the part of the path specified in the Ingress rule
  will be stripped out before the request is sent to the Service.
  For example, if the Ingress rule has a path of `/foo` and the HTTP request
  that matches the Ingress rule has the path `/foo/bar/something`, then
  the request sent to the Kubernetes service will have the path
  `/bar/something`.
- `"false"`: If set to false, no path manipulation is performed.

All other values are ignored.
You must use quotes (`"`) around the boolean value.

Sample usage:

```yaml
konghq.com/strip-path: "true"
```


### ingress.kubernetes.io/force-ssl-redirect

This annotation is used to enforce requests to be redirected to the SSL protocol (HTTPS or GRPCS). The default status code for requests that need to be redirected is `302`. You can configure this code with the [`konghq.com/https-redirect-status-code` annotation](#konghq-com-https-redirect-status-code).

### konghq.com/https-redirect-status-code

By default, {{site.base_gateway}} sends HTTP status code `426` for requests that need to be redirected to HTTPS. This can be changed using this annotation.

Acceptable values are:

- 301
- 302
- 307
- 308
- 426

Any other value will be ignored.

Sample usage:

```yaml
konghq.com/https-redirect-status-code: "301"
```

Quotes (`"`) are required around the integer value.

### konghq.com/regex-priority

Sets the `regex_priority` setting to this value on the {{site.base_gateway}} Route associated with the Ingress resource. This controls the [matching evaluation order](/gateway/routing/traditional/#regex-evaluation-order) for regex-based routes. It accepts any integer value. Routes are evaluated in order of highest priority to lowest.

Sample usage:

```yaml
konghq.com/regex-priority: "10"
```

{:.info}
> **Note**: The quotes (`"`) around the integer value are required.


### konghq.com/regex-prefix

Sets the prefix of the regex matched path to be some string other than `/~`. In {{site.base_gateway}} 3.0 or later, paths with regex match must start with `~`, so in ingresses, the `/~` prefix is used by default to annotate that the path is using regex match. If the annotation is set, paths with the specified prefix are considered as paths with regex match and will be translated to a `~` started path in {{site.base_gateway}}. For example, if an ingress has an annotation of `konghq.com/regex-prefix: "/@"`, paths started with `/@` are considered as paths using regex match.


### konghq.com/methods

Sets the `methods` setting on the {{site.base_gateway}} Route associated with the Ingress resource. This controls which request methods will match the Route. Any uppercase alpha ASCII string is accepted, though most users will only use [standard methods](https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods).

Sample usage:

```yaml
konghq.com/methods: "GET,POST"
```

### konghq.com/snis

Sets the `snis` match criteria on the {{site.base_gateway}} Route associated with this Ingress. When using Route-attached plugins that execute during the [certificate phase](/gateway/entities/plugin/#plugin-contexts) (for example, [Mutual TLS Authentication](/plugins/mtls-auth/)), the `snis` annotation allows route matching based on the server name indication information sent in a client's TLS handshake.

Sample usage:

```yaml
konghq.com/snis: "foo.example.com, bar.example.com"
```

### konghq.com/request-buffering

Enables or disables request buffering on the {{site.base_gateway}} Route associated with this Ingress.

Sample usage:

```yaml
konghq.com/request-buffering: "false"
```

### konghq.com/response-buffering

Enables or disables response buffering on the {{site.base_gateway}} Route associated with this Ingress.

Sample usage:

```yaml
konghq.com/response-buffering: "false"
```

### konghq.com/host-aliases

Sets additional hosts for Routes created from rules on this Ingress.

Sample usage:

```yaml
konghq.com/host-aliases: "example.com,example.net"
```

This annotation applies to all rules equally. An Ingress like this:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-ingress
  annotations:
    konghq.com/host-aliases: "example.com,example.net"
spec:
  rules:
    - host: "foo.example"
      http:
        paths:
          - pathType: Prefix
            path: "/bar"
            backend:
              service:
                name: service1
                port:
                  number: 80
    - host: "bar.example"
      http:
        paths:
          - pathType: Prefix
            path: "/bar"
            backend:
              service:
                name: service2
                port:
                  number: 80
```

Results in two Routes:

```
{"hosts":["foo.example", "example.com", "example.net"], "paths":["/foo"]}
{"hosts":["bar.example", "example.com", "example.net"], "paths":["/bar"]}
```

{:.warning}
> To avoid creating overlapping Routes, don't reuse the same path in multiple rules.

### konghq.com/path-handling

Sets the [path handling algorithm](/gateway/entities/route/#path-handling), which controls how {{site.base_gateway}} combines the Service and Route `path` fields (the Service's [path annotation](#konghq-com-path) value and Ingress rule's `path` field) are combined into the path sent upstream.

### konghq.com/headers.\*

Sets header values that are required for requests to match rules in an Ingress.

Unlike most annotations, `konghq.com/headers.*` includes part of the configuration in the annotation name. The string after the `.` in the annotation name is the header, and the value is a CSV of allowed header values.

For example, setting `konghq.com/headers.x-routing: alpha,bravo` will only match requests that include an `x-routing` header whose value is either `alpha` or `bravo`.


### konghq.com/headers-separator {% new_in 3.2 %}

Sets the separator for the `konghq.com/headers.*` annotation to be something other than default `,`. This is useful when the header values themselves contain commas. For example, setting `konghq.com/headers-separator: ";"` will allow header values to be separated by `;` instead of `,`.

### konghq.com/rewrite

Rewrite a URL path. This annotation is a shorthand method of applying a [request-transformer plugin](/plugins/request-transformer/) with [a `replace.uri` action](/plugins/request-transformer/reference/#schema--config-replace). It cannot be combined with a `konghq.com/plugins` annotation that applies a request-transformer plugin as such.

The annotation can rebuild URLs using segments captured from a regular expression path. A `$n` in the annotation path represents the nth capture group in the Ingress rule path, starting from 1. For example, combining an Ingress rule with path `/~/v(.*)/(.*)` and a `konghq.com/rewrite: /api/$1/foo/svc_$2` would send an upstream request to `/api/2/foo/svc_pricing` upstream when an inbound request is made to `/v2/pricing` (the `/~` prefix instructs {{site.base_gateway}} to treat the path as a regular expression, and isn't used in the actual request).

Annotations apply at the Ingress level and don't modify individual rules. As such, this annotation should only be used on Ingresses with a single rule, or on Ingresses whose rules paths _all_ match the rewrite pattern.

Note that this annotation overrides `strip_path` and Service `path` annotations. The value of the `konghq.com/rewrite` annotation will be the _entire_ path sent upstream. You must include path segments you would normally place in a Service `konghq.com/path` annotation at the start of your `konghq.com/rewrite` annotation.

## KongConsumer resource

These annotations are supported on KongConsumer resources.

{% table %}
columns:
  - title: Annotation name
    key: name
  - title: Description
    key: description
rows:
  - name: "[`kubernetes.io/ingress.class`](#kubernetesioingressclass)<br>*Required*"
    description: "Restrict the KongConsumers that a controller should satisfy"
  - name: "[`konghq.com/plugins`](#konghq-com-plugins)"
    description: "Run plugins for a specific Consumer"
  - name: "[`konghq.com/tags`](#konghq-com-tags)"
    description: "Assign custom tags to {{site.base_gateway}} entities generated out of this KongConsumer"
{% endtable %}

`kubernetes.io/ingress.class` is normally required, and its value should match the value of the `--ingress-class` controller argument (`kong` by default).

Setting the `--process-classless-kong-consumer` controller flag removes that requirement. When it's enabled, the controller processes KongConsumers with no `kubernetes.io/ingress.class` annotation. We recommend setting the annotation and leaving this flag disabled. The flag is primarily intended for older configurations, as controller versions prior to 0.10 processed classless KongConsumer resources by default.

## Service annotations

These annotations are supported on Service resources.

{% table %}
columns:
  - title: Annotation name
    key: name
  - title: Description
    key: description
rows:
  - name: "[`konghq.com/plugins`](#konghq-com-plugins)"
    description: "Run plugins for a specific Service"
  - name: "[`konghq.com/protocol`](#konghq-com-protocol)"
    description: "Set protocol {{site.base_gateway}} should use to talk to a Kubernetes service"
  - name: "[`konghq.com/path`](#konghq-com-path)"
    description: "HTTP Path that is always prepended to each request that is forwarded to a Kubernetes service"
  - name: "[`konghq.com/client-cert`](#konghq-com-client-cert)"
    description: "Client certificate and key pair {{site.base_gateway}} should use to authenticate itself to a specific Kubernetes service"
  - name: "[`konghq.com/host-header`](#konghq-com-host-header)"
    description: "Set the value sent in the `Host` header when proxying requests upstream"
  - name: "[`ingress.kubernetes.io/service-upstream`](#ingresskubernetesioservice-upstream)"
    description: "Offload load-balancing to kube-proxy or sidecar"
  - name: "[`konghq.com/upstream-policy`](#konghq-com-upstream-policy)"
    description: "Override {{site.base_gateway}} Upstream configuration with KongUpstreamPolicy resource"
  - name: "[`konghq.com/connect-timeout`](#konghq-com-connecttimeout)"
    description: "Set the timeout for completing a TCP connection"
  - name: "[`konghq.com/read-timeout`](#konghq-com-readtimeout)"
    description: "Set the timeout for receiving an HTTP response after sending a request"
  - name: "[`konghq.com/write-timeout`](#konghq-com-writetimeout)"
    description: "Set the timeout for writing data"
  - name: "[`konghq.com/retries`](#konghq-com-retries)"
    description: "Set the number of times to retry requests that failed"
  - name: "[`konghq.com/tags`](#konghq-com-tags)"
    description: "Assign custom tags to {{site.base_gateway}} entities generated out of this Service"
  - name: "[`konghq.com/tls-verify`](#konghq-com-tls-verify)"
    description: "Enable or disable verification of the upstream service's TLS certificates"
  - name: "[`konghq.com/tls-verify-depth`](#konghq-com-tls-verify-depth)"
    description: "Set the maximal depth of a certificate chain when verifying the upstream service's TLS certificates"
  - name: "[`konghq.com/ca-certificates-secrets`](#konghq-com-ca-certificates-secrets)"
    description: "Assign CA certificates Secrets to be used for the upstream service's TLS certificates verification"
  - name: "[`konghq.com/ca-certificates-configmaps`](#konghq-com-ca-certificates-configmaps)"
    description: "Assign CA certificates ConfigMaps to be used for the upstream service's TLS certificates verification"
{% endtable %}

### konghq.com/protocol

This annotation can be set on a Kubernetes Service resource and indicates the protocol that should be used by {{site.base_gateway}} to communicate with the Service. In other words, the protocol is used for communication between a [Kong Service](/gateway/entities/service/) and a Kubernetes Service, internally in the Kubernetes cluster.

Accepted values are:

- `http`
- `https`
- `grpc`
- `grpcs`
- `tcp`
- `tls`

### konghq.com/path

This annotation can be used on a Service resource only and can be used to prepend an HTTP path of a request before the request is forwarded.

For example, if the annotation `konghq.com/path: "/baz"` is applied to a Kubernetes Service `billings`, then any request that is routed to the `billings` service will be prepended with `/baz` HTTP path. If the request contains `/foo/something` as the path, then the service will receive an HTTP request with path set as `/baz/foo/something`.

### konghq.com/client-cert

This annotation sets the certificate and key-pair {{site.base_gateway}} should use to authenticate itself against the upstream service, if the upstream service is performing mutual-TLS (mTLS) authentication.

The value of this annotation should be the name of the Kubernetes TLS Secret resource which contains the TLS cert and key pair.

Under the hood, the controller creates a [Certificate](/gateway/entities/certificate/) in {{site.base_gateway}} and then sets the [`service.client_certificate`](/api/konnect/control-planes-config/#/operations/create-service) for the service.

### konghq.com/host-header

Sets the `host_header` setting on the {{site.base_gateway}} upstream created to represent a Kubernetes Service. By default, {{site.base_gateway}} upstreams set `Host` to the hostname or IP address of an individual target (the Pod IP for controller-managed configuration). This annotation overrides the default behavior and sends the annotation value as the `Host` header value.

If `konghq.com/preserve-host: true` is present on an Ingress it will take precedence over this annotation, and requests to the application will use the hostname in the Ingress rule.

Sample usage:

```yaml
konghq.com/host-header: "test.example.com"
```


### ingress.kubernetes.io/service-upstream

By default, the {{site.kic_product_name}} distributes traffic amongst all the Pods of a Kubernetes Service by forwarding the requests directly to Pod IP addresses. One can choose the load-balancing strategy to use by specifying a KongIngress resource.

However, in some use cases, the load balancing should be left up to `kube-proxy`, or a sidecar component in the case of Service Mesh deployments.

Setting this annotation to a Service resource in Kubernetes will configure the {{site.kic_product_name}} to directly forward the traffic outbound for this Service to the IP address of the service (usually the ClusterIP).

`kube-proxy` can then decide how it wants to handle the request and route the traffic accordingly. If a sidecar intercepts the traffic from the controller, it can also route traffic as it sees fit in this case.

Following is an example snippet you can use to configure this annotation on a Service resource in Kubernetes (the quotes around `true` are required):

```yaml
annotations:
  ingress.kubernetes.io/service-upstream: "true"
```

### konghq.com/upstream-policy {% new_in 3.0 %}

This annotation can be used to attach `KongUpstreamPolicy` resources to `Services`. The value of the annotation is the name of the `KongUpstreamPolicy` object in the same namespace as the `Service`. See the [KongUpstreamPolicy reference](/kubernetes-ingress-controller/reference/custom-resources/#kongupstreampolicy) for details on how to configure the `KongUpstreamPolicy` resource.


### konghq.com/connect-timeout

Sets the connect timeout, in milliseconds. For example, setting this annotation to `60000` will instruct the proxy to wait up to 60 seconds to complete the initial TCP connection to the upstream service.

### konghq.com/read-timeout

Sets the read timeout, in milliseconds. For example, setting this annotation to `60000` will instruct the proxy to wait up to 60 seconds after sending a request before timing out and returning a 504 response to the client.

### konghq.com/write-timeout

Sets the write timeout, in milliseconds. For example, setting this annotation to `60000` will instruct the proxy to wait up to 60 seconds without writing data before closing a kept-alive connection.

### konghq.com/retries

Sets the max retries on a request. For example, setting this annotation to `3` will re-send the request up to three times if it encounters a failure, such as a timeout.

### konghq.com/tls-verify {% new_in 3.4 %}

This annotation can be used to enable or disable verification of the upstream service's TLS certificates. The value of the annotation should be either `true` or `false`. By default, the verification is disabled.

See [TLS verification of Upstream Service](/kubernetes-ingress-controller/verify-upstream-tls/) guide for more information.

### konghq.com/tls-verify-depth {% new_in 3.4 %}

This annotation can be used to set the maximal depth of a certificate chain when verifying the upstream service's TLS certificates.
The value of the annotation should be an integer. If not set, a system default value is used.

See [TLS verification of Upstream Service](/kubernetes-ingress-controller/verify-upstream-tls/) guide for more information.


### konghq.com/ca-certificates-secrets {% new_in 3.4 %}

This annotation can be used to assign CA certificates to be used for the upstream service's TLS certificates verification.
The value of the annotation should be a comma-separated list of `Secret`s containing CA certificates.

### konghq.com/ca-certificates-configmaps {% new_in 3.4 %}

This annotation can be used to assign CA certificates to be used for the upstream service's TLS certificates verification.
The value of the annotation should be a comma-separated list of `ConfigMap`s containing CA certificates.

See [TLS verification of Upstream Service](/kubernetes-ingress-controller/verify-upstream-tls/) guide for more information.
