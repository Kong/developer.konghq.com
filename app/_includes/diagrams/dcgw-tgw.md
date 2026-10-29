<!--vale off -->
{% mermaid %}
flowchart LR

A(API or Service)
B(API or Service)
C(API or Service)
D(fa:fa-third-party/aws-transit-gateway-attachment AWS Transit Gateway attachment)
E(fa:fa-third-party/aws-transit-gateway AWS Transit Gateway)
F(fa:fa-third-party/aws-transit-gateway-attachment AWS Transit Gateway attachment)
G(fa:fa-konglogo-gradient-secondary Konnect #40;fully-managed Data Plane#41;)
H(fa:fa-konglogo-gradient-secondary Konnect #40;fully-managed Data Plane#41;)
I(fa:fa-konglogo-gradient-secondary Konnect #40;fully-managed Data Plane#41;)
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