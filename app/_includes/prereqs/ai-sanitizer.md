Kong provides **AI PII Anonymizer service Docker images** in a private repository. These images are distributed via a private Cloudsmith registry. Contact [Kong Support](https://support.konghq.com/support/s/) to request access.

To pull images, first authenticate with the token provided by Support:

```bash
docker login docker.cloudsmith.io/kong/ai-pii
```

Docker will then prompt you to enter a username and password:

```bash
Username: kong/ai-pii
Password: YOUR-TOKEN
```
To pull an image:

```bash
docker pull docker.cloudsmith.io/kong/ai-pii/IMAGE-NAME:TAG
```

Replace `IMAGE-NAME` and `TAG` with the appropriate image and version, such as:

```bash
docker pull docker.cloudsmith.io/kong/ai-pii/service:v0.1.2-en
```

{:.info}
> Each image includes a built-in NLP model. Check the [AI Sanitizer documentation](/plugins/ai-sanitizer/#ai-pii-anonymizer-service) for more detail.