---
title: "\"failed to fetch KongPlugin: no KongPlugin or KongClusterPlugin was found\" errors in the KIC logs"
content_type: support
description: "The error suggests that you have created an Ingress rule or `KongConsumer`, and added a `konghq.com/plugins` annotation using a plugin name which does not already exist."
products:
  - kic
works_on:
  - on-prem
  - konnect
tldr:
  q: "Why do we get \"failed to fetch KongPlugin: no KongPlugin or KongClusterPlugin was found\" errors in the KIC logs?"
  a: |
    This means an Ingress rule or `KongConsumer` references a `konghq.com/plugins` annotation naming a plugin that doesn't exist — often because the plugin was created in a different namespace. Current Kong Ingress Controller versions surface this only as a Kubernetes Warning Event on the affected resource (not in the controller logs), so check `kubectl get events` or `kubectl describe` on the Ingress/KongConsumer, then correct or remove the plugin reference.
related_resources: []
---

## Problem

My Ingress rule or `KongConsumer` references a `konghq.com/plugins` annotation with a plugin name that does not exist, and {{site.kic_product_name}} is failing to apply the configuration as a result.

How can I find the affected resource and stop these errors?

Note: current versions of {{site.kic_product_name}} no longer log the string `failed to fetch KongPlugin: no KongPlugin or KongClusterPlugin was found` anywhere in the controller logs. Instead, this failure surfaces only as a Kubernetes Warning Event on the affected resource — check `kubectl get events` or `kubectl describe` on the relevant Ingress/`KongConsumer` for a Warning Event describing the missing `KongPlugin`/`KongClusterPlugin`, rather than grepping the controller logs.

## Solution

The error suggests that you have created an Ingress rule or `KongConsumer`, and added a `konghq.com/plugins` annotation using a plugin name which does not already exist. This can be the case when the plugin is created in a different namespace than the Ingress rule or `KongConsumer`.

If you do not know which resource could be at fault because this is something that was created by a different team, you can try the following steps to find the relevant resource, and delete it:

1. Find all `KongPlugins`, and `KongClusterPlugins` in all workspaces:

```bash

kubectl get KongClusterPlugins --all-namespaces
kubectl get KongPlugins --all-namespaces
```

2. Check if you have any Ingress rules that reference a plugin that does not exist in either of the outputs above:

```bash

a) find all Kong Ingress rules in all workspaces:
kubectl get ing --all-namespaces

b) run the following for each Ingress rule found in a)
kubectl describe -n <relevantnamespace> ing <ingressname>|grep "konghq.com/plugins"
```

3. Check if you have a Consumer with a plugin configured that was not returned in step 1

```bash

1. Find all KongConsumers configured
kubectl get KongConsumer --all-namespaces

2. Find which plugins are configured for each consumer:
kubectl describe -n <relevantnamespace> KongConsumer <kongconsumerreturnedin1>|grep "konghq.com/plugins"
```

4. If you find a Kong Consumer or Ingress rule that has a non existent plugin configured, edit or delete the relevant Ingress rule as appropriate, and the log entries should stop
