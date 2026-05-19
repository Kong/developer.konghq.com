---
title: kongctl declarative resource reference

description: Reference for `kongctl` declarative configuration that lists supported resource types and their field-level values.

content_type: reference
layout: reference



works_on:
  - konnect

tools:
  - kongctl

breadcrumbs:
  - /kongctl/

related_resources:
  - text: Get started with kongctl
    url: /kongctl/get-started/
  - text: Declarative configuration with kongctl
    url: /kongctl/declarative/
next_steps:
  - text: Example declarative configurations
    url: https://github.com/Kong/kongctl/tree/main/docs/examples/declarative
  - text: Learn about managing declarative configuration with kongctl
    url: /kongctl/declarative/
  - text: Learn about kongctl authorization options
    url: /kongctl/authentication/
  - text: kongctl configuration reference guide
    url: /kongctl/config/
  - text: kongctl troubleshooting guide
    url: /kongctl/troubleshooting/
  - text: Using kongctl and decK for full API platform management
    url: /kongctl/kongctl-and-deck/
  - text: View the {{site.konnect_short_name}} API reference
    url: /konnect-api/
---

This document is the reference for `kongctl` declarative configuration. 
It lists supported resource types and their field-level values.
Resource configurations are provided as YAML files and can be expressed as one or more files passed to `kongctl` declarative commands.

See the [declarative configuration guide](/kongctl/declarative/) for information on managing these resources declaratively.

## File-level defaults

Use `_defaults.kongctl` to apply default `namespace` and `protected` metadata to parent resources in this file. 
Resource-level `kongctl` values override these defaults.

```yaml
_defaults:
  kongctl:
    namespace: platform-team
    protected: false
```

## YAML tags

Use YAML tags in field values to load files or reference other resources.

- `!file`: Load content from a file. 
  Supports `path#extract.path` and `path`/`extract` map form.
- `!env`: Load string content from an environment variable. 
  Supports`VAR#extract.path` and `var`/`extract` map form.
- `!ref`: Reference another declarative resource by `ref`.
  `resource-ref#field` is supported; the default field is `id`.
- `!ref` is intended for string fields.
- `string (uuid)` and `array[string(uuid)]` annotations in this document describe API value types. 
  In declarative config, prefer `!ref` and avoid literal UUID values.
- For unmanaged/external resources, prefer `_external.selector` and then reference that resource by `!ref` from other fields.
- Large text/spec fields are commonly loaded with `!file`.
- `!file` paths are resolved relative to the config file and must remain within the configured base directory boundary.

```yaml
portals:
  - ref: docs-portal
    _external:
      selector:
        matchFields:
          name: "Docs Portal"

apis:
  - ref: billing-api
    publications:
      - ref: billing-publication
        portal_id: !ref docs-portal
```

## Audit logs

Audit log webhook destinations are organization-scoped {{site.konnect_short_name}} resources.
Declarative config supports them as external references so managed portal audit log webhooks can point at destinations created elsewhere.

