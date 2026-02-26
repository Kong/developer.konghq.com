---
title: Create API Authentication
description: Set up authentication between your Kubernetes cluster and {{ site.konnect_short_name }} using the `KonnectAPIAuthConfiguration` and `KonnectExtension` resources.
content_type: how_to
permalink: /operator/get-started/konnect-crds/authentication/
breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect
  - index: operator
    group: Konnect
    section: Get Started

series:
  id: operator-get-started-konnect-crds
  position: 2

tldr:
  q: How do I authenticate my cluster with {{ site.konnect_short_name }}?
  a: |
    Define a `KonnectAPIAuthConfiguration` to provide credentials and a `KonnectExtension` to connect your cluster to a {{ site.konnect_short_name }} Control Plane.

products:
  - operator

works_on:
  - konnect

entities: []

prereqs:
  skip_product: true
  show_works_on: true

---

## Create a `KonnectAPIAuthConfiguration` object

`KonnectAPIAuthConfiguration` serves as the container for the authentication credentials
required to connect your Kubernetes cluster to {{ site.konnect_short_name }}.

It can store either:

- A Personal Access Token
- A System Account Access Token

Depending on your preferences, you can either:

- Create a `KonnectAPIAuthConfiguration` object with the token specified directly in the spec and use RBAC to restrict access to its type.
- Use a Kubernetes `Secret` of type `Opaque` and reference it from the `KonnectAPIAuthConfiguration` object.
  The token has to be specified in `Secret`'s `token` data field.

The `serverURL` should be set to the {{site.konnect_short_name}} API url in the region where your account is located.

### Using a token in `KonnectAPIAuthConfiguration`

<!-- vale off -->
{% konnect_crd %}
kind: KonnectAPIAuthConfiguration
metadata:
  name: konnect-api-auth
spec:
  type: token
  token: '$KONNECT_TOKEN'
  serverURL: us.api.konghq.com
{% endkonnect_crd %}
<!-- vale on -->

### Using a Secret reference

```sh
echo 'apiVersion: v1
kind: Secret
metadata:
  name: konnect-api-auth-secret
  namespace: kong
  labels:
    konghq.com/credential: konnect
    konghq.com/secret: "true"
stringData:
  token: "'$KONNECT_TOKEN'"' | kubectl apply -f -
```

<!-- vale off -->
{% konnect_crd %}
kind: KonnectAPIAuthConfiguration
metadata:
  name: konnect-api-auth
spec:
  type: secretRef
  secretRef:
    name: konnect-api-auth-secret
  serverURL: us.api.konghq.com
{% endkonnect_crd %}
<!-- vale on -->

## Validate

Run the following command to verify that the authentication configuration was created successfully:

```bash
kubectl get konnectapiauthconfiguration konnect-api-auth -n kong
```

You should see output similar to the following:

```bash
NAME               VALID   ORGID                                  SERVERURL
konnect-api-auth   True    5ca26716-02f7-4430-9117-1d1a7a2695e7   https://us.api.konghq.com
```

If you prefer to work with status conditions programmatically, you can also run:

```bash
kubectl get konnectapiauthconfiguration konnect-api-auth -n kong -o jsonpath="{.status.conditions[?(@.type=='APIAuthValid')]}"
```

Which should yield the follow

```json
{"lastTransitionTime":"2025-10-16T11:46:28Z","message":"Token is valid","observedGeneration":1,"reason":"Valid","status":"True","type":"APIAuthValid"}
```
