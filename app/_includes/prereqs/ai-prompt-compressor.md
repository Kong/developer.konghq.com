Kong distributes the AI Prompt Compressor service publicly on Docker Hub, under the `kong/ai-compress-service` repository. No authentication is required to pull it.

To pull an image:

```bash
docker pull kong/ai-compress-service:TAG
```

Replace `TAG` with the image tag you want to run, for example:

```bash
docker pull kong/ai-compress-service:v0.0.6
```

You can run the image with:

```bash
docker run --rm -p 8080:8080 kong/ai-compress-service:v0.0.6
```

{:.info}
> Check the [AI Prompt Compressor documentation](/plugins/ai-prompt-compressor/#ai-prompt-compression-service) for more detail.
