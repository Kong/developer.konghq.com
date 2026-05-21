---
title: "Migrating from self-managed {{site.base_gateway}} to {{site.konnect_short_name}}"

description: "Learn how to migrate from self-managed {{site.base_gateway}} to {{site.konnect_short_name}}."

content_type: reference
layout: reference
breadcrumbs:
  - /konnect/
products:
  - konnect
works_on:
    - konnect

related_resources:
  - text: "About {{site.konnect_short_name}}"
    url: /konnect/
  - text: Hybrid mode
    url: /gateway/hybrid-mode/
  - text: Control plane and Data Plane communication
    url: /gateway/cp-dp-communication/
---

As a {{site.base_gateway}} user, you can directly migrate to {{site.konnect_short_name}}, as {{site.konnect_short_name}} uses {{site.base_gateway}} in its foundation.


## Why migrate to {{site.konnect_short_name}}?

As organizations grow and scale, they need more advanced capabilities while lowering
operational complexity. This includes features such as:
* Multi-tenancy
* Federated API management
* Advanced security integrations


At its core, migration to {{site.konnect_short_name}} is mostly a straightforward export and migration of proxy configuration. Depending on your environment, you may also need to move over:
* Convert RBAC roles and permissions into {{site.konnect_short_name}} teams
* [Certificates](/gateway/entities/certificate/)
* Custom plugins

## How do I migrate to {{site.konnect_short_name}}?

This guide provides key details for completing a successful migration from a self-managed {{site.base_gateway}} to
{{site.konnect_short_name}}. It focuses on migrating a [hybrid](/gateway/hybrid-mode/)
or [traditional](/gateway/traditional-mode/) {{site.base_gateway}} deployment to {{site.konnect_short_name}}.

<!--vale off-->
{% mermaid %}
flowchart TD
A{Which deployment
topology are you
starting with?}
B(Traditional)
C(Hybrid)
D({{site.kic_product_name}})
E(DB-less)

A-->B & C & D & E

