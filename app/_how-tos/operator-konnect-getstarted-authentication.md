---
title: Create API Authentication
description: Set up authentication between your Kubernetes cluster and {{ site.konnect_short_name }} using the `KonnectAPIAuthConfiguration` and `KonnectExtension` resources.
content_type: how_to
permalink: /operator/konnect/get-started/authentication/
breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect
  - index: operator
    group: Konnect
    section: Get Started

series:
  id: kgo-get-started
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

---

## Create a `KonnectAPIAuthConfiguration` object

Depending on your preferences, you can create a `KonnectAPIAuthConfiguration` object with the token specified directly in the spec or as a reference to a Kubernetes Secret. In the CRD, the `serverURL` should be set to the {{site.konnect_short_name}} API url in the region where your account is located. 


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


## Validate

Run the following command to verify that the authentication configuration was created successfully:

```bash
kubectl get konnectapiauthconfiguration konnect-api-auth -n kong
```

