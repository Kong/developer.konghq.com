---
title: Kubernetes Secrets with {{site.operator_product_name}}
description: "Reference guide for configuring Kubernetes Secrets with {{site.operator_product_name}}."
content_type: reference
layout: reference
breadcrumbs:
  - /operator/
  - index: operator
    group: Reference
  - index: operator
    group: Reference
    section: "Reference"
products:
  - operator
works_on:
  - on-prem
  - konnect
---

{{site.operator_product_name}} uses a strict filtering mechanism for watching Kubernetes Secrets. To prevent {{site.operator_product_name}} from reconciling every Secret in the cluster, which can be expensive and insecure, it only watches Secrets that are explicitly labeled.

All Secrets referenced by Kong resources must have the following label:

```yaml
metadata:
  labels:
    konghq.com/secret: "true"
```

If this label is missing, {{site.operator_product_name}} will ignore the Secret, even if it's correctly referenced in other resources.

## Types of Secrets

The following Secret types can be configured with {{site.operator_product_name}}.

### TLS certificates

TLS certificates can be references in `Gateway` listeners or `KongPlugin` configuration.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-cert
  namespace: kong
  labels:
    konghq.com/secret: "true"
type: kubernetes.io/tls
data:
  tls.crt: $CERT_CONTENT
  tls.key: $KEY_CONTENT
```

### Consumer credentials

Consumer credentials can be referenced in `KongConsumer` resources. In addition to the `konghq.com/secret: "true"` label, these Secrets usually require a type-specific credential label. In this example, `konghq.com/credential: key-auth` is needed to identify the credential type:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-apikey
  namespace: kong
  labels:
    konghq.com/secret: "true"
    konghq.com/credential: key-auth
type: Opaque
stringData:
  key: my-secret-key
```

### Plugin configuration

Some plugins allow referencing a Secret for sensitive configuration values:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: plugin-secret
  namespace: kong
  labels:
    konghq.com/secret: "true"
type: Opaque
stringData:
  secret-value: "super-secure"
```

## Troubleshooting

If your `Gateway`, `KongConsumer`, or `KongPlugin` has the status `Programmed` or `Created` but is returning an error, such as `401 Unauthorized, default certificate served`, check the labels on your referenced Secret and ensure `konghq.com/secret` is present and set to `"true"`:

```bash
kubectl get secret $SECRET_NAME -n $NAMESPACE --show-labels
```
    