* [Reference for listening to audit logs with kongctl](/kongctl/audit-logs/)
* [API specification](/api/konnect/audit-logs/)
* [Examples](https://github.com/Kong/kongctl/tree/main/docs/examples/declarative/audit-logs)

```yaml
audit-logs:
  destinations:
    - ref: string
      _external:
        id: string # destination UUID, or use selector
        selector:
          matchFields:
            name: string
```

{:.warning}
> **Note:** Only `_external.id` and `_external.selector.matchFields.name` are supported.
Audit log webhook destinations **cannot** declare `kongctl` metadata and are not created, updated, or deleted by declarative `kongctl apply`.

## APIs

* [API specification](/api/konnect/api-builder/#/operations/create-api)
* [Example](https://github.com/Kong/kongctl/tree/main/docs/examples/declarative/basic/api.yaml)

```yaml
apis:
  - ref: string
    name: string required (1-255 chars)
    description: string (nullable)
    version: string (1-255 chars, nullable)
    slug: string (pattern: ^[\w-]+$, nullable)
    labels: object [string]string
      key: value
    attributes: object [string]array[string]
      key:
        - value
    versions: # /api/konnect/api-builder/v3/#/operations/create-api-version
      - ref: string
        version: string
        spec: object required
          content: string required (OpenAPI or AsyncAPI content; json or yaml) # prefer: !file ./specs/api.yaml
    publications: # /api/konnect/api-builder/v3/#/operations/publish-api-to-portal
      - ref: string
        portal_id: string required (uuid) # prefer: !ref <portal-ref>
        auto_approve_registrations: boolean
        auth_strategy_ids: array[string(uuid)] (nullable, max 1 item) # prefer: !ref values
        visibility: One of (public | private)
    implementations: # /api/konnect/api-builder/v3/#/operations/create-api-implementation
      - ref: string
        service: # oneOf variant
          id: string required (uuid) # prefer: !ref <gateway-service-ref>
          control_plane_id: string required (uuid) # prefer: !ref <control-plane-ref>
        control_plane: # oneOf variant
          control_plane_id: string required (uuid) # prefer: !ref <control-plane-ref>
    documents: # /api/konnect/api-builder/v3/#/operations/create-api-document
      - ref: string
        content: string required (markdown) # prefer: !file ./docs/page.md
        title: string
        slug: string (pattern: ^[\w-]+$)
        status: One of (published | unpublished)
        parent_document_id: string (uuid, nullable) # prefer: !ref <document-ref>
        children:
          - ref: string
            content: string required (markdown) # prefer: !file ./docs/page.md
            title: string
            slug: string (pattern: ^[\w-]+$)
            status: One of (published | unpublished)
```
{:.collapsible}

API specifications must be declared on API versions with `versions[].spec` or
root-level `api_versions[].spec`; `apis[].spec_content` is not supported in
declarative configuration.

## Application auth strategies

* [API specification](/api/konnect/application-auth-strategies/#/operations/create-app-auth-strategy)
* [Example](https://github.com/Kong/kongctl/tree/main/docs/examples/declarative/portal/auth-strategies.yaml)

```yaml
application_auth_strategies:
 - ref: string
   name: string required
   display_name: string required
   strategy_type: One of (key_auth | openid_connect) required
   configs: object required
     key-auth: # if strategy_type: key_auth
       key_names: array[string] required (1-10 items)
       ttl: object
         value: integer required (minimum: 1)
         unit: One of (days | weeks | years) required
     openid-connect: # if strategy_type: openid_connect
       issuer: string (url, max 256 chars) required
       credential_claim: array[string] required (max 10 items)
       scopes: array[string] required (max 50 items)
       auth_methods: array[string] required (max 10 items)
   dcr_provider_id: string (uuid, nullable; openid_connect only) # prefer: !ref <dcr-provider-ref>
   labels: object [string]string
     key: value
```

## DCR providers

* [API specification](/api/konnect/application-auth-strategies/#/operations/create-dcr-provider)
* [Examples](https://github.com/Kong/kongctl/tree/main/docs/examples/declarative/dcr-providers)

```yaml
dcr_providers:
 - ref: string
   name: string required
   display_name: string
   provider_type: One of (auth0 | azureAd | curity | okta | http) required
   issuer: string (url, max 256 chars) required
   dcr_config: object required
   labels: object [string]string
     key: value
```

## Catalog services

* [API specification](/api/konnect/service-catalog/v1/#/operations/create-catalog-service)
* [Examples](https://github.com/Kong/kongctl/tree/main/docs/examples/declarative/catalog/service.yaml)

```yaml
catalog_services:
 - ref: string
   name: string required (1-120 chars, pattern: ^[0-9a-z.-]+$)
   display_name: string required (1-120 chars)
   description: string (max 2048 chars)
   labels: object [string]string
     key: value
   custom_fields: object
     key: value
```

## Dashboards

Dashboard names don't need to be unique in {{site.konnect_short_name}}, but `kongctl` follows the same resource matching pattern used elsewhere in declarative configuration.
When planning against the live state, it considers dashboards with the matching `KONGCTL-namespace` label and matches the desired dashboard by name. 
Avoid using duplicate dashboard names within a kongctl namespace.

Dashboard resources are declared under the `analytics` grouping key.

For dashboards created in the {{site.konnect_short_name}} UI:
1. Run `kongctl adopt analytics dashboard` with the dashboard ID to apply the namespace label.
1. Run `kongctl dump declarative --resources=analytics.dashboards --default-namespace <name>` to generate declarative configuration.

Name-based adoption fails if the name matches multiple dashboards.

Use the dashboard definition JSON exported from {{site.konnect_short_name}} as the `definition` value. 
The field accepts that API-shaped object either inline or loaded from a JSON/YAML file with `!file`; `kongctl` sends the parsed object as the dashboard definition without translating it to another schema. 
`!file` is preferred for larger dashboard definitions.

* [Custom dashboards](/custom-dashboards/)
* [API specification](/api/konnect/analytics-dashboards/)
* [Examples](https://github.com/Kong/kongctl/tree/main/docs/examples/declarative/analytics/dashboards/dashboard.yaml)

```yaml
analytics:
  dashboards:
    - ref: string
      name: string required
      definition: object required # prefer: !file ./definitions/dashboard.json
        tiles: array[object] required
        preset_filters: array[object]
      labels: object [string]string
        key: value
```

When the exported JSON includes the full API response, use `#definition` to extract the payload expected by the dashboard API:

```yaml
analytics:
  dashboards:
    - ref: traffic-summary
      name: Traffic Summary
      definition: !file ./exports/traffic-summary.json#definition
```

## Control planes

`control_planes` are {{site.base_gateway}} resources.
For {{site.event_gateway_short}} control planes, see [{{site.event_gateway_short}}s](#event-gateways).

* [API specification](/api/konnect/control-planes/#/operations/create-control-plane)
* [Examples](https://github.com/Kong/kongctl/tree/main/docs/examples/declarative/control-plane/control-plane.yaml)

```yaml
control_planes:
 - ref: string
   name: string required
   description: string
   cluster_type: >-
     One of (CLUSTER_TYPE_CONTROL_PLANE |
     CLUSTER_TYPE_K8S_INGRESS_CONTROLLER |
     CLUSTER_TYPE_CONTROL_PLANE_GROUP |
     CLUSTER_TYPE_SERVERLESS |
     CLUSTER_TYPE_SERVERLESS_V1)
   auth_type: One of (pinned_client_certs | pki_client_certs)
   cloud_gateway: boolean
   proxy_urls: array[object]
     - host: string required
       port: integer required
       protocol: string required
   labels: object [string]string
     key: value
   _deck:
     files: array[string]
     flags: array[string]
   _external:
     selector:
       matchFields:
         name: string
     requires:
       deck: boolean
   gateway_services:
     - ref: string
       # _external only, Kong Gateway resources are managed by deck
       _external:
         selector:
           matchFields:
             name: string
   # API: create-dataplane-certificate
   data_plane_certificates:
     - ref: string
       cert: string required # prefer: !file ./certs/data-plane.pem
```

Control plane data plane certificates can also be declared as root resources.
The certificate contents identify a certificate within its control plane when a certificate ID is not available. 
The `cert` field supports `!file` and `!env`.

```yaml
control_plane_data_plane_certificates:
 - ref: string
   control_plane: string required # control plane ref
   cert: string required # prefer: !file ./certs/data-plane.pem
```

## {{site.event_gateway_short}}s

* [API specification](/api/konnect/event-gateway/v1/#/operations/create-event-gateway)
* [Examples](https://github.com/Kong/kongctl/tree/main/docs/examples/declarative/event-gateway)

```yaml
event_gateways:
 - ref: string
   name: string required (1-255 chars)
   description: string (max 512 chars)
   min_runtime_version: string (pattern: ^\d+\.\d+$)
   labels: object [string]string
     key: value
   backend_clusters: # /api/konnect/event-gateway/v1/#/operations/create-event-gateway-backend-cluster
     - ref: string
       name: string required (1-255 chars)
       description: string (max 512 chars)
       authentication: object required
         type: One of (anonymous | sasl_plain | sasl_scram) required
         username: string # required for sasl_plain/sasl_scram
         password: string # required for sasl_plain/sasl_scram
         algorithm: One of (sha256 | sha512) # required for sasl_scram
       insecure_allow_anonymous_virtual_cluster_auth: boolean
       bootstrap_servers: array[string] required (address:port)
       tls: object required
         enabled: boolean required
         insecure_skip_verify: boolean
         ca_bundle: string
         tls_versions: array[One of (tls12 | tls13)]
         client_identity: object # requires min_runtime_version: "1.1"
           certificate: string required
           key: string required
       metadata_update_interval_seconds: integer (1-43200)
       labels: object [string]string
         key: value
   virtual_clusters: # /api/konnect/event-gateway/v1/#/operations/create-event-gateway-virtual-cluster
     - ref: string
       name: string required (1-255 chars)
       description: string (max 512 chars)
       destination: object required
         id: string (uuid) # oneOf; declarative: prefer !ref <backend-cluster-ref>
         name: string # oneOf
       authentication: array[object] required (min 1 item)
         - type: One of (anonymous | sasl_plain | sasl_scram | oauth_bearer | client_certificate) required
           mediation: One of (passthrough | terminate) # required for sasl_plain; One of (passthrough | validate_forward | terminate) for oauth_bearer
           principals: array[object] # for sasl_plain terminate mode
             - username: string required
               password: string required
           algorithm: One of (sha256 | sha512) # required for sasl_scram
           claims_mapping: object # for oauth_bearer
             sub: string
             scope: string
           jwks: object # for oauth_bearer
             endpoint: string (uri) required
             timeout: string (default: 10s)
             cache_expiration: string (default: 1h)
           validate: object # for oauth_bearer
             audiences: array[object] (min 1 item)
               - name: string required
             issuer: string
           # client_certificate requires no additional fields; requires min_runtime_version: "1.1"
       namespace:
         mode: One of (hide_prefix | enforce_prefix) required
         prefix: string required
         additional:
           topics: array[object]
             - type: One of (glob | exact_list) required
               glob: string # if type=glob
               conflict: One of (warn | ignore) # if type=glob or exact_list
               exact_list: array[object] (min 1 item) # if type=exact_list
                 - backend: string required
           consumer_groups: array[object]
             - type: One of (glob | exact_list) required
               glob: string # if type=glob
               exact_list: array[object] (min 1 item) # if type=exact_list
                 - value: string required
       acl_mode: One of (enforce_on_gateway | passthrough) required
       dns_label: string required (1-63 chars, RFC1035 label)
       labels: object [string]string
         key: value
       cluster_policies: # /api/konnect/event-gateway/v1/#/operations/create-event-gateway-virtual-cluster-cluster-level-policy
         - ref: string
           type: acls required
           name: string (1-255 chars)
           description: string (max 512 chars)
           enabled: boolean
           labels: object [string]string
             key: value
           config: object required
             rules: array[object] required (min 1 item)
               - resource_type: One of (topic | group | transactional_id | cluster) required
                 action: One of (allow | deny) required
                 operations: array[object] required
                   - name: One of (all | alter | alter_configs | create | delete | describe | describe_configs | idempotent_write | read | write) required
                 resource_names: array[object] required (max 50 items)
                   - match: string required # glob pattern; * matches any characters
           condition: string (boolean expression, max 1000 chars)
       produce_policies: # /api/konnect/event-gateway/v1/#/operations/create-event-gateway-virtual-cluster-produce-policy
         - ref: string
           type: One of (modify_headers | schema_validation | encrypt) required
           name: string (1-255 chars)
           description: string (max 512 chars)
           enabled: boolean
           labels: object [string]string
             key: value
           config: object required
             actions: array[object] required (min 1 item) # if type=modify_headers
               - op: One of (remove | set) required
                 key: string required
                 value: string # required if op=set
             type: One of (confluent_schema_registry | json) required # if type=schema_validation
             schema_registry: object # if type=schema_validation; oneOf id or name
               id: string (uuid) # declarative: prefer !ref <schema-registry-ref>
               name: string
             key_validation_action: One of (reject | mark) # if type=schema_validation
             value_validation_action: One of (reject | mark) # if type=schema_validation
             failure_mode: One of (error | passthrough) required # if type=encrypt
             part_of_record: array[One of (key | value)] required (min 1 item) # if type=encrypt
             encryption_key: object required # if type=encrypt
               type: One of (aws | static) required
               arn: string # required if type=aws; AWS KMS key ARN (pattern: ^arn:aws:kms:.+)
               key: object # required if type=static; declarative: prefer !ref <static-key-ref>
                 id: string (uuid) # oneOf
                 name: string # oneOf
           condition: string (boolean expression, max 1000 chars)
           parent_policy_id: string (uuid) # for child policies under schema_validation
       consume_policies: # /api/konnect/event-gateway/v1/#/operations/create-event-gateway-virtual-cluster-consume-policy
         - ref: string
           type: One of (schema_validation | modify_headers | skip_record | decrypt) required
           name: string (1-255 chars)
           description: string (max 512 chars)
           enabled: boolean
           labels: object [string]string
             key: value
           config: object required
             type: One of (confluent_schema_registry | json) required # if type=schema_validation
             schema_registry: object # if type=schema_validation; oneOf id or name
               id: string (uuid) # declarative: prefer !ref <schema-registry-ref>
               name: string
             key_validation_action: One of (mark | skip) # if type=schema_validation
             value_validation_action: One of (mark | skip) # if type=schema_validation
             actions: array[object] required (min 1 item) # if type=modify_headers
               - op: One of (remove | set) required
                 key: string required
                 value: string # required if op=set
             failure_mode: One of (error | skip | passthrough | mark) required # if type=decrypt
             key_sources: array[object] required (min 1 item) # if type=decrypt
               - type: One of (aws | static) required
             part_of_record: array[One of (key | value)] required (min 1 item) # if type=decrypt
           condition: string (boolean expression, max 1000 chars)
           parent_policy_id: string (uuid) # for child policies under schema_validation
   listeners: # /api/konnect/event-gateway/v1/#/operations/create-event-gateway-listener
     - ref: string
       name: string required (1-255 chars)
       description: string (max 512 chars)
       addresses: array[string] required (min 1 item)
       ports: array[integer|string] required (min 1 item)
       labels: object [string]string
         key: value
       policies: # /api/konnect/event-gateway/v1/#/operations/create-event-gateway-listener-policy
         - ref: string
           type: One of (tls_server | forward_to_virtual_cluster) required
           name: string
           description: string
           enabled: boolean
           labels: object [string]string
             key: value
           config: object required
             certificates: array[object] required (min 1, max 1 item) # if type=tls_server
               - certificate: string required
                 key: string required
             versions: object # if type=tls_server
               min: One of (TLSv1.2 | TLSv1.3)
               max: One of (TLSv1.2 | TLSv1.3)
             allow_plaintext: boolean # if type=tls_server
             client_authentication: object # if type=tls_server; requires min_runtime_version: "1.1"
               mode: One of (required | requested) required
               tls_trust_bundles: array[object] required (min 1 item)
                 - id: string (uuid) # oneOf; declarative: prefer !ref <tls-trust-bundle-ref>
                   name: string # oneOf
               principal_mapping: string # expression; requires min_runtime_version: "1.1"
             type: One of (sni | port_mapping) required # if type=forward_to_virtual_cluster
             sni_suffix: string # if config.type=sni
             advertised_port: integer # if config.type=sni
             broker_host_format: object # if config.type=sni; requires min_runtime_version: "1.1"
               type: One of (per_cluster_suffix | shared_suffix) required
             destination: object required # if config.type=port_mapping; oneOf id or name
               id: string (uuid) # declarative: prefer !ref <virtual-cluster-ref>
               name: string
             advertised_host: string required # if config.type=port_mapping
             bootstrap_port: One of (none | at_start) # if config.type=port_mapping
             min_broker_id: integer # if config.type=port_mapping
   data_plane_certificates: # /api/konnect/event-gateway/v1/#/operations/create-event-gateway-data-plane-certificate
     - ref: string
       name: string (1-255 chars)
       description: string (max 512 chars)
       certificate: string required # PEM-encoded certificate; prefer: !file ./certs/data-plane.pem
   schema_registries: # /api/konnect/event-gateway/v1/#/operations/create-event-gateway-schema-registry
     - ref: string
       type: confluent required
       name: string required (1-255 chars)
       description: string (max 512 chars)
       labels: object [string]string
         key: value
       config: object required
         schema_type: One of (avro | json) required
         endpoint: string (uri) required
         timeout_seconds: integer (min 1, default 10)
         authentication: object
           type: basic required
           username: string required
           password: string required
   static_keys: # /api/konnect/event-gateway/v1/#/operations/create-event-gateway-static-key
     - ref: string
       name: string required (1-255 chars)
       description: string (max 512 chars)
       labels: object [string]string
         key: value
       value: string required # sensitive; prefer: !env SECRET_KEY
   tls_trust_bundles: # /api/konnect/event-gateway/v1/#/operations/create-event-gateway-tls-trust-bundle; requires min_runtime_version: "1.1"
     - ref: string
       name: string required (1-255 chars)
       description: string (max 512 chars)
       labels: object [string]string
         key: value
       config: object required
         trusted_ca: string required # PEM-encoded CA certificates; prefer: !file ./certs/ca.pem

```
{:.collapsible}

## Organization

* [API specification](/api/konnect/identity/v3/#/)
* [Examples](https://github.com/Kong/kongctl/tree/main/docs/examples/declarative/organization/)

```yaml
organization:
 teams:
   # /api/konnect/identity/v3/#/operations/create-team
   - ref: string
     name: string required
     description: string (max 250 chars)
     labels: object [string]string
       key: value
     roles:
       - ref: string
         role_name: string
         # Prefer: !ref <api-ref> when entity_type_name=APIs.
         entity_id: string (uuid)
         entity_type_name: string
         entity_region: One of (us | eu | au | me | in | sg | *)
```

Organization team roles can also be declared as root resources.

```yaml
organization_team_roles:
  - ref: string
    # Declarative organization team ref, not team name or UUID.
    team: string required
    role_name: string
    # Prefer: !ref <api-ref> when entity_type_name=APIs.
    entity_id: string (uuid)
    entity_type_name: string
    entity_region: One of (us | eu | au | me | in | sg | *)
```

## Portals

* [API specification](/api/konnect/portal-management/v3/#/operations/create-portal)
* [Examples](https://github.com/Kong/kongctl/tree/main/docs/examples/declarative/portal/portal.yaml)

```yaml
portals:
 - ref: string
   name: string required (1-255 chars)
   display_name: string (1-255 chars)
   description: string (max 512 chars, nullable)
   authentication_enabled: boolean (default: true)
   rbac_enabled: boolean (default: false)
   default_api_visibility: One of (public | private)
   default_page_visibility: One of (public | private)
   default_application_auth_strategy_id: string (uuid, nullable) # prefer: !ref <app-auth-strategy-ref>
   auto_approve_developers: boolean (default: false)
   auto_approve_applications: boolean (default: false)
   labels: object [string]string
     key: value
   customization: # /api/konnect/portal-management/v3/#/operations/replace-portal-customization
     ref: string
     theme:
       name: string
       mode: One of (light | dark | system)
       colors:
         primary: string (hex color, for example #0055A4)
     layout: string
     css: string (nullable)
     menu:
       main: array[PortalMenuItem]
       footer_sections: array[PortalFooterMenuSection]
       footer_bottom: array[PortalMenuItem]
     spec_renderer:
       try_it_ui: boolean
       try_it_insomnia: boolean
       infinite_scroll: boolean
       show_schemas: boolean
       hide_internal: boolean
       hide_deprecated: boolean
       allow_custom_server_urls: boolean
     robots: string (nullable)
   auth_settings: # /api/konnect/portal-management/v3/#/operations/update-portal-authentication-settings
     ref: string
     # OIDC and SAML provider-specific fields are no longer supported here.
     # Move provider config to identity_providers or portal_identity_providers.
     basic_auth_enabled: boolean
     konnect_mapping_enabled: boolean
     idp_mapping_enabled: boolean
   ip_allow_list: # /api/konnect/portal-management/v3/#/operations/create-portal-ip-allow-list
     ref: string
     allowed_ips: array[string] required # IP addresses or CIDR blocks
   integrations: # /api/konnect/portal-management/v3/#/operations/upsert-portal-integrations
     ref: string
     google_tag_manager:
       enabled: boolean required
       type: tracking
       config_data:
         id: string required (pattern: ^GTM-[A-Za-z0-9]+$)
         l: string (nullable)
         preview: string (nullable)
         cookies_win: boolean (nullable)
         debug: boolean (nullable)
         npa: boolean (nullable)
         data_layer: string (nullable)
         env_name: string (nullable)
         auth_referrer_policy: string (nullable)
     google_analytics_4:
       enabled: boolean required
       type: analytics
       config_data:
         id: string required (pattern: ^G-[A-Za-z0-9-]+$)
         l: string (nullable)
   identity_providers: # /api/konnect/portal-management/v3/#/operations/create-portal-identity-provider
     - ref: string
       # Use this child for portal OIDC and SAML provider configuration.
       # At the root of a config, use portal_identity_providers.
       type: One of (oidc | saml) required
       enabled: boolean
       config: object required
         issuer_url: string # OIDC
         client_id: string # OIDC
         client_secret: string # OIDC
         scopes: array[string] # OIDC
         claim_mappings: # OIDC
           name: string
           email: string
           groups: string
         idp_metadata_url: string # SAML
         idp_metadata_xml: string # SAML
   custom_domain: # /api/konnect/portal-management/v3/#/operations/create-portal-custom-domain
     ref: string
     hostname: string required
     enabled: boolean required
     ssl: object required
       domain_verification_method: One of (http | custom_certificate) required
       custom_certificate: string # when domain_verification_method=custom_certificate
       custom_private_key: string # when domain_verification_method=custom_certificate
       skip_ca_check: boolean
   pages: # /api/konnect/portal-management/v3/#/operations/create-portal-page
     - ref: string
       slug: string required (max 512 chars)
       content: string required (markdown) # prefer: !file ./docs/page.md
       title: string (max 512 chars)
       visibility: One of (public | private)
       status: One of (published | unpublished)
       description: string (max 160 chars)
       parent_page_id: string (uuid, nullable) # prefer: !ref <page-ref>
       children:
         - ref: string
           slug: string required (max 512 chars)
           content: string required (markdown) # prefer: !file ./docs/page.md
           title: string (max 512 chars)
           visibility: One of (public | private)
           status: One of (published | unpublished)
           description: string (max 160 chars)
           parent_page_id: string (uuid, nullable) # prefer: !ref <page-ref>
   snippets: # /api/konnect/portal-management/v3/#/operations/create-portal-snippet
     - ref: string
       name: string required (max 512 chars)
       content: string required (markdown) # prefer: !file ./docs/snippet.md
       title: string (max 512 chars)
       visibility: One of (public | private)
       status: One of (published | unpublished)
       description: string (max 160 chars)
   teams: # /api/konnect/portal-management/v3/#/operations/create-portal-team
     - ref: string
       name: string required
       description: string (max 250 chars)
       roles: # /api/konnect/portal-management/v3/#/operations/assign-role-to-portal-teams
         - ref: string
           role_name: string
           entity_id: string (uuid)
           entity_type_name: string
           entity_region: One of (us | eu | au | me | in | sg | *)
   email_config: # /api/konnect/portal-management/v3/#/operations/create-portal-email-config
     ref: string
     domain_name: string (nullable)
     from_name: string (nullable)
     from_email: string (email, nullable)
     reply_to_email: string (email, nullable)
   audit_log_webhook: # /api/konnect/portal-management/v3/#/operations/update-portal-audit-log-webhook
     ref: string
     enabled: boolean
     audit_log_destination_id: string (uuid) # prefer: !ref
   email_templates: # /api/konnect/portal-management/v3/#/operations/update-portal-custom-email-template
     <template_name>:
       ref: string
       name: string
       enabled: boolean
       content:
         subject: string (max 1024 chars, nullable)
         title: string (max 1024 chars, nullable)
         body: string (max 4096 chars, nullable)
         button_label: string (max 128 chars, nullable)
   assets:
     logo: string # data URL image (png/jpeg/gif/ico/svg)
     favicon: string # data URL image (png/jpeg/gif/ico/svg)
```
{:.collapsible}

Portal identity providers and integrations can also be declared as root
resources.

```yaml
portal_identity_providers:
 - ref: string
   portal: string required # prefer: !ref <portal-ref>
   type: One of (oidc | saml) required
   enabled: boolean
   config: object required
     issuer_url: string # OIDC
     client_id: string # OIDC
     client_secret: string # OIDC
     scopes: array[string] # OIDC
     claim_mappings: # OIDC
       name: string
       email: string
       groups: string
     idp_metadata_url: string # SAML
     idp_metadata_xml: string # SAML

portal_integrations:
 - ref: string
   portal: string required # prefer: !ref <portal-ref>
   google_tag_manager:
     enabled: boolean required
     type: tracking
     config_data:
       id: string required (pattern: ^GTM-[A-Za-z0-9]+$)
       l: string (nullable)
       preview: string (nullable)
       cookies_win: boolean (nullable)
       debug: boolean (nullable)
       npa: boolean (nullable)
       data_layer: string (nullable)
       env_name: string (nullable)
       auth_referrer_policy: string (nullable)
   google_analytics_4:
     enabled: boolean required
     type: analytics
     config_data:
       id: string required (pattern: ^G-[A-Za-z0-9-]+$)
       l: string (nullable)
```

Portal IP allow lists can also be declared as root resources.

```yaml
portal_ip_allow_lists:
  - ref: string
    portal: string required # prefer: !ref <portal-ref>
    allowed_ips: array[string] required # IP addresses or CIDR blocks
```

In sync mode, omitted `ip_allow_list` configuration is ignored. Include the
`ip_allow_list` block when the portal IP allow list is owned by the config.

Portal audit-log webhooks can also be declared as root resources.

```yaml
portal_audit_log_webhooks:
  - ref: string
    portal: string required # prefer: !ref <portal-ref>
    enabled: boolean
    audit_log_destination_id: string (uuid) # prefer: !ref
```

In sync mode, omitted `audit_log_webhook` configuration is ignored. Include the
`audit_log_webhook` block when the portal webhook is owned by the config.

```yaml
portals:
  - ref: docs-portal
    name: Docs Portal
    audit_log_webhook:
      ref: docs-portal-audit-log-webhook
      enabled: true
      audit_log_destination_id: !ref foo

audit-logs:
  destinations:
    - ref: foo
      _external:
        selector:
          matchFields:
            name: foo
```
