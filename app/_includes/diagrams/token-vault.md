{% mermaid %}
sequenceDiagram
autonumber
actor user as User
participant cc as Claude Code
participant gw as AI Gateway
participant okta as Okta (corp IdP)
participant vault as Token Vault (identity-auth)
participant gh as GitHub


user->>cc: "List my open GitHub pull requests"
cc->>gw: Call tool (MCP)
gw-->>cc: 401 www-authenticate → resource metadata pointing at Okta


rect rgb(235,242,235)
Note over cc,okta: Standard user authentication against the corp IdP
cc->>okta: Browser OAuth flow
okta-->>cc: access token (iss = Okta, sub = Lucas)
end


cc->>gw: Retry tool call, presenting the Okta subject token


rect rgb(245,240,235)
Note over gw,vault: Token exchange — vault verifies the subject token itself
gw->>vault: POST /{dir}/vault/token<br/>client_id=gateway-123, client_auth=mtls,<br/>grant_type=token-exchange, subject_token={okta-token},<br/>audience={provider_id}, scope=repo
vault->>okta: (cached) GET /jwks.json
vault->>vault: Verify signature + issuer against directory's vault_trusted_idps config
vault->>vault: Extract (iss, sub) from the verified token


alt No credential for (provider_id, iss, sub)
vault-->>gw: 401 { error: invalid_grant, enrollment_url }
gw-->>cc: Surface enrollment_url (MCP elicitation)
cc-->>user: "Connect your GitHub account: {enrollment_url}"
user->>gh: Open enrollment_url → OAuth consent
gh-->>vault: GET /callback?code&state
vault->>gh: Exchange code at GitHub's token endpoint
vault->>vault: Store credential keyed by (provider_id, iss, sub)
user->>cc: Retry original request
cc->>gw: Retry tool call
gw->>vault: POST /{dir}/vault/token (same as above)
end


vault-->>gw: 200 { token_type: bearer, access_token: {github-token} }
end


gw->>gh: Call GitHub API, injecting the returned token
gh-->>gw: Open pull requests
gw-->>cc: Result
cc-->>user: "Here are your open pull requests…"
{% endmermaid %}