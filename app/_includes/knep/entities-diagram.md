{% mermaid %}
flowchart LR
    
    A[Kafka 
    client]
    B[Listener 
    &#40TCP socket&#41
    + listener policies]
    C@{ shape: processes, label: "Virtual clusters
    + consume, produce, 
    and cluster policies"}
    D[Backend 
    cluster]
    E[Kafka 
    cluster]

    A --> B
    subgraph id1 [{{site.event_gateway_short}}]
    B --> C 
    C --> D
    end
    D --> E
{% if include.entity == 'policy' %}
    style B stroke:#86e2cc
    style C stroke:#86e2cc
{% else %}
    style {{include.entity}} stroke:#86e2cc
{% endif %}
    style id1 rx:7,ry:7
{% endmermaid %}