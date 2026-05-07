---
title: Issue identity with MeshIdentity bundled provider
description: Learn how to issue SPIFFE-compliant identities using MeshIdentity with the bundled provider and configure MeshTrafficPermission with SPIFFE ID matching.
content_type: how_to
permalink: /mesh/meshidentity-guide/
products:
  - mesh
works_on:
  - on-prem
breadcrumbs:
  - /mesh/
tags:
  - security
tldr:
  q: How do I issue identity with the MeshIdentity bundled provider?
  a: By the end of this guide, you will issue workload identities with MeshIdentity, inspect the generated MeshTrust, and allow traffic with MeshTrafficPermission SPIFFE ID matching.
prereqs:
  inline:
    - title: Helm
      content: Install [Helm](https://helm.sh/) to install and manage Kubernetes applications.
    - title: Minikube
      content: Install [minikube](https://minikube.sigs.k8s.io/docs/) to run a local Kubernetes cluster for testing.
related_resources:
  - text: Issue identity with MeshIdentity Spire provider
    url: /mesh/meshidentity-spire/
  - text: MeshIdentity policy
    url: /mesh/policies/meshidentity/
  - text: MeshTrust policy
    url: /mesh/policies/meshtrust/
---

{:.warning}
> This guide covers an experimental feature.

The [MeshIdentity](/mesh/policies/meshidentity/) policy allows you to issue identity for selected data planes. This approach is [SPIFFE](https://spiffe.io/docs/latest/spiffe-about/overview/) compliant and can be used with [Spire](/mesh/meshidentity-spire/). In this guide, you'll issue identities using the bundled provider.

## Start a Kubernetes cluster

Start a local Kubernetes cluster using minikube. The `-p` flag creates a new profile named `mesh-zone`:

```bash
minikube start -p mesh-zone
```

{:.info}
> If you already have a running Kubernetes cluster, either locally or in the cloud (for example, EKS, GKE, or AKS), you can skip this step.

## Install {{site.mesh_product_name}}

Install the {{site.mesh_product_name}} control plane with Helm:

```sh
helm repo add {{site.mesh_helm_repo_name}} {{site.mesh_helm_repo_url}}
helm repo update
helm install --create-namespace --namespace {{ site.mesh_namespace }} {{ site.mesh_helm_install_name }} {{ site.mesh_helm_repo }}
```

## Deploy the demo application

1. Deploy the application:

   ```sh
   kubectl apply -f kuma-demo://k8s/000-with-kuma.yaml
   kubectl wait -n kuma-demo --for=condition=ready pod --selector=app=demo-app --timeout=90s
   ```

   {:.warning}
   > For `MeshIdentity` to work, set `meshServices.mode: Exclusive` on the Mesh resource. This value is already configured in the demo.

1. Port-forward the service to the namespace on port `5000`:

   ```sh
   kubectl port-forward svc/demo-app -n kuma-demo 5050:5050
   ```

1. Test requests to `demo-app`:

   ```sh
   curl -XPOST localhost:5050/api/counter
   ```

   You should see similar output:

   ```json
   {"counter":1,"zone":""}
   ```
   {:.no-copy-code}

## Review identity concepts

In {{site.mesh_product_name}}, there are two identity concepts:

* **[Identity](/mesh/concepts/#identity)**: Who a workload is. A workload identity is the name encoded in its certificate, and this identity is valid only if the certificate is signed by a trust.
* **[Trust](/mesh/concepts/#trust)**: Who to believe. Trust defines which identities you accept as valid through trusted certificate authorities (CA) that issue those identities. Trust is attached to a trust domain, and there can be multiple trusts in a [mesh](/mesh/concepts/#mesh).

## Issue identities

`MeshIdentity` manages identity issuance. To issue a new identity in a [mesh](/mesh/concepts/#mesh), create this resource:

```sh
echo "apiVersion: kuma.io/v1alpha1
kind: MeshIdentity
metadata:
  name: identity
  namespace: {{ site.mesh_namespace }}
  labels:
    kuma.io/mesh: default
spec:
  selector:
    dataplane:
      matchLabels: {}
  spiffeID:
    trustDomain: '{% raw %}{{ .Mesh }}.{{ .Zone }}.mesh.local{% endraw %}'
    path: '{% raw %}/ns/{{ .Namespace }}/sa/{{ .ServiceAccount }}{% endraw %}'
  provider:
    type: Bundled
    bundled:
      meshTrustCreation: Enabled
      insecureAllowSelfSigned: true
      certificateParameters:
        expiry: 24h
      autogenerate:
        enabled: true" | kubectl apply -f -
```

`MeshIdentity` uses `selector` to choose the data planes that receive identities. In this example, identity is issued for all data planes in the mesh.

`spiffeID` defines templates for workload SPIFFE IDs. In this example, the trust domain is built from mesh name, zone name, and `.mesh.local`. The path is built from namespace and service account. Example SPIFFE ID: `spiffe://default.default.mesh.local/ns/kuma-demo/sa/default`.

The `provider` field contains identity-provider-specific configuration. This guide uses the `Bundled` provider. This config enables `MeshTrust` generation, allows self-signed certificates, and sets cert expiry time to 24h.

## Inspect trust configuration

This `MeshIdentity` creates a `MeshTrust` resource. Check whether it was created:

```sh
kubectl get meshtrusts -n {{ site.mesh_namespace }}
```

You should see a similar response:

```text
NAME       AGE
identity   45s
```
{:.no-copy-code}

Inspect the full generated `MeshTrust` resource:

```sh
kubectl get meshtrust identity -n {{ site.mesh_namespace }} -oyaml
```

Generated `MeshTrust` should look similar to:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshTrust
metadata:
  labels:
    kuma.io/env: kubernetes
    kuma.io/mesh: default
    kuma.io/origin: zone
    kuma.io/zone: default
  name: identity
  namespace: {{ site.mesh_namespace }}
spec:
  caBundles:
  - pem:
      value: |
        -----BEGIN CERTIFICATE-----
        MIIDgzCCAmugAwIBAgIRAO8psy2B4YbbzSvhSaRYTlMwDQYJKoZIhvcNAQELBQAw
        QzENMAsGA1UEChMES3VtYTENMAsGA1UECxMETWVzaDEjMCEGA1UEAxMaZGVmYXVs
        dC5kZWZhdWx0Lm1lc2gubG9jYWwwHhcNMjUwOTAyMTMxMjA4WhcNMzUwODMxMTMx
        MjE4WjBDMQ0wCwYDVQQKEwRLdW1hMQ0wCwYDVQQLEwRNZXNoMSMwIQYDVQQDExpk
        ZWZhdWx0LmRlZmF1bHQubWVzaC5sb2NhbDCCASIwDQYJKoZIhvcNAQEBBQADggEP
        ADCCAQoCggEBAOERv23rg9mmNdNu2pULOMD5/5IwW7SW9WFdfEYtpuM8OxnpLOZl
        HQo7ZnPhPbpvqNYz8wpgZmOD3zMu4PT2W+Rdv/qC4wSbY1kCrFxbcc88sjmRFVJm
        1fQFgzcu91IZn4cWo7XpNA7a1t46kzAiM5oz6WsLcZ76AhG/A82L60z/k1wvFqMK
        aORPysIMLLEBs1A09iuzqvlp+7iv8BiAVgu3KD1RX5mSOyg91U/g1XhzOrHV1WY5
        VoSs9l6mbJDeVdlaLC5wQzD4E71XWpqnHXxjG695vhxMZLqHIuyxt4WXKEF78ma/
        1V5k/Sc7nUHmFBT1a0B6XCDvzdqGJYa58+sCAwEAAaNyMHAwDgYDVR0PAQH/BAQD
        AgEGMA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFIrDUs8m5iAB+f9Jx4gFC7e4
        hKlBMC4GA1UdEQQnMCWGI3NwaWZmZTovL2RlZmF1bHQuZGVmYXVsdC5tZXNoLmxv
        Y2FsMA0GCSqGSIb3DQEBCwUAA4IBAQDZvq4Pz7VxscfP+DkqNJDMKMidbaEnPbac
        nr5RG2YJ4+HuGakvHLc7Of8a3FSYAQX2cgjRrGLAnsC7zrOxYT3kEuXZzbQ545rw
        eZp9I6AdTa5fd0G9vnmUDkJnpQNDg0Ao/vJfv0hSmouJrkp9yvuR0VkLrMSkRUN+
        rHdPHVlnEBDRsZv8a1/ShVffF5mmdX5qifw35Iv+owS+ATWfhOO3nvOMKR4tY9qb
        aZ/Vckmai7QO4BhGUiVnhUdPQCWqQoxE3h8+kMD9BL1Vxpi8uXpLmQpi8HQbaBKO
        lahgDp2cp52Edw5luev1Vx/y23R5F6gxyO1h1lX7mb5qV8PoK0WE
        -----END CERTIFICATE-----
    type: Pem
  origin:
    kri: kri_mid_default_default_{{ site.mesh_namespace }}_identity_
  trustDomain: default.default.mesh.local
```

In the generated `MeshTrust`, `caBundle` is generated by the control plane and `trustDomain` is created from the `MeshIdentity` template. The `origin` value specifies the KRI (Kuma Resource Identifier) for the `MeshIdentity` that generated this trust.

## Review MeshIdentity in the GUI

In the GUI, open the Mesh view to find `MeshIdentity` and `MeshTrust` sections, then inspect these resources.

<center>
<img src="/assets/images/guides/meshidentity/gui-mi.png" alt="Data Plane Proxies Stats metric for inbound_POD_IP_6379.rbac.allowed"/>
</center>

## Test connectivity with MeshIdentity

Send a request to `demo-app`:

```sh
curl -XPOST localhost:5050/api/counter
```

You should see an error similar to:

```json
{"instance":"d11ee97a4b45ff3a7b59091d1612b7f7","status":500,"title":"failed to retrieve zone","type":"https://github.com/kumahq/kuma-counter-demo/blob/main/ERRORS.md#INTERNAL-ERROR"}
```
{:.no-copy-code}

Because identity is issued for workloads, mTLS is configured. Zero trust is the default behavior in this case, and without `MeshTrafficPermission` configured, these errors are expected.

## Allow traffic in the `kuma-demo` namespace

Create a `MeshTrafficPermission`:

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
              value: spiffe://default.default.mesh.local/ns/kuma-demo" | kubectl apply -f -
```

This `MeshTrafficPermission` uses rules API SPIFFE ID matching. This policy allows traffic from workloads whose SPIFFE ID starts with `spiffe://default.default.mesh.local/ns/kuma-demo`.

## Validate the result

Send another request:

```sh
curl -XPOST localhost:5050/api/counter
```

You should see output similar to:

```json
{"counter":3,"zone":""}
```
{:.no-copy-code}

## Next steps

- Check out [MeshIdentity guide with Spire provider](/mesh/meshidentity-spire/)
- Learn more about [MeshIdentity](/mesh/policies/meshidentity/) and [MeshTrust](/mesh/policies/meshtrust/)
- Explore [MeshTrafficPermission with SPIFFE ID matchers](/mesh/policies/meshtrafficpermission/)
