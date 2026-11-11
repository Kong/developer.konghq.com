---
title: "Adopt existing resources with kongctl"
description: "Preview ownership changes, select existing children, and save declarative configuration for adopted resources."
content_type: reference
layout: reference
works_on:
  - konnect
tools:
  - kongctl
breadcrumbs:
  - /kongctl/
  - /kongctl/declarative/
related_resources:
  - text: Ownership, namespaces, and protection
    url: /kongctl/declarative/ownership/
  - text: References and external resource lookups
    url: /kongctl/declarative/references/
  - text: Planning, reviewing, and executing changes
    url: /kongctl/declarative/planning/
  - text: Adopt command reference
    url: /kongctl/adopt/
---

Use `kongctl adopt` to bring existing {{site.konnect_short_name}} resources into
declarative management. Adoption assigns ownership metadata to existing
objects while preserving their IDs, configuration, and credentials. Use
`--declarative-output` to save the selected resources as YAML that you can
add to your declarative inputs.

Every adoption command requires `--namespace`. If a resource already has a
namespace, adoption fails unless you pass `--overwrite-namespace`, including
when the existing namespace matches the requested one. Adoption preserves
existing protection. See [ownership and namespaces](/kongctl/declarative/ownership/)
for the boundaries that these metadata fields establish.

Adopting a parent changes ownership of that parent only. Run separate commands
for independently owned children. There isn't a recursive command that adopts
all child resource types together.

## Select child resources

Choose one selection method per child command:

{% table %}
columns:
  - title: |
      Selection
    key: selection
  - title: |
      Example
    key: example
  - title: |
      Behavior
    key: behavior
rows:
  - selection: |
      Exact identifier
    example: |
      `models legacy-chat`
    behavior: |
      Select one child by ID or exact name.
  - selection: |
      All children in a family
    example: |
      `models --all`
    behavior: |
      Select every model under the selected gateway.
  - selection: |
      Filtered selection
    example: |
      `models --name-pattern 'legacy-*'`
    behavior: |
      Select children whose full names match the quoted glob.
{% endtable %}

Don't combine an identifier, `--all`, or `--name-pattern`. Patterns support
`*`, `?`, and character classes such as `[ab]`. Quote patterns so your shell
doesn't expand them. Selection fails when no resources match or an exact
identifier is ambiguous. Patterns match resource names, or basic-auth
usernames, rather than display names.

### {{site.ai_gateway}} children

Select the remote gateway explicitly with `--gateway-id` or `--gateway-name`.
Each family supports exact selection, `--all`, and `--name-pattern`:

{% table %}
columns:
  - title: |
      Child subcommand
    key: command
  - title: |
      Resource
    key: resource
rows:
  - command: |
      `models`
    resource: |
      Models
  - command: |
      `model-providers`
    resource: |
      Model providers
  - command: |
      `auth-strategies`
    resource: |
      Authentication strategies
  - command: |
      `policies`
    resource: |
      Policy instances
  - command: |
      `custom-policies`
    resource: |
      Custom policy definitions
  - command: |
      `agents`
    resource: |
      Agents
  - command: |
      `mcp-servers`
    resource: |
      MCP servers
  - command: |
      `vaults`
    resource: |
      Vaults
  - command: |
      `consumers`
    resource: |
      Consumers
  - command: |
      `consumer-groups`
    resource: |
      Consumer groups
  - command: |
      `ca-certificates`
    resource: |
      CA certificates
  - command: |
      `snis`
    resource: |
      SNIs
{% endtable %}

For example, preview adoption of a filtered model selection:

```shell
kongctl adopt ai-gateway models --name-pattern 'legacy-*' \
  --gateway-name shared-gateway --namespace team-a --dry-run
```

These children store independent ownership in `managed_by`. Adopting models
doesn't adopt their providers or policies. Adopting consumers doesn't change
their credentials or group membership.

### Kong Identity children

Directory-scoped commands use the directory named `default` when you omit
both directory flags. Use `--directory-id` to override that default, or
`--directory-name` to select another directory. OAuth clients require an
explicit auth server selector.

{% table %}
columns:
  - title: |
      Command under `kongctl adopt identity`
    key: command
  - title: |
      Selection
    key: selection
  - title: |
      Parent selector
    key: parent
rows:
  - command: |
      `groups`
    selection: |
      ID, exact name, `--all`, or `--name-pattern`
    parent: |
      Directory
  - command: |
      `principal`
    selection: |
      Individual UUID and required `--ref`
    parent: |
      Directory
  - command: |
      `principal identities`
    selection: |
      Individual UUID and required `--ref`
    parent: |
      Directory and `--principal-id`
  - command: |
      `principal basic-auths`
    selection: |
      UUID, `--username`, `--all`, or username pattern
    parent: |
      Directory and `--principal-id`
  - command: |
      `auth-server clients`
    selection: |
      Client ID, `--client-name`, `--all`, or name pattern
    parent: |
      `--auth-server-id` or `--auth-server-name`
{% endtable %}

