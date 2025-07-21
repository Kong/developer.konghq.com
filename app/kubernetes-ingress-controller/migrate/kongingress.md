---
title: Migrating from KongIngress to annotations and KongUpstreamPolicy

description: |
  Learn how to migrate from the deprecated KongIngress resource to annotations and KongUpstreamPolicy.

content_type: reference
layout: reference
breadcrumbs:
  - /kubernetes-ingress-controller/
products:
  - kic

works_on:
  - on-prem
  - konnect

tags:
  - migration

related_resources:
  - text: KongUpstreamPolicy
    url: /kubernetes-ingress-controller/reference/annotations/#konghq-com-upstream-policy
  - text: Annotation reference
    url: /kubernetes-ingress-controller/reference/annotations/
  - text: Gateway API Migration
    url: /kubernetes-ingress-controller/migrate/ingress-to-gateway/

---

{:.warning}
> **Important: KongIngress Deprecation Notice**
>
> The `KongIngress` custom resource is **deprecated** as of {{site.kic_product_name}} 3.5 and will be **completely removed in Kong Operator 2.0.0**.
>
> **Migration is required** before upgrading to Kong Operator 2.0.0:
>
> - The `proxy` and `route` sections are **already deprecated** and replaced by dedicated annotations
> - The `upstream` section is being replaced by the new `KongUpstreamPolicy` resource
> - `KongIngress` is **not supported** with Gateway API resources (HTTPRoute, TCPRoute, etc.)
>
> Use this guide to migrate your existing `KongIngress` resources to their modern equivalents.

## Overview

The `KongIngress` resource was originally designed to extend the capabilities of the standard Kubernetes Ingress resource. However, as the Kubernetes ecosystem evolved and the Gateway API matured, `KongIngress` has become redundant and is being phased out in favor of:

- **Annotations**: For simple proxy and route configurations
- **KongUpstreamPolicy**: For complex upstream configurations
- **Gateway API**: For advanced routing and traffic management

## Migration strategy

The migration approach depends on which sections of `KongIngress` you're using:

### 1. Proxy and Route sections (already deprecated)

These sections are replaced by dedicated annotations:

| KongIngress field | Replacement annotation |
|-------------------|------------------------|
| `proxy.connect_timeout` | `konghq.com/connect-timeout` |
| `proxy.read_timeout` | `konghq.com/read-timeout` |
| `proxy.write_timeout` | `konghq.com/write-timeout` |
| `proxy.retries` | `konghq.com/retries` |
| `route.methods` | `konghq.com/methods` |
| `route.headers.*` | `konghq.com/headers.*` |
| `route.protocols` | `konghq.com/protocols` |
| `route.regex_priority` | `konghq.com/regex-priority` |
| `route.strip_path` | `konghq.com/strip-path` |
| `route.preserve_host` | `konghq.com/preserve-host` |
| `route.https_redirect_status_code` | `konghq.com/https-redirect-status-code` |

### 2. Upstream section

The `upstream` section is replaced by the `KongUpstreamPolicy` resource.

## Migrating proxy and route sections

### Example migration

If you have a KongIngress like this:

```yaml
apiVersion: configuration.konghq.com/v1
kind: KongIngress
metadata:
  name: example-kongingress
proxy:
  connect_timeout: 30000
  read_timeout: 60000
  retries: 5
route:
  methods:
  - GET
  - POST
  strip_path: true
  preserve_host: true
```

Replace it with annotations on your Service or Ingress:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: example-service
  annotations:
    konghq.com/connect-timeout: "30000"
    konghq.com/read-timeout: "60000"
    konghq.com/retries: "5"
    konghq.com/methods: "GET,POST"
    konghq.com/strip-path: "true"
    konghq.com/preserve-host: "true"
spec:
  # service configuration...
```

## Migrating headers configuration

### konghq.com/headers.* annotation

The [`konghq.com/headers.*` annotation](/kubernetes-ingress-controller/reference/annotations/#konghq-com-headers) uses a special format to set headers. The string after the `.` in the annotation name is the header name and the annotation value is the header value. For example, to apply `x-custom-header-a: example,otherexample` and `x-custom-header-b: example` headers to requests, the KongIngress configuration is:

```yaml
route:
  headers:
    x-custom-header-a:
    - example
    - otherexample
    x-custom-header-b:
    - example
```

The equivalent annotation configuration looks like:

```text
konghq.com/headers.x-custom-header-a: example,otherexample
konghq.com/headers.x-custom-header-b: example
```

You cannot apply multiple instances of the same header annotation to set multiple header values. You must set the CSV format within a single header.

## KongUpstreamPolicy

The `upstream` section of `KongIngress` resources contains a complex object that does not easily fit in annotations. Version 3.x uses the new `KongUpstreamPolicy` resource to configure upstream settings. The `spec` field of `KongUpstreamPolicy` is similar to the `upstream` section of KongIngress, with the following differences:

- Field names now use `lowerCamelCase` instead of `snake_case` to be consistent with Kubernetes APIs.
- `hash_on`, `hash_fallback`, and their related `has_on_*`, `hash_fallback_*` fields are now `hashOn` and `hashOnFallback` objects. To define the primary hashing strategy, use `hashOn` with one of its fields filled (e.g. when you want to hash on a header, fill `hashOn.header` with a header name). Similarly, to define the secondary hashing strategy, use `hashOnFallback`.

For the exact schema please refer to [KongUpstreamPolicy reference](/kubernetes-ingress-controller/reference/custom-resources/#kongupstreampolicy).

For example, if you previously used a KongIngress like:

```yaml
apiVersion: configuration.konghq.com/v1
kind: KongIngress
metadata:
  name: sample-customization
upstream:
  hash_on: header
  hash_on_header: x-lb
  hash_fallback: ip
  algorithm: consistent-hashing
```

You need to use a `KongUpstreamPolicy`:

```yaml
apiVersion: configuration.konghq.com/v1beta1
kind: KongUpstreamPolicy
metadata:
  name: sample-customization
spec:
  hashOn:
    header: x-lb
  hashOnFallback:
    input: ip
  algorithm: consistent-hashing
```

Apply it to a Service resource with a `konghq.com/upstream-policy: sample-customization` annotation.
