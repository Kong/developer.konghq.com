---
title: Managing secrets in {{site.mesh_product_name}}
description: Store and manage secrets securely in {{site.mesh_product_name}}, including mesh-scoped and global-scoped secrets for use in mTLS, policies, and external services.

content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/

tags:
  - secrets-management

related_resources:
  - text: Authentication with the API server
    url: /mesh/authentication-with-the-api-server/
  - text: Data plane proxy
    url: /mesh/data-plane-proxy/
---

The `Secret` resource enables users to store sensitive data. This includes anything a user considers non-public, such as:
* TLS keys
* Tokens
* Passwords

Secrets belong to a specific `Mesh` resource, and can't be shared across different `Meshes`.
[Policies](/mesh/policies-introduction/on) use secrets at runtime.

{:.info}
> {{site.mesh_product_name}} leverages `Secret` resources internally for certain operations, for example when storing auto-generated certificates and keys when Mutual TLS is enabled.

{% navtabs "Environments" %}
{% navtab "Kubernetes" %}

On Kubernetes, {{site.mesh_product_name}} leverages the native [Kubernetes Secret](https://kubernetes.io/docs/concepts/configuration/secret/) resource to store sensitive information.

{{site.mesh_product_name}} secrets are stored in the same namespace as the control plane with `type` set to `system.kuma.io/secret`. 
You can use `kubectl` to manage secrets like any other Kubernetes resource:

```sh
echo "apiVersion: v1
kind: Secret
metadata:
  name: sample-secret
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: default
data:
  value: dGVzdAo=
type: system.kuma.io/secret" | kubectl apply -f -

kubectl get secrets -n {{site.mesh_namespace}} --field-selector='type=system.kuma.io/secret'
```

Kubernetes secrets are identified with the combination of their name and namespace, therefore is impossible to have a `Secret` with the same name in multiple meshes, since multiple meshes always belong to one {{site.mesh_product_name}} control plane that always runs in one namespace.

In order to reassign a `Secret` from one mesh to another, you must delete the `Secret` resource and create it in another mesh.

{% endnavtab %}

{% navtab "Universal" %}

A `Secret` is a resource that stores specific `data`. You can use `kumactl` to manage any `Secret`:

```sh
echo "type: Secret
mesh: default
name: sample-secret
data: dGVzdAo=" | kumactl apply -f -
```

{% endnavtab %}
{% endnavtabs %}


The `data` field of a {{site.mesh_product_name}} secret is a Base64-encoded value.
Use the `base64` command in Linux or macOS to encode any value in Base64:

```sh
# Base64 encode a file
cat cert.pem | base64

# or Base64 encode a string
echo "value" | base64
```


{{site.mesh_product_name}} provides two types of secrets:
* [Mesh-scoped](#mesh-scoped-secrets)
* [Global](#global-secrets)

## Mesh-scoped secrets

Mesh-scoped secrets are bound to a given mes.
This is the only type of secret that can be used in mesh policies like [Provided CA](/mesh/policies/mutual-tls/#usage-of-provided-ca) or TLS setting in [External Service](/mesh/policies/external-services/).

{% navtabs "Environments" %}
{% navtab "Kubernetes" %}

On Kubernetes, mesh-scoped secrets must include the `kuma.io/mesh` label and have `type` set to `system.kuma.io/secret`:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: sample-secret
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: default
data:
  value: dGVzdAo=
type: system.kuma.io/secret
```

{% endnavtab %}
{% navtab "Universal" %}

On Universal, mesh-scoped secrets must include the `mesh` parameter and have `type` set to `Secret`:
```yaml
type: Secret
name: sample-secret
mesh: default
data: dGVzdAo=
```

{% endnavtab %}
{% endnavtabs %}

## Global secrets

Global secrets are not bound to a given mesh and can't be used in mesh policies.
Global secrets are used for internal purposes.

{% navtabs "Environments" %}
{% navtab "Kubernetes" %}
On Kubernetes, global secrets must have `type` set to `system.kuma.io/global-secret`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: sample-secret
  namespace: {{site.mesh_namespace}}
data:
  value: dGVzdAo=
type: system.kuma.io/global-secret
```

{% endnavtab %}
{% navtab "Universal" %}
On Universal, mesh-scoped secrets must have `type` set to `GlobalSecret`:

```yaml
type: GlobalSecret
name: sample-global-secret
data: dGVzdAo=
```

{% endnavtab %}
{% endnavtabs %}

## Secrets in multi-zone deployments

Secrets are synced from the global control plane to the zones CPs, but not the other way around as this would risk exposing sensitive information.

{% new_in 2.10 %} If there's a name conflict between a secret on the global CP and a secret on a zone CP, the secret is not overwritten and a warning will appear in the logs. In versions prior to 2.10, secrets can't be created on a zone control plane.

## Example

Here is an example of how to use a {{site.mesh_product_name}} `Secret` with a `provided` [Mutual TLS](/mesh/policies/mutual-tls/#usage-of-provided-ca) backend.

The examples below assume that the `Secret` object has already been created:

{% navtabs "Environments" %}
{% navtab "Universal" %}

```yaml
type: Mesh
name: default
mtls:
  backends:
    - name: ca-1
      type: provided
      config:
        cert:
          secret: my-cert # name of the {{site.mesh_product_name}} secret
        key:
          secret: my-key # name of the {{site.mesh_product_name}} secret
```

{% endnavtab %}
{% navtab "Kubernetes" %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  mtls:
    backends:
      - name: ca-1
        type: provided
        config:
          cert:
            secret: my-cert # name of the Kubernetes secret
          key:
            secret: my-key # name of the Kubernetes secret
```

{% endnavtab %}
{% endnavtabs %}