Principal and principal identity adoption persist the supplied `--ref` as
the declarative lookup identity. They don't support bulk selection. Adoption
rejects duplicate namespace/ref matches and imported org-chart principals.
Other unsupported imported or associated resource types also remain outside
adoption.

## Preview ownership changes

Every adoption command supports `--dry-run`, which defaults to `false`.
A dry run selects and validates resources without changing remote ownership:

```shell
kongctl adopt ai-gateway models --all \
  --gateway-name shared-gateway --namespace team-a --dry-run -o json
```

Choose `-o text`, `-o json`, or `-o yaml` for the ownership report. Text shows
resources, parents, and ownership changes. JSON and YAML contain
`dry_run: true` and a `changes` array with resource identity, namespace,
parent IDs, metadata location, and `before` and `after` ownership maps.
The report excludes public configuration and credentials. For ownership in
labels, it includes only reserved `KONGCTL-*` labels.

This report describes an adoption. It isn't a declarative plan and can't be
passed to `apply --plan` or `sync --plan`. Run adoption again without
`--dry-run` to change ownership, then generate a fresh declarative plan.

## Save declarative configuration

Every supported adoption command accepts `--declarative-output PATH`,
including parent adoption commands for portals, APIs, control planes,
{{site.ai_gateway}} instances, Event Gateway control planes, dashboards,
application auth strategies, DCR providers, organization teams, and Kong
Identity directories and auth servers.

The file contains the selected resources with explicit namespace and
protection metadata where applicable. It doesn't add file-level defaults,
generated `managed_by` maps, write-only credentials, siblings, or independently
owned descendants. A parent export contains that parent only. Control-plane
group exports retain their existing member IDs without adopting those members.

The destination must be a new file in an existing directory. Existing files
and symlinks fail validation before remote changes. Stdout keeps the usual
adoption results in your selected `-o` format; the configuration file is
always YAML. kongctl doesn't edit your existing configuration files.

With `--dry-run --declarative-output`, kongctl writes proposed configuration
and marks it with a `DRY RUN` comment. Choose a different destination when
performing the actual adoption. Keep preview files out of your normal
configuration inputs.

### Choose a parent reference

For child exports, `--parent-ref` controls how the generated configuration
links to the parent:

{% table %}
columns:
  - title: |
      Export option
    key: option
  - title: |
      Generated configuration
    key: configuration
  - title: |
      Files needed for planning
    key: files
rows:
  - option: |
      Omit `--parent-ref`
    configuration: |
      The selected children and an external parent declaration using the
      parent's exact remote ID.
    files: |
      The exported file. Other referenced resources must already exist or have
      declarations.
  - option: |
      Set `--parent-ref REF`
    configuration: |
      Root-level children with `!ref REF#id` parent links and no parent
      declaration.
    files: |
      The exported file and a declaration with that ref for the same remote
      parent.
{% endtable %}

`--parent-ref` names a local declarative ref. It doesn't select the remote
parent or read existing input files. The gateway, directory, principal, or
auth server selectors still identify the remote parent. A missing ref fails
normal reference validation when you load the files together.

For {{site.ai_gateway}} children, the parent ref names the gateway. For Kong
Identity, it names the nearest parent: a directory for groups and principals,
a principal for identities and basic-auth usernames, or an auth server for
OAuth clients. Without the flag, exports under an external principal also
include the external directory needed to resolve that principal.

`--parent-ref` is available only on child adoption commands. Parent exports
use the remote ID as their ref. Child exports also use remote IDs, except
for Identity principals and identities, which retain the supplied `--ref`.
Include each declaration only once across your inputs.

## Adopt a gateway and its existing children

This example assumes an unmanaged {{site.ai_gateway}} with existing model
providers, models, MCP servers, and consumers. Use an authenticated profile
with permission to read and update these resources. Replace `YOUR_GATEWAY_ID`
with the gateway UUID:

```shell
export GATEWAY_ID=YOUR_GATEWAY_ID
```

Preview model adoption and save proposed configuration:

```shell
kongctl adopt ai-gateway models --all \
  --gateway-id "$GATEWAY_ID" --namespace team-a --dry-run \
  --declarative-output proposed-models.yaml -o json
```

Without `--parent-ref`, this preview includes an external gateway declaration.
The preview doesn't change ownership. Inspect the report and proposed YAML
before continuing.

Adopt the gateway and save its declaration:

