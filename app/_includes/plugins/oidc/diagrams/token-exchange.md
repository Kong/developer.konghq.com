<!--vale off-->
{% mermaid %}
sequenceDiagram

participant s1 as IDP1<br>(e.g. Okta)
participant c1 as Client1<br>(e.g. App1)

c1<<->>+s1: token

participant s2 as IDP2<br>(e.g. GitHub)
participant c2 as Client2<br>(e.g. App2)
 
c2<<->>+s2: token
participant kong as API Gateway<br>(Kong) 

participant u as Upstream<br>(protected by target IdP)
participant t as Target IdP

loop Protected by
    t->>+u: 
end
activate c1 
c1->>kong: Service with access token 
deactivate c1 
activate c2
c2->>kong: Service with access token 
deactivate c2
activate kong 
loop check incoming token
    kong->>kong: load access token 
    kong->>kong: verify claims (iss,nbf,exp) 
    kong->>kong: check conditions for exchange
end  
kong->>t: Trigger exchange token   
deactivate kong
activate t
t->>kong: Respond with exchanged token 
deactivate t
activate kong 
loop check exchanged token
    kong->>kong: Validate newly exchanged token
end    
kong->>u: Proxy request to upstream
deactivate kong
activate u
u->>kong: Response
deactivate u
activate kong
kong->>c2: Respond to client
kong->>c1: Respond to client
deactivate kong
{% endmermaid %}
<!--vale on-->