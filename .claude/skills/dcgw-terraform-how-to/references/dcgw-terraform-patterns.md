# DCGW Terraform how-to patterns

Reference for drafting Terraform-based Dedicated Cloud Gateways how-tos. Read this before drafting.

## Contents

1. [Frontmatter schema and template](#frontmatter-schema-and-template)
2. [Provider setup and prereqs](#provider-setup-and-prereqs)
3. [Cloud-gateway Terraform resource map](#cloud-gateway-terraform-resource-map)
4. [Transit gateway attachment kinds](#transit-gateway-attachment-kinds)
5. [The end-to-end Terraform workflow](#the-end-to-end-terraform-workflow)
6. [Liquid blocks](#liquid-blocks)
7. [Existing DCGW how-tos and shared includes](#existing-dcgw-how-tos-and-shared-includes)
8. [Style reminders](#style-reminders)

---

## Frontmatter schema and template

Frontmatter is validated against `app/_data/schemas/frontmatter/how_to.json` (which extends `base.json`). Required fields for a how-to: `tldr` (with `q` and `a`), `content_type`, `title`, `products`, `permalink`.

DCGW conventions:
- `permalink: /dedicated-cloud-gateways/<slug>/`
- `breadcrumbs: [/dedicated-cloud-gateways/]`
- `products` is `[gateway]` or `[konnect]` (existing DCGW how-tos use both; DCGW is a Gateway topology that only runs on Konnect, so `works_on: [konnect]` is always set)
- `tools: [terraform]` (valid enum value; this is what marks the guide as Terraform-driven)
- `automated_tests: false` (DCGW provisioning is slow and account-specific)

Recommended `tags` (all valid in `app/_data/schemas/frontmatter/tags.json`): `dedicated-cloud-gateways`, `terraform`, the provider (`aws`, `azure`, or `google-cloud`), and a feature tag like `network` or `networking`.

Canonical template (Azure VNet peering shown, adapt per provider/feature):

```yaml
---
title: Configure an Azure Dedicated Cloud Gateway with VNET peering using Terraform
description: 'Use Terraform to configure an Azure Dedicated Cloud Gateway with VNET peering.'
content_type: how_to
permalink: /dedicated-cloud-gateways/azure-vnet-peering-terraform/
breadcrumbs:
  - /dedicated-cloud-gateways/
products:
  - konnect
works_on:
  - konnect
tools:
  - terraform
tags:
  - dedicated-cloud-gateways
  - terraform
  - azure
  - network
automated_tests: false
tldr:
  q: How do I configure an Azure Dedicated Cloud Gateway with VNET peering using Terraform?
  a: |
    Define a `konnect_cloud_gateway_transit_gateway` resource with an `azure-vnet-peering-attachment`,
    apply it with Terraform, then create the peering role and assign it to the Kong service principal in Azure.
related_resources:
  - text: Dedicated Cloud Gateways
    url: /dedicated-cloud-gateways/
  - text: Configure an Azure Dedicated Cloud Gateway with VNET peering
    url: /dedicated-cloud-gateways/azure-peering/
prereqs:
  skip_product: true
  inline:
    - title: Terraform and the Konnect provider
      include_content: prereqs/products/konnect-terraform
      icon_url: /assets/icons/terraform.svg
    - title: Microsoft Azure CLI
      include_content: prereqs/azure-cli
      icon_url: /assets/icons/azure.svg
next_steps:
  - text: Dedicated Cloud Gateways production readiness checklist
    url: /dedicated-cloud-gateways/production-readiness/
---
```

Add `faqs:` only when there's a real, recurring error to document (the API-based Azure VNet guide includes one for the duplicate-role error via `{% include faqs/azure-vnet-same-tenant-multi-subscription.md %}`).

---

## Provider setup and prereqs

The provider block comes from `app/_includes/prereqs/products/konnect-terraform.md`. It sets up both providers and reads `KONNECT_TOKEN`:

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

The provider automatically uses the `KONNECT_TOKEN` env var. `server_url` changes by region (for example `https://eu.api.konghq.com`).

Relevant prereq includes:
- `prereqs/products/konnect-terraform` — Konnect PAT + provider block + `terraform init` (use this; don't re-explain provider auth inline)
- `prereqs/terraform` — minimal "install Terraform" line, when you only need the binary
- `prereqs/azure-cli`, `prereqs/entra-tenant` — Azure guides
- `prereqs/dedicated-cloud-gateways` — the standard DCGW prereq used by the API-based guides; useful when the reader needs an existing network

When the network and control plane are prerequisites (the common case), state that the reader needs an existing `Ready` DCGW network and a cloud-enabled control plane, and have them export `KONNECT_NETWORK_ID` / `CONTROL_PLANE_ID`.

---

## Cloud-gateway Terraform resource map

Verified resource and data source names in the `kong/konnect` provider (`registry.terraform.io/providers/Kong/konnect/latest/docs`). The OpenAPI spec at `api-specs/konnect/cloud-gateways/v2/openapi.yaml` is the source of truth for every argument and is the place to look when a field name is uncertain.

| Resource / data source | Purpose | OpenAPI operationId |
|---|---|---|
| `konnect_cloud_gateway_provider_account_list` (data) | Look up the provider account id | `list-provider-accounts` |
| `konnect_cloud_gateway_network` | Create a DCGW network | `create-network` |
| `konnect_cloud_gateway_transit_gateway` | Peering / transit attachment on a network | `create-transit-gateway` |
| `konnect_cloud_gateway_configuration` | Data-plane group configuration | `create-configuration` |
| `konnect_cloud_gateway_addon` | Add-ons such as managed cache | (add-ons) |
| `konnect_cloud_gateway_custom_domain` | Custom domain | `create-custom-domains` |
| `konnect_cloud_gateway_private_dns` | Private DNS | `create-private-dns` |
| `konnect_gateway_control_plane` (`cloud_gateway = true`) | Cloud-enabled control plane | — |

Verified canonical snippets already in the repo:

Network creation, from `app/dedicated-cloud-gateways/network-architecture.md`:

```hcl
data "konnect_cloud_gateway_provider_account_list" "my_cloudgatewayprovideraccountlist" {
}

resource "konnect_cloud_gateway_network" "my_cloudgatewaynetwork" {
  name   = "Terraform Network"
  region = "eu-west-1"
  availability_zones = [
    "euw1-az1",
    "euw1-az2",
    "euw1-az3"
  ]
  cidr_block      = "10.4.0.0/16"
  cloud_gateway_provider_account_id = data.konnect_cloud_gateway_provider_account_list.my_cloudgatewayprovideraccountlist.data[0].id
}
```

Managed cache add-on, from `app/dedicated-cloud-gateways/managed-cache.md`:

```hcl
resource "konnect_gateway_control_plane" "test_cp" {
  name         = "CGW Control Plane"
  cloud_gateway = true
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
```

The `konnect_cloud_gateway_transit_gateway` resource has a top-level `network_id` plus **one per-provider attribute block** that wraps `name`, `transit_gateway_attachment_config`, and an optional `dns_config`. The block keys are: `azure_transit_gateway` (VNet peering), `azure_vhub_peering_gateway`, `aws_vpc_peering_gateway`, `aws_transit_gateway`, `aws_resource_endpoint_gateway`, `gcp_vpc_peering_transit_gateway`. Azure VNet peering looks like:

```hcl
resource "konnect_cloud_gateway_transit_gateway" "my_vnet_peering" {
  network_id = konnect_cloud_gateway_network.my_cloudgatewaynetwork.id

  azure_transit_gateway = {
    name = "azure vnet peering"

    transit_gateway_attachment_config = {
      kind                = "azure-vnet-peering-attachment"
      tenant_id           = var.tenant_id
      subscription_id     = var.subscription_id
      resource_group_name = var.resource_group_name
      vnet_name           = var.vnet_name
    }
  }
}
```

The Azure blocks take no `cidr_blocks` (the AWS VPC peering / transit gateway variants do). The resource exposes a top-level computed `id`, so validation can extract `.values.id` from state.

> **Important:** the OpenAPI spec (`api-specs/konnect/cloud-gateways/v2/openapi.yaml`) is authoritative for **field names and values**, but it models transit gateways as a flat `oneOf`. The Terraform provider does **not** match that shape, it nests each provider's config under its own attribute block (`azure_transit_gateway`, etc.). Always confirm the HCL **structure** against the provider docs (`github.com/Kong/terraform-provider-konnect/tree/main/docs/resources`), not the OpenAPI alone. The same applies to data sources: e.g. `konnect_cloud_gateway_provider_account_list` takes no arguments (no `page_number`/`page_size`), even though the API endpoint paginates.

### Network + control plane prereq

The network and a cloud-enabled control plane are usually prereqs. When the guide provisions them with Terraform (for readers who don't have them yet), the pattern is a `konnect_cloud_gateway_network` plus a `konnect_gateway_control_plane` with `cloud_gateway = true`. The shared include `prereqs/dcgw-azure-network-cp` (`app/_includes/prereqs/dcgw-azure-network-cp.md`) does exactly this for Azure and is the include to reuse in Azure peering guides:

```hcl
resource "konnect_cloud_gateway_network" "my_cloudgatewaynetwork" {
  name               = "Terraform Network"
  region             = "eastus2"
  availability_zones = ["eastus2-az2", "eastus2-az3"]
  cidr_block         = "10.4.0.0/16"
  cloud_gateway_provider_account_id = data.konnect_cloud_gateway_provider_account_list.my_cloudgatewayprovideraccountlist.data[0].id
}

resource "konnect_gateway_control_plane" "my_cp" {
  name          = "Azure CGW Control Plane"
  cloud_gateway = true
}
```

The network takes 30-40 minutes to reach `Ready`. Downstream resources that reference `konnect_cloud_gateway_network.my_cloudgatewaynetwork.id` get an implicit dependency, so a single `terraform apply` provisions the network before the dependent resource.

The `region`, `availability_zones`, and `cidr_block` are **provider- and account-specific, don't hardcode or guess them**. A wrong combination returns `400 Invalid Parameters` ("cloud provider account, region, and availability zone targets are not supported"). The supported values come from the availability endpoint, so tell the reader to look them up and substitute:

```sh
curl -s -H "Authorization: Bearer $KONNECT_TOKEN" \
  https://global.api.konghq.com/v2/cloud-gateways/availability.json | \
  jq '.providers[] | select(.provider == "azure") | .regions[] | {region, availability_zones, cidr_blocks}'
```

`availability_zones` is a list and doesn't map cleanly to a `TF_VAR_` env var, so leave region/AZs/CIDR as literal values the reader substitutes (or use a `terraform.tfvars` file), rather than env-var variables.

---

## Transit gateway attachment kinds

The attachment `kind` and its fields are provider-specific. These are verified from `api-specs/konnect/cloud-gateways/v2/openapi.yaml`:

| Provider | `kind` | Fields |
|---|---|---|
| Azure VNet | `azure-vnet-peering-attachment` | `tenant_id`, `subscription_id`, `resource_group_name`, `vnet_name` |
| Azure Virtual WAN | `azure-vhub-peering-attachment` | `tenant_id`, `subscription_id`, `resource_group_name`, `vhub_name` |
| AWS VPC | `aws-vpc-peering-attachment` | peer account id, peer VPC id, peer VPC region (see spec) |
| GCP VPC | `gcp-vpc-peering-attachment` | `peer_project_id`, `peer_vpc_name` |

Private DNS / hosted zone attachment kinds also exist (`azure-private-hosted-zone-attachment`, `azure-outbound-resolver`, and AWS/GCP equivalents). Look them up in the spec when the guide covers DNS.

All four attachment fields for Azure VNet are required by the API. The values come from the reader's Azure environment, never guess them, have the reader export them as env vars (`AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, etc.).

---

## The end-to-end Terraform workflow

Mirror the structure of `app/_how-tos/gateway/terraform-gateway-authentication.md`. The repo convention is to build the config files with `echo` so each step is copy-pasteable:

1. **Configure the provider**: `echo '...' > auth.tf` (the provider block above), then `terraform init`.
2. **Define resources**: `echo '...' >> main.tf` for each resource, each in an ```hcl block. Reference upstream resources by attribute (for example `konnect_gateway_control_plane.test_cp.id`) rather than hardcoding IDs.
3. **Apply**: 

   ```bash
   terraform apply -auto-approve
   ```

   Show the expected output and mark it no-copy:

   ````
   ```text
   Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
   ```
   {:.no-copy-code}
   ````
4. **Cloud provider side steps**: the part Terraform can't do (Azure role + service principal assignment, AWS accept peering + route table, GCP peering resource). Reuse a shared include if one exists, otherwise write exact CLI/UI steps.
5. **Validate** (see below).

### Passing inputs

Don't interpolate shell env vars into the echoed HCL (`name = "'$FOO'"`), it's fragile and Terraform doesn't read shell vars anyway. Use the production-idiomatic approach:

- **External, reader-supplied values** (cloud account IDs, region, VNet/VPC names): `variable` blocks + `var.<name>`, supplied via `export TF_VAR_<name>=...`. Terraform reads `TF_VAR_*` automatically.

  ```hcl
  variable "tenant_id" {}
  variable "subscription_id" {}
  # ...
  azure_transit_gateway = {
    name = "azure vnet peering"
    transit_gateway_attachment_config = {
      kind            = "azure-vnet-peering-attachment"
      tenant_id       = var.tenant_id
      subscription_id = var.subscription_id
      # ...
    }
  }
  ```

  ```sh
  export TF_VAR_tenant_id='...'
  export TF_VAR_subscription_id='...'
  ```
- **Terraform-managed values**: reference the resource attribute (`network_id = konnect_cloud_gateway_network.my_cloudgatewaynetwork.id`), which also orders the apply correctly.
- Add a note for readers whose network was created outside the Terraform project: replace the resource reference with their own ID (or a variable).

### Validation

Default pattern: pull the resource id out of the Terraform state, then confirm via the Konnect API.

```bash
TRANSIT_GATEWAY_ID=$(terraform show -json | jq -r '.values.root_module.resources[] | select(.address == "konnect_cloud_gateway_transit_gateway.my_tgw") | .values.id')
```

```
<!--vale off-->
{% konnect_api_request %}
url: /v2/cloud-gateways/networks/$KONNECT_NETWORK_ID/transit-gateways/$TRANSIT_GATEWAY_ID
status_code: 200
method: GET
{% endkonnect_api_request %}
<!--vale on-->
```

When readiness is only visible in the UI (peering takes 30-40 minutes to reach `Ready`), use a UI check instead, like the existing guides:

```
1. In the {{site.konnect_short_name}} sidebar, click **API Gateway**.
1. Click your Azure Dedicated Cloud Gateway.
1. Click the **Networks** tab.
1. Scroll until you see `Ready` for VNET peering.
```

---

## Liquid blocks

- `{% konnect_api_request %}` — Konnect API calls. Keys: `url`, `method`, `status_code`, `region` (default `us`; use `global` for some cloud-gateways endpoints, check the existing guide you're modeling on), `headers` (Authorization is added automatically), `body`, `capture` (jq filters to save response values for later steps). Wrap in `<!--vale off-->` / `<!--vale on-->`.
- `{% navtabs "name" %}` / `{% navtab "Terraform" %}` ... `{% endnavtab %}` / `{% endnavtabs %}` — offer Terraform alongside an API or UI path. `app/dedicated-cloud-gateways/network-architecture.md` and `managed-cache.md` already use a "Terraform" navtab; match that style if the guide should show more than one method.
- `{% include_cached /sections/<file>.md %}` and `{% include /... %}` — pull in shared DCGW sections (see below).

---

## Existing DCGW how-tos and shared includes

All under `app/_how-tos/dedicated-cloud-gateways/`. None use Terraform yet, so use them for **structure, prose, and validation style**, not for the config method.

- `azure-vnet-peering.md` — closest structural model for an Azure Terraform guide. Uses `{% include_cached /sections/azure-peering.md %}` (diagram), `/sections/azure-dcgw-network-setup.md`, `/sections/azure-dcgw-vnet-peering-setup.md`, and a UI `Ready` validation.
- `azure-virtual-wan.md` (+ `-with-private-dns`, `-with-outbound-dns-resolver`) — vHub variants.
- `aws-vpc-peering.md` — API-driven AWS peering, shows the `konnect_api_request` POST body and AWS-side accept + route table steps.
- `gcp-vpc-peering.md` — uses `{% navtabs %}` to show API vs UI; good model for adding a Terraform tab.
- `aws-managed-cache-control-plane.md` / `-group.md`, `azure-managed-cache-*` — managed cache, built almost entirely from `/sections/managed-cache-*.md` includes.

Useful shared includes:
- `app/_includes/sections/azure-peering.md` — architecture diagram (mermaid)
- `app/_includes/sections/azure-dcgw-network-setup.md`, `azure-dcgw-vnet-peering-setup.md` — Azure UI setup steps (UI, not Terraform; reuse only the cloud-provider-side parts)
- `app/_includes/faqs/azure-vnet-same-tenant-multi-subscription.md` — the duplicate-role FAQ
- `app/_includes/prereqs/dcgw-azure-vnet.md`, `dcgw-azure-vwan.md` — Azure DCGW prereqs (UI-based)
- `app/_includes/prereqs/dcgw-azure-network-cp.md` — Terraform prereq that provisions the Azure network + cloud-enabled control plane (use this in Azure Terraform guides)

Before writing any Azure role-assignment or AWS accept-peering steps inline, check whether one of these includes already covers it.

---

## Style reminders

- Sentence case headings, capitalize only the first word and proper nouns. ("Configure the provider", not "Configure The Provider".)
- No em dashes. Use a comma, parentheses, or a period.
- Export every value that a later step reads, as an env var.
- `{:.no-copy-code}` under expected-output blocks (`terraform apply` output, API responses).
- No screenshots of Azure, AWS, or GCP UIs. Describe the steps with exact UI labels per `docs/ui-steps-standards.md` (one action per step, state location before action).
- Wrap HCL and API blocks that contain resource field names or values in `<!--vale off-->` / `<!--vale on-->`.
- Every how-to ends with a validation step, that's a hard repo convention.
- Reference Terraform resources by attribute (`<resource>.<name>.id`), don't hardcode IDs that Terraform creates.
