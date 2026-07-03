---
title: How to use topologySpreadConstraints to distribute pods evenly
content_type: support
description: Use topologySpreadConstraints, supported in the Kong Helm charts from version 2.0.0, to evenly distribute Kong pods across your Kubernetes cluster nodes.
products:
  - gateway
  - kic
works_on:
  - on-prem
  - konnect
published: false
tldr:
  q: How do I use topologySpreadConstraints to distribute Kong pods evenly across my Kubernetes cluster nodes?
  a: |
    Add a `topologySpreadConstraints` block to your Helm values (supported from chart version 2.0.0), setting `topologyKey` to a node label and `labelSelector.matchLabels` to match Kong pods.
    Use `maxSkew` and `whenUnsatisfiable` to control how strictly the spread is enforced.
related_resources:
  - text: "topologySpreadConstraints support in the Kong Helm charts (CHANGELOG 2.0.0)"
    url: https://github.com/Kong/charts/blob/7fb11b7658f48de14d04a6d8155f1b2e1c8dbba8/charts/kong/CHANGELOG.md#200
  - text: "Kubernetes Pod Topology Spread Constraints documentation"
    url: https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/
---

## Steps

`topologySpreadConstraints` is supported in the Kong Helm charts from version 2.0.0.

The following commands are useful when working with `topologySpreadConstraints`:

```bash
# See which node pods are residing on:
kubectl get pods -n kong -o wide
# Show Kubernetes node information with labels:
kubectl get nodes --show-labels
# Label a node with a particular label:
kubectl label nodes k8s-worker-2 zone=2
```

Node labels determine where `topologySpreadConstraints` schedules pods.
The examples below use the following cluster:

```text
NAME              STATUS   ROLES           AGE    VERSION   LABELS
k8s-master-node   Ready    control-plane   116d   v1.24.3   kubernetes.io/hostname=k8s-master-node
k8s-worker-1      Ready    <none>          116d   v1.24.3   kubernetes.io/hostname=k8s-worker-1,zone=1
k8s-worker-2      Ready    <none>          116d   v1.24.3   kubernetes.io/hostname=k8s-worker-2,zone=2
```
{:.no-copy-code.wrap}

The key parameters are:

`topologyKey`: the node label used to select hosts for distribution.
To spread across all nodes, set this to a label present on every node, such as `kubernetes.io/hostname`.

`labelSelector.matchLabels`: selects the pods to balance.
Kong pods have the `app.kubernetes.io/instance: kong-enterprise` label.

`maxSkew` and `whenUnsatisfiable`: control how strictly the spread is enforced.
See the [Kubernetes topology spread constraints documentation](https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/) for details.

### Example 1: 2 pods across 3 nodes

```yaml
replicaCount: 2
topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: kubernetes.io/hostname
    whenUnsatisfiable: DoNotSchedule
    labelSelector:
      matchLabels:
        app.kubernetes.io/instance: kong-enterprise
```

Each pod is scheduled on a separate node:

```text
kong-enterprise-kong-785c5d5db8-bqqfx  | k8s-master-node |
kong-enterprise-kong-785c5d5db8-pn9z5  | k8s-worker-1    |
```
{:.no-copy-code.wrap}

### Example 2: 3 pods across 3 nodes

Change `replicaCount` to `3` and upgrade the Helm deployment.
One pod is scheduled per node:

```text
kong-enterprise-kong-785c5d5db8-bqqfx | k8s-master-node |
kong-enterprise-kong-785c5d5db8-pn9z5 | k8s-worker-1    |
kong-enterprise-kong-785c5d5db8-8gq6s | k8s-worker-2    |
```
{:.no-copy-code.wrap}

### Example 3: 3 pods across 2 nodes using a zone label

```yaml
replicaCount: 3
topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: zone
    whenUnsatisfiable: DoNotSchedule
    labelSelector:
      matchLabels:
        app.kubernetes.io/instance: kong-enterprise
```

Pods are distributed across the two zone-labeled worker nodes, with one node receiving two pods to satisfy `maxSkew: 1`:

```text
kong-enterprise-kong-579f9678bd-mm5mj  | k8s-worker-2    |
kong-enterprise-kong-579f9678bd-p788t  | k8s-worker-1    |
kong-enterprise-kong-579f9678bd-whqrg  | k8s-worker-2    |
```
{:.no-copy-code.wrap}

This is a fairly simple load balancing scenario, but `topologySpreadConstraints` offers greater flexibility than affinity rules.
