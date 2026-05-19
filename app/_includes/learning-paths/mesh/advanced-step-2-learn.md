`MeshPassthrough` allowlists external destinations. That's enough when the dependency is one of 50 SaaS APIs your platform talks to occasionally. It's _not_ enough when the dependency is a critical part of every checkout — AeroPay's payment API, Kong Air's primary flight-database, the corporate identity provider. For those, you want them to feel like internal services: friendly names, mesh observability, mesh-managed TLS, and the same resilience policies you'd apply to any internal `MeshService`.

That's `MeshExternalService`.

### What `MeshExternalService` gives you that allowlisting doesn't

| Capability | `MeshPassthrough` (allowlist) | `MeshExternalService` (first-class) |
| --- | --- | --- |
| **Friendly hostname** | No — use the external URL | Yes — `aeropay.ext.kongair.com` |
| **Per-service metrics** | Aggregated under egress | Distinct, like an internal service |
| **Tracing context** | Carried but the service is opaque | Full span with service identity |
| **mTLS / TLS origination** | The application configures it | The sidecar handles it |
| **Resilience policies** | Not targetable | Targetable by `MeshRetry`, `MeshTimeout`, `MeshCircuitBreaker`, … |
| **DNS** | Resolved by the OS | Resolved by mesh DNS |

The trade-off is more setup per dependency. So you reserve `MeshExternalService` for the dependencies that justify it — critical, frequently-called, or anywhere you want resilience policies attached.

### The two-resource model: `HostnameGenerator` + `MeshExternalService`

A `MeshExternalService` defines what the external endpoint is. A `HostnameGenerator` defines how its name gets exposed inside the mesh. They're separate so you can centralize the naming convention once and reuse it across every external dependency.

#### `HostnameGenerator`: platform-team territory

A `HostnameGenerator` is an _infrastructure-level_ resource. It's the policy that says "every `MeshExternalService` tagged like this gets a hostname under the `*.ext.kongair.com` namespace." Defining this is the **platform team's** responsibility — the same team that owns `MeshIdentity` and the system namespace. It's not something application teams (or even the security team) should be writing one-off.

```yaml
apiVersion: kuma.io/v1alpha1
kind: HostnameGenerator
metadata:
  name: external-services
  namespace: kong-mesh-system
spec:
  template: '{% raw %}{{ .DisplayName }}{% endraw %}.ext.kongair.com'
  selector:
    meshExternalService:
      matchLabels:
        kuma.io/origin: zone
```

The `template` field uses Go-template variables; `.DisplayName` is the `MeshExternalService`'s metadata name. So a `MeshExternalService` named `aeropay-api` becomes `aeropay-api.ext.kongair.com`. The selector controls which `MeshExternalService`s the generator applies to — here, anything tagged zone-origin.

#### `MeshExternalService`: application-team or platform-team

The `MeshExternalService` itself is owned by whichever team owns the calling workload. It declares the external endpoint, the expected protocol, and (optionally) TLS settings.

### Three shapes worth knowing

#### Plain TCP — the flight database

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshExternalService
metadata:
  name: flight-db
  namespace: kong-air-production
spec:
  match:
    type: HostnameGenerator
    port: 5432
    protocol: tcp
  endpoints:
    - address: rds-instance-01.c7x2.us-east-1.rds.amazonaws.com
      port: 5432
```

Application code uses the standard PostgreSQL driver against `flight-db.ext.kongair.com:5432`. The sidecar intercepts that, looks up the `MeshExternalService`, and forwards to the AWS RDS endpoint.

#### HTTPS with TLS origination — AeroPay

The application doesn't manage AeroPay's certs. It calls **plain HTTP** at the mesh-internal hostname; the sidecar **originates TLS** to the upstream:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshExternalService
metadata:
  name: aeropay-api
  namespace: kong-air-production
spec:
  match:
    type: HostnameGenerator
    port: 80                       # The PORT the app calls
    protocol: http
  endpoints:
    - address: api.aeropay.com
      port: 443                    # The PORT the sidecar connects to
  tls:
    enabled: true
    verification:
      mode: Secured                # Verify the upstream's cert
      serverName: api.aeropay.com
```

Two things to notice:

1. **`port` in `match` and `port` in `endpoints` are different.** The application calls `aeropay-api.ext.kongair.com:80` (HTTP); the sidecar upgrades that to HTTPS:443 on the way out.
2. **`verification.mode: Secured`** means the sidecar validates AeroPay's certificate against the system trust store. Use `serverName` to match the SNI / CN. Set `mode: Skip` if you absolutely must call a self-signed external endpoint, but recognise the security implication.

#### gRPC (rare but useful)

Same shape as HTTPS but with `protocol: grpc` in `match`. Lets you apply `MeshHTTPRoute` for path-based routing against external gRPC APIs.

### Adding resilience: use `MeshRetry`, not `MeshHTTPRoute` filters

This is the one part of the `MeshExternalService` flow that's easy to get wrong. Retries against external services use the **`MeshRetry`** policy, not a `MeshHTTPRoute` with a `RequestRetry` filter.

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshRetry
metadata:
  name: aeropay-retry
  namespace: kong-air-production
spec:
  targetRef:
    kind: MeshService
    name: booking-svc
  to:
    - targetRef:
        kind: MeshExternalService
        name: aeropay-api
      default:
        http:
          numRetries: 3
          backOff:
            baseInterval: 100ms
            maxInterval: 1s
          retryOn:
            - 5xx
            - retriable-status-codes
            - connect-failure
```

A `MeshHTTPRoute` filter named `RequestRetry` _does not exist_ in this shape. Documentation in the wild that suggests applying retry filters at the route level is incorrect — `MeshRetry` is the supported and correct resource.

Pair it with `MeshTimeout` for an upper-bound on the whole call, and `MeshCircuitBreaker` to stop hammering AeroPay if they're plainly down:

```yaml
spec:
  targetRef:
    kind: MeshService
    name: booking-svc
  to:
    - targetRef:
        kind: MeshExternalService
        name: aeropay-api
      default:
        http:
          requestTimeout: 5s
```

### Visibility you get for free

Because `MeshExternalService` is a first-class resource, every standard observability piece you set up in the previous path applies to it. The Service Map dashboard shows `aeropay-api` as a node with its own RED metrics. Traces traverse the external hop with proper service decoration. Access logs distinguish between internal-internal and internal-external calls.

### Further reading

- [`MeshExternalService` reference](/mesh/policies/meshexternalservice/)
- [`HostnameGenerator` reference](/mesh/policies/hostnamegenerator/)
- [`MeshRetry` reference](/mesh/policies/meshretry/)
- [`MeshTimeout` reference](/mesh/policies/meshtimeout/)
- [`MeshCircuitBreaker` reference](/mesh/policies/meshcircuitbreaker/)
