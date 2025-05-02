<!--vale off -->
{% mermaid %}
flowchart LR

A(API or service)
B(API or service)
C(API or service)

G(<img src="/assets/logos/konglogo-gradient-secondary.svg" style="max-height:32px" class="no-image-expand"/>Konnect <br>#40;fully-managed <br>data plane#41;)
H(<img src="/assets/logos/konglogo-gradient-secondary.svg" style="max-height:32px" class="no-image-expand"/>Konnect <br>#40;fully-managed <br>data plane#41;)
J(Internet)

subgraph 1 [User Azure Cloud]
      subgraph 3 [Virtual Network #40;VNET#41;]
      A
      B
      C
      end
end
3 <--VNET Peering <br> Private API Access--> 6

subgraph 4 [Kong Azure Cloud]
      subgraph 6 [Virtual Network #40;VNET#41;]
      G
      H
      end
end

G & H <--public API <br> access--> J

{% endmermaid %}
<!--vale on-->