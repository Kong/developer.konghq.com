This is a Konnect tutorial and requires a Konnect personal access token.

1. Create a new personal access token by opening the [Konnect PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**.

1. Export your token to an environment variable:

    ```bash
    export KONNECT_TOKEN='YOUR_KONNECT_PAT'
    ```

1. Create an `auth.tf` file that configures the `kong/konnect` Terraform provider. Change `server_url` if you are using a region other than `us`:
{% capture the_code %}
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
{% endcapture %}
{{ the_code | indent: 3 }}

1. Next, initialize your project and download the provider:
   ```bash
   terraform init
   ```

The provider automatically uses the `KONNECT_TOKEN` environment variable if it is available. If you would like to use a custom authentication token, set the `personal_access_token` field alongside `server_url` in the `provider` block.

