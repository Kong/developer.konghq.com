<!--vale off -->
{% mermaid %}
flowchart LR

A(API or Service)
B(API or Service)
C(API or Service)
D(<img src="/assets/icons/third-party/aws-transit-gateway-attachment.svg" style="max-height:32px" class="no-image-expand"/>AWS Transit Gateway attachment)
E(<img src="/assets/icons/third-party/aws-transit-gateway.svg" style="max-height:32px" class="no-image-expand"/> AWS Transit Gateway)
F(<img src="/assets/icons/third-party/aws-transit-gateway-attachment.svg" style="max-height:32px" class="no-image-expand"/>AWS Transit Gateway attachment)
G(<img src="/assets/logos/konglogo-gradient-secondary.svg" style="max-height:32px" class="no-image-expand"/>Konnect #40;fully-managed Data Plane#41;)
H(<img src="/assets/logos/konglogo-gradient-secondary.svg" style="max-height:32px" class="no-image-expand"/>Konnect #40;fully-managed Data Plane#41;)
I(<img src="/assets/logos/konglogo-gradient-secondary.svg" style="max-height:32px" class="no-image-expand"/>Konnect #40;fully-managed Data Plane#41;)
J(Internet)

subgraph 1 [User AWS Cloud]
    subgraph 2 [Region]
        subgraph 3 [Virtual Private Cloud #40;VPC#41;]
        A
        B
        C
        end
        A & B & C <--> D
    end
   D<-->E
end

subgraph 4 [Kong AWS Cloud]
    subgraph 5 [Region]
        E<-->F
        F <--private API access--> G & H & I
        subgraph 6 [Virtual Private Cloud #40;VPC#41;]
        G
        H
        I
        end
    end
end

G & H & I <--public API access--> J


{% endmermaid %}
<!--vale on-->