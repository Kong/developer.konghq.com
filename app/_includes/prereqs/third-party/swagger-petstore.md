This tutorial uses Swagger's Petstore API, run the following command to start the server:

```sh
docker run -d \
  --name swagger-petstore \
  --network kong-ai-quickstart-net \
  --network-alias host.docker.internal \
  -p 8080:8080 \
  swaggerapi/petstore3:latest
```
{:data-test-prereq="block"}
