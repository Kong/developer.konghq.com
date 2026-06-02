---
name: dcgw-terraform-how-to
description: >
  Write or revise Terraform-based Dedicated Cloud Gateways (DCGW) how-to guides for
  developer.konghq.com. Use this skill any time someone asks to draft, write, create,
  update, or revise a Dedicated Cloud Gateways how-to that provisions resources with
  Terraform, including Azure VNet peering, Azure Virtual WAN, AWS VPC peering or Transit
  Gateway, GCP VPC peering, managed cache, custom domains, private DNS, or any new DCGW
  Terraform integration. Always use this skill before writing any DCGW Terraform how-to
  content, even if the request seems straightforward. Also use it when an engineer or PM
  shares raw HCL, a Konnect API request, or cloud provider configs and asks for help
  turning them into a DCGW Terraform how-to.
---

Read `references/dcgw-terraform-patterns.md` before doing anything else. It contains the frontmatter schema, the canonical Terraform workflow pattern, the verified cloud-gateway Terraform resource map, attachment kinds, shared includes, and summaries of the existing DCGW how-tos. You need this context to draft correctly.

## Overview

This skill produces how-to guide files (`.md`) under `app/_how-tos/dedicated-cloud-gateways/` that provision Dedicated Cloud Gateways resources using Terraform and follow the conventions on `developer.konghq.com`. It works for new how-tos and revisions.

Two things make this skill necessary. First, no existing DCGW how-to uses Terraform yet, they all use `{% konnect_api_request %}` blocks, cloud provider CLIs, and UI steps. So you are combining the DCGW how-to structure with the repo's established Terraform how-to pattern. Second, the Konnect cloud-gateway Terraform resources have specific argument names and the transit gateway attachment config differs per cloud provider.

The most important rule: **do not invent Terraform resource argument names, attachment `kind` values, provider account regions, `availability_zones`, or `cidr_block` values**. A guessed field name produces HCL that won't `terraform apply`. Env var placeholders like `$KONNECT_NETWORK_ID` or `$CONTROL_PLANE_ID` are fine when that value is exported or captured in an earlier step of the same how-to. When you are unsure what a resource argument is called, consult the cloud-gateways OpenAPI spec at `api-specs/konnect/cloud-gateways/v2/openapi.yaml` and the Konnect Terraform provider registry (`registry.terraform.io/providers/Kong/konnect/latest/docs`) rather than guessing. `references/dcgw-terraform-patterns.md` lists the verified resource names and the Azure attachment fields.

---

## Step 1: Determine mode

Ask the user: are they writing a new how-to, or revising an existing one?

- **New**: run the full interview below before drafting anything.
- **Revision**: ask what needs to change. If the change touches any HCL value (a resource argument, an attachment field, a region, a CIDR block, a request body), require the exact value before making the edit. The same no-guessing rule applies. Read the existing file first.

---

## Step 2: Identify the provider and feature

Determine which cloud provider and which DCGW feature the how-to covers. This selects the prereq includes, the transit gateway attachment `kind`, the tags, and the validation approach:

- **Azure**: VNet peering, Virtual WAN (vHub), private DNS, outbound DNS resolver
- **AWS**: VPC peering, Transit Gateway, resource endpoints, managed cache
- **GCP**: VPC peering, private DNS
- **Cross-cloud**: managed cache, custom domains, private hosted zones

If it's a combination not covered by an existing how-to, treat it as new and lean on the OpenAPI spec for the exact resource and attachment fields. See `references/dcgw-terraform-patterns.md` for the resource map and the per-provider attachment kinds.

---

## Step 3: Interview (do not skip, do not draft until complete)

Work through these in order. Wait for answers before moving on. Skip anything a previous answer rules out.

### 3a. Prerequisites vs. provisioned resources

The Konnect cloud gateway **network** and the cloud-enabled **control plane** are usually prerequisites the reader already has, not steps the guide creates. By default, treat them as prereqs: reference an existing `Ready` network and a `konnect_gateway_control_plane` (with `cloud_gateway = true`) through prereq includes and exported env vars like `$KONNECT_NETWORK_ID` and `$CONTROL_PLANE_ID`.

Ask the user explicitly: does this how-to provision the network and control plane with Terraform, or assume they already exist? Only collect their Terraform config when the guide actually creates them:
- `konnect_cloud_gateway_network`: exact `region`, `availability_zones`, `cidr_block`, and how the provider account is looked up (`konnect_cloud_gateway_provider_account_list` data source).
- `konnect_gateway_control_plane`: exact `name`, with `cloud_gateway = true`.

### 3b. The feature the how-to provisions

Collect the exact config for whatever the guide is actually about. Never guess field names, get them from the user or the OpenAPI spec:

