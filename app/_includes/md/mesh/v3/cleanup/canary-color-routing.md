Run these commands against every zone you deployed the color rings into. The examples use `--context zone1`, so substitute your own kube-context names.

1. Delete the routing policies and the global services:

   ```sh
   kubectl --context zone1 delete meshhttproute color-pin-blu color-pin-grn -n {{site.mesh_namespace}} --ignore-not-found
   kubectl --context zone1 delete meshhttproute check-in-global-canary -n kong-air-production --ignore-not-found
   kubectl --context zone1 delete meshloadbalancingstrategy check-in-locality -n kong-air-production --ignore-not-found
   kubectl --context zone1 delete meshmultizoneservice flight-control-all flight-control-blu flight-control-grn -n {{site.mesh_namespace}} --ignore-not-found
   kubectl --context zone1 delete meshmultizoneservice check-in-api-global check-in-api-canary-global -n {{site.mesh_namespace}} --ignore-not-found
   ```

   Delete the `MeshMultiZoneService` resources last. They are what the routes resolve against, so removing them first leaves the routes pointing at nothing while they wait to be deleted.

1. Delete the color-ring workloads:

   ```sh
   kubectl --context zone1 delete deployment flight-control-blu flight-control-grn check-in-api-blu check-in-api-grn -n kong-air-production --ignore-not-found
   kubectl --context zone1 delete service flight-control-blu flight-control-grn flight-control-all -n kong-air-production --ignore-not-found
   kubectl --context zone1 delete configmap flight-control-blu-config flight-control-grn-config -n kong-air-production --ignore-not-found
   ```

   The `check-in-api` and `flight-control` service accounts stay, because the base Kong Air workloads use them.
