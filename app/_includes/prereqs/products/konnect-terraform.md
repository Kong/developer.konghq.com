This is a Konnect tutorial and requires a Konnect personal access token.

1. Create a new personal access token by opening the [Konnect PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**.

1. Export your token to an environment variable:

    ```bash
    export KONNECT_TOKEN='YOUR_KONNECT_PAT'
    ```

Create an `auth.tf` file that configures the `kong/konnect` Terraform provider. Change `server_url` if you are using a region other than `us`:

```hcl
echo '
terraform {
  required_providers {
    konnect = {
      source  = "kong/konnect"
    }
    konnect-beta = {
      source  = "kong/konnect-beta"
    }
  }
}

provider "konnect" {
  server_url = "https://us.api.konghq.com"
}

provider "konnect-beta" {
  server_url            = "https://us.api.konghq.com"
}

' > auth.tf
```

Next, initialize your project and download the provider:

```bash
terraform init
```

The provider automatically uses the `KONNECT_TOKEN` environment variable if it is available. If you would like to use a custom authentication token, set the `personal_access_token` field alongside `server_url` in the `provider` block.

Before configuring a Service and a Route, you need to create a Control Plane. If you have an existing Control Plane that you'd like to reuse, you can use the [`konnect_gateway_control_plane_list`](https://github.com/Kong/terraform-provider-konnect/blob/main/examples/data/gateway_control_plane_list.tf) data source.

```hcl
echo '
resource "konnect_gateway_control_plane" "my_cp" {
  name         = "Terraform Control Plane"
  description  = "Configured using the demo at developer.konghq.com"
  cluster_type = "CLUSTER_TYPE_CONTROL_PLANE"
}
' > main.tf
```

