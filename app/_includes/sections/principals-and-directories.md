{{site.identity}} uses principals and directories to unify how Kong products represent the entities they authenticate. 

* **Principal:** Represents an external client, workload, or human authenticating to a {{site.base_gateway}} (not a {{site.konnect_short_name}} user or {{site.dev_portal}} developer).
* **Directory:** Regional collection of principals. 
  Each {{site.konnect_short_name}} organization can provision up to one directory per region by default.

Principals work with:
* {{site.base_gateway}} in {{site.konnect_short_name}}: Principals can authenticate an entity for API traffic (using API keys or basic auth usernames and passwords), or can provide metadata about an entity already authenticated through another mechanism (such as OAuth).
* {{site.event_gateway_short}}: Principals can provide metadata about an entity already authenticated through another mechanism (such as SASL/SCRAM or SASL/OAUTHBEARER).
* {{site.dev_portal}}: Principals can adjust API gateway behavior based on the authenticating {{site.dev_portal}}.