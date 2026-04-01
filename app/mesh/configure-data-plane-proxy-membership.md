---
title: Configure data plane proxy membership
description: Define requirements and restrictions for data plane proxies joining a mesh using membership constraints based on tags, namespaces, or zones.

content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/

related_resources:
  - text: Data plane on Kubernetes
    url: /mesh/data-plane-kubernetes/
  - text: Data plane on Universal
    url: /mesh/data-plane-universal/
  - text: Data plane proxy
    url: /mesh/data-plane-proxy/
---

Data plane proxy membership constraints allow you to define a set of rules that are executed when a data plane proxy is joining a mesh. These help determine if a data plane proxy can or can't join the mesh.

Constraints contains two lists:
* Requirements: A data plane proxy has to fulfill at least one requirement to join a mesh.
* Restrictions: If a data plane proxy matches any of the restrictions, it can't join the mesh.

{:.info}
> Membership rules are enforced only on new data plane proxies. If existing data plane proxies violate rules, you must remove them manually from the mesh.

Data plane proxy constraints are defined using the `constrains.dataplaneProxy.requirements` and `constrains.dataplaneProxy.restrictions` parameters. 

## Membership constraint examples

The following examples show you different ways you can configure data plane proxy membership constraints.

### Restrict data plane membership based on namespaces

In this example, we allow data plane proxies to join the mesh if they are in either the `ns-1` namespace or the `ns-2` namespace:

{% navtabs "Environment" %}
{% navtab "Kubernetes" %}
```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  constraints:
    dataplaneProxy:
      requirements:
      - tags:
          kuma.io/namespace: ns-1
      - tags:
          kuma.io/namespace: ns-2
```
{% endnavtab %}
{% navtab "Universal" %}
```yaml
type: Mesh
name: default
constraints:
  dataplaneProxy:
    requirements:
      - tags:
          kuma.io/namespace: ns-1
      - tags:
          kuma.io/namespace: ns-2
```
{% endnavtab %}
{% endnavtabs %}

### Enforce consistency of tags

In this example, every data plane proxy must have non-empty `team` and `cloud` tags and can't have a `legacy` tag.

{% navtabs "Environment" %}
{% navtab "Kubernetes" %}
```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  constraints:
    dataplaneProxy:
      requirements:
      - tags:
          team: '*'
          cloud: '*'
      restrictions:
      - tags:
          legacy: '*'
```
{% endnavtab %}
{% navtab "Universal" %}
```yaml
type: Mesh
name: default
constraints:
  dataplaneProxy:
    requirements:
      - tags:
          team: '*'
          cloud: '*'
    restrictions:
      - tags:
          legacy: '*'
```
{% endnavtab %}
{% endnavtabs %}


### Multi-zone mesh segmentation

In this example, only data plane proxies from the `east` zone can join the `default` mesh, and only data plane proxies from the `west` zone can join the `demo` mesh. 

{% navtabs "Environment" %}
{% navtab "Kubernetes" %}
```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  constraints:
    dataplaneProxy:
      requirements:
      - tags:
          kuma.io/zone: east
---
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: demo
spec:
  constraints:
    dataplaneProxy:
      requirements:
        - tags:
            kuma.io/zone: west
```
{% endnavtab %}
{% navtab "Universal" %}
```yaml
type: Mesh
name: default
constraints:
  dataplaneProxy:
    requirements:
    - tags:
        kuma.io/zone: east
---
type: Mesh
name: demo
constraints:
  dataplaneProxy:
    requirements:
      - tags:
          kuma.io/zone: west
```
{% endnavtab %}
{% endnavtabs %}
