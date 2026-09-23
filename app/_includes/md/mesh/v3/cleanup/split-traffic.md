Delete the route, the permission, and the second version of `passenger-portal`:

```sh
kubectl delete meshhttproute booking-traffic-split -n kong-air-production --ignore-not-found
kubectl delete meshtrafficpermission allow-check-in-to-passenger-portal -n {{site.mesh_namespace}} --ignore-not-found
kubectl delete deployment passenger-portal-v2 -n kong-air-production --ignore-not-found
kubectl delete service passenger-portal-v1 passenger-portal-v2 -n kong-air-production --ignore-not-found
```

The original `passenger-portal` deployment and service stay in place, so the rest of the collection still works.
