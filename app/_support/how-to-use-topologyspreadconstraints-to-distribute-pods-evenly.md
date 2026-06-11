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
tldr:
  q: How do I use topologySpreadConstraints to distribute Kong pods evenly across my Kubernetes cluster nodes?
  a: |
    `topologySpreadConstraints` is supported in the Kong Helm charts from version `2.0.0`. Add a
    `topologySpreadConstraints` block to your Helm values, setting `topologyKey` to a node label shared by
    all target nodes (for example `kubernetes.io/hostname` or a custom `zone` label) and `labelSelector.matchLabels`
    to match the Kong pods (for example `app.kubernetes.io/instance: kong-enterprise`). The `maxSkew` and
    `whenUnsatisfiable` parameters control how rigidly the pods must be spread.
related_resources:
  - text: "topologySpreadConstraints support in the Kong Helm charts (CHANGELOG 2.0.0)"
    url: https://github.com/Kong/charts/blob/7fb11b7658f48de14d04a6d8155f1b2e1c8dbba8/charts/kong/CHANGELOG.md#200
  - text: "Kubernetes Pod Topology Spread Constraints documentation"
    url: https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/
---

## Overview

How do I use `topologySpreadConstraints` to load balance my pods over my Kubernetes cluster nodes?

## Steps

We added support for `topologySpreadConstraints` to our Helm charts from version 2.0.0.

The following commands are useful when working with `topologySpreadConstraints`:

```bash
# See which node pods are residing on:
kubectl get pods -n kong -o wide
# Show Kubernetes node information with labels:
kubectl get nodes --show-labels
# Label a node with a particular label:
kubectl label nodes k8s-worker-2 zone=2
```

Cluster node details:

The labels are used by `topologySpreadConstraints` to determine where various pods should go.

```text
NAME              STATUS   ROLES           AGE    VERSION   LABELS
k8s-master-node   Ready    control-plane   116d   v1.24.3   kubernetes.io/hostname=k8s-master-node
k8s-worker-1      Ready    <none>          116d   v1.24.3   kubernetes.io/hostname=k8s-worker-1,zone=1
k8s-worker-2      Ready    <none>          116d   v1.24.3   kubernetes.io/hostname=k8s-worker-2,zone=2
```

Example 1:

Distribute 2 pods over 3 nodes by applying the following in your Helm values.

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

For a more detailed explanation of what each config option does, review the Kubernetes documentation.

The important parameters are:

`topologyKey`: Denotes the pod label used to select underlying hosts for distribution. To use all nodes, set this to a label that all nodes contain, such as `kubernetes.io/hostname`.

`labelSelector.matchLabels`: Finds matching pods. To balance Kong pods, all the pods have the `app.kubernetes.io/instance: kong-enterprise` label.

The `maxSkew` and `whenUnsatisfiable` parameters control how rigidly the rules are applied and how evenly the pods must be spread.

Results:

Pod and resident node:

```text
kong-enterprise-kong-785c5d5db8-bqqfx  | k8s-master-node |
kong-enterprise-kong-785c5d5db8-pn9z5  | k8s-worker-1    |
```

Example 2:

Distribute 3 pods over 3 nodes by changing `replicaCount` to 3 and upgrading the Helm deployment.

Results:

Pod and resident node:

```text
kong-enterprise-kong-785c5d5db8-bqqfx | k8s-master-node |
kong-enterprise-kong-785c5d5db8-pn9z5 | k8s-worker-1    |
kong-enterprise-kong-785c5d5db8-8gq6s | k8s-worker-2    |
```

Example 3:

Distribute 3 pods over 2 nodes using the zone label.

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

Results:

Pod and resident node:

```text
kong-enterprise-kong-579f9678bd-mm5mj  | k8s-worker-2    |
kong-enterprise-kong-579f9678bd-p788t  | k8s-worker-1    |
kong-enterprise-kong-579f9678bd-whqrg  | k8s-worker-2    |
```

Conclusion:

This is a fairly simple load balancing scenario, however `topologySpreadConstraints` have greater flexibility than the previous affinity rules allowed.
