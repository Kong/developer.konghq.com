Kong distributes these images publicly on Docker Hub, under the `kong/ai-pii-service` repository. No authentication is required to pull them.

To pull an image:

```bash
docker pull kong/ai-pii-service:TAG
```

Replace `TAG` with the appropriate version and language code, such as:

```bash
docker pull kong/ai-pii-service:v0.2.2-en
```

{:.info}
> Each image includes a built-in NLP model. Check the [AI Sanitizer documentation](/plugins/ai-sanitizer/#ai-pii-anonymizer-service) for more detail.