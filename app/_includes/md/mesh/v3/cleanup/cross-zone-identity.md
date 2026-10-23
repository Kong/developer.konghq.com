Run these commands if you applied the identity and the trust copies to a second zone.
They remove the peer trust from each zone first, then the second zone's identity:

```sh
kubectl --context zone1 delete meshtrust kong-air-mesh-trust-of-zone2 -n {{site.mesh_namespace}} --ignore-not-found
kubectl --context zone2 delete meshtrust kong-air-mesh-trust-of-zone1 -n {{site.mesh_namespace}} --ignore-not-found
kubectl --context zone2 delete meshidentity kong-air-identity -n {{site.mesh_namespace}} --ignore-not-found
kubectl --context zone2 delete meshtrust kong-air-identity -n {{site.mesh_namespace}} --ignore-not-found
```

Deleting a `MeshIdentity` doesn't remove the `MeshTrust` that the identity generated, so the last command deletes that `MeshTrust` separately.
Until you delete it, proxies in `zone2` still accept certificates from its CA.
