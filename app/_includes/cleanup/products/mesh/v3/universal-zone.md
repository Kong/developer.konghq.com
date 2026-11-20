Stop the control plane this guide started:

```sh
kill "$(cat "$MESH_INSTALL_DIR/kuma-cp.pid")"
```

Leave the zone working directory and delete it:

```sh
cd "$(dirname "$MESH_INSTALL_DIR")"
rm -rf "$MESH_INSTALL_DIR"
```
