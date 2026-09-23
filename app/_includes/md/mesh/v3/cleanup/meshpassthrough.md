Delete the passthrough policies:

```sh
kubectl delete meshpassthrough allow-all-passthrough secure-perimeter selective-passthrough -n kong-air-production --ignore-not-found
```

With no `MeshPassthrough` policy in place, the mesh falls back to its default passthrough behavior, so calls to unknown external hosts behave as they did before you started.
