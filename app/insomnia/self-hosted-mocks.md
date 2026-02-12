---
title: Self-hosted mocks
description: Insomnia allows Enterprise users to create self-hosted mock servers.

content_type: reference
layout: reference
breadcrumbs:
  - /insomnia/
  - /insomnia/mock-servers/
products:
  - insomnia

tier: enterprise
tags:
  - mock-servers

related_resources:
  - text: Mocks
    url: /insomnia/mock-servers/
  - text: Create a cloud-hosted mock server
    url: /how-to/create-a-cloud-hosted-mock-server/
  - text: Auto-generate a self-hosted mock server
    url: /insomnia/ai-in-insomnia/#Use-ai-to-auto-generate-a-mock-server
---

Enterprise users can use Insomnia to create self-hosted mock servers that let you run mock API endpoints in your own environment, outside of Insomnia's cloud.

Our self-hosted mock servers use the [Insomnia Mockbin](https://github.com/kong/insomnia-mockbin) service which allows you to simulate API behavior during development, testing, or integration work without depending on external mock hosting. 

Self-hosted mocks give you full control over availability, traffic limits, and infrastructure.

## Prerequisites
Before you deploy a self-hosted mock server, you need the following:

- Pull the Docker image
- Install and run the Redis instance

### Pull the Docker image

The self-hosted mock server runs on a Docker image. You can either install it using the command line or a base image in a Dockerfile.

{% navtabs "docker-pull" %}
{% navtab "Command line" %}
Install from the command line:
```sh
docker pull ghcr.io/kong/insomnia-mockbin-self-hosted:latest
```
{% endnavtab %}
{% navtab "Dockerfile" %}
Use as base image in Dockerfile:
```sh
FROM ghcr.io/kong/insomnia-mockbin-self-hosted:latest
```
{% endnavtab %}
{% endnavtabs %}

These will pull the latest image. You can see all available versions in the [self-hosted mock server repository](https://github.com/Kong/insomnia-mockbin/pkgs/container/insomnia-mockbin-self-hosted/versions).

### Install the Redis instance

1. Install Redis:
   
   ```sh
   brew install redis
   ```
1. Start Redis:
   
   ```sh
   brew services start redis
   ```
   Redis should be now running on `localhost:6379`. 

1. Clone the mockbin repository:
   ```sh
   git clone https://github.com/Kong/mockbin.git ./mockbin
   cd mockbin
   cp .env.sample .env
   brew install fnm
   fnm use
   npm install
   ```

   {:.info}
   > **Note:** You can use `nvm`, `n` or `volta` instead of `fnm`.


For more information about how to verify the container signature and provenance, see the [Insomnia mockbin README](https://github.com/Kong/insomnia-mockbin/tree/self-hosted).

{:.info}
> To run a self-hosted mock server locally, use [NodeJS](https://github.com/Kong/insomnia-mockbin/tree/self-hosted?tab=readme-ov-file#running-with-node), [Docker](https://github.com/Kong/insomnia-mockbin/tree/self-hosted?tab=readme-ov-file#running-with-docker-compose), or Kubernetes.

## Create a self-hosted mock server with Kubernetes

To run mock endpoints in your own infrastructure using standard Kubernetes resources, deploy a self-hosted mock server to Kubernetes. This approach lets you manage availability, scaling, and networking using the same deployment and operational practices you already use for other services.

### Configure the deployment

Self-hosted mock servers require Redis to store mock data at runtime. When you deploy the mock server to Kubernetes, you must configure the Redis connection using environment variables. At a minimum, you must provide the **Redis host** so that the container can connect to your Redis service.

Set the following environment variable in the container spec:

- `MOCKBIN_REDIS`: The Redis connection URL. For example, `redis://redis.mock.svc:6379`.

For a full list of supported environment variables in the mock server, review the [Docker Compose configuration](https://github.com/Kong/insomnia-mockbin/blob/self-hosted/docker-compose.yml).

Run the following command to create a deployment for your mock server:

```sh
echo "
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: insomnia-mock
    namespace: mock
  spec:
    replicas: 1
    selector:
      matchLabels:
        app: insomnia-mock
    template:
      metadata:
        labels:
          app: insomnia-mock
      spec:
        containers:
        - name: insomnia-mock
          image: ghcr.io/kong/insomnia-mockbin-self-hosted:latest
          ports:
          - containerPort: 9080
          env:
            - name: MOCKBIN_PORT
              value: '9080'
            - name: MOCKBIN_REDIS
              value: "redis://redis:6379"  
" | kubectl apply -f -
```

{:.info}
> When you run a self-hosted mock server in Kubernetes, Redis connectivity depends on both the mock server configuration and the Redis image that you deploy. If your mock server can't connect to Redis even though Redis appears healthy and reachable with port-forwarding, use a different [Redis base image](https://hub.docker.com/r/bitnami/redis).

### Configure the service

To create a service that exposes the Mockbin internally to the cluster, run the following command:

```sh
echo "
  apiVersion: v1
  kind: Service
  metadata:
    name: insomnia-mock
    namespace: mock
  spec:
    type: ClusterIP
    ports:
    - name: mock
      port: 9080
      targetPort: 9080
    selector:
      app: insomnia-mock
" | kubectl apply -f -
```

### Configure the Ingress

To configure the Ingress to manage external access, first set your domain and TLS secret, and then apply the manifest. Your domain and TLS settings determine the host and secret of the configuration.

To export a domain and a TLS secret name as environment variables, run the following command:

```sh
export DOMAIN='your-domain'
export SECRET_NAME='your-tls-secret-name'
```

To apply the Ingress manifest, run the following command:

```sh
echo "
  apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    name: insomnia-mock-ingress
    namespace: mock
  spec:
    ingressClassName: nginx
    rules:
    - host: $DOMAIN
      http:
        paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: insomnia-mock
              port:
                number: 9080
    tls:
    - hosts:
      - $DOMAIN
      secretName: $SECRET_NAME
" | kubectl apply -f -
```

### Validate

Use the following commands to check the status of your resources:

```sh
kubectl get deployments -n mock
kubectl get services -n mock
kubectl get ingress -n mock
```

Once you deploy your mock, point your front-end application to the mock URL.

## Create an auto-generated mock server
Use Insomnia’s AI-assisted mock server generation to transform a short description, or an existing API source into a working self-hosted mock server.

You can generate a mock server from any of the following: 
- **URL**: Generate from a live endpoint response.  
- **OpenAPI**: Generate from a spec.  
- **Text**: Generate by providing a description of the API endpoints.
                    
{:.info}
> AI-generated mock servers are only supported with self-hosted mocks.

**To create an AI-generated mock server:**
1. In your Insomnia project, click **Create**.  
1. Click **Mock Server**.  
1. Click **Auto-Generate**.  
1. Select either **URL**, **OpenAPI spec**, or **Text**.
1. (Optional) Select the **Enable dynamic responses** checkbox.  
1. (Optional) Click **+ Add Files** to upload extra JSON files or YAML files.
1. Insert an example mock-server URL.
1. Click **Create**.


**AI-assisted mocks and dynamic mocking**: AI generation focuses on creating a complete mock structure from your input prompt or source. [Dynamic mocking](/insomnia/dynamic-mocking/) extends those generated mocks by making them **request-aware**. 
                    
Together, they enable rapid creation of realistic, responsive test environments without manual setup.