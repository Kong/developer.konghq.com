---
title: "{{site.mesh_product_name}} CLI"
description: Reference for kongctl, the CLI for working with {{site.mesh_product_name}} 3 control planes and their resources.
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
  - text: How policies select traffic
    url: /mesh/policy-targeting/
  - text: Migrate policies to {{site.mesh_product_name}} 3
    url: /mesh/migrate-policies-to-3/
  - text: MeshIdentity
    url: /mesh/policies/meshidentity/
---

`kongctl` is the CLI for {{site.mesh_product_name}} 3, replacing `kumactl`. It talks to a
control plane over its HTTP API and works the same way against Konnect and a self-managed
control plane.

One difference from `kumactl` shapes everything below: **`kongctl` learns the resource types
from the control plane itself**, by reading what the control plane serves rather than carrying a
compiled-in list. A policy added in a newer {{site.mesh_product_name}} release is usable without
upgrading the CLI, and `kongctl get mesh resource-types` is the authoritative list for the
control plane in front of you.

{{site.mesh_product_name}} 3.0 or later is required. Earlier control planes serve a different
API and are not supported.

## Authenticating

Against Konnect, log in once:

```sh
kongctl login
```

This runs a browser-based device authorization flow and stores a token. A Personal Access Token
works instead, with `--pat` or the matching configuration entry, which is what CI usually uses.

A self-managed control plane needs no login. Point `--control-plane-url` at its API instead, and
that flag takes precedence over `--control-plane-id`.

## Choosing a control plane and a mesh

Every mesh command needs to know which control plane to talk to, and most need to know which
mesh. Both can be given as flags or held in configuration.

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
    what: "A Konnect control plane by ID."
    config: "`konnect.mesh.control-plane.id`"
  - flag: "`--control-plane-name`"
    what: "A Konnect control plane by name."
    config: "`konnect.mesh.control-plane.name`"
  - flag: "`--control-plane-url`"
    what: "A self-managed control plane by API URL. Takes precedence over `--control-plane-id`."
    config: "`konnect.mesh.control-plane.url`"
  - flag: "`-m`, `--mesh`"
    what: "The mesh that mesh-scoped resources belong to. Defaults to `default`."
    config: "`konnect.mesh.mesh`"
  - flag: "`--all-meshes`"
    what: "Read mesh-scoped resources across every mesh. Ignored for global types."
    config: "—"
{% endtable %}

Setting the control plane in configuration once is what makes the examples below readable; every
one of them would otherwise carry `--control-plane-id <id>`.

To see what is available:

```sh
kongctl get mesh control-planes
```

## Commands

### Listing and reading resources

```sh
# every resource type this control plane serves
kongctl get mesh resource-types

# all of one type, in the default mesh
kongctl get mesh meshtimeouts

# one resource, as YAML
kongctl get mesh meshtimeouts slow -o yaml

# across every mesh
kongctl get mesh meshtrafficpermissions --all-meshes
```

A type can be given as its plural name, its singular, or its short alias — `meshtrafficpermissions`,
`meshtrafficpermission` and `mtp` all work, and matching is case-insensitive.
`resource-types` lists the aliases.

### Applying resources

```sh
# one file
kongctl create mesh -f policy.yaml

# every resource in a directory
kongctl create mesh -f ./policies

# from stdin
cat policy.yaml | kongctl create mesh -f -
```

`create mesh` creates or updates, so re-applying a file is how a resource is edited. Each
resource carries its own `type`, `name` and `mesh`, so one file or directory can span types and
meshes.

### Deleting resources

```sh
kongctl delete mesh meshtrafficpermission allow-all
kongctl delete mesh meshtimeout slow -m prod
```

`--auto-approve` skips the confirmation prompt, which is what scripts need.

### Inspecting what the control plane computed

`get mesh` reads resources back as they were written. `inspect` answers the questions only the
control plane can, once matching and merging have run.

```sh
# which policies apply to a proxy, and on which of its ports
kongctl get mesh inspect dataplane backend-01

# which proxies a policy matches
kongctl get mesh inspect meshtimeout slow

# overviews
kongctl get mesh inspect dataplanes
kongctl get mesh inspect meshes
kongctl get mesh inspect zones
```

`inspect dataplane` reports per port rather than per proxy, because that is where a policy
actually lands — one applying to a proxy's inbound but not its outbounds is the case that is
hard to see any other way:

```
PORT       KIND         ORIGINS
admin-ssl  MeshTimeout  kri_mt_default___mesh-wide-timeout_
proxy      MeshTimeout  kri_mt_default___mesh-wide-timeout_
postgres   MeshTimeout  kri_mt_default___outbound-timeout_
```