B & C --> F["Migrate to Konnect
(use this guide)"]
E --> H["Migrate to hybrid mode
(reach out to support for help)"] --> F
D --> G[<a href="https://cloud.konghq.com/gateway-manager/create-gateway">Link your {{site.kic_product_name}} deployment to a
{{site.kic_product_name}}-based control plane</a>]
{% endmermaid %}
<!--vale on-->

> _**Figure 1**: For traditional and hybrid deployments, you can migrate directly to {{site.konnect_short_name}}. DB-less deployments must migrate to hybrid first. For {{site.kic_product_name}} deployments, migrate to a {{site.kic_product_name}}-based control plane._

## Role Based Access Controls (RBAC) migration

{{site.base_gateway}}'s RBAC system does not map directly to the IAM system provided by {{site.konnect_short_name}}.
When migrating from a self-managed {{site.base_gateway}} to {{site.konnect_short_name}},
we recommend using {{site.konnect_short_name}}'s IdP integrations.
You can take advantage of your existing IdP solution and {{site.konnect_short_name}}'s
team-based mappings instead of migrating your self-managed {{site.base_gateway}}
RBAC configuration directly.

The following are the general steps for setting up IAM in {{site.konnect_short_name}} for your migration:

1. [Sign up](https://konghq.com/products/kong-konnect/register?utm_medium=referral&utm_source=docs) for
  {{site.konnect_short_name}} (if necessary), and use the [Org Switcher](https://cloud.konghq.com/org-switcher?ref=account)
  to create or select the organization you are going to migrate your self-managed deployment to.
2. [Set up single sign-on (SSO) access to {{site.konnect_short_name}} using an existing IdP provider](/konnect-platform/sso/).
3. [Create teams](/konnect-platform/teams-and-roles/) in {{site.konnect_short_name}} or use
  [predefined teams](/konnect-platform/teams-and-roles/#predefined-teams) to create your desired organizational structure.
4. For any custom teams, assign the appropriate roles
  from the predefined list of available roles in {{site.konnect_short_name}}.
5. Use the {{site.konnect_short_name}} IdP Team Mappings feature to
  [map the {{site.konnect_short_name}} teams to your IdP provider groups](/konnect-platform/sso/#team-mapping-configuration).

## Migrating from self-managed Workspaces to {{site.konnect_short_name}}

{{site.base_gateway}} supports configuration isolation using
[Workspaces](/gateway/entities/workspace/).
{{site.konnect_short_name}} also supports Workspaces within a control plane, so you can
preserve your existing Workspace structure when migrating.

### Example Workspace migration

The following provides an example of migrating a multi-Workspace self-managed setup to
{{site.konnect_short_name}}. These steps illustrate the general approach rather than a complete
step-by-step guide. The examples use [decK](/deck/) and well-known CLI tools for
querying APIs and manipulating text output. See the [jq](https://jqlang.github.io/jq/) and [yq](https://github.com/mikefarah/yq)
tool pages for more information.

1. Query the [Admin API](/api/gateway/admin-ee/) of your self-managed installation to get
   a list of Workspaces using the [`/workspaces` endpoint](/api/gateway/admin-ee/#/operations/list-workspace).
   The response includes a `name` field for each Workspace.

   {:.info}
   > The `default` Workspace in your self-managed deployment maps to the `default` Workspace in your {{site.konnect_short_name}} control plane. Neither can be deleted.

1. Dump your self-managed configuration into per-Workspace files:

   ```sh
   deck gateway dump --all-workspaces
   ```

   This produces one YAML file per Workspace, each with a `_workspace:` header.

1. Set your decK environment variables:

   ```sh
   export DECK_KONNECT_TOKEN="kpat_..."
   export DECK_KONNECT_ADDR="https://us.api.konghq.com"
   ```

1. Sync each file to your {{site.konnect_short_name}} control plane. If a Workspace doesn't exist yet,
   decK creates it automatically:

   ```sh
   deck gateway sync default.yaml \
     --konnect-control-plane-name my-control-plane \
     --workspace default
   ```

   Repeat for each Workspace.

1. Log in to the [{{site.konnect_short_name}} UI](https://cloud.konghq.com/gateway-manager/) and validate that your Workspaces and entities migrated correctly.

## Multi-tenancy

{{site.base_gateway}} Workspaces provide a way to share runtime infrastructure across isolated configurations.
With {{site.konnect_short_name}}, this is achieved using
[control plane groups](/gateway/control-plane-groups/). control planes can be added to
and removed from control plane groups, and you can set them up to mirror your existing multi-tenant Workspace configuration.

With control plane groups set up, you can connect Data Plane instances to each group, creating
a shared Data Plane infrastructure among the constituent control planes.

## Plugin migration

{{site.konnect_short_name}} supports the majority of [plugins](/plugins/) available to {{site.base_gateway}}. Since {{site.konnect_short_name}} runs in hybrid mode, this limits support for plugins that require direct access
to a database. See the [plugins page](/plugins/?deployment-topology=konnect) for those that are supported on {{site.konnect_short_name}}.

{{site.konnect_short_name}} also provides [Dedicated Cloud Gateways](/dedicated-cloud-gateways/), which 
further [limit plugins](/konnect-platform/compatibility/#considerations-for-dedicated-cloud-gateways) that require specialized software agents running on the Data Plane hosts. 

To migrate plugins from a self-managed deployment to {{site.konnect_short_name}}, review 
[Konnect Compatibility page](/konnect-platform/compatibility/#plugin-compatibility) to check for supported and unsupported plugins.
Also review any plugin configuration values, as certain values are unsupported in {{site.konnect_short_name}} and may require additional
changes to your configuration.

## Custom plugins migration

{{site.konnect_short_name}} supports custom plugins with similar restrictions to pre-built plugins. Since {{site.konnect_short_name}} runs in a hybrid deployment mode, custom plugins can't access a database directly
and can't provide custom Admin API endpoints. See the {{site.konnect_short_name}} documentation for more details
on [custom plugin support](/gateway/entities/plugin/#custom-plugins) requirements.

Migrating custom plugins to {{site.konnect_short_name}} requires uploading and associating your custom plugin's `schema.lua` file to
the desired control plane. This can be done using the
{{site.konnect_short_name}} UI or the
[{{site.konnect_short_name}} control planes Config API](/api/konnect/control-planes-config/#/operations/list-plugin-schemas).

Just like in self-managed deployments, the custom plugin code must be distributed to the Data Plane instances.

{:.info}
> **Note**: {{site.konnect_short_name}}'s Dedicated Cloud Gateways can support custom plugins
but currently require a manual deployment process involving {{site.base_gateway}}'s support team.
Contact your Kong representative for more information.

## Migrating {{site.base_gateway}} configuration

We recommend migrating {{site.base_gateway}} configuration to {{site.konnect_short_name}}
using [decK](/deck/gateway/konnect-configuration/), the declarative management tool for {{site.base_gateway}}
configurations.

The general process for migrating the configuration involves "dumping" your existing  self-managed configuration
to a local file, modifying the configuration slightly to remove any Workspace-specific metadata,
and then synchronizing the configuration to your desired control plane in {{site.konnect_short_name}}.

For example, if you have three Workspaces (`default`, `inventory`, and `sales`), use decK to dump the configuration of each Workspace to a local file:

```sh
deck gateway dump --workspace default --output-file default.yaml
deck gateway dump --workspace inventory --output-file inventory.yaml
deck gateway dump --workspace sales --output-file sales.yaml
```

When using `deck` to dump the configuration, the output file will include the Workspace name in the configuration. 
You need to remove the `_workspace` key before uploading the configuration to {{site.konnect_short_name}}.
To remove the key, you can use the `yq` tool:

```sh
yq -i 'del(._workspace)' default.yaml
yq -i 'del(._workspace)' inventory.yaml
yq -i 'del(._workspace)' sales.yaml
```

Synchronize the configuration to the control planes using decK configured with the
proper control plane name and the {{site.konnect_short_name}} access token:

```sh
deck gateway sync --konnect-token "$KONNECT_PAT" --konnect-control-plane-name default default.yaml
deck gateway sync --konnect-token "$KONNECT_PAT" --konnect-control-plane-name inventory inventory.yaml
deck gateway sync --konnect-token "$KONNECT_PAT" --konnect-control-plane-name sales sales.yaml
```

In this example, replace `$KONNECT_PAT` with your {{site.konnect_short_name}} PAT or specify your PAT as an environment variable.

In addition to decK, {{site.konnect_short_name}} provides
other tools that could be used for migrating your configuration. Each tool requires a different process. See their documentation for more information:

* [Konnect control planes Config API](/api/konnect/control-planes-config/)
* [{{site.konnect_short_name}} Terraform Provider](/terraform/)

## Migrating Data Planes

The recommended approach for migrating your Data Plane instances to {{site.konnect_short_name}} is to
create new Data Plane instances connected to your control plane, validate their configuration and connectivity,
and then decommission the self-managed Data Plane instances.

See the [Data Plane hosting options](/gateway/topology-hosting-options/) for more information. 
The easiest way to deploy new Data Planes is using the {{site.konnect_short_name}} UI, which provides integrated
launchers for popular operating systems and compute platforms.

## Next steps

If you are interested in assistance with migrating from a self-managed {{site.base_gateway}} to
{{site.konnect_short_name}}, contact a Kong field representative.
