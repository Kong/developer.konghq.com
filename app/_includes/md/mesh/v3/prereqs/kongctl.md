Your global control plane is hosted in {{site.konnect_short_name}}, so you can't reach it with `kubectl`. Global resources, including the `Mesh` itself, are created with [kongctl](/kongctl/), which requires {{site.mesh_product_name}} 3.0 or later.

1. Install kongctl. On macOS:

   ```sh
   brew install --formula kong/kongctl/kongctl
   ```

   For Linux, Windows, Docker, and mise, see the install instructions on the [kongctl](/kongctl/) page.

1. Authenticate to {{site.konnect_short_name}} using the browser-based device flow:

   ```sh
   kongctl login
   ```

   kongctl prints a URL. Open it, authorize the CLI, and return to your terminal.

   If you're running in CI or another non-interactive environment, use a [personal access token](https://cloud.konghq.com/global/account/tokens) instead:

   ```sh
   export KONGCTL_DEFAULT_KONNECT_PAT='YOUR KONNECT PAT'
   ```

   For both options, see [Authentication with kongctl](/kongctl/authentication/).

1. List the {{site.mesh_product_name}} control planes your account can reach:

   ```sh
   kongctl get mesh control-planes
   ```

   Each row reports a name, an identifier, and the {{site.konnect_short_name}} API line the control plane is reached on. Only control planes on the `v3` line run {{site.mesh_product_name}} 3.

1. Export the name of the control plane you want to use, so the rest of this guide can address it:

   ```sh
   export MESH_CP='YOUR CONTROL PLANE NAME'
   ```

   Every `kongctl` mesh command in this guide passes `--control-plane-name "$MESH_CP"`. You can pass `--control-plane-id` instead if two control planes share a name.

   For a self-managed control plane, skip the {{site.konnect_short_name}} steps and pass `--control-plane-url` with its API address instead, adding `--control-plane-token` if the API requires authentication.
