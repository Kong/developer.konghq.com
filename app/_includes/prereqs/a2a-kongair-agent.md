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
      
      # Route OpenAI calls through {{site.base_gateway}} (v2.0.0+)
      - OPENAI_BASE_URL=http://host.docker.internal:8000/openai
      - HTTP_HEADERS={"Authorization": "Bearer ${DECK_OAUTH_TOKEN}"}
      
      # KongAir backend
      - KONGAIR_BASE_URL=https://api.kong-air.com
      - PUBLIC_AGENT_URL=http://a2a-agent:10000
    ports:
      - "10000:10000"
EOF
```

Export your OAuth token:

```sh
export DECK_OAUTH_TOKEN=your-kong-oauth-token
```

If using API key authentication instead, replace `HTTP_HEADERS` with:

```sh
HTTP_HEADERS={"apikey": "your-kong-api-key"}
```

Start the agent:

```sh
docker compose up -d
```

The agent listens on port 10000 and uses the A2A JSON-RPC protocol to handle flight route queries. By default, it routes OpenAI API calls through {{site.base_gateway}} at `http://host.docker.internal:8000/openai`. In this guide, the gateway service points to `host.docker.internal:10000` instead of the container name because {{site.base_gateway}} runs in its own container with a separate DNS resolver.
