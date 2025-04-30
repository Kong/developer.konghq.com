---
title: Fallback configuration

description: |
  Prevent {{ site.kic_product_name }} lock-ups when bad configuration is accidentally introduced to your k8s cluster
content_type: reference
layout: reference

products:
  - kic

works_on:
  - on-prem
  - konnect
min_version:
  kic: '3.2'

related_resources:
  - text: "How-To: Backfill broken configuration"
    url: /kubernetes-ingress-controller/fallback-configuration/backfill/
  - text: "How-To: Exclude broken configuration"
    url: /kubernetes-ingress-controller/fallback-configuration/exclude/
  - text: Last Known Good Config
    url: /kubernetes-ingress-controller/last-known-good-config/

---

{{site.kic_product_name}} 3.2.0 introduced the Fallback Configuration feature. It is designed to isolate issues related to individual parts of the configuration, allowing updates to the rest of it to proceed with no interruption. If you're using {{site.kic_product_name}} in a multi-team environment, the fallback configuration mechanism can help you avoid lock-ups when one team's
configuration is broken.

{:.info}
> **Note:** Fallback Configuration is an opt-in feature. You must enable it by setting `FallbackConfiguration=true` in the controller's feature gates configuration. See [Feature Gates](/kubernetes-ingress-controller/reference/feature-gates) to learn how to do that.

## How fallback configuration works

{{site.kic_product_name}} translates Kubernetes objects it gets from the Kubernetes API and pushes the translation result via {{site.base_gateway}}’s Admin API to {{site.base_gateway}} instances. However, issues can arise at various stages of this process:

1. Admission Webhook: Validates individual Kubernetes objects against schemas and basic rules.
2. Translation Process: Detects issues like cross-object validation errors.
3. {{site.base_gateway}} Response: {{site.base_gateway}} rejects the configuration and returns an error associated with a specific object.

Fallback Configuration is triggered when an issue is detected in the 3rd stage and provides the following benefits:
- Allows unaffected objects to be updated even when there are configuration errors.
- Automatically builds a fallback configuration that {{site.base_gateway}} will accept without requiring user intervention by
  either:
  - Excluding the broken objects along with its dependants.
  - Backfilling the broken object along with its dependants using the last valid Kubernetes objects' in-memory cache (if `CONTROLLER_USE_LAST_VALID_CONFIG_FOR_FALLBACK` environment variable is set to `true`).
- Enables users to inspect and identify what objects were excluded from or backfilled in the configuration using
  diagnostic endpoints.

The following table summarizes the behavior of the Fallback Configuration feature based on the configuration:

{% table %}
columns:
  - title: "`FallbackConfiguration` feature gate value"
    key: gate
  - title: "`CONTROLLER_USE_LAST_VALID_CONFIG_FOR_FALLBACK` value"
    key: flag
  - title: Behavior
    key: behavior
rows:
  - gate: "`false`"
    flag: Not applicable
    behavior: "The last valid configuration is used as a whole to recover (if stored)."
  - gate: "`true`"
    flag: "`false`"
    behavior: "The Fallback Configuration is triggered, broken objects and their dependents are excluded."
  - gate: "`true`"
    flag: "`true`"
    behavior: "The Fallback Configuration is triggered, broken objects and their dependents are excluded and backfilled with their last valid version (if stored)."
{% endtable %}


The diagram below illustrates how the Fallback Configuration feature works in detail:

<!--vale off-->
{% mermaid %}
flowchart TD
classDef sub opacity:0
classDef note stroke:#e1bb86,fill:#fdf3d8
classDef externalCall fill:#9e8ebf,stroke:none,color:#ffffff
classDef decision fill:#a6b4c8

    A([Update loop triggered]) --> B[Generate Kubernetes objects' store snapshot to be passed to the Translator]
    B --> C[Translator: generate Kong configuration based on the generated snapshot]
    C --> D(Configure Kong Gateways using generated declarative configuration)
    D --> E{Configuration rejected?}
    E --> |No| G[Store the Kubernetes objects' snapshot to be used as the last valid state]
    E --> |Yes| F[Build a dependency graph of Kubernetes objects - using the snapshot]
    G --> H[Store the declarative configuration to be used as the last valid configuration]
    H --> Z([End of the loop])
    F --> I[Exclude an object along with all its dependants from the fallback Kubernetes objects snapshot]
    I --> J[Add a previous valid version of the object along with its dependants' previous versions to the fallback snapshot]
    J --> K[Translator: generate Kong configuration based on the fallback snapshot]
    K --> L(Configure Kong Gateways using generated fallback declarative configuration)
    L --> M{Fallback
    configuration
    rejected?}
    M --> |Yes| N{Was the last valid configuration preserved?}
    N --> |Yes| O(Configure Kong Gateways using the last valid declarative configuration)
    O --> Z
    N --> |No| Z
    M --> |No| P[Store the fallback Kubernetes objects' snapshot to be used as the last valid state]
    P --> R[Store the fallback declarative configuration to be used as the last valid configuration]
    R --> Z

    subgraph subI [" "]
        I
        noteI[For every invalid object reported by the Gateway]
    end

    subgraph subJ [" "]
        J
        noteJ[Given there was a last valid Kubernetes objects' store snapshot preserved and the object is present]
    end

    class subI,subJ sub
    class noteI,noteJ note
    class D,L,O externalCall
    class E,M,N decision

{% endmermaid %}
<!--vale on-->


### Inspecting the fallback configuration process

Each time {{site.kic_product_name}} successfully applies a fallback configuration, it emits a Kubernetes Event with the `FallbackKongConfigurationSucceeded` reason. It will also emit an Event with the `FallbackKongConfigurationApplyFailed` reason in case the fallback configuration gets rejected by {{site.base_gateway}}. You can monitor these events to track the fallback configuration process.

You can check to see if the Event is emitted by running:

```bash
kubectl get events -A --field-selector='reason=FallbackKongConfigurationSucceeded'
```

The results should look like this:
```text
NAMESPACE   LAST SEEN   TYPE     REASON                               OBJECT                                 MESSAGE
kong        4m26s       Normal   FallbackKongConfigurationSucceeded   pod/kong-controller-7f4fd47bb7-zdktb   successfully applied fallback Kong configuration to https://192.168.194.11:8444
```

{:.info}
> Another way to monitor the Fallback Configuration mechanism is by Prometheus metrics. See [Prometheus Metrics](/kubernetes-ingress-controller/observability/prometheus) for more information.

