---
title: Claude Code SSO
description: Authenticate Claude Code requests via Okta SSO with consumer-based model routing and per-tier rate limiting.
url: "/cookbooks/claude-code-sso/"
content_type: cookbook
layout: cookbook
products:
  - ai-gateway
tools:
  - kongctl
canonical: true
works_on:
  - konnect
min_version:
  gateway: '3.14'
categories:
  - access-control
  - llm
featured: false
popular: false

# Machine-readable fields for AI agent setup
plugins:
  - openid-connect
  - ai-proxy-advanced
  - ai-rate-limiting-advanced
requires_embeddings: false
providers:
  - anthropic
  - bedrock
  - azure
extra_services:
  - name: Okta
    env_vars: [DECK_OKTA_ISSUER, DECK_OKTA_AUDIENCE]
    hint: "Create a Native Application in Okta with PKCE flow and configure an API Authorization Server with a groups claim. See the Okta section in Prerequisites."

hint: "Requires an Okta organization with admin access, LLM provider credentials, and Python 3.11+."

prereqs:
  skip_product: true
  skip_tool: true
  inline:
    - title: "{{site.konnect_product_name}}"      
      content: |
        This tutorial uses {{site.konnect_product_name}}. You will provision a recipe-scoped Control Plane and local Data Plane via the [quickstart script](https://get.konghq.com/quickstart).

        1. Create a new personal access token by opening the [Konnect PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**.
        1. Export your token. The same token is reused later for kongctl commands:

           ```bash
           export KONNECT_TOKEN='YOUR_KONNECT_PAT'
           ```

        1. Set the recipe-scoped Control Plane name and run the quickstart script:

           ```bash
           export KONNECT_CONTROL_PLANE_NAME='claude-code-sso-recipe'
           curl -Ls https://get.konghq.com/quickstart | bash -s -- -k $KONNECT_TOKEN --deck-output
           ```

           This provisions a Konnect Control Plane named `claude-code-sso-recipe`, a local Data Plane connected to it, and prints `export` lines for the rest of the session vars. Paste those into your shell when prompted.
    - title: kongctl + decK
      content: |
        This tutorial uses [kongctl](/kongctl/) and [decK](/deck/) to manage Kong configuration.

        1. Install **kongctl** from [developer.konghq.com/kongctl](/kongctl/).
        2. Install **decK** version 1.43 or later from [docs.konghq.com/deck](https://docs.konghq.com/deck/).

        You can verify both are installed:

        ```bash
        kongctl version
        deck version
        ```
    - title: Okta
      icon_url: /assets/icons/okta.svg
      content: |
        This recipe requires an Okta organization with admin access. You will create an OIDC application and authorization server that issue JWTs for Claude Code to present to Kong.

        Follow the [Okta Developer documentation](https://developer.okta.com/docs/guides/) to complete these steps:

        1. **Create a Native Application.** In the Okta Admin Console, go to
           **Applications > Create App Integration**. Select **OIDC, OpenID Connect** and
           **Native Application**. Enable **Authorization Code + PKCE** as the grant type. Set the
           sign-in redirect URI to `http://localhost:9876/callback`. Assign the application to your
           engineering groups. No client secret is generated. PKCE replaces it. Note the **Client ID**.

        2. **Create an API Authorization Server.** Go to **Security > API > Add Authorization Server**.
           Set the audience to a value like `api://claude-proxy`. Add a scope named `groups` (in addition
           to the defaults `openid`, `profile`, `email`, `offline_access`).

        3. **Add a groups claim.** Under the authorization server, go to **Claims > Add Claim**.
           Set the name to `groups`, include in the **Access Token**, value type **Groups**, and filter
           with a regex like `.*` (or a prefix like `claude-`). This ensures the `groups` array is
           present in the JWT so Kong can map it to Consumers.

        4. **Create user groups.** In **Directory > Groups**, create two groups:
           - `claude-standard-users`, general engineering
           - `claude-power-users`, senior engineers, ML team

           Assign users to the appropriate group, and ensure both groups are assigned to the
           Native Application.

        After completing Okta setup, export the issuer URL and audience as decK variables:

        ```bash
        export DECK_OKTA_ISSUER='https://your-org.okta.com/oauth2/default'
        export DECK_OKTA_AUDIENCE='api://claude-proxy'
        ```

        #### Helper script: okta-claude-auth.sh

        Claude Code's [`apiKeyHelper`](https://docs.anthropic.com/en/docs/claude-code/settings) setting
        runs a script before each API call and uses its stdout as the `Authorization` header value.
        The following script implements the OAuth 2.0 Authorization Code + PKCE flow against Okta,
        caches the token locally, and refreshes silently when possible.

        Save this script to `~/.claude/okta-claude-auth.sh` and make it executable:

        ```bash
        cat <<'SCRIPT' > ~/.claude/okta-claude-auth.sh
        #!/usr/bin/env bash
        # okta-claude-auth.sh — apiKeyHelper for Claude Code + Okta PKCE
        set -euo pipefail

        OKTA_DOMAIN="${OKTA_DOMAIN:-"https://your-org.okta.com"}"
        CLIENT_ID="${OKTA_CLIENT_ID:-"0oa1b2c3d4YourClientId"}"
        REDIRECT_PORT="${OKTA_REDIRECT_PORT:-"9876"}"
        REDIRECT_URI="http://localhost:${REDIRECT_PORT}/callback"
        SCOPES="openid profile email offline_access groups"
        AUDIENCE="${OKTA_AUDIENCE:-"api://claude-proxy"}"
        AUTH_SERVER="${OKTA_AUTH_SERVER:-"default"}"

        CACHE_DIR="${HOME}/.claude/okta-cache"
        TOKEN_CACHE="${CACHE_DIR}/tokens.json"
        LOCK_FILE="${CACHE_DIR}/auth.lock"

        log()  { echo "[okta-auth] $*" >&2; }
        die()  { echo "[okta-auth] ERROR: $*" >&2; exit 1; }
        b64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }
        random_str() { openssl rand -hex "${1:-32}"; }
        json_get() { echo "$1" | grep -o "\"$2\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | sed 's/.*: *"\([^"]*\)".*/\1/'; }
        json_get_num() { echo "$1" | grep -o "\"$2\"[[:space:]]*:[[:space:]]*[0-9]*" | grep -o '[0-9]*$'; }

        mkdir -p "$CACHE_DIR" && chmod 700 "$CACHE_DIR"

        cache_read() { [[ -f "$TOKEN_CACHE" ]] && cat "$TOKEN_CACHE" || echo "{}"; }
        cache_write() { echo "$1" > "$TOKEN_CACHE" && chmod 600 "$TOKEN_CACHE"; }

        access_token_valid() {
          local cache exp now tok
          cache=$(cache_read)
          tok=$(json_get "$cache" "access_token")
          exp=$(json_get_num "$cache" "expires_at")
          now=$(date +%s)
          [[ -z "$tok" || -z "$exp" ]] && return 1
          (( now < exp - 60 )) && { echo "$tok"; return 0; }
          return 1
        }

        do_refresh() {
          local cache refresh_tok response new_access new_refresh expires_in expires_at now
          cache=$(cache_read)
          refresh_tok=$(json_get "$cache" "refresh_token")
          [[ -z "$refresh_tok" ]] && return 1
          log "Attempting silent refresh..."
          response=$(curl -sf -X POST "${OKTA_DOMAIN}/oauth2/${AUTH_SERVER}/v1/token" \
            -H "Content-Type: application/x-www-form-urlencoded" \
            -d "grant_type=refresh_token&refresh_token=${refresh_tok}&client_id=${CLIENT_ID}&scope=${SCOPES// /%20}") || return 1
          new_access=$(json_get "$response" "access_token")
          new_refresh=$(json_get "$response" "refresh_token")
          expires_in=$(json_get_num "$response" "expires_in")
          [[ -z "$new_access" ]] && return 1
          now=$(date +%s); expires_at=$(( now + ${expires_in:-3600} ))
          cache_write "{\"access_token\":\"${new_access}\",\"refresh_token\":\"${new_refresh:-$refresh_tok}\",\"expires_at\":${expires_at}}"
          log "Token refreshed successfully."
          echo "$new_access"
        }

        start_callback_server() {
          local expected_state="$1"
          python3 - "$REDIRECT_PORT" "$expected_state" <<'PYEOF'
        import sys, socket, urllib.parse
        port, expected_state = int(sys.argv[1]), sys.argv[2]
        HTML_OK = b"<html><body><h2>Authenticated! Close this tab.</h2><script>window.close();</script></body></html>"
        HTML_ERR = b"<html><body><h2>Authentication failed.</h2></body></html>"
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        sock.bind(("127.0.0.1", port)); sock.listen(1); sock.settimeout(120)
        try:
            conn, _ = sock.accept(); data = b""
            while b"\r\n\r\n" not in data:
                chunk = conn.recv(4096)
                if not chunk: break
                data += chunk
            path = data.decode(errors="replace").split(" ")[1] if b" " in data else "/"
            params = urllib.parse.parse_qs(urllib.parse.urlparse(path).query)
            code, state = params.get("code",[None])[0], params.get("state",[None])[0]
            error = params.get("error",[None])[0]
            ok = code and state == expected_state and not error
            conn.sendall(b"HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nConnection: close\r\n\r\n" + (HTML_OK if ok else HTML_ERR))
            conn.close()
            if not ok: sys.exit(1)
            print(code, end="")
        except socket.timeout:
            sys.stderr.write("[okta-auth] Timed out waiting for callback.\n"); sys.exit(1)
        finally: sock.close()
        PYEOF
        }

        do_auth_code_flow() {
          local verifier challenge state auth_url code response access_tok refresh_tok expires_in expires_at now
          verifier=$(random_str 32)
          challenge=$(echo -n "$verifier" | openssl dgst -binary -sha256 | b64url)
          state=$(random_str 16)
          auth_url="${OKTA_DOMAIN}/oauth2/${AUTH_SERVER}/v1/authorize?response_type=code&client_id=${CLIENT_ID}&redirect_uri=${REDIRECT_URI}&scope=${SCOPES// /+}&audience=${AUDIENCE}&state=${state}&code_challenge=${challenge}&code_challenge_method=S256"
          log "Opening browser for Okta login..."
          log "If the browser doesn't open, visit: ${auth_url}"
          command -v open &>/dev/null && open "$auth_url" & || command -v xdg-open &>/dev/null && xdg-open "$auth_url" 2>/dev/null &
          log "Waiting for callback on http://localhost:${REDIRECT_PORT}/callback ..."
          code=$(start_callback_server "$state")
          [[ -z "$code" ]] && die "No authorization code received."
          log "Authorization code received. Exchanging for tokens..."
          response=$(curl -sf -X POST "${OKTA_DOMAIN}/oauth2/${AUTH_SERVER}/v1/token" \
            -H "Content-Type: application/x-www-form-urlencoded" \
            -d "grant_type=authorization_code&code=${code}&redirect_uri=${REDIRECT_URI}&client_id=${CLIENT_ID}&code_verifier=${verifier}") || die "Token exchange failed."
          access_tok=$(json_get "$response" "access_token")
          refresh_tok=$(json_get "$response" "refresh_token")
          expires_in=$(json_get_num "$response" "expires_in")
          [[ -z "$access_tok" ]] && die "No access_token in response."
          now=$(date +%s); expires_at=$(( now + ${expires_in:-3600} ))
          cache_write "{\"access_token\":\"${access_tok}\",\"refresh_token\":\"${refresh_tok}\",\"expires_at\":${expires_at}}"
          log "Authentication successful. Token cached."
          echo "$access_tok"
        }

        acquire_lock() {
          local waited=0
          while ! mkdir "$LOCK_FILE" 2>/dev/null; do
            sleep 0.5; (( waited++ ))
            (( waited > 30 )) && { log "Lock timeout — removing stale lock"; rm -rf "$LOCK_FILE"; }
          done
          trap 'rm -rf "$LOCK_FILE"' EXIT INT TERM
        }

        main() {
          acquire_lock
          tok=$(access_token_valid) && { echo "$tok"; exit 0; }
          tok=$(do_refresh 2>/dev/null) && { echo "$tok"; exit 0; }
          tok=$(do_auth_code_flow)
          echo "$tok"
        }

        main "$@"
        SCRIPT
        chmod +x ~/.claude/okta-claude-auth.sh
        ```
        {:.collapsible}

        Claude Code runs `apiKeyHelper` in a clean environment. Shell exports from
        `~/.zshrc` or `~/.bashrc` are not inherited by the helper process. All Okta
        variables the script needs must be defined in the `env` block of your Claude Code
        `settings.json` (see the [Try it out](#use-claude-code) section). If you also want
        the variables available in your normal shell for running the script manually, export
        them in your `~/.zshrc` or `~/.bashrc`:

        ```bash
        export OKTA_DOMAIN='https://your-org.okta.com'
        export OKTA_CLIENT_ID='0oa1b2c3d4YourClientId'
        export OKTA_AUDIENCE='api://claude-proxy'
        export OKTA_AUTH_SERVER='default'  # set to your custom auth server ID if not using default
        ```

        The script requires `bash`, `curl`, `openssl`, and `python3` (for the local callback server).
        Token files are stored at `~/.claude/okta-cache/` with `600`/`700` permissions.
    - title: AI Credentials
      content: |
        {% navtabs "Providers" %}
        {% navtab "Anthropic" %}
        This tutorial uses Anthropic:

        1. [Create an Anthropic account](https://console.anthropic.com/).
        1. [Get an API key](https://console.anthropic.com/settings/keys).
        1. Create a decK variable with the API key:

           ```sh
           export DECK_ANTHROPIC_TOKEN='YOUR-ANTHROPIC-KEY'
           ```
        {% endnavtab %}
        {% navtab "AWS Bedrock" %}
        This tutorial uses AWS Bedrock:

        1. Ensure you have an AWS account with [Bedrock model access](https://docs.aws.amazon.com/bedrock/latest/userguide/model-access.html) enabled.
        1. Create decK variables with your AWS credentials:

           ```sh
           export DECK_AWS_ACCESS_KEY_ID='your-access-key'
           export DECK_AWS_SECRET_ACCESS_KEY='your-secret-key'
           export DECK_AWS_REGION='us-east-1'
           ```
        {% endnavtab %}
        {% navtab "Azure AI Services" %}
        This tutorial uses Azure AI Services hosting Claude models. Standard Azure OpenAI endpoints
        do not support Anthropic-format requests. You need an Azure AI Services resource with a
        Claude model deployment:

        1. [Create an Azure AI Services resource](https://learn.microsoft.com/en-us/azure/ai-services/model-catalog/how-to/deploy-models-serverless) with a Claude model deployment.
        1. Note your instance name, deployment ID, and API version.
        1. Create decK variables:

           ```sh
           export DECK_AZURE_API_KEY='your-azure-api-key'
           export DECK_AZURE_INSTANCE='your-instance-name'
           export DECK_AZURE_DEPLOYMENT_ID='your-deployment-id'
           export DECK_AZURE_API_VERSION='YOUR-API-VERSION'  # check Azure docs for current version
           ```
        {% endnavtab %}
        {% endnavtabs %}
    - title: Python 3.11+
      icon_url: /assets/icons/python.svg
      content: |
        The demo script requires Python 3.11 or later. Set up an isolated environment:

        ```bash
        python3 -m venv .venv
        source .venv/bin/activate
        pip install 'anthropic>=0.39.0'
        ```

overview: |
  This recipe connects Claude Code to your organization's Okta identity layer through Kong AI
  Gateway. By the end of this tutorial, every Claude Code request from your engineering team will
  be authenticated via Okta SSO, routed to a model tier based on the developer's Okta group
  membership, and subject to per-tier token rate limits, all without any LLM provider credentials
  on developer machines.

  The recipe uses three Kong Plugins working together: the
  [OpenID Connect](/plugins/openid-connect/) Plugin for Okta JWT validation, the
  [AI Proxy Advanced](/plugins/ai-proxy-advanced/) Plugin for consumer-scoped model routing, and
  the [AI Rate Limiting Advanced](/plugins/ai-rate-limiting-advanced/) Plugin for per-tier token
  budgets.
---

## The problem

Claude Code supports two authentication modes, and both create organizational blind spots at scale:

**Static API keys (`ANTHROPIC_API_KEY`).** A single key is shared across a team via environment
variables, `.env` files, or CI secrets stores. Every developer's requests are indistinguishable on
the Anthropic bill. When a key leaks in shell history or a commit, rotation requires touching every
machine and pipeline that uses it. There is no per-user audit trail, no way to revoke one person's
access without rotating the shared key, and no mechanism to assign different models or rate limits
to different roles.

**OAuth login (`claude auth login`).** Claude Code's built-in OAuth flow authenticates against a
Claude subscription (Pro, Max, Team, or Enterprise). On Enterprise plans, Anthropic's WorkOS
integration can enforce Okta SSO for the Claude web interface and Console. However, this controls
access to the *Claude subscription*, not to the API itself. Any developer with `ANTHROPIC_API_KEY`
set bypasses that SSO boundary entirely. The key works regardless of whether the developer has an
active Okta session, has passed MFA, or has been offboarded. The two auth modes operate as
independent systems with no overlap.

**No integration with organizational identity.** Okta already defines who belongs to which team,
what MFA policy applies, and when access should be revoked. Neither Claude Code auth mode surfaces
that context to the API layer. A developer removed from an Okta group at 10 AM can still make API
calls at 3 PM because the API key or cached OAuth token has no connection to Okta's session state.

**No model governance.** Every developer with a valid key gets the same model access. There is no
built-in way to say "interns get Haiku, senior engineers get Opus" or "this team's monthly token
budget is 500K." Cost controls happen retroactively through billing alerts, not proactively through
access policy.

The root issue is that in both modes, trust is established at the *developer machine*, either via
a static key or a locally cached token. There is no server-side enforcement point that can apply
your organization's identity policies, revoke access instantly, or route requests based on who is
asking.

## The solution

This recipe moves the enforcement point to a {{site.base_gateway}} that your organization controls, with
Okta as the single source of truth for identity:

- **For API key users**, Kong replaces `ANTHROPIC_API_KEY` entirely. Developers never hold the
  provider key. Kong injects it server-side after validating their Okta identity. Key rotation
  happens in one place (Kong's config), not on every developer machine.
- **For `claude auth login` / Enterprise users**, Kong extends the SSO boundary from the Claude
  web interface down to the API layer, so the same Okta session and group memberships that govern
  claude.ai access also govern which models a developer can reach via Claude Code.
- **Consumer-based model routing** maps Okta groups to Kong Consumers, each with their own model
  configuration and rate limits. Standard users get a cost-efficient model; power users get the
  most capable model. Changing a user's tier is an Okta group assignment, not a config change.
- **Instant revocation.** Removing a user from an Okta group or disabling their account
  immediately blocks API access. The short-lived JWT fails validation on the next request.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant CC as Claude Code
    participant H as apiKeyHelper script
    participant O as Okta
    participant K as {{site.base_gateway}}
    participant L as LLM Provider

    CC->>H: Request bearer token
    activate H
    alt Cached token still valid
        H-->>CC: Cached JWT
    else Refresh or PKCE flow
        H->>O: PKCE flow (browser)
        activate O
        O-->>H: JWT (id_token + refresh_token)
        deactivate O
        H-->>CC: Fresh JWT
    end
    deactivate H

    CC->>K: POST /claude-code-sso (Authorization: Bearer JWT)
    activate K
    K->>K: openid-connect — JWKS validate, Okta group → Kong Consumer
    K->>K: ai-proxy-advanced — inject provider key, route by Consumer tier
    K->>K: ai-rate-limiting-advanced — check per-Consumer token budget
    K->>L: Forwarded request
    activate L
    L-->>K: Provider response
    deactivate L
    K-->>CC: OpenAI-format response
    deactivate K
{% endmermaid %}
<!-- vale on -->

| Component | Responsibility |
|-----------|---------------|
| `okta-claude-auth.sh` | PKCE flow, token caching, silent refresh. Runs on the developer machine |
| Okta | Identity, MFA, group membership, JWT issuance |
| Kong, [openid-connect](/plugins/openid-connect/) | JWT signature validation via JWKS, audience verification, Okta group to Kong Consumer mapping |
| Kong, [ai-proxy-advanced](/plugins/ai-proxy-advanced/) | LLM provider auth injection, model routing per Consumer tier, format translation |
| Kong, [ai-rate-limiting-advanced](/plugins/ai-rate-limiting-advanced/) | Per-Consumer token rate limits with sliding windows |
| LLM Provider | Model inference |

{:.info}
> **Provider compatibility:** Claude Code sends requests in Anthropic's native format.
> This recipe uses `llm_format: anthropic` in the AI Proxy Advanced Plugin, which passes
> Anthropic-format requests through without translation. Only providers with
> Anthropic-compatible endpoints are supported: Anthropic (native), AWS Bedrock (Claude
> models via InvokeModel), and Azure AI Services (Claude model deployments).

## How it works

When a developer runs Claude Code, every API request flows through Kong before reaching the
LLM provider. Here is the complete request lifecycle:

1. **Token acquisition.** Claude Code invokes the `apiKeyHelper` script
   (`okta-claude-auth.sh`) before each API call. The script checks its local token cache for a
   valid access token. If the token has expired but a refresh token exists, it silently exchanges
   for a new access token via Okta's token endpoint. If no valid tokens exist, it opens a browser
   to Okta's authorization endpoint for a full PKCE authentication flow, captures the
   authorization code via a local callback server, and exchanges it for tokens. The resulting
   JWT is returned to Claude Code.

2. **Request to Kong.** Claude Code sends `POST /claude-code-sso/v1/messages` with
   `Authorization: Bearer <jwt>` to {{site.base_gateway}}. The request body is in Anthropic's native
   message format.

3. **JWT validation and Consumer mapping.** The [openid-connect](/plugins/openid-connect/)
   Plugin validates the JWT signature against Okta's cached JWKS keys, checks that the token
   has not expired, and verifies the `aud` claim matches the expected audience. It then reads
   the `groups` array from the JWT and matches it against Kong Consumer usernames. A developer
   in the `claude-power-users` Okta group is resolved to the `claude-power-users` Kong Consumer.

4. **Credential injection and model routing.** The consumer-scoped
   [ai-proxy-advanced](/plugins/ai-proxy-advanced/) Plugin for that Consumer injects the
   LLM provider API key (which the developer never sees) and routes the request to the model
   configured for that tier.

5. **Token rate limiting.** The consumer-scoped
   [ai-rate-limiting-advanced](/plugins/ai-rate-limiting-advanced/) Plugin counts prompt and
   completion tokens against the Consumer's per-tier budget. Rate limit headers
   (`X-AI-RateLimit-Remaining`) are added to the response.

6. **Response.** The LLM provider's response flows back through Kong to Claude Code.
   Subsequent requests reuse the cached Okta token silently. No browser flow unless the
   refresh token has expired.

### OpenID Connect, JWT validation and Consumer mapping

The [openid-connect](/plugins/openid-connect/) Plugin is the authentication layer. It validates
every incoming JWT against Okta's JWKS keys, rejects tokens that have expired or were issued for
a different audience, and maps the developer's Okta group membership to a Kong Consumer. This
Consumer mapping is the bridge between your identity provider and Kong's consumer-scoped
Plugins. It determines which model tier and rate limit apply to each request.

#### Configuration details

```yaml
plugins:
  - name: openid-connect
    config:
      issuer: "https://your-org.okta.com/oauth2/default"
      auth_methods:
        - bearer
      bearer_token_param_type:
        - header
      audience_claim:
        - aud
      audience_required:
        - "api://claude-proxy"
      consumer_claim:
        - groups
      consumer_by:
        - username
      upstream_headers_claims:
        - sub
        - email
      upstream_headers_names:
        - X-Authenticated-User
        - X-User-Email
      ssl_verify: true
      hide_credentials: true
```
{:.no-copy-code}

**`issuer`**. The Okta Authorization Server's base URL. Kong appends
`/.well-known/openid-configuration` to discover JWKS endpoints, signing keys, and token metadata
automatically. Kong caches the JWKS keys to avoid hitting Okta on every request.

**`auth_methods: [bearer]`**. Tells Kong to look for a Bearer token in the `Authorization`
header. Claude Code's `apiKeyHelper` outputs a bare token; Claude Code sends it as
`Authorization: Bearer <token>`.

**`audience_required`**. The JWT's `aud` claim must match this value exactly. This prevents
tokens issued for other Okta applications from being accepted. Set this to whatever audience
you configured on the Okta Authorization Server.

**`consumer_claim: [groups]`** and **`consumer_by: [username]`**. This is the core of the
identity mapping. The Plugin reads the `groups` array from the JWT payload (populated by the
Okta groups claim you configured) and matches each value against Kong Consumer usernames. If the
JWT contains `"groups": ["claude-power-users"]`, Kong resolves the request to the
`claude-power-users` Consumer. The resolved Consumer determines which downstream Plugin instances
handle the request.

If a user belongs to multiple groups that correspond to Kong Consumers, the first match is used.
Structure your Okta group assignments so each user maps to exactly one Consumer tier.

**`upstream_headers_claims`** and **`upstream_headers_names`**. Extracts the `sub` and `email`
claims from the validated JWT and forwards them as `X-Authenticated-User` and `X-User-Email`
headers. These are useful for audit logging. You can see which user made each request without
decoding the JWT.

**`ssl_verify: true`**. Enables TLS certificate verification when Kong connects to Okta's JWKS
endpoint to fetch signing keys. In {{site.base_gateway}} 3.14+, this defaults to `true` as part of the
Secure by Default initiative. Set explicitly here for clarity.

**`hide_credentials: true`**. Strips the `Authorization` header from the request before
forwarding upstream. Since the ai-proxy-advanced Plugin injects its own provider credentials,
the Okta JWT is not needed upstream. In {{site.base_gateway}} 3.14+, this defaults to `true`. Set
explicitly here for clarity.

**Alternative configurations:**

- **`consumer_optional: true`**. If set, requests without a valid Consumer mapping are still
  allowed through (without a Consumer context). Useful if you want a "default" tier that applies
  to authenticated users who aren't in a specific group.
- **`anonymous`**. Set to a Consumer username to use as a fallback when authentication fails
  entirely. This creates a public-access tier with its own rate limits and model access.

### AI Proxy Advanced, model routing and credential injection

Each Consumer tier gets its own [ai-proxy-advanced](/plugins/ai-proxy-advanced/) Plugin instance,
scoped to that Consumer. This is how different Okta groups get different model access. The
openid-connect Plugin resolves which Consumer the request belongs to, and the matching
ai-proxy-advanced instance handles credential injection and model selection. Developers never
hold the provider API key; Kong injects it server-side after validating their Okta identity.

#### Configuration details

```yaml
plugins:
  - name: ai-proxy-advanced
    consumer: claude-standard-users
    config:
      llm_format: anthropic
      max_request_body_size: 10485760
      response_streaming: allow
      targets:
        - route_type: llm/v1/chat
          auth:
            header_name: x-api-key
            header_value: "<provider-api-key>"
            allow_override: false
          logging:
            log_statistics: true
            log_payloads: true
          model:
            provider: anthropic
            name: claude-sonnet-4-6
```
{:.no-copy-code}

**`llm_format: anthropic`**. Claude Code sends requests in Anthropic's native format
(`/v1/messages` with `messages` array). This setting tells the Plugin to expect Anthropic-format
input. For Anthropic, requests pass through natively. For AWS Bedrock and Azure AI Services
(both hosting Claude models), the Plugin translates from Anthropic format to the target
provider's format automatically. Claude Code always speaks Anthropic, and Kong handles the
translation.

{:.warning}
> Do not use `llm_format: openai` with Claude Code. Claude Code sends Anthropic-native tool definitions in its requests. The OpenAI format translation path mangles these structures, causing 400 errors from the LLM provider (typically "tools: Input should be a valid list"). Always use `llm_format: anthropic` when proxying Claude Code traffic.

**`consumer: claude-standard-users`**. Scopes this Plugin instance to one Consumer. When the
openid-connect Plugin resolves a request to the `claude-standard-users` Consumer, this Plugin
instance handles it. The `claude-power-users` Consumer has a separate Plugin instance with a
different model.

**`auth`**. Kong holds the provider API key and injects it into every upstream request. The
developer's Okta JWT is used only for authentication at the Kong layer. It never reaches the
LLM provider. The credential values come from environment variables via decK's
{%raw%}`${{ env "..." }}`{%endraw%} syntax, resolved at apply time. `allow_override` is `false`
by default, meaning client-provided credentials are replaced. Set it to `true` only if you want
developers to use their own provider API keys while still enforcing Okta authentication.

**`route_type: llm/v1/chat`**. Selects the chat completions translation path. Kong maps this to
the appropriate provider endpoint (`/v1/messages` for Anthropic, Bedrock's InvokeModel API for
AWS Bedrock, etc.).

**`model.name`**. The model assigned to this Consumer tier. Standard users might get
`claude-sonnet-4-6` (cost-efficient) while power users get `claude-opus-4-6` (most capable).
Change the model by updating the `DECK_CHAT_MODEL_1` or `DECK_CHAT_MODEL_2` environment
variable and re-applying.

**`logging.log_statistics`**. Appends token usage data (`prompt_tokens`, `completion_tokens`) to
any attached logging Plugin's output (e.g. [http-log](/plugins/http-log/),
[file-log](/plugins/file-log/)). Combined with the `X-Authenticated-User` header from the OIDC
Plugin, this enables per-user cost attribution.

**`logging.log_payloads`**. Includes request and response bodies in logging Plugin output.
Whether to enable this depends on your organization's observability and compliance requirements.
The important consideration is where the logged data goes (to whatever log destination your
logging Plugins are configured to send to).

**`max_request_body_size: 10485760`**. Sets the maximum allowed request body to 10 MB. Claude
Code conversations accumulate large context windows (100 KB or more of conversation history,
tool results, and file contents). The default body size limit rejects these requests. Set this
value to accommodate your expected maximum context size.

**`response_streaming: allow`**. Permits the Plugin to pass Server-Sent Events (SSE) streaming
responses from the provider back to Claude Code. Claude Code uses streaming for interactive
terminal output. Without this setting, streaming responses may be buffered or rejected.

**Alternative configurations:**

- **Native format (`llm_format`)**. Set `llm_format` to a provider's native format
  (`anthropic`, `bedrock`, `gemini`, etc.) to pass requests through without transformation.
  Useful when you need provider-specific capabilities or already use a provider's native SDK.
- **Multiple targets**. A single Plugin instance can have multiple targets for different route
  types (e.g. `llm/v1/chat` and `llm/v1/embeddings`), each with their own model and auth.

### AI Rate Limiting Advanced, per-Consumer token limits

Each Consumer tier gets its own [ai-rate-limiting-advanced](/plugins/ai-rate-limiting-advanced/)
instance with different token budgets. Unlike request-count rate limiting, this Plugin counts
tokens (prompt + completion), which is the correct unit for LLM cost control. Standard users
get a smaller token budget per window while power users get a larger one. When a Consumer
exhausts their budget, Kong returns `429 Too Many Requests` until the window resets.

#### Configuration details

```yaml
plugins:
  - name: ai-rate-limiting-advanced
    consumer: claude-standard-users
    config:
      policies:
        - limits:
            - limit: 5000
              window_size: 60
          window_type: sliding
      identifier: consumer
      tokens_count_strategy: total_tokens
      strategy: local
      llm_format: anthropic
```
{:.no-copy-code}

**`policies`**. An array of rate limiting policies (replaces the deprecated `llm_providers`
field). Each policy contains a `limits` array of limit/window pairs and an optional `match`
array for targeting specific Consumers, providers, models, or other dimensions. A policy without
`match` conditions acts as a fallback that applies to all requests, which is what this recipe
uses, since each Plugin instance is already consumer-scoped. Standard users get 5,000 total
tokens per 60-second window; power users get 25,000. Add multiple entries in the `limits` array
for multiple windows (e.g. per-minute and per-hour token budgets):
`limits: [{limit: 5000, window_size: 60}, {limit: 500000, window_size: 86400}]`.

**`window_type: sliding`**. Set per-policy. Uses a sliding window algorithm for smoother rate
limiting compared to fixed windows. The `fixed` alternative uses strict time windows.

**`tokens_count_strategy: total_tokens`**. Counts both prompt (input) and completion (output)
tokens against the limit. Can also be set per-limit within a policy. Alternatives: `prompt_tokens`
(count only input), `completion_tokens` (count only output), or `cost` (calculates based on
input/output cost per 1M tokens if you've set those in the ai-proxy-advanced target config).

**`identifier: consumer`**. Tracks token usage per Kong Consumer. Since each Consumer maps to an
Okta group, this effectively sets token budgets per organizational tier. For more flexible
multi-dimensional scoping, use `policies[].match` conditions with `partition_by: true` instead.

**`strategy: local`**. Uses in-memory counters on each Kong node. For single-node or
development deployments this is sufficient. For multi-node production clusters, switch to
`strategy: redis` with a shared Redis instance so counters are consistent across nodes.

**`llm_format: anthropic`**. Must match the `llm_format` in the ai-proxy-advanced Plugin so the
rate limiting Plugin can correctly parse token counts from the response.

Kong returns token rate limit headers with every response:

| Header | Description |
|--------|-------------|
| `X-AI-RateLimit-Limit-{window}-{provider}` | Maximum tokens allowed in the window |
| `X-AI-RateLimit-Remaining-{window}-{provider}` | Tokens remaining in the current window |
| `RateLimit-Reset` | Seconds until the window resets |

When the token limit is exceeded, Kong returns `429 Too Many Requests` with a `Retry-After`
header.

{:.info}
> In production, store credentials in [Kong Vaults](/gateway/latest/kong-enterprise/secrets-management/) using {%raw%}`{vault://backend/key}`{%endraw%} references rather than environment variables. Kong supports HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager, and the Konnect Config Store.

## Apply the Kong configuration

This section configures the Control Plane in two parts. First, adopt the quickstart Control Plane into a kongctl namespace so the apply commands below can manage it. The recipe's `select_tags` and the `claude-code-sso-recipe` namespace scope every resource so teardown removes only this recipe's configuration.

```bash
kongctl adopt control-plane "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Adoption stamps the `KONGCTL-namespace` label on the Control Plane.

The provider tabs below create a {{site.base_gateway}} Service and Route at `/claude-code-sso`,
two Consumers (`claude-standard-users` and `claude-power-users`), an
[openid-connect](/plugins/openid-connect/) Plugin for Okta JWT validation, consumer-scoped
[ai-proxy-advanced](/plugins/ai-proxy-advanced/) Plugins for model routing, and consumer-scoped
[ai-rate-limiting-advanced](/plugins/ai-rate-limiting-advanced/) Plugins for per-tier token limits.
See the [kongctl documentation](/kongctl/) for more on federated configuration management.

Select your provider below, export the required environment variables, and apply.

{% navtabs "Providers" %}
{% tab Anthropic %}

Export your environment variables:

```bash
export DECK_CHAT_MODEL_1='claude-sonnet-4-6'   # standard tier
export DECK_CHAT_MODEL_2='claude-opus-4-6'     # power tier, or claude-opus-4-1
```

`KONNECT_CONTROL_PLANE_NAME`, `DECK_OKTA_ISSUER`, `DECK_OKTA_AUDIENCE`, and `DECK_ANTHROPIC_TOKEN` are already exported during the Prerequisites, so they do not need to be re-exported per tab.

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_format_version: '3.0'
_info:
  select_tags:
  - claude-code-sso-recipe
consumers:
- username: claude-standard-users
- username: claude-power-users
services:
- name: claude-code-sso
  url: http://localhost
  routes:
  - name: claude-code-sso
    paths:
    - /claude-code-sso
    protocols:
    - http
    - https
    methods:
    - POST
    - OPTIONS
    strip_path: true
  plugins:
  - name: openid-connect
    instance_name: claude-code-sso-oidc
    config:
      issuer: ${{ env "DECK_OKTA_ISSUER" }}
      auth_methods:
      - bearer
      bearer_token_param_type:
      - header
      audience_claim:
      - aud
      audience_required:
      - ${{ env "DECK_OKTA_AUDIENCE" }}
      consumer_claim:
      - groups
      consumer_by:
      - username
      upstream_headers_claims:
      - sub
      - email
      upstream_headers_names:
      - X-Authenticated-User
      - X-User-Email
      ssl_verify: true
      hide_credentials: true
plugins:
- name: ai-proxy-advanced
  instance_name: claude-code-sso-standard-proxy
  service: claude-code-sso
  consumer: claude-standard-users
  config:
    llm_format: anthropic
    max_request_body_size: 10485760
    response_streaming: allow
    targets:
    - route_type: llm/v1/chat
      auth:
        header_name: x-api-key
        header_value: ${{ env "DECK_ANTHROPIC_TOKEN" }}
      logging:
        log_statistics: true
        log_payloads: true
      model:
        provider: anthropic
        name: ${{ env "DECK_CHAT_MODEL_1" }}
- name: ai-proxy-advanced
  instance_name: claude-code-sso-power-proxy
  service: claude-code-sso
  consumer: claude-power-users
  config:
    llm_format: anthropic
    max_request_body_size: 10485760
    response_streaming: allow
    targets:
    - route_type: llm/v1/chat
      auth:
        header_name: x-api-key
        header_value: ${{ env "DECK_ANTHROPIC_TOKEN" }}
      logging:
        log_statistics: true
        log_payloads: true
      model:
        provider: anthropic
        name: ${{ env "DECK_CHAT_MODEL_2" }}
- name: ai-rate-limiting-advanced
  instance_name: claude-code-sso-standard-ratelimit
  service: claude-code-sso
  consumer: claude-standard-users
  config:
    policies:
    - limits:
      - limit: 5000
        window_size: 60
      window_type: sliding
    identifier: consumer
    tokens_count_strategy: total_tokens
    strategy: local
    llm_format: anthropic
- name: ai-rate-limiting-advanced
  instance_name: claude-code-sso-power-ratelimit
  service: claude-code-sso
  consumer: claude-power-users
  config:
    policies:
    - limits:
      - limit: 25000
        window_size: 60
      window_type: sliding
    identifier: consumer
    tokens_count_strategy: total_tokens
    strategy: local
    llm_format: anthropic
EOF
{% endraw -%}

echo "
_defaults:
  kongctl:
    namespace: claude-code-sso-recipe
control_planes:
  - ref: recipe-cp
    name: \"${KONNECT_CONTROL_PLANE_NAME}\"
    _deck:
      files:
        - kong-recipe.yaml
" | kongctl sync -f - -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endtab %}
{% tab AWS Bedrock %}

Export your environment variables:

```bash
export DECK_CHAT_MODEL_1='anthropic.claude-sonnet-4-6-20250514-v1:0'   # standard tier
export DECK_CHAT_MODEL_2='anthropic.claude-opus-4-6-20250514-v1:0'     # power tier
```

`KONNECT_CONTROL_PLANE_NAME`, `DECK_OKTA_ISSUER`, `DECK_OKTA_AUDIENCE`, and the `DECK_AWS_*` credentials are already exported during the Prerequisites, so they do not need to be re-exported per tab.

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_format_version: '3.0'
_info:
  select_tags:
  - claude-code-sso-recipe
consumers:
- username: claude-standard-users
- username: claude-power-users
services:
- name: claude-code-sso
  url: http://localhost
  routes:
  - name: claude-code-sso
    paths:
    - /claude-code-sso
    protocols:
    - http
    - https
    methods:
    - POST
    - OPTIONS
    strip_path: true
  plugins:
  - name: openid-connect
    instance_name: claude-code-sso-oidc
    config:
      issuer: ${{ env "DECK_OKTA_ISSUER" }}
      auth_methods:
      - bearer
      bearer_token_param_type:
      - header
      audience_claim:
      - aud
      audience_required:
      - ${{ env "DECK_OKTA_AUDIENCE" }}
      consumer_claim:
      - groups
      consumer_by:
      - username
      upstream_headers_claims:
      - sub
      - email
      upstream_headers_names:
      - X-Authenticated-User
      - X-User-Email
      ssl_verify: true
      hide_credentials: true
plugins:
- name: ai-proxy-advanced
  instance_name: claude-code-sso-standard-proxy
  service: claude-code-sso
  consumer: claude-standard-users
  config:
    llm_format: anthropic
    max_request_body_size: 10485760
    response_streaming: allow
    targets:
    - route_type: llm/v1/chat
      auth:
        aws_access_key_id: ${{ env "DECK_AWS_ACCESS_KEY_ID" }}
        aws_secret_access_key: ${{ env "DECK_AWS_SECRET_ACCESS_KEY" }}
      logging:
        log_statistics: true
        log_payloads: true
      model:
        provider: bedrock
        name: ${{ env "DECK_CHAT_MODEL_1" }}
        options:
          bedrock:
            aws_region: ${{ env "DECK_AWS_REGION" }}
- name: ai-proxy-advanced
  instance_name: claude-code-sso-power-proxy
  service: claude-code-sso
  consumer: claude-power-users
  config:
    llm_format: anthropic
    max_request_body_size: 10485760
    response_streaming: allow
    targets:
    - route_type: llm/v1/chat
      auth:
        aws_access_key_id: ${{ env "DECK_AWS_ACCESS_KEY_ID" }}
        aws_secret_access_key: ${{ env "DECK_AWS_SECRET_ACCESS_KEY" }}
      logging:
        log_statistics: true
        log_payloads: true
      model:
        provider: bedrock
        name: ${{ env "DECK_CHAT_MODEL_2" }}
        options:
          bedrock:
            aws_region: ${{ env "DECK_AWS_REGION" }}
- name: ai-rate-limiting-advanced
  instance_name: claude-code-sso-standard-ratelimit
  service: claude-code-sso
  consumer: claude-standard-users
  config:
    policies:
    - limits:
      - limit: 5000
        window_size: 60
      window_type: sliding
    identifier: consumer
    tokens_count_strategy: total_tokens
    strategy: local
    llm_format: anthropic
- name: ai-rate-limiting-advanced
  instance_name: claude-code-sso-power-ratelimit
  service: claude-code-sso
  consumer: claude-power-users
  config:
    policies:
    - limits:
      - limit: 25000
        window_size: 60
      window_type: sliding
    identifier: consumer
    tokens_count_strategy: total_tokens
    strategy: local
    llm_format: anthropic
EOF
{% endraw -%}

echo "
_defaults:
  kongctl:
    namespace: claude-code-sso-recipe
control_planes:
  - ref: recipe-cp
    name: \"${KONNECT_CONTROL_PLANE_NAME}\"
    _deck:
      files:
        - kong-recipe.yaml
" | kongctl sync -f - -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endtab %}
{% tab Azure %}

Export your environment variables:

```bash
export DECK_CHAT_MODEL_1='claude-sonnet-4-6'   # standard tier, matches your Azure deployment name
export DECK_CHAT_MODEL_2='claude-opus-4-6'     # power tier, matches your Azure deployment name
```

`KONNECT_CONTROL_PLANE_NAME`, `DECK_OKTA_ISSUER`, `DECK_OKTA_AUDIENCE`, and the `DECK_AZURE_*` values are already exported during the Prerequisites, so they do not need to be re-exported per tab.

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_format_version: '3.0'
_info:
  select_tags:
  - claude-code-sso-recipe
consumers:
- username: claude-standard-users
- username: claude-power-users
services:
- name: claude-code-sso
  url: http://localhost
  routes:
  - name: claude-code-sso
    paths:
    - /claude-code-sso
    protocols:
    - http
    - https
    methods:
    - POST
    - OPTIONS
    strip_path: true
  plugins:
  - name: openid-connect
    instance_name: claude-code-sso-oidc
    config:
      issuer: ${{ env "DECK_OKTA_ISSUER" }}
      auth_methods:
      - bearer
      bearer_token_param_type:
      - header
      audience_claim:
      - aud
      audience_required:
      - ${{ env "DECK_OKTA_AUDIENCE" }}
      consumer_claim:
      - groups
      consumer_by:
      - username
      upstream_headers_claims:
      - sub
      - email
      upstream_headers_names:
      - X-Authenticated-User
      - X-User-Email
      ssl_verify: true
      hide_credentials: true
plugins:
- name: ai-proxy-advanced
  instance_name: claude-code-sso-standard-proxy
  service: claude-code-sso
  consumer: claude-standard-users
  config:
    llm_format: anthropic
    max_request_body_size: 10485760
    response_streaming: allow
    targets:
    - route_type: llm/v1/chat
      auth:
        header_name: api-key
        header_value: ${{ env "DECK_AZURE_API_KEY" }}
      logging:
        log_statistics: true
        log_payloads: true
      model:
        provider: azure
        name: ${{ env "DECK_CHAT_MODEL_1" }}
        options:
          azure_api_version: ${{ env "DECK_AZURE_API_VERSION" }}
          azure_deployment_id: ${{ env "DECK_AZURE_DEPLOYMENT_ID" }}
          azure_instance: ${{ env "DECK_AZURE_INSTANCE" }}
- name: ai-proxy-advanced
  instance_name: claude-code-sso-power-proxy
  service: claude-code-sso
  consumer: claude-power-users
  config:
    llm_format: anthropic
    max_request_body_size: 10485760
    response_streaming: allow
    targets:
    - route_type: llm/v1/chat
      auth:
        header_name: api-key
        header_value: ${{ env "DECK_AZURE_API_KEY" }}
      logging:
        log_statistics: true
        log_payloads: true
      model:
        provider: azure
        name: ${{ env "DECK_CHAT_MODEL_2" }}
        options:
          azure_api_version: ${{ env "DECK_AZURE_API_VERSION" }}
          azure_deployment_id: ${{ env "DECK_AZURE_DEPLOYMENT_ID" }}
          azure_instance: ${{ env "DECK_AZURE_INSTANCE" }}
- name: ai-rate-limiting-advanced
  instance_name: claude-code-sso-standard-ratelimit
  service: claude-code-sso
  consumer: claude-standard-users
  config:
    policies:
    - limits:
      - limit: 5000
        window_size: 60
      window_type: sliding
    identifier: consumer
    tokens_count_strategy: total_tokens
    strategy: local
    llm_format: anthropic
- name: ai-rate-limiting-advanced
  instance_name: claude-code-sso-power-ratelimit
  service: claude-code-sso
  consumer: claude-power-users
  config:
    policies:
    - limits:
      - limit: 25000
        window_size: 60
      window_type: sliding
    identifier: consumer
    tokens_count_strategy: total_tokens
    strategy: local
    llm_format: anthropic
EOF
{% endraw -%}

echo "
_defaults:
  kongctl:
    namespace: claude-code-sso-recipe
control_planes:
  - ref: recipe-cp
    name: \"${KONNECT_CONTROL_PLANE_NAME}\"
    _deck:
      files:
        - kong-recipe.yaml
" | kongctl sync -f - -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endtab %}
{% endnavtabs %}

## Try it out

With the configuration applied and Okta configured, Claude Code requests now flow through Kong
for authentication, model routing, and rate limiting. The primary way to verify is to use Claude
Code itself, the tool this recipe enables.

### Use Claude Code

Configure Claude Code to route through Kong by creating or updating `~/.claude/settings.json`:

```json
{
  "apiKeyHelper": "/Users/you/.claude/okta-claude-auth.sh",
  "env": {
    "ANTHROPIC_BASE_URL": "http://localhost:8000/claude-code-sso",
    "OKTA_DOMAIN": "https://your-org.okta.com",
    "OKTA_CLIENT_ID": "0oa1b2c3d4YourClientId",
    "OKTA_AUDIENCE": "api://claude-proxy"
  }
}
```

Replace `/Users/you/.claude/okta-claude-auth.sh` with the actual path to the helper script you
saved in Prerequisites. The `env` block passes variables to the `apiKeyHelper` process. Claude
Code runs `apiKeyHelper` in an isolated environment without access to your shell profile, so
all Okta variables must be listed here. `ANTHROPIC_BASE_URL` points Claude Code at Kong instead
of `api.anthropic.com`.

{:.warning}
> Claude Code checks credentials in this order: cloud provider credentials, then `ANTHROPIC_AUTH_TOKEN`, then `ANTHROPIC_API_KEY`, then `apiKeyHelper`. If `ANTHROPIC_API_KEY` is set in your environment, Claude Code uses it directly and never invokes `apiKeyHelper`, bypassing Kong entirely. Unset it before using this recipe: `unset ANTHROPIC_API_KEY`.

Launch Claude Code:

```bash
claude
```

On the first invocation (or when the cached token expires), a browser window opens to Okta for
authentication. After authenticating, the terminal continues automatically:

```text
[okta-auth] Opening browser for Okta login...
[okta-auth] Waiting for callback on http://localhost:9876/callback ...
[okta-auth] Authorization code received. Exchanging for tokens...
[okta-auth] Authentication successful. Token cached.

╭─────────────────────────────────╮
│ ✻  Welcome to Claude Code!      │
╰─────────────────────────────────╯
```
{:.no-copy-code}

Try asking a question. Claude Code sends the request through Kong, which validates your Okta JWT,
maps your group to a Consumer tier, injects the provider API key, and forwards to the configured
model.

Subsequent invocations reuse the cached token silently. No browser flow unless the refresh token
has expired.

### Example request and response

Claude Code sends requests to Kong in Anthropic's native message format. Here is what a typical
request and response look like.

Request:

```json
POST http://localhost:8000/claude-code-sso/v1/messages
Authorization: Bearer eyJhbG...

{
  "model": "claude-sonnet-4-6",
  "max_tokens": 1024,
  "messages": [
    { "role": "user", "content": "What is the capital of France?" }
  ]
}
```
{:.no-copy-code}

Response (Anthropic format, passed through or translated from the provider):

```json
{
  "id": "msg_abc123",
  "type": "message",
  "role": "assistant",
  "model": "claude-sonnet-4-6",
  "content": [
    {
      "type": "text",
      "text": "The capital of France is Paris."
    }
  ],
  "usage": {
    "input_tokens": 14,
    "output_tokens": 9
  }
}
```
{:.no-copy-code}

Kong adds the following response headers:

| Header | Description |
|--------|-------------|
| `X-Kong-LLM-Model` | Model name selected for this request |
| `X-Kong-Upstream-Latency` | Time (ms) Kong spent waiting for the provider to respond |
| `X-Kong-Proxy-Latency` | Time (ms) Kong spent processing the request (auth, rate limiting, format translation) |
| `X-AI-RateLimit-Limit-60-{provider}` | Token limit for the 60-second window for this Consumer tier |
| `X-AI-RateLimit-Remaining-60-{provider}` | Tokens remaining in the current window |
| `RateLimit-Reset` | Seconds until the window resets |

The `Authorization: Bearer` header on the request carries the Okta JWT. Kong validates it,
strips it before forwarding upstream, and injects the provider API key in its place. The
`usage` object in the response is what the AI Rate Limiting Advanced Plugin reads to track
token consumption against the Consumer's per-tier budget.

### What happened

When Claude Code made its first request:

1. The `apiKeyHelper` script ran the PKCE flow against Okta and returned a JWT.
2. Claude Code sent `POST /claude-code-sso/v1/messages` with `Authorization: Bearer <jwt>`.
3. Kong's openid-connect Plugin validated the JWT signature via Okta's JWKS endpoint, checked
   the audience claim, and mapped the `groups` claim to a Kong Consumer (e.g.
   `claude-standard-users`).
4. The consumer-scoped ai-proxy-advanced Plugin injected the provider API key and forwarded the
   request to the configured model for that tier.
5. The consumer-scoped ai-rate-limiting-advanced Plugin counted the request's tokens against the
   Consumer's token budget and added `X-AI-RateLimit-Remaining` headers to the response.

The provider API key never reached the developer's machine. Kong injected it server-side.
Revoking the user's Okta group membership or disabling their account immediately blocks access
on the next request.

### Verify with a script (optional)

This script exercises the same authentication and routing flow programmatically, showing rate
limit headers and testing unauthenticated access.

The script uses the Anthropic Python SDK with `auth_token`. This sends
`Authorization: Bearer <jwt>`, which is exactly what Claude Code does via
`apiKeyHelper`. The same client works regardless of which provider tab you applied
(Anthropic, Bedrock, or Azure AI Services) because the developer always talks to Kong in
Anthropic format with a Bearer token. Kong handles provider-specific auth injection and
format translation behind the scenes.

```bash
cat <<'EOF' > demo.py
"""
Claude Code SSO. Demo script
============================
Demonstrates Okta SSO authentication and consumer-based model routing
through {{site.ai_gateway_name}} using the Anthropic Python SDK.

The script uses the same client for every provider tab. Anthropic(auth_token=...)
sends Authorization: Bearer <jwt>, which is what the OIDC plugin validates. Kong
handles provider auth injection and format translation behind the scenes, so the
developer experience is provider-agnostic: always Anthropic SDK, always Bearer token.

Expected output:
  === Authenticated request ===
  [REQUEST] What is the capital of France?
  [RESPONSE] The capital of France is Paris.
  [MODEL] claude-sonnet-4-6
  [LATENCY] upstream=423ms  proxy=12ms  total=440ms
  [TOKEN LIMIT] 4850/5000 remaining (60s window)

  === Token rate limit countdown (5 rapid requests) ===
  [REQUEST 1] tokens remaining=4700/5000
  [REQUEST 2] tokens remaining=4550/5000
  [REQUEST 3] tokens remaining=4400/5000
  [REQUEST 4] tokens remaining=4250/5000
  [REQUEST 5] tokens remaining=4100/5000

  === Invalid JWT request ===
  [REQUEST] Authorization: Bearer not-a-valid-jwt
  [ERROR] 401 Unauthorized

How to run:
  1. Apply the recipe config (see README for the full kongctl sync command)
  2. Get an Okta token:
       export OKTA_TOKEN=$(bash okta-claude-auth.sh)
  3. Run:
       python demo.py
"""

import os
import sys
import time

from anthropic import Anthropic, APIStatusError

PROXY_URL = os.getenv("PROXY_URL", "http://localhost:8000")
CHAT_MODEL = os.getenv("CHAT_MODEL", "claude-sonnet-4-6")
OKTA_TOKEN = os.getenv("OKTA_TOKEN", "")

# ANSI color codes. Disabled when stdout isn't a TTY or NO_COLOR is set.
_USE_COLOR = sys.stdout.isatty() and "NO_COLOR" not in os.environ
def _c(code: str, s: str) -> str:
    return f"\033[{code}m{s}\033[0m" if _USE_COLOR else s
BOLD  = lambda s: _c("1", s)
DIM   = lambda s: _c("2", s)
GREEN = lambda s: _c("32", s)
BLUE  = lambda s: _c("34", s)
CYAN  = lambda s: _c("36", s)
RED   = lambda s: _c("31", s)
YELLOW= lambda s: _c("33", s)

if not OKTA_TOKEN:
    print(f"{RED(BOLD('[ERROR]'))} OKTA_TOKEN environment variable is required.")
    print("        Get a token: export OKTA_TOKEN=$(bash okta-claude-auth.sh)")
    sys.exit(1)

# The Anthropic SDK's auth_token parameter sends Authorization: Bearer <token>,
# which is exactly what the OIDC plugin validates. This works regardless of which
# provider tab you applied. Kong handles provider auth and format translation.
client = Anthropic(
    auth_token=OKTA_TOKEN,
    base_url=f"{PROXY_URL}/claude-code-sso",
)


def get_rate_limit_headers(headers):
    """Extract AI rate limit remaining and limit from response headers."""
    remaining = None
    limit = None
    for key, value in headers.items():
        key_lower = key.lower()
        if "ratelimit-remaining" in key_lower:
            remaining = value
        elif "ratelimit-limit" in key_lower and "remaining" not in key_lower:
            limit = value
    return remaining, limit


# --- 1. Authenticated request ---
print(BOLD("=== Authenticated request ==="))
prompt = "What is the capital of France? Answer in one sentence."
print(f"{BOLD('[REQUEST]')} {prompt}")

start_ms = round(time.time() * 1000)
try:
    raw = client.messages.with_raw_response.create(
        model=CHAT_MODEL,
        max_tokens=256,
        messages=[{"role": "user", "content": prompt}],
    )
    elapsed_ms = round(time.time() * 1000) - start_ms
    message = raw.parse()

    upstream_ms = raw.headers.get("x-kong-upstream-latency", "n/a")
    proxy_ms = raw.headers.get("x-kong-proxy-latency", "n/a")
    kong_model = raw.headers.get("x-kong-llm-model", message.model)
    remaining, limit = get_rate_limit_headers(raw.headers)

    print(f"[RESPONSE] {DIM(message.content[0].text)}")
    print(f"[MODEL] {CYAN(BOLD(kong_model))}")
    latency_text = f"upstream={upstream_ms}ms  proxy={proxy_ms}ms  total={elapsed_ms}ms"
    print(f"[LATENCY] {DIM(latency_text)}")
    # Token-limit remaining is the headline metric for this section.
    tokens_text = f"{remaining or 'n/a'}/{limit or 'n/a'}"
    print(f"[TOKEN LIMIT] {BLUE(BOLD(tokens_text))} remaining (60s window)")

except APIStatusError as e:
    elapsed_ms = round(time.time() * 1000) - start_ms
    print(f"{RED(BOLD('[ERROR]'))} {RED(BOLD(str(e.status_code)))} {e.message}  ({elapsed_ms}ms)")

# --- 2. Token rate limit countdown ---
print(f"\n{BOLD('=== Token rate limit countdown (5 rapid requests) ===')}")
for i in range(1, 6):
    try:
        raw = client.messages.with_raw_response.create(
            model=CHAT_MODEL,
            max_tokens=32,
            messages=[{"role": "user", "content": "Say 'ok' and nothing else."}],
        )
        remaining, limit = get_rate_limit_headers(raw.headers)
        # The countdown is the whole point of this section — color the remaining value.
        tokens_text = f"{remaining or 'n/a'}/{limit or 'n/a'}"
        print(f"[REQUEST {i}] tokens remaining={BLUE(BOLD(tokens_text))}")
    except APIStatusError as e:
        if e.status_code == 429:
            retry_after = e.response.headers.get('retry-after', 'n/a')
            print(f"[REQUEST {i}] {YELLOW(BOLD('TOKEN LIMIT EXCEEDED'))}, retry after {retry_after}s")
            break
        print(f"[REQUEST {i}] {RED(BOLD(str(e.status_code)))} {e.message}")

# --- 3. Invalid JWT request ---
print(f"\n{BOLD('=== Invalid JWT request ===')}")
print(f"{BOLD('[REQUEST]')} Authorization: Bearer not-a-valid-jwt")
# Present a malformed bearer token. The OIDC plugin rejects it before any LLM call.
unauth_client = Anthropic(
    auth_token="not-a-valid-jwt",
    base_url=f"{PROXY_URL}/claude-code-sso",
)
try:
    unauth_client.messages.create(
        model=CHAT_MODEL,
        max_tokens=32,
        messages=[{"role": "user", "content": "Hello"}],
    )
    print(f"{YELLOW(BOLD('[UNEXPECTED]'))} Request succeeded. OIDC plugin may not be configured.")
except APIStatusError as e:
    reason = "Unauthorized" if e.status_code == 401 else e.message
    print(f"{RED(BOLD('[ERROR]'))} {RED(BOLD(str(e.status_code)))} {reason}")
EOF
```
{:.collapsible}

Run it:

```bash
export OKTA_TOKEN=$(bash ~/.claude/okta-claude-auth.sh)
python demo.py
```

Example output:

```text
=== Authenticated request ===
[REQUEST] What is the capital of France? Answer in one sentence.
[RESPONSE] The capital of France is Paris.
[MODEL] claude-sonnet-4-6
[LATENCY] upstream=423ms  proxy=12ms  total=440ms
[TOKEN LIMIT] 4850/5000 remaining (60s window)

=== Token rate limit countdown (5 rapid requests) ===
[REQUEST 1] tokens remaining=4700/5000
[REQUEST 2] tokens remaining=4550/5000
[REQUEST 3] tokens remaining=4400/5000
[REQUEST 4] tokens remaining=4250/5000
[REQUEST 5] tokens remaining=4100/5000

=== Invalid JWT request ===
[REQUEST] Authorization: Bearer not-a-valid-jwt
[ERROR] 401 Unauthorized
```
{:.no-copy-code}

The first request shows a successful authenticated call. The `[MODEL]` line is read from the
`X-Kong-LLM-Model` response header that Kong adds, confirming which model the consumer-scoped
AI Proxy Advanced Plugin selected. The countdown demonstrates per-Consumer token rate limiting.
Each request consumes tokens from the budget within the 60-second sliding window, visible via
the `X-AI-RateLimit-Remaining` header. The invalid JWT request confirms that the OpenID Connect
Plugin rejects malformed Bearer tokens at the auth boundary, so no provider call is ever made.

### Explore in Konnect

Konnect's UI surfaces every resource the recipe created, so you can see the same configuration
the apply block put in place.

- **Control Plane.** Navigate to **API Gateway > Gateways > `claude-code-sso-recipe`** to view the
  Control Plane provisioned by the quickstart and adopted into the kongctl namespace.
- **Service and Routes.** Open the `claude-code-sso` Gateway Service. The **Routes** tab lists the
  `claude-code-sso` Route at `/claude-code-sso`. The **Plugins** tab shows the OpenID Connect
  Plugin attached to the Service, plus the consumer-scoped AI Proxy Advanced and AI Rate Limiting
  Advanced Plugins.
- **Consumers.** The **Consumers** menu lists `claude-standard-users` and `claude-power-users`,
  the Consumers that the OpenID Connect Plugin maps each Okta group to.
- **Analytics.** The **Analytics** tab on the `claude-code-sso` Service shows at-a-glance request
  volume, token counts, and latency for the demo traffic you just sent.
- **Observability.** The L1 **Observability** menu in the Konnect sidebar provides a deeper dive
  across Control Planes, including detailed analytics dashboards and log explorer views.

## Cleanup

The recipe's `select_tags` and kongctl namespace scoped all resources, so this teardown removes
only this recipe's configuration. Tear down the local data plane and delete the control plane
from Konnect:

```bash
export KONNECT_CONTROL_PLANE_NAME='claude-code-sso-recipe' && curl -Ls https://get.konghq.com/quickstart | bash -s -- -d -k $KONNECT_TOKEN
```

To remove the Claude Code configuration, reset `~/.claude/settings.json` to its original state
(remove the `apiKeyHelper` and `ANTHROPIC_BASE_URL` entries). Optionally remove the cached
tokens:

```bash
rm -rf ~/.claude/okta-cache/
```

## Variations and next steps

- **Switching models.** The easiest change. Update `DECK_CHAT_MODEL_1` and/or
  `DECK_CHAT_MODEL_2` to different model IDs and re-apply the configuration. The model names are
  resolved from environment variables at apply time, so no config file edits are needed. For
  example, switch the standard tier from `claude-sonnet-4-6` to `claude-opus-4-6` by changing
  one export.

- **Adding more Consumer tiers.** The recipe defines two tiers (standard and power), but you can
  add as many as your organization needs. Create additional Okta groups, add matching Kong
  Consumers, and add consumer-scoped Plugin instances for each. For example, an `intern` tier
  with a smaller model and stricter rate limits, or an `ml-team` tier with access to specialized
  models.

- **Adjusting token budgets.** The recipe sets 5,000 tokens/minute for standard and
  25,000 tokens/minute for power users. For production, you'll likely want larger windows and
  higher limits, for example `limit: [500000]` with `window_size: [86400]` for daily token budgets.
  You can also add multiple windows: `limit: [5000, 500000]` with `window_size: [60, 86400]`
  enforces both a per-minute burst limit and a daily budget simultaneously.

- **Multi-node rate limiting with Redis.** The recipe uses `strategy: local` for rate limiting,
  which keeps counters in memory on each Kong node. For production clusters with multiple data
  plane nodes, switch to `strategy: redis` and point to a shared Redis instance so rate limit
  counters are consistent across all nodes. See the
  [ai-rate-limiting-advanced](/plugins/ai-rate-limiting-advanced/)
  documentation for Redis configuration details.

- **Using a different IdP.** While this recipe uses Okta, the
  [openid-connect](/plugins/openid-connect/) Plugin works with any OIDC-compliant identity
  provider: Microsoft Entra ID, Auth0, Keycloak, PingIdentity, etc. The configuration is the
  same. Update the `issuer` URL and adjust the claim names to match your IdP's token format.
  The PKCE helper script also works with any OIDC provider that supports the authorization code
  + PKCE flow.

- **Adding OpenAI or other providers.** This recipe uses `llm_format: anthropic` because Claude
  Code sends requests in Anthropic's native format. This limits provider support to Anthropic,
  AWS Bedrock, and Azure AI Services (all hosting Claude models). If your team doesn't
  specifically need Claude Code and wants broader provider support (OpenAI, Google Gemini,
  Mistral, etc.), use the [basic-llm-routing](/cookbooks/basic-llm-routing/) recipe with
  `llm_format: openai` (the default), which supports all providers.
