Delete the timeout policies this guide created:

```sh
kubectl delete meshtimeout regional-baseline -n {{site.mesh_namespace}} --ignore-not-found
kubectl delete meshtimeout flight-control-timeout -n kong-air-production --ignore-not-found
```
