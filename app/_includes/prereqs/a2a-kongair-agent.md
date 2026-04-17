You need a running A2A-compliant agent. This guide uses a sample KongAir travel agent that uses OpenAI and LangGraph to answer flight route queries.

Create a `docker-compose.yaml` file:

```sh
cat <<'EOF' > docker-compose.yaml
services:
  a2a-agent:
    container_name: a2a-kongair-agent
    image: ghcr.io/tomek-labuk/a2a-kongair-openai-agent:1.0.0
    environment:
      - OPENAI_API_KEY=${DECK_OPENAI_API_KEY}
      - OPENAI_MODEL=gpt-5-mini
      - KONGAIR_BASE_URL=https://api.kong-air.com
      - PUBLIC_AGENT_URL=http://localhost:10000
    ports:
      - "10000:10000"
EOF
```

Export your OpenAI API key and start the agent:

```sh
export DECK_OPENAI_API_KEY='your-openai-key'
docker compose up -d
```

The agent listens on port 10000 and uses the A2A JSON-RPC protocol to handle flight route queries. In this guide, the gateway service points to `host.docker.internal:10000` instead of the container name because {{site.base_gateway}} runs in its own container with a separate DNS resolver.
