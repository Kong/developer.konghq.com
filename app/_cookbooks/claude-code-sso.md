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
  ai-gateway: '2.0'
categories:
  - access-control
  - llm
featured: false
popular: false

# Machine-readable fields for AI agent setup
plugins:
  - openid-connect
  - ai-model
  - ai-model-provider
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
    - title: Kong Konnect
      content: |
        This tutorial uses {{site.konnect_product_name}}. The {{site.ai_gateway}} [quickstart script](https://get.konghq.com/ai) provisions a recipe-scoped {{site.ai_gateway}} and local data plane.

        1. Create a new personal access token by opening the [{{site.konnect_short_name}} PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**.
        1. Export your token. You reuse the same token later for kongctl commands:

           ```bash
           export KONNECT_TOKEN='YOUR_KONNECT_PAT'
           ```

        1. Set the recipe-scoped {{site.ai_gateway}} name and run the quickstart script. The `-e` flags raise the data plane's nginx body buffer so Claude Code's large request payloads (full conversation context, tool definitions, file contents) stay in memory instead of spilling to disk:

           ```bash
           export KONNECT_CONTROL_PLANE_NAME='claude-code-sso-recipe'
           curl -Ls https://get.konghq.com/ai | \
             bash -s -- -k $KONNECT_TOKEN \
               -e KONG_NGINX_HTTP_CLIENT_BODY_BUFFER_SIZE=16m \
               -e KONG_NGINX_HTTP_CLIENT_MAX_BODY_SIZE=16m
           ```

           The script provisions an {{site.ai_gateway}} named `claude-code-sso-recipe`, a local data plane connected to it, and prints `export` lines for the rest of the session vars, including `AI_GATEWAY_ID`. Paste those into your shell when prompted.
    - title: kongctl + jq
      content: |
        This tutorial uses [kongctl](/kongctl/) to manage {{site.ai_gateway}} configuration, plus [jq](https://jqlang.org/) for JSON processing in the dashboard and cleanup steps.

        1. Install **kongctl** from the [kongctl documentation](/kongctl/).
        1. Install **jq** from [jqlang.org](https://jqlang.org/).

        Verify that both are installed:

        ```bash
        kongctl version
        jq --version
        ```
    - title: Okta
      icon_url: /assets/icons/okta.svg
      content: |
        This recipe requires an Okta organization with admin access. The steps below create one Native OIDC Application for Claude Code, enable refresh tokens, configure a `groups` claim on Okta's authorization server, and assign one test user to one group.

        **Create the Native Application**

        The Native Application is a public client representing Claude Code. Public clients use Authorization Code + PKCE without a client secret.

        1. In the Okta Admin Console, go to **Applications → Create App Integration**.
        1. Select **OIDC - OpenID Connect** and **Native Application**, then click **Next**.
        1. Name the application `Claude Code`.
        1. Set the sign-in redirect URI to `http://localhost:9876/callback`. The helper script in the **Claude Code** prereq listens on this local callback.
        1. On the application's **General** tab under **Client Credentials**, confirm that **Proof Key for Code Exchange (PKCE)** is checked. Okta enables it by default for Native app types.
        1. Under **General Settings → Grant type**, check **Refresh Token** (alongside the **Authorization Code** entry that's already enabled). Without the **Refresh Token** grant, Okta doesn't issue refresh tokens even when the helper script requests `offline_access`, and developers hit the browser PKCE flow on every token expiry.
        1. Copy the **Client ID** for use in the **Claude Code** prereq.

        **Confirm the authorization server scopes**

        The helper script requests `openid`, `profile`, `email`, and `offline_access`. Okta's `default` authorization server enables these out of the box, so you usually don't need to change anything.

        1. Go to **Security → API → Authorization Servers** and select the `default` server (or your custom server).
        1. Click the **Scopes** tab and confirm that `openid`, `profile`, `email`, and `offline_access` are listed and enabled. If `offline_access` is missing, add it. Without `offline_access`, Okta never issues refresh tokens.

        **Configure the groups claim**

        The OpenID Connect AI Auth Strategy reads the `groups` claim out of the access token and maps each value to an AI Consumer Group with the same name. Configure the authorization server to include the claim:

        1. On the same authorization server, click the **Claims** tab and add a new claim:
           - **Name:** `groups`
           - **Include in token type:** Access Token
           - **Value type:** Groups
           - **Filter:** Matches regex `.*` (or restrict to a prefix like `claude-`)

        **Set up an Okta group and a test user**

        Create one group and assign one user to start. The Kong configuration includes both `claude-standard-users` and `claude-power-users` AI Consumer Groups, but you only need to test one tier at a time and can swap the user between groups later to exercise the other tier:

        1. Go to **Directory → Groups** and create `claude-standard-users`.
        1. Go to **Directory → People** and either add a new person (for example, `claude-test-user@example.com`) or pick an existing user. Make sure the user has a password set and can sign in.
        1. Open the user, click the **Groups** tab, and assign them to `claude-standard-users`.
        1. Open the `Claude Code` application, click the **Assignments** tab, and assign the same user. Without this, Okta blocks the OAuth flow at sign-in.

        To exercise the power tier later, also create a `claude-power-users` group. The [Swap to the power tier](#swap-to-the-power-tier) section walks through swapping the user between groups to switch tiers.

        **Export Okta endpoints and audience**

        You configure the audience on the authorization server itself, not per request. View or edit it at **Security → API → Authorization Servers → [server] → Settings tab → Audience**. The built-in `default` server uses `api://default`.

        ```bash
        export DECK_OKTA_ISSUER='https://your-org.okta.com/oauth2/default'
        export DECK_OKTA_AUDIENCE='api://default'
        # Salt for the openid-connect Auth Strategy's token cache key. Stable across syncs.
        # Not a credential. For production, regenerate with `openssl rand -hex 16` and
        # source from your secrets manager (or AI Vaults).
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
        > **Claude Code bypasses `apiKeyHelper` if `ANTHROPIC_API_KEY` or `ANTHROPIC_AUTH_TOKEN` is set in your environment.** Both env vars take precedence over the helper per Claude Code's [credential precedence rules](https://code.claude.com/docs/en/iam). If either is set in your shell profile, unset it before running Claude Code with this recipe: `unset ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN`.

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

        Replace `https://your-org.okta.com` and `0oa1b2c3d4YourClientId` with values from your Okta setup. Claude Code runs `apiKeyHelper` in an isolated environment without access to your shell profile, so you must list all Okta variables in the `env` block. `ANTHROPIC_BASE_URL` points Claude Code at Kong. `OKTA_AUTH_SERVER` defaults to `default`; set it to your custom server's ID if you use one.

        The model env vars pin which name Claude Code sends in the request body so it always matches an alias configured in Kong:

        - **`ANTHROPIC_MODEL`** sets the active model from session start. Without it, the picker boots on the system default and Claude Code sends the literal placeholder `<default>`, which has no matching alias in Kong.
        - **`ANTHROPIC_DEFAULT_SONNET_MODEL`** and **`ANTHROPIC_DEFAULT_OPUS_MODEL`** control what the `sonnet` and `opus` aliases resolve to when the user runs `/model sonnet` or `/model opus` mid-session.

        These three values must match the `DECK_SONNET_ALIAS` and `DECK_OPUS_ALIAS` set in the apply step. That's the alias contract Kong uses to route the request to the right tier. Whenever the platform team rolls out a new model version (for example, Sonnet 4.6 lands on Bedrock), they update the four `DECK_*` values in Kong and announce a corresponding bump for the three `ANTHROPIC_*_MODEL` values here.

        {:.warning}
        > On Windows, Claude Code does not expand `~` in the `apiKeyHelper` field (see the [GitHub issue on tilde expansion](https://github.com/anthropics/claude-code/issues/13013)). Substitute the absolute path, for example `C:\\Users\\you\\.claude\\okta-claude-auth.sh`. Tilde expansion works on macOS and Linux.

        **Token caching and refresh cadence**

        Claude Code caches the helper's output and re-invokes `okta-claude-auth.sh` every 5 minutes by default, and immediately on any HTTP 401 from the upstream. The helper itself caches the access and refresh tokens in `~/.claude/okta-cache/tokens.json` and silently exchanges the refresh token for a new access token when the cached one is within 60 seconds of expiry. On Okta's default 1-hour access-token TTL, the helper refreshes well before Kong sees a stale JWT, and developers never see a browser or a 401 after the initial sign-in.

        If your Okta authorization server is configured with a much shorter access-token TTL (for example, 2 minutes), set `CLAUDE_CODE_API_KEY_HELPER_TTL_MS` in the `env` block of `~/.claude/settings.json` to match. For example, set `"CLAUDE_CODE_API_KEY_HELPER_TTL_MS": "60000"` for 60 seconds. This lowers Claude Code's helper-output cache window so the helper's refresh logic runs before each token expires, avoiding a transient 401-retry cycle on every TTL boundary. The env var has no effect on the helper's refresh-token handling, which the script decides based on the cached `expires_at`. Lowering the env var doesn't speed up Okta revocation detection. The OpenID Connect AI Auth Strategy re-validates the JWT signature and expiry on every request and is the real revocation guard.
    - title: AI Credentials
      content: |
        {% navtabs "Providers" %}
        {% navtab "Anthropic" %}
        This tutorial uses Anthropic:

        1. [Create an Anthropic account](https://console.anthropic.com/).
        1. [Get an API key](https://console.anthropic.com/settings/keys).
        1. Export environment variables for the API key and the [Messages API schema version](https://docs.claude.com/en/api/versioning) Kong should send upstream on every request:

           ```bash
           export DECK_ANTHROPIC_TOKEN='YOUR-ANTHROPIC-KEY'
           export DECK_ANTHROPIC_VERSION='2023-06-01'
           ```
        {% endnavtab %}
        {% navtab "AWS Bedrock" %}
        This tutorial uses AWS Bedrock:

        1. Ensure you have an AWS account with [Bedrock model access](https://docs.aws.amazon.com/bedrock/latest/userguide/model-access.html) enabled.
        1. Export environment variables with your AWS credentials:

           ```bash
           export DECK_AWS_ACCESS_KEY_ID='your-access-key'
           export DECK_AWS_SECRET_ACCESS_KEY='your-secret-key'
           export DECK_AWS_REGION='us-east-1'
           ```
        {% endnavtab %}
        {% navtab "Azure AI Foundry" %}
        This tutorial uses [Azure AI Foundry](https://learn.microsoft.com/en-us/azure/ai-foundry/), which hosts Claude at `https://<resource>.services.ai.azure.com/anthropic/v1/messages`.

        1. Ensure you have a Foundry project with Claude Sonnet 4.5 and Claude Opus 4.5 deployments. The deployment names you assigned in the portal become `DECK_AZURE_FOUNDRY_DEPLOYMENT_ID_1` and `_2`.
        1. Export environment variables. `DECK_AZURE_FOUNDRY_UPSTREAM_URL` is the full endpoint URL Kong calls. `DECK_AZURE_FOUNDRY_TOKEN` accepts either a Foundry API key or an [Entra ID](https://learn.microsoft.com/en-us/azure/ai-foundry/concepts/rbac-azure-ai-foundry) bearer token; the AI Model Provider forwards it verbatim, so include the `Bearer ` prefix yourself if your token requires it:

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

        1. Ensure your GCP project has the Vertex AI API enabled, Claude Sonnet 4.5 and Claude Opus 4.5 access granted in AI Model Garden, and a service account JSON key with `roles/aiplatform.user`.
        1. Export environment variables. `DECK_VERTEX_LOCATION_ID` accepts `global` (works for every Claude variant) or a regional endpoint like `us-east5`, `europe-west1`, or `asia-southeast1`:

           ```bash
           export DECK_VERTEX_PROJECT_ID='your-gcp-project-id'
           export DECK_VERTEX_LOCATION_ID='global'
           export DECK_VERTEX_API_ENDPOINT='aiplatform.googleapis.com'
           export DECK_VERTEX_SERVICE_ACCOUNT_JSON="$(cat path/to/service-account-key.json)"
           ```

           Service account JSON is one of the GCP IAM auth modes the AI Model Provider supports for Vertex. For production, prefer workload identity over a downloaded key.
        {% endnavtab %}
        {% endnavtabs %}

overview: |
  This recipe puts {{site.ai_gateway_name}} in front of Anthropic Console API access (or AWS Bedrock,
  Azure AI Foundry, or Google Vertex AI). Okta SSO authenticates every Claude Code request from your
  engineering team, the developer's Okta group membership selects the model tier, and per-tier token
  rate limits cap usage. No provider credentials sit on developer machines.

  The recipe combines an OpenID Connect AI Auth Strategy for Okta JWT validation, two AI Models (one
  per tier) whose access control lists gate which AI Consumer Group can reach them, and the
  [AI Rate Limiting Advanced](/ai-gateway/policies/ai-rate-limiting-advanced/) Policy for per-tier
  token budgets.

  Scope: this recipe governs Claude Code's API-key authentication path. That's the path it uses
  when configured with `apiKeyHelper`, `ANTHROPIC_API_KEY`, `ANTHROPIC_AUTH_TOKEN`, or cloud-provider
  credentials. Claude.ai subscription seats authenticated via interactive `claude /login` go
  directly to Anthropic, bill against the subscription seat, and are out of scope.
---

## The problem

Anthropic Console API keys (and AWS Bedrock provider credentials) give engineers programmatic
access to LLMs through Claude Code, but they govern that access at the *credential level*, not at
the *organizational identity level*. That gap creates several blind spots at scale:

**Static keys are shared and untraceable.** Teams typically distribute a single Console API key
(or AWS access key) via shell profiles, `.env` files, or CI secrets stores. Every developer's requests are indistinguishable on the Anthropic bill. When a key leaks
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

The root issue is that the *developer machine* establishes trust, not a server-side
enforcement point your organization controls. That enforcement point is what this recipe builds.

## The solution

This recipe moves the enforcement point to a {{site.base_gateway}} that your organization controls,
with Okta as the single source of truth for identity. It applies to Claude Code's API-key path,
the path it uses when configured with `apiKeyHelper`, `ANTHROPIC_API_KEY`, `ANTHROPIC_AUTH_TOKEN`,
or cloud-provider credentials:

- **Developers never hold the provider key.** Kong holds the Console API key (or Bedrock,
  Azure AI Foundry, or Vertex credentials) and injects it server-side after validating an
  Okta-issued JWT. Key rotation happens in one place (Kong's config), not on every developer machine.
- **Okta drives identity.** Claude Code presents the developer's Okta JWT via `apiKeyHelper`.
  Kong validates the signature against Okta's JWKS keys on every request. Removing a user from
  an Okta group or disabling their account immediately blocks API access on the next call.
- **AI Consumer Groups drive model routing.** Kong maps Okta groups to AI Consumer Groups. Each tier
  is a separate model scoped to one alias, and each model's access control list decides which
  AI Consumer Groups may reach it. Standard users can request only the cost-efficient model; power
  users can request both that model and the most capable one. Changing a user's tier is an Okta
  group assignment, not a config change.
- **Each tier gets its own token budget.** Kong applies different rate limits to each AI Consumer
  Group so the gateway enforces cost ceilings at the boundary rather than reacting to billing
  alerts after the fact.
- **Kong enforces tiers explicitly.** A standard user requesting Opus reaches Kong's routing layer
  and matches the Opus alias, and that model's access control list rejects the request before any
  upstream call. There is no silent downgrade.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant CC as Claude Code
    participant H as apiKeyHelper script
    participant O as Okta
    participant K as Kong Gateway
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
    K->>K: OpenID Connect Auth Strategy (JWKS validate, Okta group to Kong Consumer Group)
    K->>K: AI Model (alias match, Consumer Group ACL check)
    K->>K: AI Model Provider (inject provider key)
    K->>K: AI Rate Limiting Advanced (per-tier token budget, via Consumer Group)
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
  - component: "Kong, [OpenID Connect](/ai-gateway/policies/openid-connect/) AI Auth Strategy"
    responsibility: "JWT signature validation via JWKS, audience verification, Okta group to AI Consumer Group mapping."
  - component: "Kong, AI Model and AI Model Provider"
    responsibility: "Alias-based tier routing, AI Consumer Group access control, provider credential injection, format passthrough."
  - component: "Kong, [AI Rate Limiting Advanced](/ai-gateway/policies/ai-rate-limiting-advanced/) Policy"
    responsibility: "Per-consumer-group token rate limits with sliding windows, attached via each AI Consumer Group's policy list."
  - component: "LLM provider"
    responsibility: "Model inference."
{% endtable %}

## How it works

When a developer runs Claude Code, every API request flows through Kong before reaching the
LLM provider. Here is the complete request lifecycle:

1. **Token acquisition.** Claude Code invokes the `apiKeyHelper` script (`okta-claude-auth.sh`)
   before each API call. The script checks its local token cache for a valid access token. If the
   token has expired but a refresh token exists, it silently exchanges for a new access token via
   Okta's token endpoint. If no valid tokens exist, it opens a browser to Okta's authorization
   endpoint for a full PKCE authentication flow, captures the authorization code via a local
   callback server, and exchanges it for tokens. The script returns the resulting JWT to Claude Code.

2. **Request to Kong.** Claude Code sends `POST /claude-code-sso/v1/messages` with
   `Authorization: Bearer <jwt>` to Kong. The request body is in Anthropic's native message
   format and pins the model name to one of Claude Code's bare aliases (`claude-sonnet-4-6`,
   `claude-opus-4-7`) via the `ANTHROPIC_DEFAULT_*_MODEL` env vars in `~/.claude/settings.json`.

3. **JWT validation and AI Consumer Group mapping.** The OpenID Connect AI Auth Strategy validates the
   JWT signature against Okta's cached JWKS keys, checks expiry, and verifies the `aud` claim. It
   then reads the `groups` array from the JWT and resolves each value to an AI Consumer Group
   with the same name. Kong attaches a user in `claude-power-users` to the `claude-power-users`
   AI Consumer Group.

4. **Alias routing and tier enforcement.** Kong matches the request body's `model` value against
   each AI Model's alias: one model registers the sonnet alias, the other registers the opus
   alias, and both share the `/claude-code-sso` path. The sonnet model's access control list
   allows both AI Consumer Groups; the opus model's list allows only `claude-power-users`. A
   standard user's request for the opus alias still matches the opus model on alias, but the
   access control list then rejects it because `claude-standard-users` isn't in its allow list,
   before Kong reaches the provider.

5. **Credential injection.** On an allowed match, the AI Model Provider injects the provider API
   key server-side and forwards the request to the configured upstream model.

6. **Token rate limiting.** The AI Rate Limiting Advanced Policy attached to the caller's
   AI Consumer Group counts prompt and completion tokens against the tier's per-window budget.
   The policy adds rate-limit headers (`X-AI-RateLimit-Remaining-*`) to the response. Exhaustion
   returns `429 Too Many Requests` with a `Retry-After` header.

7. **Response.** The provider's response flows back through Kong to Claude Code. Subsequent
   requests reuse the cached Okta token silently. The browser flow only reappears after the
   refresh token expires.

### OpenID Connect: JWT validation and AI Consumer Group mapping

The OpenID Connect AI Auth Strategy is the authentication layer. It validates every incoming JWT
against Okta's JWKS keys, rejects tokens that have expired or were issued for a different
audience, and attaches the developer's Okta groups to the request as AI Consumer Groups. This
AI Consumer Group attachment is the bridge between your identity provider and Kong's tier-scoped
access control. It determines which AI Model each request can reach and which
AI Rate Limiting Advanced Policy applies.

#### Configuration details

{%- raw %}
```yaml
ai_gateway_auth_strategies:
  - ref: claude-code-sso-auth
    type: openid-connect
    display_name: "claude-code-sso Okta OIDC"
    config:
      issuer: !env DECK_OKTA_ISSUER
      auth_methods:
        - bearer
      audience_required:
        - !env DECK_OKTA_AUDIENCE
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
      cache_tokens_salt: !env DECK_OIDC_CACHE_TOKENS_SALT
```
{% endraw -%}
{:.no-copy-code}

**`issuer`**. The Okta authorization server's base URL. Kong appends
`/.well-known/openid-configuration` to discover JWKS endpoints, signing keys, and token metadata
automatically. Kong caches the JWKS keys to avoid hitting Okta on every request.

**`auth_methods: [bearer]`**. Tells Kong to look for a Bearer token in the `Authorization`
header. Claude Code's `apiKeyHelper` outputs a bare token, and Claude Code sends it as
`Authorization: Bearer <token>`.

**`audience_required`**. The JWT's `aud` claim must match one of these values. This check
rejects tokens issued for other Okta applications. Set it to the audience you
configured on the Okta authorization server.

**`consumer_groups_claim: [groups]`** with **`consumer_optional: true`** and
**`consumer_groups_optional: false`**. The AI Auth Strategy reads the `groups` array from the
validated JWT and resolves each value against existing AI Consumer Group names. A JWT with
`"groups": ["claude-power-users"]` attaches the request to the `claude-power-users` AI Consumer
Group; downstream tier-scoped access control and rate limiting apply automatically.
`consumer_optional: true` allows requests through without a per-user AI Consumer mapping.
`consumer_groups_optional: false` blocks any authenticated user whose groups don't match a
configured AI Consumer Group, so an Okta user without a tier assignment is rejected at the gateway.

**`upstream_headers_claims`** and **`upstream_headers_names`**. Forward the JWT's `sub` and
`email` claims as `X-Authenticated-User` and `X-User-Email` upstream. Useful for audit logging.
You can see which user made each request without decoding the JWT.

**`ssl_verify: true`**. Enables TLS certificate verification when Kong connects to Okta's JWKS
endpoint. In {{site.base_gateway}} 3.14+, this defaults to `true` as part of the Secure by
Default initiative. The recipe sets it explicitly for clarity.

**`hide_credentials: true`**. Strips the `Authorization` header from the request before
forwarding upstream. Since the AI Model Provider injects its own provider credentials, the
upstream doesn't need the Okta JWT. In {{site.base_gateway}} 3.14+, this defaults to `true`. The
recipe sets it explicitly for clarity.

**`cache_tokens_salt`**. Salt used when deriving the cache key for token-endpoint responses. The
AI Auth Strategy requires an explicit, stable value so cached entries survive
`kongctl apply`. The value isn't a credential and grants no token-forgery capability, but treat
it as mildly sensitive (it influences cache-key predictability). For production, regenerate with
`openssl rand -hex 16` and source it from a vault.

The AI Auth Strategy has no `audience_claim` or `bearer_token_param_type` field: `auth_methods:
[bearer]` alone is enough to select the bearer-token flow, and the AI Auth Strategy checks
`audience_required` against the standard `aud` claim.

### AI Model and AI Model Provider: alias-based tier routing and credential injection

Each tier is a separate AI Model sharing the `/claude-code-sso` path, distinguished by the alias
it registers in `config.route.model.values`. The AI Model Provider holds the actual upstream
credentials and is shared by both Models. An AI Model's `access.auth_strategies` gates
authentication, requiring a valid Okta JWT; its `access.acls` gates authorization, restricting
which AI Consumer Groups may reach it. Claude Code sends bare model names like `claude-sonnet-4-6`
in the request body; Kong matches that value against the Model that registers it, then checks
whether the caller's mapped AI Consumer Group is on that Model's allow list.

The mapping from alias to actual provider model name is what insulates developers from the
underlying provider. The platform team controls each target's upstream model ID; developers
always speak in stable bare aliases.

#### Configuration details

The Anthropic tab's configuration (every provider tab follows the same shape, and only the
provider's `type`/`config.auth` and each target's `config` differ):

{%- raw %}
```yaml
ai_gateway_model_providers:
  - ref: claude-code-sso-provider
    type: anthropic
    display_name: "claude-code-sso"
    config:
      auth:
        type: basic
        headers:
          - name: x-api-key
            value: !secret {source: !env DECK_ANTHROPIC_TOKEN}

ai_gateway_models:
  - ref: claude-code-sso-sonnet
    type: model
    display_name: "claude-code-sso (sonnet tier)"
    formats:
      - type: anthropic
    capabilities:
      - generate
    access:
      auth_strategies:
        - claude-code-sso-auth
      acls:
        allow:
          - claude-standard-users
          - claude-power-users
    config:
      max_request_body_size: 10485760
      response_streaming: allow
      logging:
        payloads: true
      route:
        paths:
          - /claude-code-sso
        model:
          body_param: model
          values:
            - !env DECK_SONNET_ALIAS
    targets:
      - name: !env CHAT_MODEL_1
        provider: claude-code-sso-provider
        config:
          version: !env DECK_ANTHROPIC_VERSION
          type: anthropic
  - ref: claude-code-sso-opus
    type: model
    display_name: "claude-code-sso (opus tier)"
    formats:
      - type: anthropic
    capabilities:
      - generate
    access:
      auth_strategies:
        - claude-code-sso-auth
      acls:
        allow:
          - claude-power-users
    config:
      max_request_body_size: 10485760
      response_streaming: allow
      logging:
        payloads: true
      route:
        paths:
          - /claude-code-sso
        model:
          body_param: model
          values:
            - !env DECK_OPUS_ALIAS
    targets:
      - name: !env CHAT_MODEL_2
        provider: claude-code-sso-provider
        config:
          version: !env DECK_ANTHROPIC_VERSION
          type: anthropic
```
{% endraw -%}
{: .no-copy-code .collapsible }

**`formats: [{type: anthropic}]`**. Claude Code sends requests in Anthropic's native format
(`/v1/messages` with a `messages` array). For Anthropic, requests pass through natively. For AWS
Bedrock and Azure AI Foundry (both hosting Claude models), Kong forwards the same
Anthropic-native format to each provider's Claude endpoint. Claude Code always speaks Anthropic;
Kong handles the rest.

{:.warning}
> Do not use `formats: [{type: openai}]` with Claude Code. Claude Code sends Anthropic-native tool definitions in its requests. The OpenAI format translation path mangles these structures, causing 400 errors from the LLM provider (typically `tools: Input should be a valid list`). Always use `formats: [{type: anthropic}]` when proxying Claude Code traffic.

**`access.auth_strategies`**. References the OpenID Connect AI Auth Strategy. Every request to
either Model must carry a valid Okta JWT.

**`access.acls.allow`**. The tier gate. Lists the AI Consumer Group names permitted to call this
Model. The sonnet Model allows both tiers; the opus Model allows only `claude-power-users`.
Kong evaluates access control lists using its established behavior for this access-control
primitive: a caller whose mapped AI Consumer Group isn't in `allow` gets `403 Forbidden`. That
specific status code follows Kong's long-standing access-control-list convention rather than
a live confirmation against this exact entity, so treat it as a strong expectation, not a
guarantee, until you've verified it against your own gateway.

**`route.model`**. The alias this Model answers to, via `body_param: model` and a single value
in `values`. When the request body's `model` field equals this value, Kong routes to this
Model. An AI Model accepts exactly one alias, so the second tier needs a second Model entity,
as this recipe does for the sonnet and opus tiers.

**`targets[].name`**. The actual provider model ID Kong sends upstream. For Anthropic, this is
the same bare name (`claude-sonnet-4-6`); for Bedrock, it's the long form
(`anthropic.claude-sonnet-4-6-20250514-v1:0`). When the platform team upgrades the underlying
model, they change `CHAT_MODEL_1` or `CHAT_MODEL_2` and re-apply. Developers don't
need to update anything on their side.

**`targets[].config`**. Provider-specific target fields, for example Bedrock's `region` or
Azure AI Foundry's `foundry_path_prefix`, alongside the `type` discriminator matching the
AI Model Provider.

**`logging.payloads: true`**. Emits request and response bodies for audit purposes. {{site.konnect_short_name}}
{{site.observability}} captures token usage and cost independently of this field.

**`max_request_body_size: 10485760`**. Sets the maximum allowed request body to 10 MB. Claude
Code conversations accumulate large context windows (100 KB or more of conversation history,
tool results, and file contents). The default body size limit rejects these requests.

**`response_streaming: allow`**. Permits the Model to pass Server-Sent Events streaming
responses from the provider back to Claude Code. Claude Code uses streaming for interactive
terminal output. Without this setting, Kong can buffer or reject streaming responses.

### AI Rate Limiting Advanced: per-tier token limits via AI Consumer Groups

Each tier's AI Consumer Group carries its own AI Rate Limiting Advanced Policy, attached through
the AI Consumer Group's own `policies` list rather than a field on the policy itself. Unlike
request-count rate limiting, this policy counts tokens (prompt + completion), which is the
correct unit for LLM cost control. Standard users get a smaller token budget per window; power
users get a larger one. When a tier exhausts its budget, Kong returns `429 Too Many Requests`
until the window resets.

#### Configuration details

{%- raw %}
```yaml
ai_gateway_consumer_groups:
  - ref: claude-standard-users
    name: claude-standard-users
    display_name: "Claude Code standard tier"
    policies:
      - claude-code-sso-standard-ratelimit

ai_gateway_policies:
  - ref: claude-code-sso-standard-ratelimit
    type: ai-rate-limiting-advanced
    display_name: "claude-code-sso standard tier rate limit"
    config:
      policies:
        - limits:
            - limit: 20000
              window_size: 60
          window_type: sliding
      identifier: consumer-group
      tokens_count_strategy: total_tokens
      strategy: local
```
{% endraw -%}
{:.no-copy-code}

**`ai_gateway_consumer_groups[].policies`**. Attaches a policy so it applies to every request
Kong maps to that AI Consumer Group: the group points at the policies that govern it, rather than
a field on the policy pointing back at a group. Adding a second tier means creating another
AI Consumer Group with its own `policies` list, not editing an existing policy's config.

**`config.policies`**. An array of rate-limiting policies. Each entry contains a `limits` array
of limit and window-size pairs, and an optional `match` array for further targeting by provider,
model, or other dimensions within a single policy. This recipe doesn't need `match` conditions
because each AI Consumer Group already has its own dedicated policy. Standard users get 20,000
total tokens per 60-second window; power users get 100,000.

**`window_type: sliding`**. Uses a sliding-window algorithm for smoother rate limiting compared
to fixed windows. The `fixed` and `calendar` alternatives use strict boundaries and reset all
counters at each window edge.

**`tokens_count_strategy: total_tokens`**. Counts both prompt (input) and completion (output)
tokens against the limit. Alternatives are `prompt_tokens`, `completion_tokens`, or `cost`.

**`identifier: consumer-group`**. Tracks token usage per AI Consumer Group rather than per
individual AI Consumer, so the budget is a shared team quota. You need this identifier because a user can
belong to multiple groups and the policy needs to know which group's counter to increment.

**`strategy: local`**. Uses in-memory counters on each Kong node. Fine for single-node or
development deployments. For multi-node production clusters, switch to `strategy: redis` with
a shared Redis instance so counters stay consistent across nodes.

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

When an AI Consumer Group exceeds its token limit, Kong returns `429 Too Many Requests` with a
`Retry-After` header.

{:.info}
> The 60-second windows here are intentionally aggressive for the demo so a few interactive prompts visibly exhaust the budget. Most teams enforce monthly or daily token budgets in production, for example {%raw%}`limits: [{limit: 5000000, window_size: 2592000}]`{%endraw%}. Combine with [AI Vaults](/ai-gateway/entities/ai-vault/) using {%raw%}`{vault://backend/key}`{%endraw%} references for credentials in production rather than environment variables.

## Apply the Kong configuration

This section configures the {{site.ai_gateway}} in two parts. First, adopt the quickstart {{site.ai_gateway}} into a kongctl namespace so the following apply commands can manage it. The recipe's `claude-code-sso-recipe` namespace scopes every resource so teardown removes only this recipe's configuration.

```bash
kongctl adopt ai-gateway "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Adoption stamps the `KONGCTL-namespace` label on the {{site.ai_gateway}}.

The provider tabs below create an AI Model Provider holding your chosen provider's credentials, an OpenID Connect AI Auth Strategy for Okta JWT validation, two AI Consumer Groups (`claude-standard-users` and `claude-power-users`) each carrying their own [AI Rate Limiting Advanced](/ai-gateway/policies/ai-rate-limiting-advanced/) Policy, and two AI Models (sonnet and opus tiers) that gate access by AI Consumer Group ACL. See the [kongctl documentation](/kongctl/) for more on federated configuration management.

Select your provider below, export the required environment variables, and apply.

{% navtabs "Providers" %}
{% navtab "Anthropic" %}

Export your environment variables:

```bash
export DECK_SONNET_ALIAS='claude-sonnet-4-6'   # standard tier alias
export DECK_OPUS_ALIAS='claude-opus-4-7'       # power tier alias
export CHAT_MODEL_1='claude-sonnet-4-6'   # actual upstream model behind the sonnet alias
export CHAT_MODEL_2='claude-opus-4-7'     # actual upstream model behind the opus alias
```

{:.warning}
> The two alias values must match the `ANTHROPIC_DEFAULT_SONNET_MODEL` and `ANTHROPIC_DEFAULT_OPUS_MODEL` set in each developer's `~/.claude/settings.json`, and the model versions you point them at must actually exist in your provider account. Claude Code pattern-matches the alias to decide which features (effort levels, extended thinking, beta tool fields) to enable. A mismatch (for example, claiming `claude-sonnet-4-6` when the upstream is Sonnet 4.5) sends fields the upstream rejects with `400`.

`KONNECT_CONTROL_PLANE_NAME`, `AI_GATEWAY_ID`, `DECK_OKTA_ISSUER`, `DECK_OKTA_AUDIENCE`, `DECK_OIDC_CACHE_TOKENS_SALT`, `DECK_ANTHROPIC_TOKEN`, and `DECK_ANTHROPIC_VERSION` are already exported from the prerequisites, so you don't need to re-export them per tab.

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: claude-code-sso-recipe
ai_gateway_model_providers:
- ref: claude-code-sso-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-code-sso-provider
  display_name: claude-code-sso
  type: anthropic
  config:
    auth:
      type: basic
      headers:
      - name: x-api-key
        value: !secret {source: !env 'DECK_ANTHROPIC_TOKEN'}
ai_gateway_auth_strategies:
- ref: claude-code-sso-auth
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-code-sso-auth
  display_name: claude-code-sso Okta OIDC
  type: openid-connect
  config:
    issuer: !env 'DECK_OKTA_ISSUER'
    auth_methods:
    - bearer
    audience_required:
    - !env 'DECK_OKTA_AUDIENCE'
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
    cache_tokens_salt: !env 'DECK_OIDC_CACHE_TOKENS_SALT'
ai_gateway_policies:
- ref: claude-code-sso-standard-ratelimit
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-code-sso-standard-ratelimit
  display_name: claude-code-sso standard tier rate limit
  type: ai-rate-limiting-advanced
  config:
    policies:
    - limits:
      - limit: 20000
        window_size: 60
      window_type: sliding
    identifier: consumer-group
    tokens_count_strategy: total_tokens
    strategy: local
- ref: claude-code-sso-power-ratelimit
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-code-sso-power-ratelimit
  display_name: claude-code-sso power tier rate limit
  type: ai-rate-limiting-advanced
  config:
    policies:
    - limits:
      - limit: 100000
        window_size: 60
      window_type: sliding
    identifier: consumer-group
    tokens_count_strategy: total_tokens
    strategy: local
ai_gateway_consumer_groups:
- ref: claude-standard-users
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-standard-users
  display_name: Claude Code standard tier
  policies:
  - claude-code-sso-standard-ratelimit
- ref: claude-power-users
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-power-users
  display_name: Claude Code power tier
  policies:
  - claude-code-sso-power-ratelimit
ai_gateway_models:
- ref: claude-code-sso-sonnet
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-code-sso-sonnet
  display_name: claude-code-sso (sonnet tier)
  type: model
  formats:
  - type: anthropic
  capabilities:
  - generate
  access:
    auth_strategies:
    - claude-code-sso-auth
    acls:
      allow:
      - claude-standard-users
      - claude-power-users
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /claude-code-sso
      protocols:
      - http
      - https
      methods:
      - POST
      - OPTIONS
      strip_path: true
      model:
        body_param: model
        values:
        - !env 'DECK_SONNET_ALIAS'
  targets:
  - name: !env 'CHAT_MODEL_1'
    provider: claude-code-sso-provider
    config:
      version: !env 'DECK_ANTHROPIC_VERSION'
      type: anthropic
- ref: claude-code-sso-opus
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-code-sso-opus
  display_name: claude-code-sso (opus tier)
  type: model
  formats:
  - type: anthropic
  capabilities:
  - generate
  access:
    auth_strategies:
    - claude-code-sso-auth
    acls:
      allow:
      - claude-power-users
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /claude-code-sso
      protocols:
      - http
      - https
      methods:
      - POST
      - OPTIONS
      strip_path: true
      model:
        body_param: model
        values:
        - !env 'DECK_OPUS_ALIAS'
  targets:
  - name: !env 'CHAT_MODEL_2'
    provider: claude-code-sso-provider
    config:
      version: !env 'DECK_ANTHROPIC_VERSION'
      type: anthropic
EOF
{% endraw -%}

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endnavtab %}
{% navtab "AWS Bedrock" %}

Export your environment variables. The defaults below pin to Sonnet 4.5 and Opus 4.6, the canonical stable versions on Bedrock. If your account has different versions enabled, update the aliases and the upstream model IDs to match:

```bash
export DECK_SONNET_ALIAS='claude-sonnet-4-5'                                # standard tier alias
export DECK_OPUS_ALIAS='claude-opus-4-6'                                    # power tier alias
export CHAT_MODEL_1='global.anthropic.claude-sonnet-4-5-20250929-v1:0' # actual upstream model behind the sonnet alias
export CHAT_MODEL_2='global.anthropic.claude-opus-4-6-20250930-v1:0'   # actual upstream model behind the opus alias
```

{:.warning}
> The two alias values must match the `ANTHROPIC_DEFAULT_SONNET_MODEL` and `ANTHROPIC_DEFAULT_OPUS_MODEL` set in each developer's `~/.claude/settings.json`, and the model versions you point them at must actually exist in your provider account. Claude Code pattern-matches the alias to decide which features (effort levels, extended thinking, beta tool fields) to enable. A mismatch (for example, claiming `claude-sonnet-4-6` when the upstream is Sonnet 4.5) sends fields the upstream rejects with `400`.

`KONNECT_CONTROL_PLANE_NAME`, `AI_GATEWAY_ID`, `DECK_OKTA_ISSUER`, `DECK_OKTA_AUDIENCE`, `DECK_OIDC_CACHE_TOKENS_SALT`, and the `DECK_AWS_*` credentials are already exported from the prerequisites, so you don't need to re-export them per tab.

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: claude-code-sso-recipe
ai_gateway_model_providers:
- ref: claude-code-sso-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-code-sso-provider
  display_name: claude-code-sso
  type: bedrock
  config:
    auth:
      type: aws
      access_key_id: !env 'DECK_AWS_ACCESS_KEY_ID'
      secret_access_key: !secret {source: !env 'DECK_AWS_SECRET_ACCESS_KEY'}
ai_gateway_auth_strategies:
- ref: claude-code-sso-auth
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-code-sso-auth
  display_name: claude-code-sso Okta OIDC
  type: openid-connect
  config:
    issuer: !env 'DECK_OKTA_ISSUER'
    auth_methods:
    - bearer
    audience_required:
    - !env 'DECK_OKTA_AUDIENCE'
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
    cache_tokens_salt: !env 'DECK_OIDC_CACHE_TOKENS_SALT'
ai_gateway_policies:
- ref: claude-code-sso-standard-ratelimit
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-code-sso-standard-ratelimit
  display_name: claude-code-sso standard tier rate limit
  type: ai-rate-limiting-advanced
  config:
    policies:
    - limits:
      - limit: 20000
        window_size: 60
      window_type: sliding
    identifier: consumer-group
    tokens_count_strategy: total_tokens
    strategy: local
- ref: claude-code-sso-power-ratelimit
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-code-sso-power-ratelimit
  display_name: claude-code-sso power tier rate limit
  type: ai-rate-limiting-advanced
  config:
    policies:
    - limits:
      - limit: 100000
        window_size: 60
      window_type: sliding
    identifier: consumer-group
    tokens_count_strategy: total_tokens
    strategy: local
ai_gateway_consumer_groups:
- ref: claude-standard-users
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-standard-users
  display_name: Claude Code standard tier
  policies:
  - claude-code-sso-standard-ratelimit
- ref: claude-power-users
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-power-users
  display_name: Claude Code power tier
  policies:
  - claude-code-sso-power-ratelimit
ai_gateway_models:
- ref: claude-code-sso-sonnet
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-code-sso-sonnet
  display_name: claude-code-sso (sonnet tier)
  type: model
  formats:
  - type: anthropic
  capabilities:
  - generate
  access:
    auth_strategies:
    - claude-code-sso-auth
    acls:
      allow:
      - claude-standard-users
      - claude-power-users
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /claude-code-sso
      protocols:
      - http
      - https
      methods:
      - POST
      - OPTIONS
      strip_path: true
      model:
        body_param: model
        values:
        - !env 'DECK_SONNET_ALIAS'
  targets:
  - name: !env 'CHAT_MODEL_1'
    provider: claude-code-sso-provider
    config:
      region: !env 'DECK_AWS_REGION'
      type: bedrock
- ref: claude-code-sso-opus
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-code-sso-opus
  display_name: claude-code-sso (opus tier)
  type: model
  formats:
  - type: anthropic
  capabilities:
  - generate
  access:
    auth_strategies:
    - claude-code-sso-auth
    acls:
      allow:
      - claude-power-users
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /claude-code-sso
      protocols:
      - http
      - https
      methods:
      - POST
      - OPTIONS
      strip_path: true
      model:
        body_param: model
        values:
        - !env 'DECK_OPUS_ALIAS'
  targets:
  - name: !env 'CHAT_MODEL_2'
    provider: claude-code-sso-provider
    config:
      region: !env 'DECK_AWS_REGION'
      type: bedrock
EOF
{% endraw -%}

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endnavtab %}
{% navtab "Azure AI Foundry" %}

Export your environment variables. The defaults below pin to Sonnet 4.5 and Opus 4.5, the canonical stable Claude versions in Foundry's Model catalog. The alias values are also the Foundry deployment names you configured in the **AI Credentials** prereq:

```bash
export DECK_SONNET_ALIAS='claude-sonnet-4-5'   # standard tier alias and Foundry deployment name
export DECK_OPUS_ALIAS='claude-opus-4-5'       # power tier alias and Foundry deployment name
export CHAT_MODEL_1='claude-sonnet-4-5'   # body model name forwarded to Foundry
export CHAT_MODEL_2='claude-opus-4-5'     # body model name forwarded to Foundry
```

{:.warning}
> The two alias values must match the `ANTHROPIC_DEFAULT_SONNET_MODEL` and `ANTHROPIC_DEFAULT_OPUS_MODEL` set in each developer's `~/.claude/settings.json`, and the model versions you point them at must actually exist in your provider account. Claude Code pattern-matches the alias to decide which features (effort levels, extended thinking, beta tool fields) to enable. A mismatch (for example, claiming `claude-sonnet-4-6` when the upstream is Sonnet 4.5) sends fields the upstream rejects with `400`.

`KONNECT_CONTROL_PLANE_NAME`, `AI_GATEWAY_ID`, `DECK_OKTA_ISSUER`, `DECK_OKTA_AUDIENCE`, `DECK_OIDC_CACHE_TOKENS_SALT`, and the `DECK_AZURE_FOUNDRY_*` credentials are already exported from the prerequisites, so you don't need to re-export them per tab.

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: claude-code-sso-recipe
ai_gateway_model_providers:
- ref: claude-code-sso-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-code-sso-provider
  display_name: claude-code-sso
  type: azure
  config:
    auth:
      type: basic
      headers:
      - name: Authorization
        value: !secret {source: !env 'DECK_AZURE_FOUNDRY_TOKEN'}
    service: azure-foundry
    foundry:
      resource: !env 'DECK_AZURE_FOUNDRY_INSTANCE'
ai_gateway_auth_strategies:
- ref: claude-code-sso-auth
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-code-sso-auth
  display_name: claude-code-sso Okta OIDC
  type: openid-connect
  config:
    issuer: !env 'DECK_OKTA_ISSUER'
    auth_methods:
    - bearer
    audience_required:
    - !env 'DECK_OKTA_AUDIENCE'
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
    cache_tokens_salt: !env 'DECK_OIDC_CACHE_TOKENS_SALT'
ai_gateway_policies:
- ref: claude-code-sso-standard-ratelimit
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-code-sso-standard-ratelimit
  display_name: claude-code-sso standard tier rate limit
  type: ai-rate-limiting-advanced
  config:
    policies:
    - limits:
      - limit: 20000
        window_size: 60
      window_type: sliding
    identifier: consumer-group
    tokens_count_strategy: total_tokens
    strategy: local
- ref: claude-code-sso-power-ratelimit
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-code-sso-power-ratelimit
  display_name: claude-code-sso power tier rate limit
  type: ai-rate-limiting-advanced
  config:
    policies:
    - limits:
      - limit: 100000
        window_size: 60
      window_type: sliding
    identifier: consumer-group
    tokens_count_strategy: total_tokens
    strategy: local
ai_gateway_consumer_groups:
- ref: claude-standard-users
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-standard-users
  display_name: Claude Code standard tier
  policies:
  - claude-code-sso-standard-ratelimit
- ref: claude-power-users
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-power-users
  display_name: Claude Code power tier
  policies:
  - claude-code-sso-power-ratelimit
ai_gateway_models:
- ref: claude-code-sso-sonnet
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-code-sso-sonnet
  display_name: claude-code-sso (sonnet tier)
  type: model
  formats:
  - type: anthropic
  capabilities:
  - generate
  access:
    auth_strategies:
    - claude-code-sso-auth
    acls:
      allow:
      - claude-standard-users
      - claude-power-users
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /claude-code-sso
      protocols:
      - http
      - https
      methods:
      - POST
      - OPTIONS
      strip_path: true
      model:
        body_param: model
        values:
        - !env 'DECK_SONNET_ALIAS'
  targets:
  - name: !env 'CHAT_MODEL_1'
    provider: claude-code-sso-provider
    config:
      foundry_path_prefix: /anthropic/v1
      type: azure
- ref: claude-code-sso-opus
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-code-sso-opus
  display_name: claude-code-sso (opus tier)
  type: model
  formats:
  - type: anthropic
  capabilities:
  - generate
  access:
    auth_strategies:
    - claude-code-sso-auth
    acls:
      allow:
      - claude-power-users
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /claude-code-sso
      protocols:
      - http
      - https
      methods:
      - POST
      - OPTIONS
      strip_path: true
      model:
        body_param: model
        values:
        - !env 'DECK_OPUS_ALIAS'
  targets:
  - name: !env 'CHAT_MODEL_2'
    provider: claude-code-sso-provider
    config:
      foundry_path_prefix: /anthropic/v1
      type: azure
EOF
{% endraw -%}

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endnavtab %}
{% navtab "Google Vertex AI" %}

Export your environment variables. Vertex requires Claude model names to carry the `@<date>` suffix matching the model variant; the bare alias is what Claude Code sends, and Kong rewrites it to the dated upstream name:

```bash
export DECK_SONNET_ALIAS='claude-sonnet-4-5'          # standard tier alias (what Claude Code sends)
export DECK_OPUS_ALIAS='claude-opus-4-5'              # power tier alias
export CHAT_MODEL_1='claude-sonnet-4-5@20250929' # actual Vertex model name behind the sonnet alias
export CHAT_MODEL_2='claude-opus-4-5@20250929'   # actual Vertex model name behind the opus alias
```

{:.warning}
> The two alias values must match the `ANTHROPIC_DEFAULT_SONNET_MODEL` and `ANTHROPIC_DEFAULT_OPUS_MODEL` set in each developer's `~/.claude/settings.json`, and the model versions you point them at must actually exist in your provider account. Claude Code pattern-matches the alias to decide which features (effort levels, extended thinking, beta tool fields) to enable. A mismatch (for example, claiming `claude-sonnet-4-6` when the upstream is Sonnet 4.5) sends fields the upstream rejects with `400`.

`KONNECT_CONTROL_PLANE_NAME`, `AI_GATEWAY_ID`, `DECK_OKTA_ISSUER`, `DECK_OKTA_AUDIENCE`, `DECK_OIDC_CACHE_TOKENS_SALT`, and the `DECK_VERTEX_*` credentials are already exported from the prerequisites, so you don't need to re-export them per tab.

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: claude-code-sso-recipe
ai_gateway_model_providers:
- ref: claude-code-sso-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-code-sso-provider
  display_name: claude-code-sso
  type: gemini
  config:
    auth:
      type: gcp
      use_gcp_service_account: true
      service_account_json: !secret {source: !env 'DECK_VERTEX_SERVICE_ACCOUNT_JSON'}
ai_gateway_auth_strategies:
- ref: claude-code-sso-auth
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-code-sso-auth
  display_name: claude-code-sso Okta OIDC
  type: openid-connect
  config:
    issuer: !env 'DECK_OKTA_ISSUER'
    auth_methods:
    - bearer
    audience_required:
    - !env 'DECK_OKTA_AUDIENCE'
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
    cache_tokens_salt: !env 'DECK_OIDC_CACHE_TOKENS_SALT'
ai_gateway_policies:
- ref: claude-code-sso-standard-ratelimit
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-code-sso-standard-ratelimit
  display_name: claude-code-sso standard tier rate limit
  type: ai-rate-limiting-advanced
  config:
    policies:
    - limits:
      - limit: 20000
        window_size: 60
      window_type: sliding
    identifier: consumer-group
    tokens_count_strategy: total_tokens
    strategy: local
- ref: claude-code-sso-power-ratelimit
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-code-sso-power-ratelimit
  display_name: claude-code-sso power tier rate limit
  type: ai-rate-limiting-advanced
  config:
    policies:
    - limits:
      - limit: 100000
        window_size: 60
      window_type: sliding
    identifier: consumer-group
    tokens_count_strategy: total_tokens
    strategy: local
ai_gateway_consumer_groups:
- ref: claude-standard-users
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-standard-users
  display_name: Claude Code standard tier
  policies:
  - claude-code-sso-standard-ratelimit
- ref: claude-power-users
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-power-users
  display_name: Claude Code power tier
  policies:
  - claude-code-sso-power-ratelimit
ai_gateway_models:
- ref: claude-code-sso-sonnet
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-code-sso-sonnet
  display_name: claude-code-sso (sonnet tier)
  type: model
  formats:
  - type: anthropic
  capabilities:
  - generate
  access:
    auth_strategies:
    - claude-code-sso-auth
    acls:
      allow:
      - claude-standard-users
      - claude-power-users
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /claude-code-sso
      protocols:
      - http
      - https
      methods:
      - POST
      - OPTIONS
      strip_path: true
      model:
        body_param: model
        values:
        - !env 'DECK_SONNET_ALIAS'
  targets:
  - name: !env 'CHAT_MODEL_1'
    provider: claude-code-sso-provider
    config:
      gcp_environment:
        api_endpoint: !env 'DECK_VERTEX_API_ENDPOINT'
        project_id: !env 'DECK_VERTEX_PROJECT_ID'
        location_id: !env 'DECK_VERTEX_LOCATION_ID'
      type: gemini
- ref: claude-code-sso-opus
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: claude-code-sso-opus
  display_name: claude-code-sso (opus tier)
  type: model
  formats:
  - type: anthropic
  capabilities:
  - generate
  access:
    auth_strategies:
    - claude-code-sso-auth
    acls:
      allow:
      - claude-power-users
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /claude-code-sso
      protocols:
      - http
      - https
      methods:
      - POST
      - OPTIONS
      strip_path: true
      model:
        body_param: model
        values:
        - !env 'DECK_OPUS_ALIAS'
  targets:
  - name: !env 'CHAT_MODEL_2'
    provider: claude-code-sso-provider
    config:
      gcp_environment:
        api_endpoint: !env 'DECK_VERTEX_API_ENDPOINT'
        project_id: !env 'DECK_VERTEX_PROJECT_ID'
        location_id: !env 'DECK_VERTEX_LOCATION_ID'
      type: gemini
EOF
{% endraw -%}

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endnavtab %}
{% endnavtabs %}

### Create the Claude Code Usage dashboard

Create a custom dashboard at the org level. The dashboard surfaces cost, token usage, request volume, model mix, per-developer (AI Consumer) usage, and latency for Claude Code traffic. The dashboard JSON is in the code block below; if a labeled dashboard from a prior apply already exists, the block reuses it instead of creating a duplicate.

```bash
EXISTING_DASHBOARDS=$(kongctl api get "/v2/dashboards?filter%5Blabels.recipe%5D=claude-code-sso-recipe" \
  --pat "${KONNECT_TOKEN}" -o json --jq '.data | length')

if [ "${EXISTING_DASHBOARDS}" -gt 0 ]; then
  echo "Claude Code Usage dashboard already exists. Reusing."
else
  DASHBOARD_ID=$(kongctl api post /v2/dashboards \
    -f claude-code-usage-dashboard.json \
    --pat "${KONNECT_TOKEN}" -o json --jq '.id' -r)
  echo "Created Claude Code Usage dashboard (id: ${DASHBOARD_ID}). Open it in Konnect at Observability → Custom dashboards → 'Claude Code Usage'."
fi
```
{: data-test-step="block" .collapsible }

Add `claude-code-usage-dashboard.json` alongside the import command before you run it:

```json
{
  "name": "Claude Code Usage",
  "definition": {
    "tiles": [
      {
        "id": "e3f9588a-71fd-4996-818f-33c93afe6eae",
        "type": "chart",
        "layout": { "size": { "cols": 2, "rows": 1 }, "position": { "col": 0, "row": 0 } },
        "definition": {
          "chart": { "type": "single_value", "chart_title": "Total cost ($)" },
          "query": {
            "filters": [
              { "field": "ai_provider", "operator": "not_empty" },
              { "field": "ai_provider", "value": ["UNSPECIFIED"], "operator": "not_in" }
            ],
            "metrics": ["cost"],
            "datasource": "llm_usage",
            "dimensions": []
          }
        }
      },
      {
        "id": "9edab295-d705-403f-a612-59847420a195",
        "type": "chart",
        "layout": { "size": { "cols": 2, "rows": 1 }, "position": { "col": 2, "row": 0 } },
        "definition": {
          "chart": { "type": "single_value", "chart_title": "Total Tokens" },
          "query": {
            "filters": [
              { "field": "ai_provider", "operator": "not_empty" },
              { "field": "ai_provider", "value": ["UNSPECIFIED"], "operator": "not_in" }
            ],
            "metrics": ["total_tokens"],
            "datasource": "llm_usage",
            "dimensions": []
          }
        }
      },
      {
        "id": "e5cc504e-c505-4f0b-8633-638a0e7b5833",
        "type": "chart",
        "layout": { "size": { "cols": 2, "rows": 1 }, "position": { "col": 4, "row": 0 } },
        "definition": {
          "chart": { "type": "single_value", "chart_title": "Total Claude Code requests" },
          "query": {
            "filters": [
              { "field": "ai_provider", "operator": "not_empty" },
              { "field": "ai_provider", "value": ["UNSPECIFIED"], "operator": "not_in" }
            ],
            "metrics": ["ai_request_count"],
            "datasource": "llm_usage",
            "dimensions": []
          }
        }
      },
      {
        "id": "4ab1fb73-d60b-4f77-b915-a0c88d427263",
        "type": "chart",
        "layout": { "size": { "cols": 3, "rows": 2 }, "position": { "col": 0, "row": 1 } },
        "definition": {
          "chart": { "type": "top_n", "chart_title": "Top Claude Models by Usage" },
          "query": {
            "limit": 10,
            "filters": [],
            "metrics": ["total_tokens", "ai_request_count"],
            "datasource": "llm_usage",
            "dimensions": ["ai_request_model"]
          }
        }
      },
      {
        "id": "e6c5fbe0-9dd2-46ac-af1c-3ba3af9ffd43",
        "type": "chart",
        "layout": { "size": { "cols": 3, "rows": 2 }, "position": { "col": 3, "row": 1 } },
        "definition": {
          "chart": { "type": "timeseries_line", "stacked": false, "chart_title": "Model usage trend (top 5)" },
          "query": {
            "limit": 5,
            "filters": [
              { "field": "ai_provider", "operator": "not_empty" },
              { "field": "ai_provider", "value": ["UNSPECIFIED"], "operator": "not_in" }
            ],
            "metrics": ["total_tokens"],
            "datasource": "llm_usage",
            "dimensions": ["ai_request_model", "time"]
          }
        }
      },
      {
        "id": "fd14bf28-0cd2-409e-9a48-2cbbd7907409",
        "type": "chart",
        "layout": { "size": { "cols": 2, "rows": 2 }, "position": { "col": 0, "row": 3 } },
        "definition": {
          "chart": { "type": "donut", "chart_title": "Claude health check" },
          "query": {
            "filters": [
              { "field": "gateway_service", "operator": "not_empty" },
              { "field": "ai_provider", "operator": "not_empty" },
              { "field": "ai_provider", "value": ["UNSPECIFIED"], "operator": "not_in" }
            ],
            "metrics": ["ai_request_count"],
            "datasource": "llm_usage",
            "dimensions": ["status_code_grouped"]
          }
        }
      },
      {
        "id": "f26edaa8-56d5-49f8-8f04-ade9451c76ec",
        "type": "chart",
        "layout": { "size": { "cols": 2, "rows": 2 }, "position": { "col": 2, "row": 3 } },
        "definition": {
          "chart": { "type": "donut", "chart_title": "Claude provider usage" },
          "query": {
            "filters": [
              { "field": "gateway_service", "operator": "not_empty" },
              { "field": "ai_provider", "operator": "not_empty" },
              { "field": "ai_provider", "value": ["UNSPECIFIED"], "operator": "not_in" }
            ],
            "metrics": ["ai_request_count"],
            "datasource": "llm_usage",
            "dimensions": ["ai_provider"]
          }
        }
      },
      {
        "id": "d27037a3-7ace-49cc-affb-3b34a71ab9b1",
        "type": "chart",
        "layout": { "size": { "cols": 2, "rows": 2 }, "position": { "col": 4, "row": 3 } },
        "definition": {
          "chart": { "type": "timeseries_bar", "stacked": true, "chart_title": "LLM latency (avg)" },
          "query": {
            "filters": [
              { "field": "ai_request_model", "operator": "not_empty" },
              { "field": "ai_request_model", "value": ["UNSPECIFIED"], "operator": "not_in" }
            ],
            "metrics": ["llm_latency_average"],
            "datasource": "llm_usage",
            "dimensions": ["ai_request_model", "time"]
          }
        }
      },
      {
        "id": "5f88c24b-80de-4fe1-8948-ef0bde29f948",
        "type": "chart",
        "layout": { "size": { "cols": 3, "rows": 2 }, "position": { "col": 0, "row": 9 } },
        "definition": {
          "chart": { "type": "horizontal_bar", "stacked": true, "chart_title": "Claude model usage (requests)" },
          "query": {
            "filters": [
              { "field": "ai_request_model", "operator": "not_empty" },
              { "field": "ai_request_model", "value": ["UNSPECIFIED"], "operator": "not_in" }
            ],
            "metrics": ["ai_request_count"],
            "datasource": "llm_usage",
            "dimensions": ["ai_request_model"]
          }
        }
      },
      {
        "id": "702f6291-e02d-47eb-b38b-85438c643712",
        "type": "chart",
        "layout": { "size": { "cols": 3, "rows": 2 }, "position": { "col": 3, "row": 9 } },
        "definition": {
          "chart": { "type": "vertical_bar", "stacked": true, "chart_title": "Claude model usage count (tokens)" },
          "query": {
            "filters": [
              { "field": "ai_provider", "operator": "not_empty" },
              { "field": "ai_provider", "value": ["UNSPECIFIED"], "operator": "not_in" }
            ],
            "metrics": ["total_tokens"],
            "datasource": "llm_usage",
            "dimensions": ["ai_request_model"]
          }
        }
      },
      {
        "id": "2242b427-2999-4cfe-b17e-9e4ca61be362",
        "type": "chart",
        "layout": { "size": { "cols": 2, "rows": 2 }, "position": { "col": 0, "row": 11 } },
        "definition": {
          "chart": { "type": "vertical_bar", "stacked": true, "chart_title": "AI security report" },
          "query": {
            "filters": [
              { "field": "status_code_grouped", "value": ["4XX"], "operator": "in" },
              { "field": "ai_provider", "operator": "not_empty" },
              { "field": "ai_provider", "value": ["UNSPECIFIED"], "operator": "not_in" }
            ],
            "metrics": ["ai_request_count"],
            "datasource": "llm_usage",
            "dimensions": ["route", "status_code"]
          }
        }
      },
      {
        "id": "df1b0486-2c04-430e-a8ff-7e26c7821bf7",
        "type": "chart",
        "layout": { "size": { "cols": 3, "rows": 2 }, "position": { "col": 2, "row": 11 } },
        "definition": {
          "chart": { "type": "timeseries_bar", "stacked": true, "chart_title": "Monthly spend trends" },
          "query": {
            "limit": 10,
            "filters": [],
            "metrics": ["cost"],
            "datasource": "llm_usage",
            "dimensions": ["ai_request_model", "time"],
            "time_range": { "type": "relative", "time_range": "30d" },
            "granularity": "daily"
          }
        }
      }
    ],
    "template_id": "AI_GATEWAY"
  },
  "labels": {
    "recipe": "claude-code-sso-recipe"
  }
}
```
{: .no-copy-code .collapsible }

{:.info}
> This dashboard shows account-wide Claude Code traffic by default. To scope it to just this recipe's {{site.ai_gateway}}, add a filter in the {{site.konnect_short_name}} dashboard editor after you apply the recipe configuration.

## Try it out

With the configuration applied and Okta configured, Claude Code requests now flow through Kong for authentication, alias-based routing, tier enforcement, and rate limiting. Verify the recipe by running Claude Code itself, the tool the recipe enables.

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

Ask a question. Claude Code sends the request through Kong, which validates your Okta JWT, attaches the matching AI Consumer Group, checks the alias against each AI Model's access control list, injects the provider API key, and forwards to the configured upstream model.

Subsequent invocations reuse the cached token silently. The browser flow only reappears after the refresh token expires.

### Hit the tier enforcement boundary

Standard users have access only to the sonnet AI Model. Inside Claude Code, switch to Opus and send a prompt:

```text
> /model opus
> Hello
```
{:.no-copy-code}

Claude Code sends the configured Opus alias (whatever value you set as `ANTHROPIC_DEFAULT_OPUS_MODEL`) in the request body. Kong matches the alias to the opus AI Model, but that Model's access control list doesn't include `claude-standard-users`, so Kong rejects the request before any provider call:

```text
API Error: 403 Forbidden
```
{:.no-copy-code}

This is the explicit block: a standard user can't use Opus, regardless of what Claude Code's UI offers, and they see exactly why. Switch back to Sonnet (`/model sonnet`) and the request succeeds again.

### Hit the rate limit

The standard tier allows 20,000 tokens per 60-second sliding window. A few interactive prompts that include conversation history and file context exhaust the budget quickly. Send three or four prompts in rapid succession that each carry meaningful context (for example, ask Claude Code to summarize a file in your repo). When you exhaust the budget, Kong returns:

```text
API Error: 429 Too Many Requests
```
{:.no-copy-code}

The response includes a `Retry-After` header indicating how many seconds remain in the window.

### Swap to the power tier

The IdP-issued `groups` claim drives the AI Consumer Group attachment, so changing the user's Okta group is all you need to switch tiers. Kong already has the `claude-power-users` AI Consumer Group, the opus AI Model that allows it, and its own AI Rate Limiting Advanced Policy in place from the apply step.

1. In Okta, go to **Directory → Groups** and create `claude-power-users` if it doesn't already exist.
1. Open your test user, click the **Groups** tab, remove `claude-standard-users`, and add `claude-power-users`.
1. Force a fresh token by clearing the helper script's cache so it doesn't silently reuse the old JWT (which still carries the previous `groups` claim):

   ```bash
   rm -rf ~/.claude/okta-cache/
   ```

1. Re-launch Claude Code. The browser opens for a fresh PKCE flow, the new JWT carries `groups: ["claude-power-users"]`, and Kong now attaches the request to the power-tier AI Consumer Group. Run `/model opus` followed by a prompt; the request succeeds. The token budget jumps to 100,000 per 60-second window.

Swap back the same way: move the user between groups in Okta, clear the cache, and re-authenticate.

### Explore in {{site.konnect_short_name}}

Open [{{site.konnect_short_name}}](https://cloud.konghq.com/) and find the {{site.ai_gateway}} named `claude-code-sso-recipe`. The recipe created an AI Model Provider holding your chosen provider's credentials, two AI Models (`claude-code-sso-sonnet` and `claude-code-sso-opus`), an OpenID Connect AI Auth Strategy, two AI Consumer Groups (`claude-standard-users` and `claude-power-users`), and two AI Rate Limiting Advanced Policies, all scoped to this recipe by the kongctl namespace applied above.

**Claude Code Usage dashboard.** Navigate to **Observability → Custom dashboards → `Claude Code Usage`**. It surfaces cost, total tokens, request count, model mix and usage trend, health-check and provider-share breakdowns, average latency, and an AI security report scoped to 4XX responses.

For platform-wide traffic analysis across every {{site.ai_gateway}}, head to the **Observability** L1 menu in {{site.konnect_short_name}}.

## Variations and next steps

- **Switch the underlying model.** Update `CHAT_MODEL_1` or `CHAT_MODEL_2` to a different provider model ID and re-apply. Developers see no change because the alias they send (`claude-sonnet-4-6` or `claude-opus-4-7`) stays the same.
- **Add more tiers.** Create additional Okta groups, additional AI Consumer Groups with matching names, an additional AI Model gated by the new group's ACL, and an additional AI Rate Limiting Advanced Policy attached to that AI Consumer Group. For example, an `intern` tier with only Haiku registered, or an `ml-team` tier with access to a specialized model alias.
- **Adjust token budgets.** Most teams enforce monthly or daily windows in production. For example, `limits: [{limit: 5000000, window_size: 2592000}]` for a 5 million token monthly budget per tier. Combine windows with multiple `limits` entries to enforce both burst and sustained budgets simultaneously.
- **Restrict access by IP.** Add an [IP Restriction](/ai-gateway/policies/ip-restriction/) Policy with `allow` set to your egress ranges (corporate VPN, CI runners). It runs before Okta JWT validation and refuses connections from unknown sources, narrowing the attack surface to authenticated traffic from approved networks.
- **Share rate-limit counters with Redis.** The recipe uses `strategy: local`, which keeps counters in memory on each Kong node. For multi-node production clusters, switch to `strategy: redis` and point to a shared Redis instance so counters stay consistent across nodes.
- **Use a different IdP.** The OpenID Connect AI Auth Strategy works with any OIDC-compliant identity provider (Microsoft Entra ID, Auth0, Keycloak, PingIdentity, others). Update the `issuer` URL and adjust the claim names to match your IdP's token format. The PKCE helper script works with any OIDC provider that supports Authorization Code + PKCE.
- **Cover non-Claude clients.** This recipe uses `formats: [{type: anthropic}]` because Claude Code sends requests in Anthropic's native format. If your team needs broader provider support (OpenAI, Google Gemini, Mistral), see [Basic LLM Routing](/cookbooks/basic-llm-routing/) with `formats: [{type: openai}]`.

## Cleanup

The recipe's kongctl namespace scoped all resources, so this teardown removes only this recipe's configuration.

Delete the **Claude Code Usage** custom dashboard. The dashboard is an org-level resource and outlives the {{site.ai_gateway}}, so remove it before tearing down Kong:

```bash
DASHBOARD_IDS=$(kongctl api get "/v2/dashboards?filter%5Blabels.recipe%5D=claude-code-sso-recipe" \
  --pat "${KONNECT_TOKEN}" -o json --jq '.data[].id' -r)

if [ -z "${DASHBOARD_IDS}" ]; then
  echo "No Claude Code Usage dashboard found. Skipping."
else
  for id in ${DASHBOARD_IDS}; do
    if kongctl api delete "/v2/dashboards/${id}" --pat "${KONNECT_TOKEN}"; then
      echo "Deleted Claude Code Usage dashboard ${id}."
    else
      echo "Failed to delete dashboard ${id}."
    fi
  done
fi
```
{: data-test-step="block" .collapsible }

Tear down the local data plane and delete the {{site.ai_gateway}} from {{site.konnect_short_name}}:

```bash
export KONNECT_CONTROL_PLANE_NAME='claude-code-sso-recipe' && curl -Ls https://get.konghq.com/ai | bash -s -- -d -k $KONNECT_TOKEN
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

{:.info}
> **Subscription seat users (Pro, Max, Team, or Enterprise):** Claude Code attempts to fall back to your cached subscription credentials once `apiKeyHelper` is removed from `settings.json`. Run `claude /status` to confirm the session resumed, and run `claude /login` again if it didn't.
