---
title: "{{site.mesh_product_name}} CLI"
description: Reference for kongctl, the CLI for working with {{site.mesh_product_name}} 3.x control planes and their resources.
content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/
tags:
  - cli
works_on:
  - on-prem
  - konnect
related_resources:
  - text: Policy targeting
    url: /mesh/policy-targeting/
  - text: Migrate policies to {{site.mesh_product_name}} 3.x
    url: /mesh/migrate-policies-to-3/
  - text: MeshIdentity
    url: /mesh/policies/meshidentity/
---

`kongctl` is the CLI for {{site.mesh_product_name}} 3.x, replacing `kumactl`. It talks to a
control plane over its HTTP API and works the same way against {{site.konnect_short_name}} and a self-managed
control plane.

One difference from `kumactl` shapes every command in this reference: **`kongctl` learns the resource types
from the control plane itself**, by reading what the control plane serves rather than carrying a
compiled-in list. A policy added in a newer {{site.mesh_product_name}} release is usable without
upgrading the CLI, and `kongctl get mesh resource-types` is the authoritative list for the
control plane in front of you.

`kongctl` requires {{site.mesh_product_name}} 3.0 or later. Earlier control planes serve a different
API and aren't supported.

## Authenticating

Against {{site.konnect_short_name}}, log in once:

```sh
kongctl login
```

`kongctl login` runs a browser-based device authorization flow and stores a token. A Personal Access Token
works instead, with `--pat` or the matching configuration entry, which is what CI usually uses.

A self-managed control plane needs no login. Point `--control-plane-url` at its API instead,
and pass a user token with `--control-plane-token` (plus `--ca-cert-file` for HTTPS). The
{{site.mesh_product_name}} API enforces RBAC and treats only requests from the control plane
host itself as admin, so without a token, a remote `kongctl` can't issue tokens or write
resources.

## Choosing a control plane and a mesh

Every mesh command needs to know which control plane to talk to, and most need to know which
mesh. You can pass both as flags or hold them in configuration.

{% table %}
columns:
  - title: Flag
    key: flag
  - title: Selects
    key: what
  - title: Configuration entry
    key: config
rows:
  - flag: "`--control-plane-id`"
    what: "A {{site.konnect_short_name}} control plane by ID."
    config: "`konnect.mesh.control-plane.id`"
  - flag: "`--control-plane-name`"
    what: "A {{site.konnect_short_name}} control plane by name."
    config: "`konnect.mesh.control-plane.name`"
  - flag: "`--control-plane-url`"
    what: "A self-managed control plane by API URL."
    config: "`konnect.mesh.control-plane.url`"
  - flag: "`-m`, `--mesh`"
    what: "The mesh that mesh-scoped resources belong to. Defaults to `default`."
    config: "`konnect.mesh.mesh`"
  - flag: "`--all-meshes`"
    what: "Read mesh-scoped resources across every mesh. Ignored for global types."
    config: "None"
{% endtable %}

Pass only one of `--control-plane-id`, `--control-plane-name` or `--control-plane-url`. When
you pass none, `kongctl` uses the configured values in the order URL, ID, name.

Setting the control plane in configuration once is what makes the examples in this reference readable; every
one of them would otherwise carry `--control-plane-id CONTROL_PLANE_ID`.

To see what is available:

```sh
kongctl get mesh control-planes
```

## Commands

### Listing and reading resources

List every resource type this control plane serves:

```sh
kongctl get mesh resource-types
```

List all resources of one type, in the default mesh:

```sh
kongctl get mesh meshtimeouts
```

Read one resource, as YAML:

```sh
kongctl get mesh meshtimeouts slow -o yaml
```

List resources across every mesh:

```sh
kongctl get mesh meshtrafficpermissions --all-meshes
```

You can give a type as its plural name, its singular, or its short alias: `meshtrafficpermissions`,
`meshtrafficpermission` and `mtp` all work, and matching is case-insensitive.
`resource-types` lists the aliases.

### Applying resources

Apply one file:

```sh
kongctl apply mesh -f policy.yaml
```

Apply every resource in a directory:

```sh
kongctl apply mesh -f ./policies
```

Apply from stdin:

```sh
cat policy.yaml | kongctl apply mesh -f -
```

