In this tutorial, we'll collect data in OpenTelemetry Collector. Use the following command to launch a Collector instance with default configuration that listens on port 4318 and writes its output to the container logs:

```sh
docker run -d --rm \
  --name otel-collector \
  -p 127.0.0.1:4318:4318 \
  otel/opentelemetry-collector:0.141.0
```
{: data-test-prereq="block" }

Export the OTEL Collector host. In this example, use the following host:
```sh
export DECK_OTEL_HOST=host.docker.internal
```
