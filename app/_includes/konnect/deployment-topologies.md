<!--vale off -->
{% mermaid %} 
flowchart TD
    A(Dev Portal &bull; Observability &bull; Catalog)
    B(<img src="/assets/icons/gateway.svg" style="max-height:20px"> Kong-managed Control Plane #40;Kong Gateway instance#41;)
    C(<img src="/assets/icons/gateway.svg" style="max-height:20px"> Data Plane #40;Kong Gateway instance#41;)

    subgraph id1 [Konnect]
    A --- B
    end

    B --Kong proxy 
    configuration---> id2

    subgraph id2 [Fully-managed cloud nodes]
    C
    end

    style id1 stroke-dasharray:3,rx:10,ry:10
    style id2 stroke-dasharray:3,rx:10,ry:10
{% endmermaid %}
<!-- vale on-->
