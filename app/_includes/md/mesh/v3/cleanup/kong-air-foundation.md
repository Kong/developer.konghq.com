{:.warning}
> Run these steps only when you are finished with the whole scenario collection.
> The other guides in this series build on the same `kong-air-mesh` and Kong Air demo applications.
> If you delete them, you must run the prerequisites again.

1. Delete the base policies and the demo applications:

   ```sh
   kubectl delete meshtrafficpermission allow-flight-control-to-check-in -n {{site.mesh_namespace}} --ignore-not-found
   kubectl delete meshtls strict-mtls -n {{site.mesh_namespace}} --ignore-not-found
   kubectl delete meshidentity kong-air-identity -n {{site.mesh_namespace}} --ignore-not-found
   kubectl delete namespace kong-air-production --ignore-not-found
   ```

   Deleting the `kong-air-production` namespace removes the three deployments, their services, their service accounts, and the nginx `ConfigMap`.

1. Delete the mesh. The command depends on where your global control plane runs.

   A zone control plane can't delete a resource that the global control plane owns. On a {{site.konnect_short_name}}-hosted global control plane, delete the mesh with kongctl:

   ```sh
   kongctl delete mesh meshes kong-air-mesh --control-plane-name "$MESH_CP"
   ```

   On a self-managed global control plane, point kongctl at the global control plane API instead:

   ```sh
   kongctl delete mesh meshes kong-air-mesh --control-plane-url http://localhost:5681
   ```

   On a zone control plane that isn't connected to a global control plane, delete the mesh with `kubectl delete mesh kong-air-mesh`.

1. If you installed {{site.mesh_product_name}} only for this collection, remove the control plane too. Skip this step if the cluster runs other meshes:

   ```sh
   helm uninstall kong-mesh -n {{site.mesh_namespace}}
   kubectl delete namespace {{site.mesh_namespace}}
   ```
