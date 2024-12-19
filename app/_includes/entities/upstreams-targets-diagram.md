<!--vale off-->

{% mermaid %}
flowchart LR

  A("Request")
  B("`Route 
  (/mock)`")
  C("`Service
  (example_service)`")
  D("Target
  (httpbin.konghq.com)")
  E("Target
  (httpbun.com)")
  F(httpbin.konghq.com)
  G(httpbun.com)

  A --> B
  subgraph id1 ["`**KONG GATEWAY**`"]
    B --> C --> D & E
  subgraph id3 ["`**Upstream**`"]
    D & E
  end

  end

  subgraph id2 ["`**Upstream targets**`"]
    D --> F
    E --> G

  end

  style id2 stroke:none
{% endmermaid %}

<!--vale on-->