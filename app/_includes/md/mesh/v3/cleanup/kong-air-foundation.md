{:.warning}
> Run this only when you're finished with the whole scenario collection. The other guides in this series build on the same `kong-air-mesh` and Kong Air demo applications, so tearing them down means running the prerequisites again.

1. Delete the base policies and the demo applications:

   ```sh
   kubectl delete meshtrafficpermission allow-flight-control-to-check-in -n {{site.mesh_namespace}} --ignore-not-found
   kubectl delete meshtls strict-mtls -n {{site.mesh_namespace}} --ignore-not-found
   kubectl delete meshidentity kong-air-identity -n {{site.mesh_namespace}} --ignore-not-found
   kubectl delete namespace kong-air-production --ignore-not-found
   ```

   Deleting the namespace removes the three deployments, their services, their service accounts, and the nginx `ConfigMap`.

1. Delete the mesh. Where you run this depends on where your global control plane lives.

   On a {{site.konnect_short_name}}-hosted global control plane, a zone can't delete a global resource, so use kongctl:

   ```sh
   kongctl delete mesh meshes kong-air-mesh --control-plane-name "$MESH_CP"
   ```

   On a self-managed global control plane, point kongctl at its API instead:

   ```sh
   kongctl delete mesh meshes kong-air-mesh --control-plane-url http://localhost:5681
   ```

   On a standalone control plane, where there is no global and zone split, `kubectl delete mesh kong-air-mesh` works.

1. If you installed {{site.mesh_product_name}} only to follow this collection, remove the control plane too. Skip this if the cluster runs other meshes:

   ```sh
   helm uninstall kong-mesh -n {{site.mesh_namespace}}
   kubectl delete namespace {{site.mesh_namespace}}
   ```
