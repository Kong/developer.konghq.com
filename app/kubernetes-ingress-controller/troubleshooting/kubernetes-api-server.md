---
title: Debugging Kubernetes API Server connectivity
short_title: Kubernetes API Server

description: |
  Learn how to customize {{ site.kic_product_name }}'s connection to the Kubernetes API Server.

content_type: reference
layout: reference

breadcrumbs:
  - /kubernetes-ingress-controller/
  - index: kubernetes-ingress-controller
    section: Troubleshooting

products:
  - kic

works_on:
  - on-prem
  - konnect

tags:
  - troubleshooting

related_resources:
  - text: "Debugging KIC in {{site.konnect_short_name}}"
    url: /kubernetes-ingress-controller/troubleshooting/konnect/
  - text: "Debugging {{site.base_gateway}} Configuration"
    url: /kubernetes-ingress-controller/troubleshooting/kong-gateway-configuration/
  - text: "Debugging KIC in {{site.konnect_short_name}}"
    url: /kubernetes-ingress-controller/troubleshooting/konnect/
  - text: Failure Modes
    url: /kubernetes-ingress-controller/troubleshooting/failure-modes/
---

## Kubernetes API Server authentication

A number of components are involved in the authentication process and the first step is to narrow down the source of the problem, namely whether it is a problem with service authentication or with the kubeconfig file.  Both authentications must work:

{% mermaid %}
graph RL
    ingress["ingress controller"]
    apiserver["apiserver"]

    ingress -- "service authentication" --> apiserver
{% endmermaid %}

## Service authentication

The Ingress controller needs information from the API server to configure {{site.base_gateway}}. Therefore, authentication is required, which can be achieved in two different ways:

1. **Service Account**: This is recommended because nothing has to be configured.  The Ingress controller will use information provided by the system to communicate with the API server. See the [Service Account](#service-account) section for details.
1. **Kubeconfig file**: In some Kubernetes environments, service accounts aren't available. In this case, a manual configuration is required.  You can start the Ingress controller binary with the `--kubeconfig` flag.  The value of the flag is a path to a file specifying how to connect to the API server. Using the `--kubeconfig` doesn't require the flag `--apiserver-host`.  The format of the file is identical to `~/.kube/config` which is used by `kubectl` to connect to the API server.  See ['kubeconfig' section](#kubeconfig) for details.

## Discovering the API server

Using this flag `--apiserver-host=http://localhost:8080`, you can specify an unsecured API server or reach a remote Kubernetes cluster using [kubectl proxy](https://kubernetes.io/docs/tasks/administer-cluster/access-cluster-api/#using-kubectl-proxy). **Do not** use this approach in production.

{% mermaid %}
flowchart LR
    subgraph Kubernetes
        k8s_apiserver["apiserver"]
        k8s_ingress["ingress controller"]

        k8s_apiserver -- "apiserver proxy" --> k8s_ingress
        k8s_ingress -- "service account / kubeconfig" --> k8s_apiserver
    end

    subgraph Workstation
        ws_ingress["ingress controller"]
    end

    ws_ingress -- "kubeconfig" --> k8s_apiserver
{% endmermaid %}

## Service Account

If you're using a service account to connect to the API server, Dashboard expects the file `/var/run/secrets/kubernetes.io/serviceaccount/token` to be present. It provides a secret token that is required to authenticate with the API server.

Verify with the following commands:

1. Start a container that contains curl:
   ```
   kubectl run test --image=tutum/curl -- sleep 10000
   ```
1. Check that the container is running:
   ```sh
   kubectl get pods
   ```
1. Check if secret exists:
   ```sh
   kubectl exec $POD_NAME ls /var/run/secrets/kubernetes.io/serviceaccount/
   ```
1. Get the cluster IP:
   ```sh
   kubectl get services
   ```
1. Check the base connectivity from the cluster:
   ```sh
   kubectl exec $POD_NAME -- curl -k $CLUSTER_IP
   ```
1. Connect using tokens:
   ```sh
   export TOKEN_VALUE=$(kubectl exec $POD_NAME -- cat /var/run/secrets/kubernetes.io/serviceaccount/token)
   kubectl exec $POD_NAME -- curl --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt -H  "Authorization: Bearer $TOKEN_VALUE" $CLUSTER_IP
   ```

If it isn't working, there are two possible reasons:

1. The contents of the tokens are invalid.
    Find the secret name:

    ```bash
    kubectl get secrets --field-selector=type=kubernetes.io/service-account-token
    ```

    Delete the secret:

    ```bash
    kubectl delete secret $SECRET_NAME
    ```

    It will automatically be recreated.

1. You have a non-standard Kubernetes installation and the file containing the token may not be present.

The API server will mount a volume containing this file, but only if the API server is configured to use the ServiceAccount admission controller. If you experience this error, verify that your API server is using the ServiceAccount admission controller. If you are configuring the API server by hand, you can set this with the `--admission-control` parameter. You should use other admission controllers as well. Before configuring this option, read about admission controllers.

For more information, see the following:

- [User Guide: Service Accounts](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)
- [Cluster Administrator Guide: Managing Service Accounts](https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/)

## Kubeconfig

If you want to use a kubeconfig file for authentication, follow the deploy procedure and add the flag `--kubeconfig=/etc/kubernetes/kubeconfig.yaml` to the deployment.