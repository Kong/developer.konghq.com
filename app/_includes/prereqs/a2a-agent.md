You need a running A2A-compliant agent. This guide uses a sample currency conversion agent from the [A2A project](https://github.com/a2aproject/a2a-samples).

Create a `docker-compose.yaml` file:

```sh
cat <<'EOF' > docker-compose.yaml
services:
  a2a-agent:
    container_name: a2a-currency-agent
    build:
      context: .
      dockerfile_inline: |
        FROM python:3.12-slim
        WORKDIR /app
        RUN pip install uv && apt-get update && apt-get install -y git
        RUN git clone --depth 1 https://github.com/a2aproject/a2a-samples.git /tmp/a2a && \
            cp -r /tmp/a2a/samples/python/agents/langgraph/* . && \
            rm -rf /tmp/a2a
        ENV UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy
        RUN uv sync --frozen --no-dev
        EXPOSE 10000
        CMD ["uv", "run", "app", "--host", "0.0.0.0"]
    environment:
      - model_source=openai
      - API_KEY=${DECK_OPENAI_API_KEY}
      - TOOL_LLM_URL=https://api.openai.com/v1
      - TOOL_LLM_NAME=gpt-5.1
    ports:
      - "10000:10000"
    networks:
      - kong-net

networks:
  kong-net:
    external: true
    name: kong-quickstart-net
EOF
```

Export your OpenAI API key and start the agent:

```sh
export DECK_OPENAI_API_KEY='your-openai-key'
docker compose up --build -d
```

The agent listens on port 10000 and uses the A2A JSON-RPC protocol to handle currency conversion queries.
