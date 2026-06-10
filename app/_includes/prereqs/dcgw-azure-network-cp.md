This is a {{site.konnect_short_name}} tutorial that requires Dedicated Cloud Gateways access.

If you don't have a {{site.konnect_short_name}} account, you can get started quickly with our [onboarding wizard](https://konghq.com/products/kong-konnect/register?utm_medium=referral&utm_source=docs).

You need a Dedicated Cloud Gateway Azure network and control plane to complete this tutorial. If you don't already have them, you can configure them with Terraform.

In {{site.konnect_short_name}}, you need to retrieve the provider account ID.

First, make a GET request to the {{site.konnect_short_name}} Cloud Gateways API using the `/provider-accounts` endpoint:

<!--vale off-->
{% konnect_api_request %}
url: /v2/cloud-gateways/provider-accounts?filter%5Bprovider%5D%5Beq%5D=azure
status_code: 201
region: global
method: GET
headers:
  - 'Accept: application/json'
  - 'Content-Type: application/json'
{% endkonnect_api_request %}
<!--vale on-->

Save the `id` from the output to use in your Terraform resource.

The supported region, availability zones, and CIDR blocks depend on your provider account. List the values that Azure supports from the availability endpoint:

```sh
curl -s -H "Authorization: Bearer $KONNECT_TOKEN" \
  https://global.api.konghq.com/v2/cloud-gateways/availability.json | \
  jq '.providers[] | select(.provider == "azure") | .regions[] | {region, availability_zones, cidr_blocks}'
```

Use a supported `region`, its `availability_zones`, and a CIDR subnet inside one of the supported `cidr_blocks` in the following configuration:

```hcl
echo '
data "konnect_cloud_gateway_provider_account_list" "my_cloudgatewayprovideraccountlist" {
}

resource "konnect_cloud_gateway_network" "my_cloudgatewaynetwork" {
  name   = "Terraform Network"
  region = "eastus2"
  availability_zones = [
    "eastus2-az2",
    "eastus2-az3"
  ]

  cidr_block      = "10.99.98.0/23"

  cloud_gateway_provider_account_id = "d53d2872-514f-4fb9-819e-43bd792b4759"
}

resource "konnect_gateway_control_plane" "my_cp" {
  name          = "Azure CGW Control Plane"
  cloud_gateway = true
}
' >> main.tf
```

Create the Azure network resource using Terraform:
```sh
terraform apply -auto-approve
```

{:.warning}
> **Important:** It can take 30-40 minutes for your network to initialize. You **must** wait for your network to display as `Ready` before you can configure private networking.