`--type` reaches the proxy's own Envoy configuration instead of the control plane's view:

{% table %}
columns:
  - title: "`--type`"
    key: type
  - title: Reports
    key: what
rows:
  - type: "`policies`"
    what: "The policies the control plane matched to each port. The default, and the only one that does not need the proxy reachable."
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
needs the zone connected to the control plane and the proxy reachable from the zone. A failure
at either hop is reported as it arrives — `zone is offline` when the zone is down, and a
connection error naming the admin port when the proxy is.

### Exporting a control plane

```sh
# what a new global control plane needs
kongctl dump mesh > mesh.yaml

# apply it to another control plane
kongctl create mesh -f mesh.yaml --control-plane-id <other>
```

`dump mesh` writes resources in the same shape `create mesh` reads, so an export can be applied
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
> On `dump mesh`, `--profile` means the export profile above, and the global `-p, --profile`
> flag that selects a `kongctl` configuration profile is not available on this command. Use a
> different command, or set the configuration profile another way, if you need both.

### Issuing tokens

```sh
# a token a dataplane uses to prove its identity
kongctl create mesh dataplane-token --name backend-01 --valid-for 24h > token

# a token for a zone control plane
kongctl create mesh zone-token --zone zone-1 --valid-for 720h > token
```

Both write the token to stdout with no trailing newline, so the output can be redirected
straight into the file `kuma-dp` reads.

Bind a dataplane token as narrowly as the deployment allows — `--name`, `--workload`, or
`--tag` — rather than to the mesh alone. A token bound only to a mesh authenticates any proxy in
it.

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
    what: "Tag values the dataplane must carry. Repeatable; comma-separate multiple values for one tag."
  - flag: "`--proxy-type`"
    what: "The proxy type, for example `dataplane`."
  - flag: "`--valid-for`"
    what: "How long the token remains valid, for example `24h`."
{% endtable %}

`zone-token` takes `--zone` and `--scope`, which defaults to `cp`.

## Output

`-o` selects the format: `text`, the default, or `json` or `yaml`.

`text` is a summary table, useful for scanning. Read the whole resource with `-o yaml`, which is
also what round-trips back through `create mesh`.

For scripting, `--jq` filters JSON responses with a full jq expression, and `-r` strips the
quotes from string results:

```sh
kongctl get mesh meshservices --all-meshes -o json \
  --jq '.[] | select(.spec.state == "Unavailable") | .name' -r
```

`--columns` picks the fields a text table shows, as `HEADER=.field`, which covers the cases where
a table is wanted but the default columns are not the interesting ones.

## Differences from kumactl

{% table %}
columns:
  - title: "`kumactl`"
    key: old
  - title: "`kongctl`"
    key: new
rows:
  - old: "`kumactl apply -f policy.yaml`"
    new: "`kongctl create mesh -f policy.yaml`"
  - old: "`kumactl get meshtimeouts`"
    new: "`kongctl get mesh meshtimeouts`"
  - old: "`kumactl delete meshtimeout slow`"
    new: "`kongctl delete mesh meshtimeout slow`"
  - old: "`kumactl export`"
    new: "`kongctl dump mesh`"
  - old: "`kumactl generate dataplane-token`"
    new: "`kongctl create mesh dataplane-token`"
  - old: "`kumactl inspect dataplane NAME`"
    new: "`kongctl get mesh inspect dataplane NAME`"
  - old: "`kumactl inspect <policy> NAME`"
    new: "`kongctl get mesh inspect <policy> NAME`"
  - old: "`kumactl config control-planes add`"
    new: "`kongctl login`, or `--control-plane-url` for a self-managed control plane"
{% endtable %}

Beyond the command names:

- **Resource types come from the control plane.** `kumactl` carried a compiled-in list, so a
  newer policy needed a newer CLI. `kongctl` reads what the control plane serves.
- **Installation is not a CLI job.** `kumactl install control-plane` has no counterpart under
  `kongctl mesh`; install {{site.mesh_product_name}} with Helm. (`kongctl install` exists, but
  it installs `kongctl`'s own features, not a control plane.)
- **`kumactl apply -v` variables are gone.** Templating a resource before applying it is a job
  for whatever produces the YAML.

Read-only behaviour is unchanged in substance: on Kubernetes the control plane generates some
resources and refuses writes to them, as [MeshService](/mesh/meshservice/) does.

## Getting help

Every command explains itself:

```sh
kongctl get mesh --help
kongctl create mesh dataplane-token --help
```

`kongctl` covers the whole of Konnect, not only {{site.mesh_product_name}}, so its top-level
command list is longer than what is documented here. The `mesh` subcommand of `get`, `create`,
`delete` and `dump` is the {{site.mesh_product_name}} surface.
