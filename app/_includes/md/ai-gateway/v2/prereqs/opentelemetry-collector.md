Launch a local OpenTelemetry Collector in the background, listening on port 4318:

```sh
docker run -d \
  --name otel-collector \
  -p 127.0.0.1:4318:4318 \
  otel/opentelemetry-collector:0.141.0
```
{:data-test-prereq="block"}