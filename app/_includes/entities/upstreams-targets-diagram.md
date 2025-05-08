<!--vale off-->

{% mermaid %}
flowchart LR

  A("Request")
  B("`Route 
  (/mock)`")
  C("`Service
  (example_service)`")
  D("Target:
  httpbin.konghq.com")
  E("Target:
  httpbun.com")
  F(Upstream service:
  httpbin.konghq.com)
  G(Upstream service:
  httpbun.com)

  A --> B
  subgraph id1 ["`**KONG GATEWAY**`"]
    B --> C --> D & E
  subgraph id3 ["`**Upstream** (load balancer)`"]
  
    D & E
  end

  end

  subgraph id2 ["`**Target upstream services**`"]
    D --> F
    E --> G

  end

  style id2 stroke:none!important
{% endmermaid %}

<!--vale on-->