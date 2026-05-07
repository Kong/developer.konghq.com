---
title: 'Issue identity with MeshIdentity Spire provider'
description: 'Learn how to issue identities using Spire provider and how to use them to encrypt traffic in mesh.'
content_type: how_to
permalink: /mesh/meshidentity-spire/

breadcrumbs:
  - /mesh/

products:
  - mesh

works_on:
  - on-prem

tags:
  - security

min_version:
  mesh: '2.12'

tldr:
  q: How do I issue identities using the Spire provider in {{site.mesh_product_name}}?
  a: Install {{site.mesh_product_name}} with Spire support enabled, configure Spire to issue SPIFFE identities, then create a `MeshIdentity` resource to manage identity for your data planes.

related_resources:
  - text: Data plane proxy
    url: '/mesh/data-plane-proxy/'
  - text: MeshIdentity
    url: '/mesh/policies/meshidentity/'
  - text: MeshTrafficPermission
    url: '/mesh/policies/meshtrafficpermission/'

prereqs:
  inline:
    - title: Helm
      include_content: prereqs/helm
    - title: A running Kubernetes cluster
      include_content: prereqs/kubernetes/mesh-cluster
    - title: Install {{site.mesh_product_name}}
      content: |
        Install the {{site.mesh_product_name}} control plane with Helm. You need to enable the Kubernetes Spire injector on the control plane for Spire support to work:

        ```sh
        helm repo add {{site.mesh_helm_repo_name}} {{site.mesh_helm_repo_url}}
        helm repo update
        helm install --create-namespace --namespace {{site.mesh_namespace}} \
          --set "{{site.set_flag_values_prefix}}controlPlane.envVars.KUMA_RUNTIME_KUBERNETES_INJECTOR_SPIRE_ENABLED=true" \
          {{ site.mesh_helm_install_name }} {{ site.mesh_helm_repo }}
        ```
    - title: Install Spire
      content: |
        Install Spire CRDs:

        ```sh
        helm upgrade --install --create-namespace -n spire spire-crds spire-crds \
         --repo https://spiffe.github.io/helm-charts-hardened/
        ```

        Install Spire with custom trust domain `default.local-zone.mesh.local`. You will use this trust domain in the next steps to configure MeshIdentity:

        ```sh
        helm upgrade --install -n spire spire spire \
         --repo https://spiffe.github.io/helm-charts-hardened/ \
         --set "global.spire.trustDomain=default.local-zone.mesh.local" \
         --set "global.spire.tools.kubectl.tag=v1.31.11"
        ```
    - title: Configure Spire to issue identities in the kuma-demo namespace
      content: |
        Configure Spire to issue identities in the `kuma-demo` namespace. This specifies a spiffeID template that uses the configured trust domain, namespace, and [service account](https://kubernetes.io/docs/concepts/security/service-accounts/) name:

        ```sh
        echo "apiVersion: spire.spiffe.io/v1alpha1
        kind: ClusterSPIFFEID
        metadata:
          name: spire-registration
        spec:
          podSelector:
            matchLabels:
              kuma.io/mesh: default
          spiffeIDTemplate: '{% raw %}spiffe://{{ .TrustDomain }}/ns/{{ .PodMeta.Namespace }}/sa/{{ .PodSpec.ServiceAccountName }}{% endraw %}'
          workloadSelectorTemplates:
            - 'k8s:ns:kuma-demo'" | kubectl apply -f -
        ```
    - title: Deploy the demo application
      content: |
        1. Deploy the application:

           ```sh
           kubectl apply -f https://raw.githubusercontent.com/kumahq/kuma-counter-demo/master/k8s/000-with-kuma.yaml
           kubectl wait -n kuma-demo --for=condition=ready pod --selector=app=demo-app --timeout=90s
           ```

           {:.warning}
           > For `MeshIdentity` to work you need to have `meshServices.mode: Exclusive` set on the Mesh resource. It is already configured in the demo.

        2. Port-forward the service to the namespace on port 5050:

           ```sh
           kubectl port-forward svc/demo-app -n kuma-demo 5050:5050
           ```

        3. Make a request to the demo app to confirm it is working:

           ```sh
           curl -XPOST localhost:5050/api/counter
           ```

           You should see a response like this:

           ```
           {"counter":1,"zone":""}
           ```
---

{:.warning}
> This is a guide for an experimental feature.

## About identity and trust

In {{site.mesh_product_name}} there are two concepts around identity:

* **[Identity](/mesh/concepts/)** — Who a workload is. A workload's identity is the name encoded in its certificate, and this identity is considered valid only if the certificate is signed by a Trust.
* **[Trust](/mesh/concepts/)** — Who to believe. Trust defines which identities you accept as valid, and is established through trusted certificate authorities (CAs) that issue those identities. Trust is attached to a trust domain, and there can be multiple Trusts in the [mesh](/mesh/concepts/).

## Issue identity

In {{site.mesh_product_name}}, the `MeshIdentity` resource manages identity. In this scenario, Spire is responsible for issuing identity and managing trust, but you still need to create a `MeshIdentity` to configure the data plane to use the identity managed by Spire.

Apply the following `MeshIdentity` resource:

```sh
echo "apiVersion: kuma.io/v1alpha1
kind: MeshIdentity
metadata:
  name: identity-spire
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: default
    kuma.io/origin: zone
spec:
  selector:
    dataplane:
      matchLabels: {}
  spiffeID:
    trustDomain: default.local-zone.mesh.local
    path: '{% raw %}/ns/{{ .Namespace }}/sa/{{ .ServiceAccount }}{% endraw %}'
  provider:
    type: Spire
    spire: {}" | kubectl apply -f -
```

This resource uses three key fields:

* **`selector`** — Selects the data planes for which identity should be issued. In this example, identity is issued for all data planes in the mesh.
* **`spiffeID`** — Contains templates for building the spiffeID for your workloads. You must use the same trust domain you configured in Spire (`default.local-zone.mesh.local`) with a path dynamically created from the namespace and service account name. For example, a spiffeID looks like `spiffe://default.local-zone.mesh.local/ns/kuma-demo/sa/default`.
* **`provider`** — Contains configuration specific to the identity provider. Specify `Spire` as the provider type.

## View MeshIdentity in the GUI

When you open the Mesh view in the GUI, you'll see new sections for `MeshIdentity` and `MeshTrust`, where you can inspect these resources.

<center>
<img src="/assets/images/guides/meshidentity/mi-spire.png" alt="MeshIdentity and MeshTrust sections in the Mesh GUI view"/>
</center>

## Test connectivity with MeshIdentity

Make some requests to the demo app:

```sh
curl -XPOST localhost:5050/api/counter
```

You should see errors like this:

```
{"instance":"d11ee97a4b45ff3a7b59091d1612b7f7","status":500,"title":"failed to retrieve zone","type":"https://github.com/kumahq/kuma-counter-demo/blob/main/ERRORS.md#INTERNAL-ERROR"}
```

Since you issued identity for your workloads, mTLS was also configured. Zero trust is the default behavior, and because there is no `MeshTrafficPermission` configured yet, the requests fail.

## Allow traffic in the kuma-demo namespace

To allow traffic in `kuma-demo`, create a `MeshTrafficPermission` that uses the rules API with spiffeID matching:

```sh
echo "apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  name: mtp
  namespace: kuma-demo
  labels:
    kuma.io/mesh: default
spec:
  rules:
    - default:
        allow:
          - spiffeID:
              type: Prefix
              value: spiffe://default.local-zone.mesh.local/ns/kuma-demo" | kubectl apply -f -
```

This policy allows all traffic from workloads whose spiffeID starts with `spiffe://default.local-zone.mesh.local/ns/kuma-demo`. Based on the template from the `MeshIdentity` created earlier, every workload in the `default` mesh and in the `kuma-demo` namespace will have a spiffeID with this prefix. You can also allow only workloads matching their `exact` spiffeID for more fine-grained control.

## Validate

Run the following command to confirm that traffic is now allowed:

```sh
curl -XPOST localhost:5050/api/counter
```

You should see a response like this:

```
{"counter":3,"zone":""}
```
