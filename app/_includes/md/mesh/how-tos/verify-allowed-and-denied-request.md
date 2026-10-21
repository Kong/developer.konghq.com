Check that both workloads have ready mesh sidecars:

```sh
kubectl -n kong-mesh-demo get pods
```

Check that `server` has a generated `MeshService`:

```sh
kongctl get mesh meshservices --mesh konnect-demo \
  --control-plane-id "$CONTROL_PLANE_ID" --region "$KONNECT_REGION"
```

Confirm the workload identities in the proxy inspection output:

```sh
kongctl get mesh inspect dataplanes --mesh konnect-demo \
  --control-plane-id "$CONTROL_PLANE_ID" --region "$KONNECT_REGION"
```

Send a request from the client to the server:

```sh
kubectl -n kong-mesh-demo exec deployment/client -c client -- \
  curl --fail --max-time 10 http://server.kong-mesh-demo.svc.cluster.local/
```

Expect the nginx welcome page. The request originates in the meshed client, so it exercises
the client-to-server mesh connection rather than a port-forward that bypasses it.

For a negative check, change only the client's ServiceAccount to `default`:

```sh
kubectl -n kong-mesh-demo patch deployment client --type=merge \
  -p '{"spec":{"template":{"spec":{"serviceAccountName":"default"}}}}'
```

Wait for the replacement Pod:

```sh
kubectl -n kong-mesh-demo rollout status deployment/client --timeout=180s
```

Repeat the same request:

```sh
kubectl -n kong-mesh-demo exec deployment/client -c client -- \
  curl --fail --max-time 10 http://server.kong-mesh-demo.svc.cluster.local/
```

This caller's identity ends in `/sa/default`, which the permission does not allow. The request
must fail. Check the new caller identity and destination authorization diagnostics so an
unrelated connection failure is not mistaken for a successful permission test.

Restore the allowed identity:

```sh
kubectl -n kong-mesh-demo patch deployment client --type=merge \
  -p '{"spec":{"template":{"spec":{"serviceAccountName":"client"}}}}'
```

Wait for the replacement Pod:

```sh
kubectl -n kong-mesh-demo rollout status deployment/client --timeout=180s
```

Confirm the request succeeds again:

```sh
kubectl -n kong-mesh-demo exec deployment/client -c client -- \
  curl --fail --max-time 10 http://server.kong-mesh-demo.svc.cluster.local/
```

Use the [MeshTrafficPermission reference](/mesh/policies/meshtrafficpermission/) if the observed
result differs. Before adding cross-zone or external-service traffic, configure the appropriate
[mesh-scoped zone proxies](/mesh/mesh-scoped-zone-proxies/).
