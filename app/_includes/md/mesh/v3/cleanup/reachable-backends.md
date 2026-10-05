Remove the `kuma.io/reachable-backends` annotation from the three Kong Air deployments. Leaving the declarations in place keeps each proxy bounded to the destinations listed here, which closes the call paths the later guides depend on:

```sh
kubectl patch deployment passenger-portal check-in-api flight-control -n kong-air-production \
  --type json -p '[{"op": "remove", "path": "/spec/template/metadata/annotations/kuma.io~1reachable-backends"}]'
```

Wait for the pods to roll out, then confirm no declaration is left:

```sh
kubectl rollout status deployment -n kong-air-production --timeout=120s
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

On a control plane where `defaults.restrictOutbound` is enabled, removing the annotation does not reopen those paths: a proxy that declares nothing reaches nothing. Declare the destinations each workload needs instead of removing the annotation, unless you are tearing the whole scenario down.
