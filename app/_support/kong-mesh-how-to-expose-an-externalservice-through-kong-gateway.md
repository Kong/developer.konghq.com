---
title: "Kong Mesh: How to expose an `ExternalService` through Kong Gateway"
content_type: support
description: To expose a Kong Mesh `ExternalService` through Kong Gateway, create a Kubernetes `ExternalName` service that points to it, then route to that service with an Ingress.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How do I expose a Kong Mesh `ExternalService` through Kong Gateway?
  a: |
    Create a Kubernetes `ExternalName` service that points at the Mesh `ExternalService` (using its `<service>.mesh` DNS name), then create an Ingress that routes to that `ExternalName` service. This lets Kong Gateway proxy traffic to the external service defined in Kong Mesh.
---

## Prerequisites

- Kong Mesh and Kong Gateway are integrated, with communication already working between them (for example, you can access other Data Planes configured through the Mesh).

## Steps

1. Create your `ExternalService` on the Mesh. If using multi-zone, this should be created on the Global CP.

   ```yaml
   apiVersion: kuma.io/v1alpha1
   kind: ExternalService
   mesh: default
   metadata:
     name: httpbin
   spec:
     tags:
       kuma.io/service: httpbin
       kuma.io/protocol: http
     networking:
       address: httpbin.org:80
   ```

2. Create an `ExternalName` service that points to your `ExternalService`. This can be done in the same cluster/namespace as your Kong Gateway.

   ```yaml
   apiVersion: v1
   kind: Service
   metadata:
     name: echo-multizone
     namespace: kongfused
   spec:
     type: ExternalName
     externalName: httpbin.mesh
   ```

3. Create an ingress that points to the `ExternalName` service.

   ```yaml
   apiVersion: networking.k8s.io/v1
   kind: Ingress
   metadata:
     name: external
   spec:
     ingressClassName: kong
     rules:
     - http:
         paths:
         - path: /external
           pathType: ImplementationSpecific
           backend:
             service:
               name: echo-multizone
               port:
                 number: 80
   ```

## Validation

You can now successfully proxy your `ExternalService` that is defined on your Kong Mesh through Kong Gateway.