`apply mesh` creates or replaces each resource, so re-applying a file is how you edit a resource. Each
resource carries its own `type`, `name` and `mesh`, so one file or directory can span types and
meshes.

### Deleting resources

Delete a resource in the default mesh:

```sh
kongctl delete mesh meshtrafficpermission allow-all
```

Delete a resource in another mesh with `-m`:

```sh
kongctl delete mesh meshtimeout slow -m prod
```

`--auto-approve` skips the confirmation prompt, which is what scripts need.

### Inspecting what the control plane computed

`get mesh` reads resources back as they were written. `inspect` answers the questions only the
control plane can, once matching and merging have run.

Show which policies apply to a proxy, and on which of its ports:

```sh
kongctl inspect mesh dataplane backend-01
```

Show which proxies a policy matches:

```sh
kongctl inspect mesh meshtimeout slow
```

Get an overview of all data plane proxies:

```sh
kongctl inspect mesh dataplanes
```

Get an overview of all meshes:

```sh
kongctl inspect mesh meshes
```

Get an overview of all zones:

```sh
kongctl inspect mesh zones
```

`inspect dataplane` reports per port rather than per proxy, because that is where a policy
actually lands. One applying to a proxy's inbound but not its outbounds is the case that is
hard to see any other way:

```text
PORT       KIND         ORIGINS
admin-ssl  MeshTimeout  kri_mt_default___mesh-wide-timeout_
proxy      MeshTimeout  kri_mt_default___mesh-wide-timeout_
postgres   MeshTimeout  kri_mt_default___outbound-timeout_
```
{:.no-copy-code}

`--type` reaches the proxy's own Envoy configuration instead of the control plane's view:

{% table %}
columns:
  - title: "`--type`"
    key: type
  - title: Reports
    key: what
rows:
  - type: "`policies`"
    what: "The policies the control plane matched to each port. The default, and the only one that doesn't need the proxy reachable."
  - type: "`stats`"
    what: "Envoy statistics."
  - type: "`clusters`"
    what: "The proxy's clusters."
  - type: "`xds`"
    what: "The xDS configuration dump."
  - type: "`config`"
    what: "The proxy's configuration."
{% endtable %}

Everything but `policies` is relayed from the proxy's Envoy admin interface verbatim, so it
needs the zone connected to the control plane and the proxy reachable from the zone. `kongctl` reports
a failure at either hop as it arrives: `zone is offline` when the zone is down, and a
connection error naming the admin port when the proxy is.

### Exporting a control plane

Export what a new global control plane needs:

```sh
kongctl dump mesh > mesh.yaml
```

Apply the export to another control plane:

```sh
kongctl apply mesh -f mesh.yaml --control-plane-id $TARGET_CP_ID
```

`$TARGET_CP_ID` is the ID of the control plane that receives the export, as listed by
`kongctl get mesh control-planes`.

`dump mesh` writes resources in the same shape `apply mesh` reads, so an export can be applied
straight back. `--profile` selects how much to export:

{% table %}
columns:
  - title: "`--profile`"
    key: profile
  - title: Exports
    key: what
rows:
  - profile: "`federation`"
    what: "What a new global control plane needs to take over. The default."
  - profile: "`federation-with-policies`"
    what: "The same, plus the `targetRef` policies."
  - profile: "`no-dataplanes`"
    what: "Everything except dataplanes."
  - profile: "`all`"
    what: "Every resource type the control plane serves."
{% endtable %}

{:.warning}
> On `dump mesh`, `--profile` means the export profile, not the global `-p, --profile`
> flag that selects a `kongctl` configuration profile; that flag is not available on this command. Use a
> different command, or set the configuration profile another way, if you need both.

### Issuing tokens

Issue a token a dataplane uses to prove its identity:

```sh
kongctl create mesh dataplane-token --name backend-01 --workload backend --valid-for 24h > token
```

Issue a token for a zone control plane:

```sh
kongctl create mesh zone-token --zone zone-1 --valid-for 720h > token
```

Both write the token to stdout with no trailing newline, so the output can be redirected
straight into the file that `kuma-dp` (dataplane token) or the zone control plane (zone token)
reads.

