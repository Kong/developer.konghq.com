You need a running A2A-compliant agent. This guide uses a sample KongAir travel agent that uses OpenAI and LangGraph to answer flight route queries.

Create a `docker-compose.yaml` file:

```sh
cat <<'EOF' > docker-compose.yaml
services:
  a2a-agent:
    container_name: a2a-kongair-agent
    image: ghcr.io/tomek-labuk/a2a-kongair-openai-agent:2.0.0
    environment:
      # OpenAI credentials
      - OPENAI_API_KEY=${DECK_OPENAI_API_KEY}
      - OPENAI_MODEL=gpt-5-mini
      
      # Route OpenAI calls through {{site.base_gateway}}
      - OPENAI_BASE_URL=http://host.docker.internal:8000/openai
      - HTTP_HEADERS={"Authorization": "Bearer ${DECK_OAUTH_TOKEN}"}
      
      # KongAir backend
      - KONGAIR_BASE_URL=https://api.kong-air.com
      - PUBLIC_AGENT_URL=http://a2a-agent:10000
    ports:
      - "10000:10000"
EOF
```

(Optional) If your `/openai` Route is protected by an auth plugin, export an access token that the agent can use when calling it:

```sh
export DECK_OAUTH_TOKEN=your-kong-oauth-token
```

Start the agent:

```sh
docker compose up -d
```

The agent listens on port 10000 and routes OpenAI API calls through {{site.ai_gateway}} at `http://host.docker.internal:8000/openai`.
