Delete the fault injection policies.
A policy that you leave in place keeps injecting failures into traffic that later guides depend on:

```sh
kubectl delete meshfaultinjection test-check-in-api-abort test-check-in-api-latency test-check-in-api-throttle -n kong-air-production --ignore-not-found
kubectl delete meshfaultinjection zone-egress-fault-injection -n {{site.mesh_namespace}} --ignore-not-found
```

Confirm that no `MeshFaultInjection` policy remains in the cluster:

```sh
kubectl get meshfaultinjections -A
```

Expected output:

```text
No resources found
```
{:.no-copy-code}

Delete the test file that the response rate limit check created in the `check-in-api` container:

```sh
kubectl exec -n kong-air-production deploy/check-in-api -c check-in-api -- rm -f /tmp/manifest.bin
```
