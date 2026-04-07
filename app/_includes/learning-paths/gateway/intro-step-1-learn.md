## What is {{site.base_gateway}}?

{{site.base_gateway}} is a lightweight, fast, and flexible cloud-native API gateway. It sits in front of your upstream services and acts as the single entry point for client requests, enforcing policies through a plugin system.

## Key concepts

### Service

A **Service** is an abstraction of your upstream API or microservice. It holds the connection details — host, port, path, and protocol — that {{site.base_gateway}} uses to forward requests. Each Service can have multiple Routes.

### Route

A **Route** defines the matching rules — paths, hosts, methods, headers — that determine which incoming requests are forwarded to a given Service. A single Service can have many Routes, each capturing a different subset of traffic.

### Consumer

A **Consumer** represents a client of your API. Consumers can be issued credentials (API keys, JWTs, OAuth tokens) and have plugins applied specifically to them, enabling per-client policies.

## Request lifecycle

When a request arrives at {{site.base_gateway}}:

1. **Router** — Matches the request against all configured Routes.
2. **Plugin chain (access phase)** — Runs plugins attached to the matched Route, its Service, and any identified Consumer.
3. **Upstream proxy** — Forwards the request to the upstream Service.
4. **Plugin chain (response phase)** — Runs plugins on the upstream response before returning it to the client.

## Deployment modes

{{site.base_gateway}} supports three main topologies:

- **DB-less** — Configuration is provided declaratively via a YAML/JSON file. No database required. Ideal for Kubernetes and immutable infrastructure.
- **Traditional (with database)** — Configuration is stored in PostgreSQL and updated live through the Admin API.
- **Hybrid** — A control plane (with database) pushes configuration to stateless data plane nodes, separating management and traffic planes.

## Further reading

- [{{site.base_gateway}} overview](/gateway/)
- [Services entity reference](/gateway/entities/services/)
- [Routes entity reference](/gateway/entities/routes/)
- [Deployment topologies](/gateway/deployment-topologies/)
