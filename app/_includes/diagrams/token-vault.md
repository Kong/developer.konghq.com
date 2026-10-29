<!--vale off-->
{% mermaid %}
flowchart LR
    principal["<b>Principal</b><br/>Your users, agents, and applications calling through Kong."]
    gateway["<b>Kong AI Gateway</b><br/>Routes the request to Token Vault."]
    vault["<b>Token Vault</b><br/>Verifies, then releases a credential."]
    idp["<b>Trusted IdP</b><br/>The issuer Token Vault trusts to verify a caller's token."]
    providers["<b>Credential providers</b><br/>GitHub, Slack, and other providers your agents call."]
    principal -->|Request| gateway
    gateway --> vault
    vault -->|Verify| idp
    vault -->|Release credential| providers
{% endmermaid %}
<!--vale on-->