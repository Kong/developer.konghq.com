---
title: Configure a Virtual Outbound
description: "Learn how to configure a VirtualOutbound in {{site.mesh_product_name}} to define custom DNS entries for mesh services."
content_type: how_to
permalink: /mesh/configure-virtual-outbound/
bread-crumbs:
  - /mesh/
related_resources:
  - text: "{{site.mesh_product_name}}"
    url: /mesh/overview/

products:
  - mesh

works_on:
  - konnect
  - on-prem

tldr:
  q: How do I configure a VirtualOutbound in {{site.mesh_product_name}}?
  a: Apply a VirtualOutbound resource to define custom hostnames for your mesh services, then access them using the new DNS name.

#prereqs:
#  inline:
#    - title: Install {{site.mesh_product_name}}
#      include_content: prereqs/kubernetes/mesh-helm

cleanup:
  inline:
    - title: Clean up Mesh
      include_content: cleanup/products/mesh
      icon_url: /assets/icons/gateway.svg
---

## Deploy the example service

Create a namespace with sidecar injection enabled and deploy the echo service into it:

```sh
echo "apiVersion: v1
kind: Namespace
metadata:
  name: echo-example
  labels:
    kuma.io/sidecar-injection: enabled" | kubectl apply -f -
```

```sh
kubectl apply -f {{site.links.web}}/manifests/kic/echo-service.yaml -n echo-example
```

Wait for the pod to be ready:

```sh
kubectl wait --for=condition=Ready pod --all -n echo-example --timeout=300s
```

{% validation kubernetes-wait-for %}
kind: pod
resource: echo-example
{% endvalidation %}

## Configure a VirtualOutbound

A [VirtualOutbound](/mesh/policies/virtual-outbound/) lets you define custom hostnames and ports for services in the mesh. This is useful when you want to access services using a simple, memorable DNS name rather than the full Kubernetes DNS name.

Apply the following VirtualOutbound resource:

<!--vale off-->
{% raw %}
```sh
echo "apiVersion: kuma.io/v1alpha1
kind: VirtualOutbound
mesh: default
metadata:
  name: flights
spec:
  selectors:
    - match:
        kuma.io/service: echo_echo-example_svc_1027
  conf:
    host: '{{.svc}}.mesh'
    port: '80'
    parameters:
      - name: service
        tagKey: kuma.io/service
      - name: svc
        tagKey: k8s.kuma.io/service-name" | kubectl apply -f -
```
{% endraw %}
<!--vale on-->

This VirtualOutbound creates an `echo.mesh:80` DNS entry that routes to the echo service's HTTP port (1027). The `parameters` section maps Go template variables to Dataplane tags:

- `service`: Maps to the `kuma.io/service` tag, which identifies the service within the mesh. This parameter is required by VirtualOutbound.
- `svc`: Maps to the `k8s.kuma.io/service-name` tag, which contains the Kubernetes service name. This is used in the `host` template to generate the `echo.mesh` hostname.

## Validate

Deploy a test container in the mesh to verify the VirtualOutbound is working:

```sh
kubectl create deployment test-client --image nicolaka/netshoot -n echo-example -- /bin/bash -c "ping -i 60 localhost"
```

Wait for the test pod to be ready:

```sh
kubectl wait --for=condition=Available deployment test-client -n echo-example --timeout=300s
```

Send a request to the echo service using the virtual outbound hostname:

```sh
kubectl exec -n echo-example deploy/test-client -- curl -s echo.mesh
```

You should see a response from the echo service, confirming that the VirtualOutbound DNS resolution is working:

```
Welcome, you are connected to node <node-name>.
Running on Pod <pod-name>.
In namespace echo-example.
With IP address <pod-ip>.
```
{:.no-copy-code}

{:.info}
> If you get a connection error, wait a few seconds for the VirtualOutbound configuration to propagate and try again.
