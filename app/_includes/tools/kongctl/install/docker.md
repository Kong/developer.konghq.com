Kong provides official Docker images for kongctl on [Docker Hub](https://hub.docker.com/r/kong/kongctl).

Pull the latest image:

```bash
docker pull kong/kongctl:latest
```

Verify the installation:

```bash
docker run --rm kong/kongctl:latest version
```

For authentication and local configuration examples, see
[Run kongctl in Docker](/kongctl/docker/).
