Turn restricted outbound back off first, so that removing the declarations reopens the call paths rather than closing them permanently:

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

This returns the control plane to the state the rest of the collection expects.

Then remove the `kuma.io/reachable-backends` annotation from the three Kong Air deployments. Leaving the declarations in place keeps each proxy bounded to the destinations listed here, which closes the call paths the later guides depend on:

```sh
kubectl patch deployment passenger-portal check-in-api flight-control -n kong-air-production \
  --type json -p '[{"op": "remove", "path": "/spec/template/metadata/annotations/kuma.io~1reachable-backends"}]'
```

Wait for the pods to roll out:

```sh
kubectl rollout status deployment -n kong-air-production --timeout=120s
```

Confirm no declaration is left:

```sh
kubectl get pods -n kong-air-production \
  -o jsonpath='{range .items[*]}{.metadata.labels.app}{"\t"}{.metadata.annotations.kuma\.io/reachable-backends}{"\n"}{end}'
```

Each workload is listed with an empty value:

```text
check-in-api
flight-control
passenger-portal
```
{:.no-copy-code}

Order matters here. On a control plane where `defaults.restrictOutbound` is still enabled, removing the annotation does not reopen those paths, because a proxy that declares nothing reaches nothing. On a running mesh, declare the destinations each workload needs rather than removing the annotation, unless you are tearing the whole scenario down.
