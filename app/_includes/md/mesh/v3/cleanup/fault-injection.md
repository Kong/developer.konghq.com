Delete the fault injection policies. Leaving any of them in place keeps injecting failures into traffic that later guides depend on:

```sh
kubectl delete meshfaultinjection test-flight-control-resilience test-check-in-api-latency test-flight-control-throttle -n kong-air-production --ignore-not-found
kubectl delete meshfaultinjection zone-egress-fault-injection -n {{site.mesh_namespace}} --ignore-not-found
```

Confirm no fault injection is left anywhere in the mesh:

```sh
kubectl get meshfaultinjections -A
```
