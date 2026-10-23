Turn off restricted outbound first.
When restricted outbound is off, removing the declarations reopens the call paths.
When it's on, removing them closes the call paths:

```sh
helm upgrade kong-mesh kong-mesh/kong-mesh \
  --namespace kong-mesh-system --reuse-values \
  --set kuma.controlPlane.envVars.KUMA_DEFAULTS_RESTRICT_OUTBOUND="false"
```

Wait for the control plane to be ready:

```sh
kubectl wait -n kong-mesh-system --for=condition=ready pod \
  --selector=app=kong-mesh-control-plane --timeout=90s
```

The control plane is now back in the state that the rest of the collection expects.

Remove the `kuma.io/reachable-backends` annotation from the three Kong Air deployments.
If you leave the declarations in place, each proxy stays limited to the destinations listed here, and the call paths that later guides depend on stay closed:

```sh
kubectl patch deployment passenger-portal check-in-api flight-control -n kong-air-production \
  --type json -p '[{"op": "remove", "path": "/spec/template/metadata/annotations/kuma.io~1reachable-backends"}]'
```

Wait for the pods to roll out:

```sh
kubectl rollout status deployment -n kong-air-production --timeout=120s
```

Confirm that no declaration remains:

```sh
kubectl get pods -n kong-air-production \
  -o jsonpath='{range .items[*]}{.metadata.labels.app}{"\t"}{.metadata.annotations.kuma\.io/reachable-backends}{"\n"}{end}'
```

The output lists each workload with an empty value:

```text
check-in-api
flight-control
passenger-portal
```
{:.no-copy-code}

On a running mesh, declare the destinations each workload needs instead of removing the annotation.
Remove the annotation only when you tear down the whole scenario.
