This plugin offers extensive options for configuring tracing header propagation, providing a high degree of flexibility.
You can customize which headers are used to extract and inject tracing context. Additionally, you can configure headers to be cleared after the tracing context extraction process, enabling a high level of customization.

<!--vale off-->
{% mermaid %}
flowchart LR
   id1(Original Request) --> Extract
   id1(Original Request) -->|"headers (original)"| Extract
   id1(Original Request) --> Extract
   subgraph ide1 [Headers Propagation]
   Extract --> Clear
   Extract -->|"headers (original)"| Clear
   Extract --> Clear
   Clear -->|"headers (filtered)"| Inject
   end
   Extract -.->|extracted ctx| id2((tracing logic))
   id2((tracing logic)) -.->|updated ctx| Inject
   Inject -->|"headers (updated ctx)"| id3(Updated request)
{% endmermaid %}
<!--vale on-->