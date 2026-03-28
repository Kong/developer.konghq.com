For this task, you need a running vLLM server.

1. Follow the [vLLM installation guide](https://docs.vllm.ai/en/latest/getting_started/installation.html) to deploy a vLLM server on your infrastructure.

1. Note the full URL where your vLLM server is accessible, including the chat completions path (for example, `http://localhost:8000/v1/chat/completions`).

1. Export the URL as an environment variable:

   ```sh
   export DECK_VLLM_UPSTREAM_URL='http://your-vllm-host:8000/v1/chat/completions'
   ```

1. If your vLLM server is configured with an API key (`--api-key` flag), export it as well:

   ```sh
   export DECK_VLLM_API_KEY='your-api-key'
   ```
