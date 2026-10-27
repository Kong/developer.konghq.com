The global control plane, the zone control planes, and the proxies each have a different job:

<!-- vale off -->
{% table %}
columns:
  - title: Component
    key: component
  - title: What it does
    key: responsibility
  - title: Carries application traffic
    key: traffic
rows:
  - component: "Global control plane"
    responsibility: "Stores global resources, sends them to the zones over KDS, and keeps an inventory of every zone."
    traffic: "No"
  - component: "Zone control plane"
    responsibility: "Finds the workloads in its zone, exchanges resources with the global control plane over KDS, and sends configuration to the local proxies over xDS."
    traffic: "No"
  - component: "Application proxy (sidecar)"
    responsibility: "Intercepts the traffic of its workload and applies routing, mTLS, authorization, and other policies."
    traffic: "Yes"
  - component: "Mesh-scoped zone ingress and zone egress"
    responsibility: "Carry the traffic of one mesh into and out of the zone."
    traffic: "Yes"
{% endtable %}
<!-- vale on -->

{% mermaid %}
flowchart LR
    K["Global control plane"]

    subgraph Z1["zone1"]
      C1["Zone control plane"]
      A1["orders<br/>sidecar"]
    end

    subgraph Z2["zone2"]
      C2["Zone control plane"]
      I2["Zone ingress"]
      A2["payments<br/>sidecar"]
    end

    K <-.->|KDS| C1
    K <-.->|KDS| C2
    C1 -.->|xDS| A1
    C2 -.->|xDS| I2
    C2 -.->|xDS| A2
    A1 --> I2
    I2 --> A2
{% endmermaid %}

KDS and xDS carry configuration only.
The solid arrows show the application request, which never passes through a control plane.
