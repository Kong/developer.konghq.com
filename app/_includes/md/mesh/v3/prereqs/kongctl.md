{{site.konnect_short_name}} hosts your global control plane, so you can't reach it with `kubectl`.
You create global resources, including the `Mesh`, with [kongctl](/kongctl/).
kongctl supports {{site.mesh_product_name}} 3.0 and later.

1. Authenticate to {{site.konnect_short_name}} using the browser-based device flow:

   ```sh
   kongctl login
   ```

   kongctl prints a URL. Open the URL, authorize the CLI, and return to your terminal. See [Authentication with kongctl](/kongctl/authentication/).

1. List the {{site.mesh_product_name}} control planes your account can reach:

   ```sh
   kongctl get mesh control-planes
   ```

   Each row shows a name, an identifier, and the {{site.konnect_short_name}} API line that serves the control plane. Only control planes on the `v3` line run {{site.mesh_product_name}} 3.

1. Export the name of the control plane you want to use, so that later commands can reference it:

   ```sh
   export MESH_CP='YOUR CONTROL PLANE NAME'
   ```

   Every `kongctl` mesh command in this guide passes `--control-plane-name "$MESH_CP"`.