Bind a dataplane token as narrowly as the deployment allows (`--name`, `--workload`, or
`--tag`) rather than to the mesh alone. Once a `MeshIdentity` derives identities from the
`kuma.io/workload` label (the Universal default), the control plane rejects a proxy carrying that label unless
its token is bound with `--workload`; a token bound only by `--name`, or only to the mesh, no
longer authenticates it.

{% table %}
columns:
  - title: Flag
    key: flag
  - title: Binds the token to
    key: what
rows:
  - flag: "`--name`"
    what: "One named dataplane."
  - flag: "`--workload`"
    what: "A workload label value the dataplane must carry."
  - flag: "`--tag`"
    what: "Label values the dataplane must carry. Repeatable; comma-separate multiple values for one label."
  - flag: "`--proxy-type`"
    what: "The proxy type, for example `dataplane`."
  - flag: "`--valid-for`"
    what: "How long the token remains valid, for example `24h`."
{% endtable %}

`zone-token` takes `--zone` and `--scope`, which defaults to `cp`.

## Output

`-o` selects the format: `text`, the default, or `json` or `yaml`.

`text` is a summary table, useful for scanning. Read the whole resource with `-o yaml`, which is
also what round-trips back through `apply mesh`.

For scripting, `--jq` filters JSON responses with a full jq expression, and `-r` strips the
quotes from string results:

```sh
kongctl get mesh meshservices --all-meshes -o json \
  --jq '.items[] | select(.spec.state == "Unavailable") | .name' -r
```

`--columns` picks the fields a text table shows, as `HEADER=.field`, which covers the cases where
you want a table but the default columns aren't the interesting ones.

## Differences from `kumactl`

{% table %}
columns:
  - title: "`kumactl`"
    key: old
  - title: "`kongctl`"
    key: new
rows:
  - old: "`kumactl apply -f policy.yaml`"
    new: "`kongctl apply mesh -f policy.yaml`"
  - old: "`kumactl get meshtimeouts`"
    new: "`kongctl get mesh meshtimeouts`"
  - old: "`kumactl delete meshtimeout slow`"
    new: "`kongctl delete mesh meshtimeout slow`"
  - old: "`kumactl export`"
    new: "`kongctl dump mesh`"
  - old: "`kumactl generate dataplane-token`"
    new: "`kongctl create mesh dataplane-token`"
  - old: "`kumactl inspect dataplane NAME`"
    new: "`kongctl inspect mesh dataplane NAME`"
  - old: "`kumactl inspect POLICY_TYPE NAME`"
    new: "`kongctl inspect mesh POLICY_TYPE NAME`"
  - old: "`kumactl config control-planes add`"
    new: "`kongctl login`, or `--control-plane-url` for a self-managed control plane"
{% endtable %}

Beyond the command names:

- **Resource types come from the control plane.** `kumactl` carried a compiled-in list, so a
  newer policy needed a newer CLI. `kongctl` reads what the control plane serves.
- **Installation isn't a CLI job.** `kumactl install control-plane` has no `kongctl`
  counterpart; install {{site.mesh_product_name}} with Helm. (`kongctl install` exists, but
  it installs `kongctl`'s own features, not a control plane.)
- **`kumactl` still installs the transparent proxy.** It ships in the
  {{site.mesh_product_name}} archive, and on Universal hosts `kumactl install transparent-proxy`
  is how you install the iptables rules. See
  [Universal data plane](/mesh/universal-data-plane/#transparent-proxying).
- **`kumactl apply -v` variables are gone.** Templating a resource before applying it is a job
  for whatever produces the YAML.

Read-only behavior is unchanged in substance: the global control plane refuses writes to
resources that zones generate, such as [MeshService](/mesh/meshservice/), and `kongctl` rejects
the write before sending the request. A zone control plane accepts the write but doesn't
reconcile it back from its source.

## Getting help

Every command explains itself. For example:

```sh
kongctl get mesh --help
```

```sh
kongctl create mesh dataplane-token --help
```

`kongctl` covers the whole of {{site.konnect_short_name}}, not only {{site.mesh_product_name}}, so its top-level
command list is longer than what is documented here. The `mesh` subcommand of `get`, `create`,
`delete` and `dump` is the {{site.mesh_product_name}} surface.