- **Transit gateway / peering** (`konnect_cloud_gateway_transit_gateway`): the `name`, the `cidr_blocks`, and the attachment config, which is provider-specific. Get the attachment `kind` and its fields:
  - Azure VNet: `kind = "azure-vnet-peering-attachment"`, plus `tenant_id`, `subscription_id`, `resource_group_name`, `vnet_name`
  - Azure Virtual WAN: `kind = "azure-vhub-peering-attachment"`, plus `tenant_id`, `subscription_id`, `resource_group_name`, `vhub_name`
  - AWS VPC: `kind = "aws-vpc-peering-attachment"`, plus the peer account / VPC / region fields
  - GCP VPC: `kind = "gcp-vpc-peering-attachment"`, plus `peer_project_id`, `peer_vpc_name`
- **Add-ons** like managed cache (`konnect_cloud_gateway_addon`): the exact `config` block and the owner control plane reference.
- **Private DNS** (`konnect_cloud_gateway_private_dns`) or **custom domains** (`konnect_cloud_gateway_custom_domain`): the exact arguments.

### 3c. Cloud provider side steps

Most DCGW guides require steps on the cloud provider side that Terraform doesn't do. Ask for the exact CLI commands or UI steps:
- **Azure**: creating the peering role and assigning it to the Kong service principal (Azure CLI), accepting/configuring the peering
- **AWS**: accepting the peering request and updating the route table
- **GCP**: creating the matching VPC peering resource (gcloud)

These are often already captured in shared includes. Check `references/dcgw-terraform-patterns.md` before writing them inline.

### 3d. Validation

Ask how the reader confirms it worked, or infer it from the feature. The default for Terraform how-tos is to extract an ID from the Terraform state and confirm the resource exists via the Konnect API. See the validation pattern in `references/dcgw-terraform-patterns.md`.

### 3e. Pre-draft confirmation

Before drafting, summarize what you collected and flag anything missing:

```
Here's what I have:
- ✅ Provider + feature: [e.g. Azure VNet peering]
- ✅ Network + control plane: [prereqs / provisioned with these values]
- ✅ Feature config: [resource(s) + attachment kind + key fields]
- ✅ Cloud provider side steps: [include name / inline CLI / UI steps]
- ✅ Validation: [terraform show + konnect_api_request / UI Ready check]
- ⚠️ Still missing: [anything you don't have]
```

Only proceed to drafting when the user confirms everything is present.

---

## Step 4: Draft the how-to

### Structure

Follow this order (see `references/dcgw-terraform-patterns.md` for the full frontmatter template and HCL examples):

```
[frontmatter]  (tools: [terraform], works_on: [konnect], DCGW permalink + breadcrumbs, tags)

[prereqs block]
  - Terraform / Konnect provider: include prereqs/products/konnect-terraform
  - Provider CLI + account: e.g. prereqs/azure-cli, prereqs/entra-tenant (Azure)
  - An existing Ready DCGW network + cloud-enabled control plane (unless the guide provisions them)
  - The cloud provider resource the reader brings (VNet, VPC), with exported env vars

[body]
  - Configure the provider (auth.tf)
  - Define the resource(s) for the feature (main.tf)
  - terraform init
  - terraform apply -auto-approve
  - Cloud provider side steps (Azure role assignment, AWS accept peering, etc.)
  - Validate
```

### Terraform workflow convention

Follow the repo's established pattern (see `app/_how-tos/gateway/terraform-gateway-authentication.md`):
- Build the config with `echo '...' > auth.tf` for the provider block and `echo '...' >> main.tf` for resources, each in an ```hcl fenced block.
- Provider auth uses the `KONNECT_TOKEN` env var automatically; note that `server_url` changes by region.
- `terraform init`, then `terraform apply -auto-approve`. Show the expected `Apply complete!` output in a ```text block with `{:.no-copy-code}` under it.

### Validation section

Default Terraform validation: extract the resource ID from state and confirm it via the Konnect API.

```bash
TRANSIT_GATEWAY_ID=$(terraform show -json | jq -r '.values.root_module.resources[] | select(.address == "konnect_cloud_gateway_transit_gateway.my_tgw") | .values.id')
```

Then a `{% konnect_api_request %}` GET against the cloud-gateways endpoint expecting `200`, or, where the result is only visible in the UI, a "scroll until you see `Ready`" check like the existing DCGW how-tos. Wrap API blocks in `<!--vale off-->` / `<!--vale on-->`.

### Style rules to enforce (don't explain to the user, just apply them)

- Sentence case for all headings (capitalize only the first word and proper nouns)
- Export env vars for any value referenced in a later step
- Active voice
- No em dashes, use a comma, parentheses, or a period instead
- `{:.no-copy-code}` directly under any expected-output code block
- No screenshots of third-party (Azure, AWS, GCP) UIs
- Link text should describe the destination, not say "click here"
- Wrap blocks that contain resource field names or values that Vale will flag in `<!--vale off-->` / `<!--vale on-->`

---

## For revisions

When revising an existing how-to:

1. Read the existing file before suggesting any changes.
2. Ask what specifically needs to change.
3. If the change involves an HCL value (resource argument, attachment field, region, CIDR, request body), require the exact value before editing.
4. If the change is structural (adding a section, reordering steps, updating prose), you can proceed without additional configs, but still follow the style rules above.
5. Preserve any `include` calls and shared block patterns that already exist in the file.
