---
title: Supported resources
content_type: reference
description: Resources that kongctl can manage declaratively in Kong Konnect.
products:
  - konnect
tools:
  - kongctl
works_on:
  - konnect
tags:
  - declarative-config
breadcrumbs:
  - /kongctl/
  - /kongctl/reference/
---

kongctl currently supports declarative management of these {{site.konnect_short_name}} resource types.

{:.note}
> **Note**: kongctl is in Tech Preview. Resource support is actively expanding. Check the [GitHub releases](https://github.com/kong/kongctl/releases/) for the latest supported resources.

## APIs

Manage API specifications, versions, and publications.

### Resource kind

```yaml
apiVersion: v1
kind: API
```

### Example

```yaml
apiVersion: v1
kind: API
metadata:
  name: users-api
spec:
  displayName: "Users API"
  description: "User management REST API"
  version: "1.0.0"
  labels:
    team: platform
    environment: production
```

### Supported fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Unique API identifier |
| `displayName` | string | Yes | Human-readable name |
| `description` | string | No | API description |
| `version` | string | No | API version |
| `labels` | object | No | Key-value labels for organization |

### Imperative commands

```bash
kongctl get apis
kongctl get api users-api
kongctl create api users-api --display-name "Users API"
kongctl delete api users-api
```

## Portals

Manage Developer Portals for API documentation.

### Resource kind

```yaml
apiVersion: v1
kind: Portal
```

### Example

```yaml
apiVersion: v1
kind: Portal
metadata:
  name: developer-portal
spec:
  displayName: "Developer Portal"
  description: "API documentation for external developers"
  isPublic: true
  customDomain: "developers.example.com"
  theme:
    primaryColor: "#1E40AF"
    logo: "https://example.com/logo.png"
```

### Supported fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Unique portal identifier |
| `displayName` | string | Yes | Human-readable name |
| `description` | string | No | Portal description |
| `isPublic` | boolean | No | Public accessibility (default: false) |
| `customDomain` | string | No | Custom domain for the portal |
| `theme` | object | No | Theming configuration |

### Imperative commands

```bash
kongctl get portals
kongctl get portal developer-portal
kongctl create portal developer-portal --display-name "Developer Portal"
kongctl delete portal developer-portal
```

## Application Auth Strategies

Manage authentication strategies for application developers.

### Resource kind

```yaml
apiVersion: v1
kind: ApplicationAuthStrategy
```

### Example

```yaml
apiVersion: v1
kind: ApplicationAuthStrategy
metadata:
  name: oauth2-strategy
spec:
  displayName: "OAuth 2.0 Authentication"
  authType: oauth2
  config:
    tokenEndpoint: "https://auth.example.com/token"
    authEndpoint: "https://auth.example.com/authorize"
  scopes:
    - read:apis
    - write:apis
```

### Supported fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Unique strategy identifier |
| `displayName` | string | Yes | Human-readable name |
| `authType` | string | Yes | Authentication type (e.g., `oauth2`, `key-auth`) |
| `config` | object | No | Type-specific configuration |
| `scopes` | array | No | Available OAuth scopes |

### Imperative commands

```bash
kongctl get auth-strategies
kongctl get auth-strategy oauth2-strategy
```

## Control Planes

Manage {{site.base_gateway}} control planes.

### Resource kind

```yaml
apiVersion: v1
kind: ControlPlane
```

### Example

```yaml
apiVersion: v1
kind: ControlPlane
metadata:
  name: production-cp
spec:
  displayName: "Production Control Plane"
  description: "Production gateway environment"
  clusterType: control_plane
  labels:
    environment: production
    region: us-east
```

### Supported fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Unique control plane identifier |
| `displayName` | string | Yes | Human-readable name |
| `description` | string | No | Control plane description |
| `clusterType` | string | Yes | Cluster type (e.g., `control_plane`) |
| `labels` | object | No | Key-value labels |

### Imperative commands

```bash
kongctl get control-planes
kongctl get control-plane production-cp
```

## Gateway Services

Manage gateway service configuration within control planes.

### Resource kind

```yaml
apiVersion: v1
kind: GatewayService
```

### Example

```yaml
apiVersion: v1
kind: GatewayService
metadata:
  name: users-service
  controlPlane: production-cp
spec:
  name: "users-service"
  url: "http://users.internal:8080"
  protocol: http
  port: 8080
  retries: 5
  connectTimeout: 60000
  writeTimeout: 60000
  readTimeout: 60000
```

### Supported fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Service name |
| `controlPlane` | string | Yes | Control plane this service belongs to |
| `url` | string | Yes | Upstream URL |
| `protocol` | string | No | Protocol (http, https, grpc, grpcs) |
| `port` | integer | No | Upstream port |
| `retries` | integer | No | Number of retry attempts |
| `*Timeout` | integer | No | Timeout values in milliseconds |

### Imperative commands

```bash
kongctl get services --control-plane production-cp
kongctl get service users-service --control-plane production-cp
```

## Planned resources

Future releases will add support for:

* **Routes**: Gateway routing configuration
* **Plugins**: Plugin configuration
* **Consumers**: API consumers and credentials
* **Certificates**: TLS certificates
* **SNIs**: Server Name Indication configuration
* **Upstreams**: Load balancing configuration
* **Targets**: Upstream targets
* **Vaults**: Secrets management

Check the [GitHub roadmap](https://github.com/kong/kongctl/issues) for planned features.

## Resource relationships

Some resources reference others:

```yaml
# Gateway Service references a Control Plane
apiVersion: v1
kind: GatewayService
metadata:
  name: my-service
  controlPlane: production-cp  # References ControlPlane
spec:
  url: "http://api.internal"
```

When using `sync`, kongctl respects dependencies:
1. Creates Control Planes first
2. Then creates Services within them
3. Deletes in reverse order

## Limitations

### Tech Preview restrictions

* Resource types are limited compared to full {{site.konnect_short_name}} API
* Some fields may not be supported yet
* Breaking changes possible in future versions

### Namespace scope

Some resources are organization-wide (APIs, Portals) while others are scoped to control planes (Gateway Services).

### Deletion protection

kongctl does not delete resources that have dependencies. Resolve dependencies first:

```bash
# ❌ Fails: Control plane has services
kongctl delete control-plane production-cp

# ✅ Delete services first
kongctl delete service users-service --control-plane production-cp
kongctl delete control-plane production-cp
```

## Related resources

* [Declarative configuration guide](/kongctl/declarative/)
* [Command reference](/kongctl/commands/)
* [Get started with kongctl](/kongctl/get-started/)
* [{{site.konnect_short_name}} API reference](/konnect-api/)
