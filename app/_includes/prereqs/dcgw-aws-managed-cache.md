This tutorial requires an AWS managed cache attached to a ready public Dedicated Cloud Gateway control plane with a live data plane.

If you don't have one configured yet, create one with Terraform.

You need to retrieve the provider account ID. 
First, make a GET request to the {{site.konnect_short_name}} Cloud Gateways API using the `/provider-accounts` endpoint:

<!--vale off-->
{% konnect_api_request %}
url: /v2/cloud-gateways/provider-accounts?filter%5Bprovider%5D%5Beq%5D=aws
status_code: 200
region: global
method: GET
headers:
  - 'Accept: application/json'
  - 'Content-Type: application/json'
{% endkonnect_api_request %}
<!--vale on-->

Export the `id` from the output as a Terraform variable:

```bash
export TF_VAR_provider_id='YOUR_PROVIDER_ACCOUNT_ID'
```

{:.danger}
> Use the `id` from the output, **not** `provider_account_id`.

The supported region, availability zones, and CIDR blocks depend on your provider account. List the values that AWS supports from the availability endpoint:

```sh
curl -s -H "Authorization: Bearer $KONNECT_TOKEN" \
  https://global.api.konghq.com/v2/cloud-gateways/availability.json | \
  jq '.providers[] | select(.provider == "aws") | .regions[] | {region, availability_zones, cidr_blocks}'
```

Use a supported `region`, its `availability_zones`, and a CIDR subnet inside one of the supported `cidr_blocks` in the following configuration, which creates the public network, the control plane, a live data plane on that network, and the managed cache:

<!--vale off-->
```hcl
echo '
variable "provider_id" {
  type = string
}

resource "konnect_cloud_gateway_network" "my_cloudgatewaynetwork" {
  name   = "Terraform Network"
  region = "us-east-2"
  availability_zones = [
    "use2-az1",
    "use2-az2",
    "use2-az3"
  ]

  cidr_block      = "10.0.0.0/16"

  cloud_gateway_provider_account_id = var.provider_id
}

resource "konnect_gateway_control_plane" "test_cp" {
  name         = "CGW Control Plane"
  cloud_gateway = true
}

resource "konnect_cloud_gateway_configuration" "test_cp_configuration" {
  control_plane_id  = konnect_gateway_control_plane.test_cp.id
  control_plane_geo = "us"
  api_access        = "public"
  version           = "3.15"
  dataplane_groups = [
    {
      provider                  = "aws"
      region                    = "us-east-2"
      cloud_gateway_network_id  = konnect_cloud_gateway_network.my_cloudgatewaynetwork.id
      autoscale = {
        configuration_data_plane_group_autoscale_autopilot = {
          kind     = "autopilot"
          base_rps = 10
        }
      }
    }
  ]
}

resource "konnect_cloud_gateway_addon" "managed_cache" {
  name = "managed-cache"
  owner = {
    control_plane = {
      control_plane_id  = konnect_gateway_control_plane.test_cp.id
      control_plane_geo = "us"
    }
  }
  config = {
    managed_cache = {
      capacity_config = {
        tiered = {
          tier = "micro"
        }
      }
    }
  }
}

output "control_plane_id" {
  value = konnect_gateway_control_plane.test_cp.id
}
' >> main.tf
```
<!--vale on-->

Create the resources using Terraform:
```sh
terraform apply -auto-approve
```

{:.warning}
> **Important:** It can take 30-40 minutes for your network to initialize, and about 15 minutes after that for the managed cache to become ready. You **must** wait for both the network and the managed cache to show as `Ready` before continuing.

For sizing recommendations or a full walkthrough, see [Configure an AWS managed cache for a Dedicated Cloud Gateway control plane](/dedicated-cloud-gateways/aws-managed-cache-control-plane/) or [Configure an AWS managed cache for a Dedicated Cloud Gateway control plane group](/dedicated-cloud-gateways/aws-managed-cache-control-plane-group/).
