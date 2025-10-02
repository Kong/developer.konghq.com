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
---

Insomnia allows Enterprise users to create self-hosted mock servers.

[Configuration details](https://github.com/Kong/insomnia-mockbin/tree/self-hosted) and a [Docker image](https://github.com/Kong/insomnia-mockbin/pkgs/container/insomnia-mockbin-self-hosted/versions) can be found on GitHub.

You can run it [locally](https://github.com/Kong/insomnia-mockbin/tree/self-hosted?tab=readme-ov-file#installation) with NodeJS or Docker, or you can use Kubernetes.

## Create a self-hosted mock server with Kubernetes

### Configure the deployment

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
" | kubectl apply -f -
```

### Configure the service

Run the following command create a service to expose Mockbin internally in the cluster:

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

For this example, you'll need to export a domain and a TLS secret name as environment variables:

```sh
export DOMAIN='your-domain'
export SECRET_NAME='your-tls-secret-name'
```

Then run the following command:

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

Once your mock is deployed, you can point your front-end application to the mock URL.