```shell
kongctl adopt ai-gateway "$GATEWAY_ID" --namespace team-a \
  --declarative-output gateway.yaml
```

The gateway export uses the gateway UUID as its ref. Pass that value as
`--parent-ref` when adopting the children. Run one command per family:

```shell
kongctl adopt ai-gateway model-providers --all \
  --gateway-id "$GATEWAY_ID" --namespace team-a \
  --parent-ref "$GATEWAY_ID" --declarative-output model-providers.yaml
```

```shell
kongctl adopt ai-gateway models --all \
  --gateway-id "$GATEWAY_ID" --namespace team-a \
  --parent-ref "$GATEWAY_ID" --declarative-output models.yaml
```

```shell
kongctl adopt ai-gateway mcp-servers --all \
  --gateway-id "$GATEWAY_ID" --namespace team-a \
  --parent-ref "$GATEWAY_ID" --declarative-output mcp-servers.yaml
```

```shell
kongctl adopt ai-gateway consumers --all \
  --gateway-id "$GATEWAY_ID" --namespace team-a \
  --parent-ref "$GATEWAY_ID" --declarative-output consumers.yaml
```

These commands adopt all children in the four selected families under this
gateway. They don't adopt resources in other families. Each family validates
its own selection; the commands don't form a shared transaction.

After all commands succeed, generate a plan from the saved declarations:

```shell
kongctl plan --mode apply \
  -f gateway.yaml -f model-providers.yaml -f models.yaml \
  -f mcp-servers.yaml -f consumers.yaml
```

If remote configuration hasn't changed, expect `changes: []`. The declarations
identify the existing resources without recreating them. Review unexpected
changes before applying a plan. Add the generated files to your regular
workflow or incorporate their declarations into your existing inputs.

## Adopt an Identity user and leave keys user-managed

For an existing, unowned `type: user` principal in the `default` directory,
replace `YOUR_PRINCIPAL_ID` with the principal UUID:

```shell
export PRINCIPAL_ID=YOUR_PRINCIPAL_ID
```

Preview adoption and a standalone declaration:

```shell
kongctl adopt identity principal "$PRINCIPAL_ID" \
  --ref self-service-user --namespace identity-team --dry-run \
  --declarative-output proposed-user.yaml
```

Adopt the principal and save its declaration:

```shell
kongctl adopt identity principal "$PRINCIPAL_ID" \
  --ref self-service-user --namespace identity-team \
  --declarative-output adopted-user.yaml
```

The file includes an external directory declaration and the principal's
existing configuration. Adoption preserves its type and doesn't adopt or
export its API keys. The {{site.konnect_short_name}} UI calls these credentials
virtual keys. Users can create, rotate, or revoke keys through their existing
interface.

Keep `api_keys` omitted from the principal declaration, and don't add separate
`identity.principal_api_keys` declarations for these keys. Both apply-mode
and sync-mode planning then leave the key collection outside reconciliation.
An explicit `api_keys: []` has different meaning: sync can delete eligible
kongctl-managed keys in that collection. It doesn't delete foreign or
unmanaged keys. See [sync scope](/kongctl/declarative/sync/) for omission and
empty-collection behavior.

Verify the exported principal with a fresh plan:

```shell
kongctl plan --mode apply -f adopted-user.yaml
```

## Ownership conflicts, failures, and exclusions

A child batch validates the entire selection and its declarative exports
before the first remote write. A known ownership conflict or unsupported
operation stops that selection without changing any resources. Use a narrower
selection, or deliberately transfer ownership with `--overwrite-namespace`.

After validation, writes run individually. Batches aren't atomic and don't
roll back completed adoptions. If a later API request fails, kongctl stops,
reports completed adoptions, and retains those declarations in the output.
A failing request can still have reached the API. Inspect receipts and
remote state before retrying; previously adopted resources require
`--overwrite-namespace` even for the same namespace.

If saving the file fails after a successful adoption, the error identifies
the adopted resource and output path. Stdout still reports that adoption,
and kongctl preserves any previously saved snapshot. Choose a new destination
for a retry; kongctl doesn't overwrite existing inputs.

Supported credential handling remains unchanged:

- Consumer credentials, passwords, and client secrets don't gain independent
  adoption. Basic-auth adoption manages the username record and preserves
  its password children. OAuth client adoption preserves its authentication
  method and client secret.
- Runtime TLS certificates, config stores and their secrets, and data plane
  certificates remain outside {{site.ai_gateway}} adoption.
- HashiCorp Vault AppRole adoption fails before writing when reads redact
  `secret_id` and no `secret_id_file` is configured. This prevents an ownership
  update from losing the credential.
- API-key adoption is unavailable. Managing a principal's declaration doesn't
  require managing its keys. Removing a managed principal requires removing
  its attached credentials first.
