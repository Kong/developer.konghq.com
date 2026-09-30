Delete the external service definitions and the policies attached to them:

```sh
kubectl delete meshretry aeropay-retry-policy -n {{site.mesh_namespace}} --ignore-not-found
kubectl delete meshtrafficpermission flight-db-access -n {{site.mesh_namespace}} --ignore-not-found
kubectl delete meshexternalservice flight-db aeropay-api -n {{site.mesh_namespace}} --ignore-not-found
```

If you widened `kong-air-identity` to cover the zone egress listeners while following this guide, reapply the version from [Get started with your first policy](/mesh/get-started-with-your-first-policy/) to put it back.
