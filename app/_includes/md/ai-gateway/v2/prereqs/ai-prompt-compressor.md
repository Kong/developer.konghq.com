Kong distributes the AI Prompt Compressor service publicly on Docker Hub, under the `kong/ai-compress-service` repository. No authentication is required to pull it.

Run the service and publish port `8080`:

```bash
docker run -d --name compress-service -p 8080:8080 kong/ai-compress-service:v0.0.6
```
{:data-test-prereq="block"}

The service downloads and loads its model on the first request, so the first compression can take a few seconds.

Verify the service is running:

```bash
curl --fail-with-body http://localhost:8080/status
```
{:data-test-prereq="block"}

For more detail, see the [AI Prompt Compressor Policy documentation](/ai-gateway/policies/ai-prompt-compressor/#llmlingua-compressor-service).
