1. Check that both workloads have ready mesh sidecars:

   ```sh
   kubectl -n kong-mesh-demo get pods
   ```

1. Check that `server` has a generated `MeshService`:

   ```sh
   kongctl get mesh meshservices --mesh konnect-demo \
     --control-plane-id "$CONTROL_PLANE_ID" --region "$KONNECT_REGION" \
     --pat "$KONNECT_TOKEN"
   ```

1. Confirm the workload identities in the proxy inspection output:

   ```sh
   kongctl get mesh inspect dataplanes --mesh konnect-demo \
     --control-plane-id "$CONTROL_PLANE_ID" --region "$KONNECT_REGION" \
     --pat "$KONNECT_TOKEN"
   ```

1. Send a request from the client to the server:

   ```sh
   kubectl -n kong-mesh-demo exec deployment/client -c client -- \
     curl --fail --max-time 10 http://server.kong-mesh-demo.svc.cluster.local/
   ```

   You should get the nginx welcome page.

1. For a negative check, change the client's ServiceAccount to `default` and wait for the replacement Pod:

   ```sh
   kubectl -n kong-mesh-demo patch deployment client --type=merge \
     -p '{"spec":{"template":{"spec":{"serviceAccountName":"default"}}}}'
   kubectl -n kong-mesh-demo rollout status deployment/client --timeout=180s
   ```

1. Repeat the same request:

   ```sh
   kubectl -n kong-mesh-demo exec deployment/client -c client -- \
     curl --fail --max-time 10 http://server.kong-mesh-demo.svc.cluster.local/
   ```

   The request fails, because the permission doesn't allow the `/sa/default` identity.

1. Restore the allowed identity and wait for the replacement Pod:

   ```sh
   kubectl -n kong-mesh-demo patch deployment client --type=merge \
     -p '{"spec":{"template":{"spec":{"serviceAccountName":"client"}}}}'
   kubectl -n kong-mesh-demo rollout status deployment/client --timeout=180s
   ```

1. Confirm the request succeeds again:

   ```sh
   kubectl -n kong-mesh-demo exec deployment/client -c client -- \
     curl --fail --max-time 10 http://server.kong-mesh-demo.svc.cluster.local/
   ```

If the results differ, see the [MeshTrafficPermission reference](/mesh/policies/meshtrafficpermission/).
