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
faqs:
  - q: How do `kumactl` commands map to `kongctl`?
    a: |
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
        - old: "`kumactl delete meshtimeout NAME`"
          new: "`kongctl delete mesh meshtimeout NAME`"
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
  - q: What else is different from `kumactl`?
    a: |
      - Resource types come from the control plane. `kumactl` carried a compiled-in list, so a
        newer policy needed a newer CLI. `kongctl` reads what the control plane serves.
      - Installation isn't supported. `kumactl install control-plane` has no `kongctl`
        counterpart.
      - `kumactl` still installs the transparent proxy. It ships in the
        {{site.mesh_product_name}} archive. Use `kumactl install transparent-proxy` on Universal to install the iptables rules. For more information, see
        [Universal data plane](/mesh/universal-data-plane/#transparent-proxying).
      - `kumactl apply -v` variables are not supported.

      Read-only behavior is unchanged: the global control plane doesn't write to
      resources that zones generate, such as [MeshService](/mesh/meshservice/), and `kongctl` rejects
      the write before sending the request. A zone control plane accepts the write but doesn't
      reconcile it back from its source.
min_version:
  mesh: '3.0'
---

`kongctl` is the CLI for {{site.mesh_product_name}}. It connects to a
control plane over its HTTP API and works the same way against {{site.konnect_short_name}} and a self-managed
control plane.

`kongctl` learns the resource types from the control plane itself, by reading what the control plane serves rather than carrying a compiled-in list. A policy added in a newer {{site.mesh_product_name}} release is usable without
upgrading the CLI, and `kongctl get mesh resource-types` is the authoritative list for your control plane.

## Authenticating

Against {{site.konnect_short_name}}, log in once:

```sh
kongctl login
```

`kongctl login` runs a browser-based device authorization flow and stores a token. You can also pass a Personal Access Token
with the `--pat` flag.

A self-managed control plane needs no login. Point `--control-plane-url` at its API instead,
and pass a user token with `--control-plane-token`, and `--ca-cert-file` for HTTPS. The
{{site.mesh_product_name}} API enforces RBAC and treats only requests from the control plane
host itself as admin, so without a token, a remote `kongctl` can't issue tokens or write
resources.

## Choosing a control plane and a mesh

Every mesh command needs to know which control plane to connect to, and most need to know which
mesh. You can pass both as flags or hold them in configuration.

{% table %}
columns:
  - title: Select
    key: what
  - title: Flag
    key: flag
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
    what: "Mesh-scoped resources across every mesh. Ignored for global types."
    config: "None"
{% endtable %}

Pass only one of `--control-plane-id`, `--control-plane-name` or `--control-plane-url`. When
you pass none, `kongctl` uses the configured values in the order URL, ID, name.

To see what control planes are available, run:

```sh
kongctl get mesh control-planes
```

## Commands

The following `kongctl` commands are available for {{site.mesh_product_name}}.
For more information, see [the `kongctl` docs](/kongctl/).

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
kongctl get mesh meshtimeouts "$POLICY_NAME" -o yaml
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
kongctl delete mesh meshtrafficpermission "$POLICY_NAME"
```

Delete a resource in another mesh with `-m`:

```sh
kongctl delete mesh meshtimeout "$POLICY_NAME" -m "$MESH_NAME"
```

Use the `--auto-approve` flag to skip the confirmation prompt.

### Inspecting what the control plane computed

`get mesh` reads resources back as they were written. `inspect` provides the state of resources once matching and merging have run.

Show which policies apply to a proxy, and on which of its ports:

```sh
kongctl inspect mesh dataplane "$DATAPLANE_NAME"
```

Show which proxies a policy matches:

```sh
kongctl inspect mesh meshtimeout "$POLICY_NAME"
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
actually lands:

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
needs the zone connected to the control plane and the proxy reachable from the zone.

### Exporting a control plane

Export control plane configuration:

```sh
kongctl dump mesh > mesh.yaml
```

`dump mesh` covers every mesh on the control plane and writes resources in the same shape
`apply mesh` reads. `--export-profile` selects which resource types to export:

{% table %}
columns:
  - title: "`--export-profile`"
    key: profile
  - title: Exports
    key: what
  - title: Leaves out
    key: skipped
rows:
  - profile: "`federation` (default)"
    what: "`Mesh`, `Secret`, `GlobalSecret`, `HostnameGenerator`, `MeshIdentity`, `MeshTrust`, `MeshExternalService`, `MeshMultiZoneService` and `MeshOpenTelemetryBackend`."
    skipped: "Policies, and the resources each zone creates for itself: `Dataplane`, `Workload`, `MeshService`, `MeshZoneAddress`, `Zone`, and every insight type."
  - profile: "`federation-with-policies`"
    what: "Everything in `federation`, and every policy."
    skipped: "The same zone-created resources as `federation`."
  - profile: "`no-dataplanes`"
    what: "Every resource type the control plane serves, including read-only insight types."
    skipped: "`Dataplane` and `DataplaneInsight`."
  - profile: "`all`"
    what: "Every resource type the control plane serves, including `Dataplane` and read-only insight types."
    skipped: "Nothing."
{% endtable %}

The two `federation` profiles prepare the export to be applied to a new global control plane:
they remove control-plane-owned labels, such as `kuma.io/origin`, `kuma.io/zone` and
`kuma.io/display-name`, so the new control plane sets its own. They keep `kuma.io/mesh`.

`all` and `no-dataplanes` keep every label and include read-only resources. They describe a
control plane rather than seed one, so they can't necessarily be applied back unchanged.

Every profile leaves out the `envoy-admin-ca` and `inter-cp-ca` global secrets, which secure
traffic between control planes and break TLS if applied to another one. Any
`user-token-signing-key` global secret goes last in the stream, because applying it invalidates
the token used to apply everything else.

{:.warning}
> An export can contain secrets. Store it somewhere appropriate for credentials.

### Issuing tokens

Issue a token a data plane uses to prove its identity:

```sh
kongctl create mesh dataplane-token --name "$DATAPLANE_NAME" --workload "$WORKLOAD_NAME" --valid-for 24h > token
```

Issue a token for a zone control plane:

```sh
kongctl create mesh zone-token --zone "$ZONE_NAME" --valid-for 720h > token
```

Both write the token to stdout with no trailing newline, so the output can be redirected
straight into the file that `kuma-dp` or the zone control plane reads.

Bind a data plane token as narrowly as the deployment allows rather than to the mesh alone. 
Once a `MeshIdentity` derives identities from the
`kuma.io/workload` label, the control plane rejects a proxy carrying that label unless
its token is bound with `--workload`. A token bound only by `--name`, or only to the mesh, no
longer authenticates it.

{% table %}
columns:
  - title: Flag
    key: flag
  - title: Binds the token to
    key: what
rows:
  - flag: "`--name`"
    what: "One named data plane."
  - flag: "`--workload`"
    what: "A workload label value the data plane must carry."
  - flag: "`--tag`"
    what: "Label values the data plane must carry. Repeatable; comma-separate multiple values for one label."
  - flag: "`--proxy-type`"
    what: "The proxy type, for example `dataplane`."
  - flag: "`--valid-for`"
    what: "How long the token remains valid, for example `24h`."
{% endtable %}

`zone-token` takes `--zone` and `--scope`, which defaults to `cp`.

## Output

`-o` selects the format: `text` (default), `json`, or `yaml`.

`text` is a summary table, useful for scanning.

For scripting, `--jq` filters JSON responses with a full jq expression, and `-r` strips the
quotes from string results:

```sh
kongctl get mesh meshservices --all-meshes -o json \
  --jq '.items[] | select(.spec.state == "Unavailable") | .name' -r
```

`--columns` picks the fields a text table shows, as `HEADER=.field`, which covers the cases where
you want a table with columns different from the default ones.

## Getting help

Every command explains itself. For example:

```sh
kongctl get mesh --help
```

```sh
kongctl create mesh dataplane-token --help
```
