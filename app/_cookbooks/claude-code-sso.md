---
title: Claude Code SSO
description: Authenticate Claude Code requests via Okta SSO with consumer-group-based model routing and per-tier rate limiting.
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
  - azure-foundry
  - vertex
extra_services:
  - name: Okta
    env_vars: [DECK_OKTA_ISSUER, DECK_OKTA_AUDIENCE]
    hint: "Create a Native Application in Okta with PKCE flow and configure an API Authorization Server with a groups claim. See the Okta section in Prerequisites."

hint: "Requires an Okta organization with admin access and LLM provider credentials."

prereqs:
  skip_product: true
  skip_tool: true
  inline:
    - title: "{{site.konnect_product_name}}"
      content: |
        This tutorial uses {{site.konnect_product_name}}. The [quickstart script](https://get.konghq.com/quickstart) provisions a recipe-scoped Control Plane and local Data Plane.

        1. Create a new personal access token by opening the [Konnect PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**.
        1. Export your token. The same token is reused later for kongctl commands:

           ```bash
           export KONNECT_TOKEN='YOUR_KONNECT_PAT'
           ```

        1. Set the recipe-scoped Control Plane name and run the quickstart script. The `-e` flags raise the data plane's nginx body buffer so Claude Code's large request payloads (full conversation context, tool definitions, file contents) stay in memory instead of spilling to disk:

           ```bash
           export KONNECT_CONTROL_PLANE_NAME='claude-code-sso-recipe'
           curl -Ls https://get.konghq.com/quickstart | \
             bash -s -- -k $KONNECT_TOKEN \
               -e KONG_NGINX_HTTP_CLIENT_BODY_BUFFER_SIZE=16m \
               -e KONG_NGINX_HTTP_CLIENT_MAX_BODY_SIZE=16m \
               --deck-output
           ```

           This provisions a {{site.konnect_product_name}} Control Plane named `claude-code-sso-recipe`, a local Data Plane connected to it, and prints `export` lines for the rest of the session vars. Paste those into your shell when prompted.
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
        This recipe requires an Okta organization with admin access. The steps below create one Native OIDC Application for Claude Code, enable refresh tokens, configure a `groups` claim on Okta's authorization server, and assign one test user to one group.

        **Create the Native Application**

        This is a public client representing Claude Code. Public clients use Authorization Code + PKCE without a client secret.

        1. In the Okta Admin Console, go to **Applications → Create App Integration**.
        1. Select **OIDC - OpenID Connect** and **Native Application**, then click **Next**.
        1. Name it `Claude Code`.
        1. Set the sign-in redirect URI to `http://localhost:9876/callback`. This is the local callback the helper script in the **Claude Code** prereq listens on.
        1. On the application's **General** tab under **Client Credentials**, confirm that **Proof Key for Code Exchange (PKCE)** is checked. Okta enables it by default for Native app types.
        1. Under **General Settings → Grant type**, check **Refresh Token** (alongside the **Authorization Code** entry that's already enabled). Without this, even when the helper script requests `offline_access`, Okta does not issue refresh tokens, and developers hit the browser PKCE flow on every token expiry.
        1. Copy the **Client ID** for use in the **Claude Code** prereq.

        **Confirm the authorization server scopes**

        The helper script requests `openid`, `profile`, `email`, and `offline_access`. Okta's `default` authorization server enables these out of the box, so no change is usually required.

        1. Go to **Security → API → Authorization Servers** and select the `default` server (or your custom server).
        1. Open the **Scopes** tab and confirm the four scopes above are listed and enabled. If `offline_access` is missing, add it. Without it, refresh tokens are never issued.

        **Configure the groups claim**

        The OpenID Connect Plugin reads the `groups` claim out of the access token and maps each value to a Kong Consumer Group with the same name. Configure the authorization server to include the claim:

        1. On the same authorization server, open the **Claims** tab and add a new claim:
           - **Name:** `groups`
           - **Include in token type:** Access Token
           - **Value type:** Groups
           - **Filter:** Matches regex `.*` (or restrict to a prefix like `claude-`)

        **Set up an Okta group and a test user**

        Create one group and assign one user to start. Kong is configured with both `claude-standard-users` and `claude-power-users` Consumer Groups, but you only need to test one tier at a time and can swap the user between groups later to exercise the other tier:

        1. Go to **Directory → Groups** and create `claude-standard-users`.
        1. Go to **Directory → People** and either add a new person (for example, `claude-test-user@example.com`) or pick an existing user. Make sure the user has a password set and can sign in.
        1. Open the user, go to the **Groups** tab, and assign them to `claude-standard-users`.
        1. Open the `Claude Code` application created above, go to the **Assignments** tab, and assign the same user. Without this, Okta blocks the OAuth flow at sign-in.

        To exercise the power tier later, also create a `claude-power-users` group. The [Swap to the power tier](#swap-to-the-power-tier) section walks through swapping the user between groups to switch tiers.

        **Export Okta endpoints and audience**

        The audience is configured on the authorization server itself, not per request. View or edit it at **Security → API → Authorization Servers → [server] → Settings tab → Audience**. The built-in `default` server uses `api://default`.

        ```bash
        export DECK_OKTA_ISSUER='https://your-org.okta.com/oauth2/default'
        export DECK_OKTA_AUDIENCE='api://default'
        # Salt for the openid-connect plugin's token cache key. Stable across syncs.
        # Not a credential. For production, regenerate with `openssl rand -hex 16` and
        # source from your secrets manager (or Kong Vaults).
        export DECK_OIDC_CACHE_TOKENS_SALT='claude-code-sso-dev-salt'
        ```

        If you use a custom authorization server, set `DECK_OKTA_ISSUER` to that server's issuer URL and `DECK_OKTA_AUDIENCE` to its configured audience value.
    - title: Claude Code
      content: |
        This recipe routes Claude Code through Kong using the [`apiKeyHelper`](https://docs.claude.com/en/docs/claude-code/settings) setting, which runs a script before each API call and uses its stdout as the credential.

        1. Install Claude Code from [docs.claude.com/en/docs/claude-code/setup](https://docs.claude.com/en/docs/claude-code/setup).
        1. Verify installation:

           ```bash
           claude --version
           ```

        {:.warning}
        > **`apiKeyHelper` is bypassed if `ANTHROPIC_API_KEY` or `ANTHROPIC_AUTH_TOKEN` is set in your environment.** Both env vars take precedence over the helper per Claude Code's [credential precedence rules](https://code.claude.com/docs/en/security-and-keys). If either is set in your shell profile, unset it before running Claude Code with this recipe: `unset ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN`.

        **Helper script: okta-claude-auth.sh**

        This script implements the OAuth 2.0 Authorization Code + PKCE flow against Okta, caches the token locally, and refreshes silently when possible. Save it to `~/.claude/okta-claude-auth.sh` and make it executable:

        ```bash
        cat <<'SCRIPT' > ~/.claude/okta-claude-auth.sh
        #!/usr/bin/env bash
        # okta-claude-auth.sh: apiKeyHelper for Claude Code + Okta PKCE
        set -euo pipefail

        OKTA_DOMAIN="${OKTA_DOMAIN:-"https://your-org.okta.com"}"
        CLIENT_ID="${OKTA_CLIENT_ID:-"0oa1b2c3d4YourClientId"}"
        REDIRECT_PORT="${OKTA_REDIRECT_PORT:-"9876"}"
        REDIRECT_URI="http://localhost:${REDIRECT_PORT}/callback"
        SCOPES="openid profile email offline_access"
        AUDIENCE="${OKTA_AUDIENCE:-"api://default"}"
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
          if command -v open >/dev/null 2>&1; then
            open "$auth_url" &
          elif command -v xdg-open >/dev/null 2>&1; then
            xdg-open "$auth_url" >/dev/null 2>&1 &
          fi
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
            (( waited > 30 )) && { log "Lock timeout, removing stale lock"; rm -rf "$LOCK_FILE"; }
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

        {:.info}
        > For a production rollout, distribute `okta-claude-auth.sh` through your internal tooling (a Homebrew tap, package manager, or setup script) rather than having every developer run this heredoc.

        **Configure Claude Code**

        Create or update `~/.claude/settings.json`. Pick the tab that matches the provider you'll apply Kong against:

        {% navtabs "Providers" %}
        {% navtab "Anthropic" %}
        ```json
        {
          "apiKeyHelper": "~/.claude/okta-claude-auth.sh",
          "env": {
            "ANTHROPIC_BASE_URL": "http://localhost:8000/claude-code-sso",
            "OKTA_DOMAIN": "https://your-org.okta.com",
            "OKTA_CLIENT_ID": "0oa1b2c3d4YourClientId",
            "OKTA_AUDIENCE": "api://default",
            "OKTA_AUTH_SERVER": "default",
            "ANTHROPIC_MODEL": "claude-sonnet-4-6",
            "ANTHROPIC_DEFAULT_SONNET_MODEL": "claude-sonnet-4-6",
            "ANTHROPIC_DEFAULT_OPUS_MODEL": "claude-opus-4-7"
          }
        }
        ```
        {% endnavtab %}
        {% navtab "AWS Bedrock" %}
        ```json
        {
          "apiKeyHelper": "~/.claude/okta-claude-auth.sh",
          "env": {
            "ANTHROPIC_BASE_URL": "http://localhost:8000/claude-code-sso",
            "OKTA_DOMAIN": "https://your-org.okta.com",
            "OKTA_CLIENT_ID": "0oa1b2c3d4YourClientId",
            "OKTA_AUDIENCE": "api://default",
            "OKTA_AUTH_SERVER": "default",
            "ANTHROPIC_MODEL": "claude-sonnet-4-5",
            "ANTHROPIC_DEFAULT_SONNET_MODEL": "claude-sonnet-4-5",
            "ANTHROPIC_DEFAULT_OPUS_MODEL": "claude-opus-4-6",
            "CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS": "1"
          }
        }
        ```

        {:.info}
        > `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1` is a precaution. The env var strips Anthropic's `anthropic-beta` headers and beta tool-schema fields (for example, `context_management`, `output_config.effort`) from outgoing requests. Anthropic betas are Anthropic-only by design, and non-Anthropic providers may reject requests carrying these fields with errors like `400 Extra inputs are not permitted`. Behavior varies by provider and beta, so this is a defensive default rather than a strict requirement. Leave it in place unless you have a specific reason to forward Anthropic betas to this upstream and have confirmed that path works.
        {% endnavtab %}
        {% navtab "Azure AI Foundry" %}
        ```json
        {
          "apiKeyHelper": "~/.claude/okta-claude-auth.sh",
          "env": {
            "ANTHROPIC_BASE_URL": "http://localhost:8000/claude-code-sso",
            "OKTA_DOMAIN": "https://your-org.okta.com",
            "OKTA_CLIENT_ID": "0oa1b2c3d4YourClientId",
            "OKTA_AUDIENCE": "api://default",
            "OKTA_AUTH_SERVER": "default",
            "ANTHROPIC_MODEL": "claude-sonnet-4-5",
            "ANTHROPIC_DEFAULT_SONNET_MODEL": "claude-sonnet-4-5",
            "ANTHROPIC_DEFAULT_OPUS_MODEL": "claude-opus-4-5",
            "CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS": "1"
          }
        }
        ```

        {:.info}
        > `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1` is a precaution. The env var strips Anthropic's `anthropic-beta` headers and beta tool-schema fields (for example, `context_management`, `output_config.effort`) from outgoing requests. Anthropic betas are Anthropic-only by design, and non-Anthropic providers may reject requests carrying these fields with errors like `400 Extra inputs are not permitted`. Behavior varies by provider and beta, so this is a defensive default rather than a strict requirement. Leave it in place unless you have a specific reason to forward Anthropic betas to this upstream and have confirmed that path works.
        {% endnavtab %}
        {% navtab "Google Vertex AI" %}
        ```json
        {
          "apiKeyHelper": "~/.claude/okta-claude-auth.sh",
          "env": {
            "ANTHROPIC_BASE_URL": "http://localhost:8000/claude-code-sso",
            "OKTA_DOMAIN": "https://your-org.okta.com",
            "OKTA_CLIENT_ID": "0oa1b2c3d4YourClientId",
            "OKTA_AUDIENCE": "api://default",
            "OKTA_AUTH_SERVER": "default",
            "ANTHROPIC_MODEL": "claude-sonnet-4-5",
            "ANTHROPIC_DEFAULT_SONNET_MODEL": "claude-sonnet-4-5",
            "ANTHROPIC_DEFAULT_OPUS_MODEL": "claude-opus-4-5",
            "CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS": "1"
          }
        }
        ```

        {:.info}
        > `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1` is a precaution. The env var strips Anthropic's `anthropic-beta` headers and beta tool-schema fields (for example, `context_management`, `output_config.effort`) from outgoing requests. Anthropic betas are Anthropic-only by design, and non-Anthropic providers may reject requests carrying these fields with errors like `400 Extra inputs are not permitted`. Behavior varies by provider and beta, so this is a defensive default rather than a strict requirement. Leave it in place unless you have a specific reason to forward Anthropic betas to this upstream and have confirmed that path works.
        {% endnavtab %}
        {% endnavtabs %}

        Replace `https://your-org.okta.com` and `0oa1b2c3d4YourClientId` with values from your Okta setup. Claude Code runs `apiKeyHelper` in an isolated environment without access to your shell profile, so all Okta variables must be listed in the `env` block. `ANTHROPIC_BASE_URL` points Claude Code at Kong. `OKTA_AUTH_SERVER` defaults to `default`; set it to your custom server's ID if you use one.

        The model env vars pin which name Claude Code sends in the request body so it always matches a `model_alias` configured in Kong:

        - **`ANTHROPIC_MODEL`** sets the active model from session start. Without it, the picker boots on the system default and Claude Code sends the literal placeholder `<default>`, which has no matching alias in Kong.
        - **`ANTHROPIC_DEFAULT_SONNET_MODEL`** and **`ANTHROPIC_DEFAULT_OPUS_MODEL`** control what the `sonnet` and `opus` aliases resolve to when the user runs `/model sonnet` or `/model opus` mid-session.

        These three values must match the `DECK_SONNET_ALIAS` and `DECK_OPUS_ALIAS` set in the apply step. That's the alias contract Kong uses to route the request to the right tier. Whenever the platform team rolls out a new model version (for example, Sonnet 4.6 lands on Bedrock), they update the four `DECK_*` values in Kong and announce a corresponding bump for the three `ANTHROPIC_*_MODEL` values here.

        {:.warning}
        > On Windows, Claude Code does not expand `~` in the `apiKeyHelper` field ([known issue](https://github.com/anthropics/claude-code/issues/13013)). Substitute the absolute path, for example `C:\\Users\\you\\.claude\\okta-claude-auth.sh`. Tilde expansion works on macOS and Linux.
    - title: AI Credentials
      content: |
        {% navtabs "Providers" %}
        {% navtab "Anthropic" %}
        This tutorial uses Anthropic:

        1. [Create an Anthropic account](https://console.anthropic.com/).
        1. [Get an API key](https://console.anthropic.com/settings/keys).
        1. Create a decK variable with the API key:

           ```bash
           export DECK_ANTHROPIC_TOKEN='YOUR-ANTHROPIC-KEY'
           ```
        {% endnavtab %}
        {% navtab "AWS Bedrock" %}
        This tutorial uses AWS Bedrock:

        1. Ensure you have an AWS account with [Bedrock model access](https://docs.aws.amazon.com/bedrock/latest/userguide/model-access.html) enabled.
        1. Create decK variables with your AWS credentials:

           ```bash
           export DECK_AWS_ACCESS_KEY_ID='your-access-key'
           export DECK_AWS_SECRET_ACCESS_KEY='your-secret-key'
           export DECK_AWS_REGION='us-east-1'
           ```
        {% endnavtab %}
        {% navtab "Azure AI Foundry" %}
        This tutorial uses [Azure AI Foundry](https://learn.microsoft.com/en-us/azure/ai-foundry/), which hosts Claude at `https://<resource>.services.ai.azure.com/anthropic/v1/messages`.

        1. Ensure you have a Foundry project with Claude Sonnet 4.5 and Claude Opus 4.5 deployments. The deployment names you assigned in the portal become `DECK_AZURE_FOUNDRY_DEPLOYMENT_ID_1` and `_2`.
        1. Create decK variables. `DECK_AZURE_FOUNDRY_UPSTREAM_URL` is the full endpoint URL Kong will call. `DECK_AZURE_FOUNDRY_TOKEN` accepts either a Foundry API key or an [Entra ID](https://learn.microsoft.com/en-us/azure/ai-foundry/concepts/rbac-azure-ai-foundry) bearer token; the provider config prefixes `Bearer ` automatically:

           ```bash
           export DECK_AZURE_FOUNDRY_INSTANCE='your-foundry-resource'
           export DECK_AZURE_FOUNDRY_UPSTREAM_URL="https://${DECK_AZURE_FOUNDRY_INSTANCE}.services.ai.azure.com/anthropic/v1/messages"
           export DECK_AZURE_FOUNDRY_DEPLOYMENT_ID_1='your-sonnet-deployment'
           export DECK_AZURE_FOUNDRY_DEPLOYMENT_ID_2='your-opus-deployment'
           export DECK_AZURE_FOUNDRY_TOKEN='your-foundry-token'
           ```
        {% endnavtab %}
        {% navtab "Google Vertex AI" %}
        This tutorial uses [Google Vertex AI Model Garden](https://cloud.google.com/vertex-ai/generative-ai/docs/partner-models/use-claude), which hosts Claude on Google Cloud.

        1. Ensure your GCP project has the Vertex AI API enabled, Claude Sonnet 4.5 and Claude Opus 4.5 access granted in Model Garden, and a service account JSON key with `roles/aiplatform.user`.
        1. Create decK variables. `DECK_VERTEX_LOCATION_ID` accepts `global` (works for every Claude variant) or a regional endpoint like `us-east5`, `europe-west1`, or `asia-southeast1`:

           ```bash
           export DECK_VERTEX_PROJECT_ID='your-gcp-project-id'
           export DECK_VERTEX_LOCATION_ID='global'
           export DECK_VERTEX_API_ENDPOINT='aiplatform.googleapis.com'
           export DECK_VERTEX_SERVICE_ACCOUNT_JSON="$(cat path/to/service-account-key.json)"
           ```

           Service account JSON is one of four [GCP IAM auth modes](/ai-gateway/ai-providers/vertex/#authentication-with-gcp-iam) the AI Proxy Advanced Plugin supports for Vertex. If you leave `DECK_VERTEX_SERVICE_ACCOUNT_JSON` unset, Kong falls back through the same chain `gcloud` uses: the `GCP_SERVICE_ACCOUNT` env var on the data plane, then the workload IAM role (for example, a GKE service account), then the VM instance role. For production, prefer workload identity over a downloaded key.
        {% endnavtab %}
        {% endnavtabs %}

overview: |
  This recipe puts {{site.ai_gateway_name}} in front of Anthropic Console API access (or AWS Bedrock) so
  every Claude Code request from your engineering team is authenticated via Okta SSO, routed to a
  model tier based on the developer's Okta group membership, and subject to per-tier token rate
  limits. No provider credentials sit on developer machines.

  The recipe uses three Kong Plugins working together: the
  [OpenID Connect](/plugins/openid-connect/) Plugin for Okta JWT validation, the
  [AI Proxy Advanced](/plugins/ai-proxy-advanced/) Plugin for Consumer-Group-scoped model routing,
  and the [AI Rate Limiting Advanced](/plugins/ai-rate-limiting-advanced/) Plugin for per-tier token
  budgets.

  Scope: this recipe governs Claude Code's API-key authentication path. That's the path it uses
  when configured with `apiKeyHelper`, `ANTHROPIC_API_KEY`, `ANTHROPIC_AUTH_TOKEN`, or cloud-provider
  credentials. Claude.ai subscription seats authenticated via interactive `claude /login` go
  directly to Anthropic, bill against the subscription seat, and are out of scope.
---

## The problem

Anthropic Console API keys (and AWS Bedrock provider credentials) give engineers programmatic
access to LLMs through Claude Code, but the access is governed at the *credential level*, not at
the *organizational identity level*. That gap creates several blind spots at scale:

**Static keys are shared and untraceable.** A single Console API key (or AWS access key) is
typically distributed across a team via shell profiles, `.env` files, or CI secrets stores. Every developer's requests are indistinguishable on the Anthropic bill. When a key leaks
in shell history or a commit, rotation requires touching every machine and pipeline that uses it.
There is no per-user audit trail, no way to revoke one person's access without rotating the
shared key, and no mechanism to assign different models or rate limits to different roles.

**No coupling to organizational identity.** Okta already defines who belongs to which team, what
MFA policy applies, and when access should be revoked. The API key has no connection to Okta's
session state. A developer removed from an Okta group at 10 AM can still call the API at 3 PM
because the cached key never re-checks anything. Anthropic's
[Claude.ai SSO](https://support.claude.com/en/articles/13132885-set-up-single-sign-on-sso) governs
the parallel `claude /login` subscription path on Pro / Max / Team / Enterprise plans, not API
keys. The two paths are
[separate billing relationships](https://support.claude.com/en/articles/9876003) at Anthropic.

**No model governance.** Every developer with a valid key gets the same model access. There is no
built-in way to say "interns get Haiku, senior engineers get Opus" or "this team's monthly token
budget is 500K." Cost controls happen retroactively through billing alerts, not proactively through
access policy.

The root issue is that trust is established at the *developer machine*, not at a server-side
enforcement point your organization controls. That enforcement point is what this recipe builds.

## The solution

This recipe moves the enforcement point to a {{site.base_gateway}} that your organization controls,
with Okta as the single source of truth for identity. It applies to Claude Code's API-key path,
the path it uses when configured with `apiKeyHelper`, `ANTHROPIC_API_KEY`, `ANTHROPIC_AUTH_TOKEN`,
or AWS provider credentials:

- **Developers never hold the provider key.** Kong holds the Console API key (or Bedrock
  credentials) and injects it server-side after validating an Okta-issued JWT. Key rotation
  happens in one place (Kong's config), not on every developer machine.
- **Okta drives identity.** Claude Code presents the developer's Okta JWT via `apiKeyHelper`.
  Kong validates the signature against Okta's JWKS keys on every request. Removing a user from
  an Okta group or disabling their account immediately blocks API access on the next call.
- **Consumer-Group-based model routing** maps Okta groups to Kong Consumer Groups, each with
  their own AI Proxy Advanced Plugin instance and model alias set. Standard users can request
  only the cost-efficient model; power users can request both that model and the most capable one.
  Changing a user's tier is an Okta group assignment, not a config change.
- **Per-tier token budgets** apply different rate limits to each Consumer Group so the gateway
  enforces cost ceilings at the boundary rather than reacting to billing alerts after the fact.
- **Explicit tier enforcement.** A standard user requesting Opus is rejected at Kong with a
  `400 model not configured`. There is no silent downgrade and no upstream provider call.

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
    K->>K: openid-connect (JWKS validate, Okta group to Kong Consumer Group)
    K->>K: ai-proxy-advanced (alias check, inject provider key, Route by tier)
    K->>K: ai-rate-limiting-advanced (per-tier token budget)
    K->>L: Forwarded request
    activate L
    L-->>K: Provider response
    deactivate L
    K-->>CC: Anthropic-format response
    deactivate K
{% endmermaid %}
<!-- vale on -->

{% table %}
columns:
  - title: Component
    key: component
  - title: Responsibility
    key: responsibility
rows:
  - component: "`okta-claude-auth.sh`"
    responsibility: "PKCE flow, token caching, silent refresh. Runs on the developer machine."
  - component: "Okta"
    responsibility: "Identity, MFA, group membership, JWT issuance."
  - component: "Kong, [OpenID Connect](/plugins/openid-connect/) Plugin"
    responsibility: "JWT signature validation via JWKS, audience verification, Okta group to Kong Consumer Group mapping."
  - component: "Kong, [AI Proxy Advanced](/plugins/ai-proxy-advanced/) Plugin"
    responsibility: "LLM provider auth injection, model alias matching for tier enforcement, format translation."
  - component: "Kong, [AI Rate Limiting Advanced](/plugins/ai-rate-limiting-advanced/) Plugin"
    responsibility: "Per-Consumer-Group token rate limits with sliding windows."
  - component: "LLM provider"
    responsibility: "Model inference."
{% endtable %}

{:.info}
> Claude Code sends requests in Anthropic's native format. This recipe uses `llm_format: anthropic` in the AI Proxy Advanced Plugin so requests pass through to Anthropic without translation, and translate to Bedrock's InvokeModel API on the Bedrock tab.

## How it works

When a developer runs Claude Code, every API request flows through Kong before reaching the
LLM provider. Here is the complete request lifecycle:

1. **Token acquisition.** Claude Code invokes the `apiKeyHelper` script (`okta-claude-auth.sh`)
   before each API call. The script checks its local token cache for a valid access token. If the
   token has expired but a refresh token exists, it silently exchanges for a new access token via
   Okta's token endpoint. If no valid tokens exist, it opens a browser to Okta's authorization
   endpoint for a full PKCE authentication flow, captures the authorization code via a local
   callback server, and exchanges it for tokens. The resulting JWT is returned to Claude Code.

2. **Request to Kong.** Claude Code sends `POST /claude-code-sso/v1/messages` with
   `Authorization: Bearer <jwt>` to Kong. The request body is in Anthropic's native message
   format and pins the model name to one of Claude Code's bare aliases (`claude-sonnet-4-6`,
   `claude-opus-4-7`) via the `ANTHROPIC_DEFAULT_*_MODEL` env vars in `~/.claude/settings.json`.

3. **JWT validation and Consumer Group mapping.** The OpenID Connect Plugin validates the JWT
   signature against Okta's cached JWKS keys, checks expiry, and verifies the `aud` claim. It
   then reads the `groups` array from the JWT and resolves each value to a Kong Consumer Group
   with the same name. A user in `claude-power-users` is attached to the `claude-power-users`
   Consumer Group.

4. **Tier enforcement and credential injection.** The Consumer-Group-scoped AI Proxy Advanced
   Plugin matches the request body's `model` value against the `model_alias` on each of its
   targets. The standard tier registers only `claude-sonnet-4-6`; the power tier registers both
   `claude-sonnet-4-6` and `claude-opus-4-7`. A standard user requesting Opus produces no match
   and is rejected with `400 model not configured`. On match, Kong injects the provider API key
   server-side and forwards the request to the configured upstream model.

5. **Token rate limiting.** The Consumer-Group-scoped AI Rate Limiting Advanced Plugin counts
   prompt and completion tokens against the tier's per-window budget. Rate-limit headers
   (`X-AI-RateLimit-Remaining-*`) are added to the response. Exhaustion returns
   `429 Too Many Requests` with a `Retry-After` header.

6. **Response.** The provider's response flows back through Kong to Claude Code. Subsequent
   requests reuse the cached Okta token silently. No browser flow unless the refresh token
   has expired.

### OpenID Connect: JWT validation and Consumer Group mapping

The OpenID Connect Plugin is the authentication layer. It validates every incoming JWT against
Okta's JWKS keys, rejects tokens that have expired or were issued for a different audience, and
attaches the developer's Okta groups to the request as Kong Consumer Groups. This Consumer Group
attachment is the bridge between your identity provider and Kong's tier-scoped Plugins. It
determines which AI Proxy Advanced and AI Rate Limiting Advanced instances run on the request.

#### Configuration details

{%- raw %}
```yaml
plugins:
  - name: openid-connect
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
      consumer_groups_claim:
        - groups
      consumer_optional: true
      consumer_groups_optional: false
      upstream_headers_claims:
        - sub
        - email
      upstream_headers_names:
        - X-Authenticated-User
        - X-User-Email
      ssl_verify: true
      hide_credentials: true
      cache_tokens_salt: ${{ env "DECK_OIDC_CACHE_TOKENS_SALT" }}
```
{% endraw -%}
{:.no-copy-code}

**`issuer`**. The Okta authorization server's base URL. Kong appends
`/.well-known/openid-configuration` to discover JWKS endpoints, signing keys, and token metadata
automatically. Kong caches the JWKS keys to avoid hitting Okta on every request.

**`auth_methods: [bearer]`**. Tells Kong to look for a Bearer token in the `Authorization`
header. Claude Code's `apiKeyHelper` outputs a bare token, and Claude Code sends it as
`Authorization: Bearer <token>`.

**`audience_required`**. The JWT's `aud` claim must match this value exactly. This prevents
tokens issued for other Okta applications from being accepted. Set it to the audience you
configured on the Okta authorization server.

**`consumer_groups_claim: [groups]`** with **`consumer_optional: true`** and
**`consumer_groups_optional: false`**. The Plugin reads the `groups` array from the validated
JWT and resolves each value against existing Kong Consumer Group names. A JWT with
`"groups": ["claude-power-users"]` attaches the request to the `claude-power-users` Consumer
Group; downstream tier-scoped Plugins fire automatically. `consumer_optional: true` allows
requests through without a per-user Consumer mapping. `consumer_groups_optional: false` blocks
any authenticated user whose groups don't match a configured Consumer Group, so an Okta user
without a tier assignment is rejected at the gateway.

**`upstream_headers_claims`** and **`upstream_headers_names`**. Forward the JWT's `sub` and
`email` claims as `X-Authenticated-User` and `X-User-Email` upstream. Useful for audit logging.
You can see which user made each request without decoding the JWT.

**`ssl_verify: true`**. Enables TLS certificate verification when Kong connects to Okta's JWKS
endpoint. In {{site.base_gateway}} 3.14+, this defaults to `true` as part of the Secure by
Default initiative. Set explicitly here for clarity.

**`hide_credentials: true`**. Strips the `Authorization` header from the request before
forwarding upstream. Since the AI Proxy Advanced Plugin injects its own provider credentials,
the Okta JWT is not needed upstream. In {{site.base_gateway}} 3.14+, this defaults to `true`.
Set explicitly here for clarity.

**`cache_tokens_salt`**. Salt used when deriving the cache key for token-endpoint responses.
The Plugin requires this to be set explicitly to a stable value so cached entries survive
`deck gateway sync`. The value is not a credential and grants no token-forgery capability, but
treat it as mildly sensitive (it influences cache-key predictability). For production,
regenerate with `openssl rand -hex 16` and source it from a vault.

**Alternative configurations:**

- **`anonymous`**. Set to a Consumer username to fall back to when authentication fails
  entirely. Creates a public-access tier with its own rate limits and model access.
- **`groups_required`**. Authorization layer. Reject any JWT whose `groups` claim doesn't include
  one of the listed values, before consumer-group mapping runs. Useful when only a subset of
  Okta-authenticated users should see this Service at all.

### AI Proxy Advanced: model alias matching and tier enforcement

Each tier gets its own AI Proxy Advanced Plugin instance, scoped to one Consumer Group. The
Plugin uses the `model_alias` field on each target to decide which target serves a request.
Claude Code sends bare model names like `claude-sonnet-4-6` in the request body; the Plugin
matches that value against the configured aliases and Routes to the matching target. A standard
user picking Opus produces a body model of `claude-opus-4-7`, which has no matching target on
the standard tier proxy, so AI Proxy Advanced returns `400 model not configured`. The block is
explicit and visible to the user.

The mapping from alias to actual provider model name is what insulates developers from the
underlying provider. The platform team controls `model.name` (the real Anthropic or Bedrock
model ID); developers always speak in stable bare aliases.

#### Configuration details

The standard tier configures one target. The power tier configures two:

{%- raw %}
```yaml
plugins:
  - name: ai-proxy-advanced
    consumer_group: claude-standard-users
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
            model_alias: ${{ env "DECK_SONNET_ALIAS" }}
            provider: anthropic
            name: ${{ env "DECK_CHAT_MODEL_1" }}
  - name: ai-proxy-advanced
    consumer_group: claude-power-users
    config:
      llm_format: anthropic
      max_request_body_size: 10485760
      response_streaming: allow
      targets:
        - route_type: llm/v1/chat
          auth:
            header_name: x-api-key
            header_value: ${{ env "DECK_ANTHROPIC_TOKEN" }}
          model:
            model_alias: ${{ env "DECK_SONNET_ALIAS" }}
            provider: anthropic
            name: ${{ env "DECK_CHAT_MODEL_1" }}
        - route_type: llm/v1/chat
          auth:
            header_name: x-api-key
            header_value: ${{ env "DECK_ANTHROPIC_TOKEN" }}
          model:
            model_alias: ${{ env "DECK_OPUS_ALIAS" }}
            provider: anthropic
            name: ${{ env "DECK_CHAT_MODEL_2" }}
```
{% endraw -%}
{: .no-copy-code .collapsible }

**`llm_format: anthropic`**. Claude Code sends requests in Anthropic's native format
(`/v1/messages` with `messages` array). For Anthropic, requests pass through natively. For AWS
Bedrock (hosting Claude models), the Plugin translates from Anthropic format to Bedrock's
InvokeModel API automatically. Claude Code always speaks Anthropic; Kong handles the rest.

{:.warning}
> Do not use `llm_format: openai` with Claude Code. Claude Code sends Anthropic-native tool definitions in its requests. The OpenAI format translation path mangles these structures, causing 400 errors from the LLM provider (typically `tools: Input should be a valid list`). Always use `llm_format: anthropic` when proxying Claude Code traffic.

**`consumer_group: claude-standard-users`** (and `claude-power-users`). Scopes each Plugin
instance to one Consumer Group. The OpenID Connect Plugin attaches the request to a Consumer
Group based on the JWT's `groups` claim, and the matching tier-scoped Plugin instance fires.

**`auth`**. Kong holds the provider API key and injects it on every upstream request. The
developer's Okta JWT is used only for authentication at the Kong layer. It never reaches the
LLM provider. Credential values come from environment variables via decK's
{%raw%}`${{ env "..." }}`{%endraw%} syntax, resolved at apply time.

**`route_type: llm/v1/chat`**. Selects the chat-completions translation path. See the
[AI Proxy Advanced reference](/plugins/ai-proxy-advanced/reference/) for the full list of
supported Route types.

**`model.model_alias`**. The bare name Claude Code sends in the request body. The Plugin matches
this string against the body's `model` field and picks the corresponding target. With one
alias per target on the standard tier, only requests for `claude-sonnet-4-6` resolve.

**`model.name`**. The actual provider model ID Kong sends upstream. For Anthropic, this is the
same bare name (`claude-sonnet-4-6`); for Bedrock, it's the long form
(`anthropic.claude-sonnet-4-6-20250514-v1:0`). When the platform team upgrades the underlying
model, they change `DECK_CHAT_MODEL_1` or `DECK_CHAT_MODEL_2` and re-apply. Developers do not
need to update anything on their side.

**`logging.log_statistics`**. Appends token usage data (`prompt_tokens`, `completion_tokens`)
to any attached logging Plugin's output (for example, [HTTP Log](/plugins/http-log/) or
[File Log](/plugins/file-log/)). Combined with the `X-Authenticated-User` header from the
OpenID Connect Plugin, this enables per-user cost attribution.

**`logging.log_payloads`**. Includes request and response bodies in logging Plugin output.
Whether to enable this depends on your organization's observability and compliance requirements.

**`max_request_body_size: 10485760`**. Sets the maximum allowed request body to 10 MB. Claude
Code conversations accumulate large context windows (100 KB or more of conversation history,
tool results, and file contents). The default body size limit rejects these requests.

**`response_streaming: allow`**. Permits the Plugin to pass Server-Sent Events streaming
responses from the provider back to Claude Code. Claude Code uses streaming for interactive
terminal output. Without this setting, streaming responses can be buffered or rejected.

**Alternative configurations:**

- **Add a third tier.** Create another Consumer Group (for example, `claude-intern-users`),
  another AI Proxy Advanced instance scoped to it, and another Okta group. The Consumer Group
  name must match the Okta group name exactly.
- **Allow the same model under different aliases.** Add multiple targets sharing one alias and
  use a `balancer` block to load-balance across them, or split traffic by `match` conditions.
  See the [AI Proxy Advanced reference](/plugins/ai-proxy-advanced/reference/) for routing
  strategies.

### AI Rate Limiting Advanced: per-tier token limits

Each tier gets its own AI Rate Limiting Advanced instance with its own token budget. Unlike
request-count rate limiting, this Plugin counts tokens (prompt + completion), which is the
correct unit for LLM cost control. Standard users get a smaller token budget per window;
power users get a larger one. When a tier exhausts its budget, Kong returns
`429 Too Many Requests` until the window resets.

#### Configuration details

```yaml
plugins:
  - name: ai-rate-limiting-advanced
    consumer_group: claude-standard-users
    config:
      policies:
        - limits:
            - limit: 20000
              window_size: 60
          window_type: sliding
      identifier: consumer-group
      tokens_count_strategy: total_tokens
      strategy: local
      llm_format: anthropic
```
{:.no-copy-code}

**`policies`**. An array of rate-limiting policies. Each policy contains a `limits` array of
limit/window pairs and an optional `match` array for targeting providers, models, or other
dimensions. A policy without `match` conditions acts as a fallback that applies to all requests,
which is what this recipe uses since each Plugin instance is already Consumer-Group-scoped.
Standard users get 20,000 total tokens per 60-second window; power users get 100,000.

**`window_type: sliding`**. Uses a sliding-window algorithm for smoother rate limiting compared
to fixed windows. The `fixed` alternative uses strict time windows and resets all counters at
the boundary.

**`tokens_count_strategy: total_tokens`**. Counts both prompt (input) and completion (output)
tokens against the limit. Alternatives are `prompt_tokens`, `completion_tokens`, or `cost`.

**`identifier: consumer-group`**. Tracks token usage per Kong Consumer Group. Required when
the Plugin instance is scoped to a Consumer Group, because a user can belong to multiple groups
and the Plugin needs to know which group's counter to increment.

**`strategy: local`**. Uses in-memory counters on each Kong node. Fine for single-node or
development deployments. For multi-node production clusters, switch to `strategy: redis` with
a shared Redis instance so counters stay consistent across nodes.

**`llm_format: anthropic`**. Must match the `llm_format` on the AI Proxy Advanced Plugin so
the rate limiting Plugin can correctly parse token counts from the response.

Kong returns token rate-limit headers with every response:

{% table %}
columns:
  - title: Header
    key: header
  - title: Description
    key: description
rows:
  - header: "`X-AI-RateLimit-Limit-{window}-{provider}`"
    description: "Maximum tokens allowed in the window."
  - header: "`X-AI-RateLimit-Remaining-{window}-{provider}`"
    description: "Tokens remaining in the current window."
  - header: "`RateLimit-Reset`"
    description: "Seconds until the window resets."
{% endtable %}

When the token limit is exceeded, Kong returns `429 Too Many Requests` with a `Retry-After`
header.

{:.info}
> The 60-second windows here are intentionally aggressive for the demo so a few interactive prompts visibly exhaust the budget. Most teams enforce monthly or daily token budgets in production, for example {%raw%}`limits: [{limit: 5000000, window_size: 2592000}]`{%endraw%}. Combine with [Kong Vaults](/gateway/latest/kong-enterprise/secrets-management/) using {%raw%}`{vault://backend/key}`{%endraw%} references for credentials in production rather than environment variables.

## Apply the Kong configuration

This section configures the Control Plane in two parts. First, adopt the quickstart Control Plane into a kongctl namespace so the apply commands below can manage it. The recipe's `select_tags` and the `claude-code-sso-recipe` namespace scope every resource so teardown removes only this recipe's configuration.

```bash
kongctl adopt control-plane "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Adoption stamps the `KONGCTL-namespace` label on the Control Plane.

The provider tabs below create a Service and Route at `/claude-code-sso`, two Consumer Groups (`claude-standard-users` and `claude-power-users`), an [OpenID Connect](/plugins/openid-connect/) Plugin for Okta JWT validation, Consumer-Group-scoped [AI Proxy Advanced](/plugins/ai-proxy-advanced/) Plugins for tier-based model alias routing, and Consumer-Group-scoped [AI Rate Limiting Advanced](/plugins/ai-rate-limiting-advanced/) Plugins for per-tier token limits. See the [kongctl documentation](/kongctl/) for more on federated configuration management.

Select your provider below, export the required environment variables, and apply.

{% navtabs "Providers" %}
{% navtab "Anthropic" %}

Export your environment variables:

```bash
export DECK_SONNET_ALIAS='claude-sonnet-4-6'   # standard tier alias
export DECK_OPUS_ALIAS='claude-opus-4-7'       # power tier alias
export DECK_CHAT_MODEL_1='claude-sonnet-4-6'   # actual upstream model behind the sonnet alias
export DECK_CHAT_MODEL_2='claude-opus-4-7'     # actual upstream model behind the opus alias
```

{:.warning}
> The two alias values must match the `ANTHROPIC_DEFAULT_SONNET_MODEL` and `ANTHROPIC_DEFAULT_OPUS_MODEL` set in each developer's `~/.claude/settings.json`, and the model versions you point them at must actually exist in your provider account. Claude Code pattern-matches the alias to decide which features (effort levels, extended thinking, beta tool fields) to enable. A mismatch (for example, claiming `claude-sonnet-4-6` when the upstream is Sonnet 4.5) sends fields the upstream rejects with `400`.

`KONNECT_CONTROL_PLANE_NAME`, `DECK_OKTA_ISSUER`, `DECK_OKTA_AUDIENCE`, `DECK_OIDC_CACHE_TOKENS_SALT`, and `DECK_ANTHROPIC_TOKEN` are already exported during the Prerequisites, so they do not need to be re-exported per tab.

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_format_version: '3.0'
_info:
  select_tags:
  - claude-code-sso-recipe
consumer_groups:
- name: claude-standard-users
- name: claude-power-users
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
      consumer_groups_claim:
      - groups
      consumer_optional: true
      consumer_groups_optional: false
      upstream_headers_claims:
      - sub
      - email
      upstream_headers_names:
      - X-Authenticated-User
      - X-User-Email
      ssl_verify: true
      hide_credentials: true
      cache_tokens_salt: ${{ env "DECK_OIDC_CACHE_TOKENS_SALT" }}
plugins:
- name: ai-proxy-advanced
  instance_name: claude-code-sso-standard-proxy
  service: claude-code-sso
  consumer_group: claude-standard-users
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
        model_alias: ${{ env "DECK_SONNET_ALIAS" }}
        provider: anthropic
        name: ${{ env "DECK_CHAT_MODEL_1" }}
- name: ai-proxy-advanced
  instance_name: claude-code-sso-power-proxy
  service: claude-code-sso
  consumer_group: claude-power-users
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
        model_alias: ${{ env "DECK_SONNET_ALIAS" }}
        provider: anthropic
        name: ${{ env "DECK_CHAT_MODEL_1" }}
    - route_type: llm/v1/chat
      auth:
        header_name: x-api-key
        header_value: ${{ env "DECK_ANTHROPIC_TOKEN" }}
      logging:
        log_statistics: true
        log_payloads: true
      model:
        model_alias: ${{ env "DECK_OPUS_ALIAS" }}
        provider: anthropic
        name: ${{ env "DECK_CHAT_MODEL_2" }}
- name: ai-rate-limiting-advanced
  instance_name: claude-code-sso-standard-ratelimit
  service: claude-code-sso
  consumer_group: claude-standard-users
  config:
    policies:
    - limits:
      - limit: 20000
        window_size: 60
      window_type: sliding
    identifier: consumer-group
    tokens_count_strategy: total_tokens
    strategy: local
    llm_format: anthropic
- name: ai-rate-limiting-advanced
  instance_name: claude-code-sso-power-ratelimit
  service: claude-code-sso
  consumer_group: claude-power-users
  config:
    policies:
    - limits:
      - limit: 100000
        window_size: 60
      window_type: sliding
    identifier: consumer-group
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
" | kongctl apply -f - -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endnavtab %}
{% navtab "AWS Bedrock" %}

Export your environment variables. The defaults below pin to Sonnet 4.5 and Opus 4.6, the canonical stable versions on Bedrock. If your account has different versions enabled, update the aliases and the upstream model IDs to match:

```bash
export DECK_SONNET_ALIAS='claude-sonnet-4-5'                          # standard tier alias
export DECK_OPUS_ALIAS='claude-opus-4-6'                              # power tier alias
export DECK_CHAT_MODEL_1='global.anthropic.claude-sonnet-4-5-20250929-v1:0'  # actual upstream model behind the sonnet alias
export DECK_CHAT_MODEL_2='global.anthropic.claude-opus-4-6-20250930-v1:0'    # actual upstream model behind the opus alias
```

{:.warning}
> The two alias values must match the `ANTHROPIC_DEFAULT_SONNET_MODEL` and `ANTHROPIC_DEFAULT_OPUS_MODEL` set in each developer's `~/.claude/settings.json`, and the model versions you point them at must actually exist in your provider account. Claude Code pattern-matches the alias to decide which features (effort levels, extended thinking, beta tool fields) to enable. A mismatch (for example, claiming `claude-sonnet-4-6` when the upstream is Sonnet 4.5) sends fields the upstream rejects with `400`.

`KONNECT_CONTROL_PLANE_NAME`, `DECK_OKTA_ISSUER`, `DECK_OKTA_AUDIENCE`, `DECK_OIDC_CACHE_TOKENS_SALT`, and the `DECK_AWS_*` credentials are already exported during the Prerequisites, so they do not need to be re-exported per tab.

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_format_version: '3.0'
_info:
  select_tags:
  - claude-code-sso-recipe
consumer_groups:
- name: claude-standard-users
- name: claude-power-users
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
      consumer_groups_claim:
      - groups
      consumer_optional: true
      consumer_groups_optional: false
      upstream_headers_claims:
      - sub
      - email
      upstream_headers_names:
      - X-Authenticated-User
      - X-User-Email
      ssl_verify: true
      hide_credentials: true
      cache_tokens_salt: ${{ env "DECK_OIDC_CACHE_TOKENS_SALT" }}
plugins:
- name: ai-proxy-advanced
  instance_name: claude-code-sso-standard-proxy
  service: claude-code-sso
  consumer_group: claude-standard-users
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
        model_alias: ${{ env "DECK_SONNET_ALIAS" }}
        provider: bedrock
        name: ${{ env "DECK_CHAT_MODEL_1" }}
        options:
          bedrock:
            aws_region: ${{ env "DECK_AWS_REGION" }}
- name: ai-proxy-advanced
  instance_name: claude-code-sso-power-proxy
  service: claude-code-sso
  consumer_group: claude-power-users
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
        model_alias: ${{ env "DECK_SONNET_ALIAS" }}
        provider: bedrock
        name: ${{ env "DECK_CHAT_MODEL_1" }}
        options:
          bedrock:
            aws_region: ${{ env "DECK_AWS_REGION" }}
    - route_type: llm/v1/chat
      auth:
        aws_access_key_id: ${{ env "DECK_AWS_ACCESS_KEY_ID" }}
        aws_secret_access_key: ${{ env "DECK_AWS_SECRET_ACCESS_KEY" }}
      logging:
        log_statistics: true
        log_payloads: true
      model:
        model_alias: ${{ env "DECK_OPUS_ALIAS" }}
        provider: bedrock
        name: ${{ env "DECK_CHAT_MODEL_2" }}
        options:
          bedrock:
            aws_region: ${{ env "DECK_AWS_REGION" }}
- name: ai-rate-limiting-advanced
  instance_name: claude-code-sso-standard-ratelimit
  service: claude-code-sso
  consumer_group: claude-standard-users
  config:
    policies:
    - limits:
      - limit: 20000
        window_size: 60
      window_type: sliding
    identifier: consumer-group
    tokens_count_strategy: total_tokens
    strategy: local
    llm_format: anthropic
- name: ai-rate-limiting-advanced
  instance_name: claude-code-sso-power-ratelimit
  service: claude-code-sso
  consumer_group: claude-power-users
  config:
    policies:
    - limits:
      - limit: 100000
        window_size: 60
      window_type: sliding
    identifier: consumer-group
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
" | kongctl apply -f - -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endnavtab %}
{% navtab "Azure AI Foundry" %}

Export your environment variables. The defaults below pin to Sonnet 4.5 and Opus 4.5, the canonical stable Claude versions in Foundry's Model catalog. The alias values are also the Foundry deployment names you configured in the **AI Credentials** prereq:

```bash
export DECK_SONNET_ALIAS='claude-sonnet-4-5'   # standard tier alias and Foundry deployment name
export DECK_OPUS_ALIAS='claude-opus-4-5'       # power tier alias and Foundry deployment name
export DECK_CHAT_MODEL_1='claude-sonnet-4-5'   # body model name forwarded to Foundry
export DECK_CHAT_MODEL_2='claude-opus-4-5'     # body model name forwarded to Foundry
```

{:.warning}
> The two alias values must match the `ANTHROPIC_DEFAULT_SONNET_MODEL` and `ANTHROPIC_DEFAULT_OPUS_MODEL` set in each developer's `~/.claude/settings.json`, and the model versions you point them at must actually exist in your provider account. Claude Code pattern-matches the alias to decide which features (effort levels, extended thinking, beta tool fields) to enable. A mismatch (for example, claiming `claude-sonnet-4-6` when the upstream is Sonnet 4.5) sends fields the upstream rejects with `400`.

`KONNECT_CONTROL_PLANE_NAME`, `DECK_OKTA_ISSUER`, `DECK_OKTA_AUDIENCE`, `DECK_OIDC_CACHE_TOKENS_SALT`, and the `DECK_AZURE_FOUNDRY_*` credentials are already exported during the Prerequisites, so they do not need to be re-exported per tab.

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_format_version: '3.0'
_info:
  select_tags:
  - claude-code-sso-recipe
consumer_groups:
- name: claude-standard-users
- name: claude-power-users
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
      consumer_groups_claim:
      - groups
      consumer_optional: true
      consumer_groups_optional: false
      upstream_headers_claims:
      - sub
      - email
      upstream_headers_names:
      - X-Authenticated-User
      - X-User-Email
      ssl_verify: true
      hide_credentials: true
      cache_tokens_salt: ${{ env "DECK_OIDC_CACHE_TOKENS_SALT" }}
plugins:
- name: ai-proxy-advanced
  instance_name: claude-code-sso-standard-proxy
  service: claude-code-sso
  consumer_group: claude-standard-users
  config:
    llm_format: anthropic
    max_request_body_size: 10485760
    response_streaming: allow
    targets:
    - route_type: llm/v1/chat
      auth:
        header_name: Authorization
        header_value: Bearer ${{ env "DECK_AZURE_FOUNDRY_TOKEN" }}
      logging:
        log_statistics: true
        log_payloads: true
      model:
        model_alias: ${{ env "DECK_SONNET_ALIAS" }}
        provider: azure
        name: ${{ env "DECK_CHAT_MODEL_1" }}
        options:
          azure_instance: ${{ env "DECK_AZURE_FOUNDRY_INSTANCE" }}
          azure_deployment_id: ${{ env "DECK_AZURE_FOUNDRY_DEPLOYMENT_ID_1" }}
          upstream_url: ${{ env "DECK_AZURE_FOUNDRY_UPSTREAM_URL" }}
- name: ai-proxy-advanced
  instance_name: claude-code-sso-power-proxy
  service: claude-code-sso
  consumer_group: claude-power-users
  config:
    llm_format: anthropic
    max_request_body_size: 10485760
    response_streaming: allow
    targets:
    - route_type: llm/v1/chat
      auth:
        header_name: Authorization
        header_value: Bearer ${{ env "DECK_AZURE_FOUNDRY_TOKEN" }}
      logging:
        log_statistics: true
        log_payloads: true
      model:
        model_alias: ${{ env "DECK_SONNET_ALIAS" }}
        provider: azure
        name: ${{ env "DECK_CHAT_MODEL_1" }}
        options:
          azure_instance: ${{ env "DECK_AZURE_FOUNDRY_INSTANCE" }}
          azure_deployment_id: ${{ env "DECK_AZURE_FOUNDRY_DEPLOYMENT_ID_1" }}
          upstream_url: ${{ env "DECK_AZURE_FOUNDRY_UPSTREAM_URL" }}
    - route_type: llm/v1/chat
      auth:
        header_name: Authorization
        header_value: Bearer ${{ env "DECK_AZURE_FOUNDRY_TOKEN" }}
      logging:
        log_statistics: true
        log_payloads: true
      model:
        model_alias: ${{ env "DECK_OPUS_ALIAS" }}
        provider: azure
        name: ${{ env "DECK_CHAT_MODEL_2" }}
        options:
          azure_instance: ${{ env "DECK_AZURE_FOUNDRY_INSTANCE" }}
          azure_deployment_id: ${{ env "DECK_AZURE_FOUNDRY_DEPLOYMENT_ID_2" }}
          upstream_url: ${{ env "DECK_AZURE_FOUNDRY_UPSTREAM_URL" }}
- name: ai-rate-limiting-advanced
  instance_name: claude-code-sso-standard-ratelimit
  service: claude-code-sso
  consumer_group: claude-standard-users
  config:
    policies:
    - limits:
      - limit: 20000
        window_size: 60
      window_type: sliding
    identifier: consumer-group
    tokens_count_strategy: total_tokens
    strategy: local
    llm_format: anthropic
- name: ai-rate-limiting-advanced
  instance_name: claude-code-sso-power-ratelimit
  service: claude-code-sso
  consumer_group: claude-power-users
  config:
    policies:
    - limits:
      - limit: 100000
        window_size: 60
      window_type: sliding
    identifier: consumer-group
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
" | kongctl apply -f - -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endnavtab %}
{% navtab "Google Vertex AI" %}

Export your environment variables. Vertex requires Claude model names to carry the `@<date>` suffix matching the model variant; the bare alias is what Claude Code sends, and Kong rewrites it to the dated upstream name:

```bash
export DECK_SONNET_ALIAS='claude-sonnet-4-5'                # standard tier alias (what Claude Code sends)
export DECK_OPUS_ALIAS='claude-opus-4-5'                    # power tier alias
export DECK_CHAT_MODEL_1='claude-sonnet-4-5@20250929'       # actual Vertex model name behind the sonnet alias
export DECK_CHAT_MODEL_2='claude-opus-4-5@20250929'         # actual Vertex model name behind the opus alias
```

{:.warning}
> The two alias values must match the `ANTHROPIC_DEFAULT_SONNET_MODEL` and `ANTHROPIC_DEFAULT_OPUS_MODEL` set in each developer's `~/.claude/settings.json`, and the model versions you point them at must actually exist in your provider account. Claude Code pattern-matches the alias to decide which features (effort levels, extended thinking, beta tool fields) to enable. A mismatch (for example, claiming `claude-sonnet-4-6` when the upstream is Sonnet 4.5) sends fields the upstream rejects with `400`.

`KONNECT_CONTROL_PLANE_NAME`, `DECK_OKTA_ISSUER`, `DECK_OKTA_AUDIENCE`, `DECK_OIDC_CACHE_TOKENS_SALT`, and the `DECK_VERTEX_*` credentials are already exported during the Prerequisites, so they do not need to be re-exported per tab.

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_format_version: '3.0'
_info:
  select_tags:
  - claude-code-sso-recipe
consumer_groups:
- name: claude-standard-users
- name: claude-power-users
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
      consumer_groups_claim:
      - groups
      consumer_optional: true
      consumer_groups_optional: false
      upstream_headers_claims:
      - sub
      - email
      upstream_headers_names:
      - X-Authenticated-User
      - X-User-Email
      ssl_verify: true
      hide_credentials: true
      cache_tokens_salt: ${{ env "DECK_OIDC_CACHE_TOKENS_SALT" }}
plugins:
- name: ai-proxy-advanced
  instance_name: claude-code-sso-standard-proxy
  service: claude-code-sso
  consumer_group: claude-standard-users
  config:
    llm_format: anthropic
    max_request_body_size: 10485760
    response_streaming: allow
    targets:
    - route_type: llm/v1/chat
      auth:
        gcp_use_service_account: true
        gcp_service_account_json: '${{ env "DECK_VERTEX_SERVICE_ACCOUNT_JSON" }}'
      logging:
        log_statistics: true
        log_payloads: true
      model:
        model_alias: ${{ env "DECK_SONNET_ALIAS" }}
        provider: gemini
        name: ${{ env "DECK_CHAT_MODEL_1" }}
        options:
          gemini:
            api_endpoint: ${{ env "DECK_VERTEX_API_ENDPOINT" }}
            project_id: ${{ env "DECK_VERTEX_PROJECT_ID" }}
            location_id: ${{ env "DECK_VERTEX_LOCATION_ID" }}
- name: ai-proxy-advanced
  instance_name: claude-code-sso-power-proxy
  service: claude-code-sso
  consumer_group: claude-power-users
  config:
    llm_format: anthropic
    max_request_body_size: 10485760
    response_streaming: allow
    targets:
    - route_type: llm/v1/chat
      auth:
        gcp_use_service_account: true
        gcp_service_account_json: '${{ env "DECK_VERTEX_SERVICE_ACCOUNT_JSON" }}'
      logging:
        log_statistics: true
        log_payloads: true
      model:
        model_alias: ${{ env "DECK_SONNET_ALIAS" }}
        provider: gemini
        name: ${{ env "DECK_CHAT_MODEL_1" }}
        options:
          gemini:
            api_endpoint: ${{ env "DECK_VERTEX_API_ENDPOINT" }}
            project_id: ${{ env "DECK_VERTEX_PROJECT_ID" }}
            location_id: ${{ env "DECK_VERTEX_LOCATION_ID" }}
    - route_type: llm/v1/chat
      auth:
        gcp_use_service_account: true
        gcp_service_account_json: '${{ env "DECK_VERTEX_SERVICE_ACCOUNT_JSON" }}'
      logging:
        log_statistics: true
        log_payloads: true
      model:
        model_alias: ${{ env "DECK_OPUS_ALIAS" }}
        provider: gemini
        name: ${{ env "DECK_CHAT_MODEL_2" }}
        options:
          gemini:
            api_endpoint: ${{ env "DECK_VERTEX_API_ENDPOINT" }}
            project_id: ${{ env "DECK_VERTEX_PROJECT_ID" }}
            location_id: ${{ env "DECK_VERTEX_LOCATION_ID" }}
- name: ai-rate-limiting-advanced
  instance_name: claude-code-sso-standard-ratelimit
  service: claude-code-sso
  consumer_group: claude-standard-users
  config:
    policies:
    - limits:
      - limit: 20000
        window_size: 60
      window_type: sliding
    identifier: consumer-group
    tokens_count_strategy: total_tokens
    strategy: local
    llm_format: anthropic
- name: ai-rate-limiting-advanced
  instance_name: claude-code-sso-power-ratelimit
  service: claude-code-sso
  consumer_group: claude-power-users
  config:
    policies:
    - limits:
      - limit: 100000
        window_size: 60
      window_type: sliding
    identifier: consumer-group
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
" | kongctl apply -f - -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endnavtab %}
{% endnavtabs %}

## Try it out

With the configuration applied and Okta configured, Claude Code requests now flow through Kong for authentication, model alias matching, tier enforcement, and rate limiting. Verify the recipe by running Claude Code itself, the tool the recipe enables.

### Launch Claude Code

```bash
claude
```

On the first invocation (or when the cached token expires), a browser window opens to Okta for authentication. After authenticating, the terminal continues automatically:

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

Ask a question. Claude Code sends the request through Kong, which validates your Okta JWT, attaches the matching Consumer Group, runs the alias check, injects the provider API key, and forwards to the configured upstream model.

Subsequent invocations reuse the cached token silently. No browser flow unless the refresh token has expired.

### Example request and response

Claude Code sends requests to Kong in Anthropic's native message format. Here is what a typical request and response look like.

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
    { "type": "text", "text": "The capital of France is Paris." }
  ],
  "usage": { "input_tokens": 14, "output_tokens": 9 }
}
```
{:.no-copy-code}

Kong adds the following response headers:

{% table %}
columns:
  - title: Header
    key: header
  - title: Description
    key: description
rows:
  - header: "`X-Kong-LLM-Model`"
    description: "Model name selected for this request."
  - header: "`X-Kong-Upstream-Latency`"
    description: "Time in milliseconds Kong spent waiting for the provider to respond."
  - header: "`X-Kong-Proxy-Latency`"
    description: "Time in milliseconds Kong spent processing the request (auth, rate limiting, format translation)."
  - header: "`X-AI-RateLimit-Limit-60-{provider}`"
    description: "Token limit for the 60-second window for this Consumer Group."
  - header: "`X-AI-RateLimit-Remaining-60-{provider}`"
    description: "Tokens remaining in the current window."
  - header: "`RateLimit-Reset`"
    description: "Seconds until the window resets."
{% endtable %}

The `Authorization: Bearer` header on the request carries the Okta JWT. Kong validates it, strips it before forwarding upstream, and injects the provider API key in its place. The `usage` object in the response is what the AI Rate Limiting Advanced Plugin reads to track token consumption against the tier's budget.

### Hit the tier enforcement boundary

Standard users have only the `claude-sonnet-4-6` model alias configured. Inside Claude Code, switch to Opus and send a prompt:

```text
> /model opus
> Hello
```
{:.no-copy-code}

Claude Code sends the configured Opus alias (whatever value you set as `ANTHROPIC_DEFAULT_OPUS_MODEL`) in the request body. The standard tier's AI Proxy Advanced Plugin instance has no matching `model_alias`, so the request is rejected at Kong before any provider call:

```text
API Error: 400 model not configured
```
{:.no-copy-code}

This is the explicit block: a standard user cannot use Opus, regardless of what Claude Code's UI offers, and they see exactly why. Switch back to Sonnet (`/model sonnet`) and the request succeeds again.

### Hit the rate limit

Standard tier is configured at 20,000 tokens per 60-second sliding window. A few interactive prompts that include conversation history and file context exhaust the budget quickly. Send three or four prompts in rapid succession that each carry meaningful context (for example, ask Claude Code to summarize a file in your repo). Once the budget exhausts, Kong returns:

```text
API Error: 429 Too Many Requests
```
{:.no-copy-code}

The response includes a `Retry-After` header indicating how many seconds remain in the window.

### Swap to the power tier

The IdP-issued `groups` claim drives the Consumer Group attachment, so changing the user's Okta group is all that's needed to switch tiers. Kong already has the `claude-power-users` Consumer Group, AI Proxy Advanced Plugin instance (with both Sonnet and Opus aliases), and AI Rate Limiting Advanced Plugin instance in place from the apply step.

1. In Okta, go to **Directory → Groups** and create `claude-power-users` if it does not already exist.
1. Open your test user, go to the **Groups** tab, remove `claude-standard-users`, and add `claude-power-users`.
1. Force a fresh token by clearing the helper script's cache so it does not silently reuse the old JWT (which still carries the previous `groups` claim):

   ```bash
   rm -rf ~/.claude/okta-cache/
   ```

1. Re-launch Claude Code. The browser opens for a fresh PKCE flow, the new JWT carries `groups: ["claude-power-users"]`, and Kong now attaches the request to the power-tier Consumer Group. Run `/model opus` followed by a prompt; the request succeeds. The token budget jumps to 100,000 per 60-second window.

Swap back the same way: move the user between groups in Okta, clear the cache, and re-authenticate.

### Explore in Konnect

{{site.konnect_product_name}} surfaces every resource the recipe created, so you can see the same configuration the apply block put in place.

- **Control Plane.** Navigate to **API Gateway → Gateways → `claude-code-sso-recipe`** to view the Control Plane provisioned by the quickstart and adopted into the kongctl namespace.
- **Service and Routes.** Open the `claude-code-sso` Gateway Service. The **Routes** tab lists the `claude-code-sso` Route at `/claude-code-sso`. The **Plugins** tab shows the OpenID Connect Plugin attached to the Service, plus the Consumer-Group-scoped AI Proxy Advanced and AI Rate Limiting Advanced Plugins.
- **Consumer Groups.** The **Consumer Groups** menu under the Control Plane lists `claude-standard-users` and `claude-power-users`, the groups the OpenID Connect Plugin attaches each Okta group to.
- **Analytics.** The **Analytics** tab on the `claude-code-sso` Gateway Service shows at-a-glance request volume, token counts, and latency for the traffic you just sent.
- **Observability.** The **Observability** L1 menu in the {{site.konnect_product_name}} sidebar provides a deeper dive across Control Planes, including detailed analytics dashboards and a log explorer view.

## Variations and next steps

- **Switch the underlying model.** Update `DECK_CHAT_MODEL_1` or `DECK_CHAT_MODEL_2` to a different provider model ID and re-apply. Developers see no change because the alias they send (`claude-sonnet-4-6` or `claude-opus-4-7`) stays the same.
- **Add more tiers.** Create additional Okta groups, additional Kong Consumer Groups with matching names, and additional Consumer-Group-scoped AI Proxy Advanced and AI Rate Limiting Advanced instances. For example, an `intern` tier with only Haiku registered, or an `ml-team` tier with access to a specialized model alias.
- **Adjust token budgets.** Most teams enforce monthly or daily windows in production. For example, `limits: [{limit: 5000000, window_size: 2592000}]` for a 5 million token monthly budget per tier. Combine windows with multiple `limits` entries to enforce both burst and sustained budgets simultaneously.
- **Restrict access by IP.** Add an [IP Restriction](/plugins/ip-restriction/) Plugin to the Service or Route with `allow` set to your egress ranges (corporate VPN, CI runners). The Plugin runs before Okta JWT validation and refuses connections from unknown sources, narrowing the attack surface to authenticated traffic from approved networks.
- **Multi-node rate limiting with Redis.** The recipe uses `strategy: local`, which keeps counters in memory on each Kong node. For multi-node production clusters, switch to `strategy: redis` and point to a shared Redis instance so counters stay consistent across nodes.
- **Use a different IdP.** The OpenID Connect Plugin works with any OIDC-compliant identity provider (Microsoft Entra ID, Auth0, Keycloak, PingIdentity, others). Update the `issuer` URL and adjust the claim names to match your IdP's token format. The PKCE helper script works with any OIDC provider that supports Authorization Code + PKCE.
- **Cover non-Claude clients.** This recipe uses `llm_format: anthropic` because Claude Code sends requests in Anthropic's native format. If your team needs broader provider support (OpenAI, Google Gemini, Mistral), see [Basic LLM Routing](/cookbooks/basic-llm-routing/) with `llm_format: openai`.

## Cleanup

The recipe's `select_tags` and kongctl namespace scoped all resources, so this teardown removes only this recipe's configuration.

Tear down Kong by deleting the local data plane and the {{site.konnect_product_name}} Control Plane:

```bash
export KONNECT_CONTROL_PLANE_NAME='claude-code-sso-recipe' && curl -Ls https://get.konghq.com/quickstart | bash -s -- -d -k $KONNECT_TOKEN
```

Remove the helper script and cached tokens:

```bash
rm -f ~/.claude/okta-claude-auth.sh
rm -rf ~/.claude/okta-cache/
```

Revert `~/.claude/settings.json`. The following [jq](https://jqlang.github.io/jq/) command removes only the keys this recipe added and preserves anything else you have in the file:

```bash
tmp=$(mktemp) && jq '
  del(.apiKeyHelper)
  | del(
      .env.ANTHROPIC_BASE_URL,
      .env.OKTA_DOMAIN,
      .env.OKTA_CLIENT_ID,
      .env.OKTA_AUDIENCE,
      .env.OKTA_AUTH_SERVER,
      .env.ANTHROPIC_MODEL,
      .env.ANTHROPIC_DEFAULT_SONNET_MODEL,
      .env.ANTHROPIC_DEFAULT_OPUS_MODEL,
      .env.CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS
    )
  | if (.env // {}) == {} then del(.env) else . end
' ~/.claude/settings.json > "$tmp" && mv "$tmp" ~/.claude/settings.json
```

If you previously ran `unset ANTHROPIC_API_KEY` or `unset ANTHROPIC_AUTH_TOKEN` to use this recipe, re-export those values from your shell profile to return to your prior Claude Code authentication setup.
