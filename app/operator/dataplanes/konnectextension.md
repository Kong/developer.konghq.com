---
title: "KonnectExtension"
description: Automatically register DataPlanes with {{ site.konnect_short_name }} by providing authentication credentials in KonnectExtension
content_type: reference
layout: reference
products:
  - operator
breadcrumbs:
  - /operator/
  - index: operator
    group: Gateway Deployment
  - index: operator
    group: Gateway Deployment
    section: Key Concepts

---

Kong Data Plane instances can be configured in {{site.konnect_short_name}} using the [`KonnectExtension`](/operator/reference/custom-resources/#konnectextension-1) resource. This resource can be used to provision isolated `DataPlane`s (Hybrid mode) or pairs of `ControlPlane`s  and `DataPlane`s ({{ site.kic_product_name }} mode).

The `KonnectExtension` resource can be referenced by `ControlPlane`s, `DataPlane`s, or `GatewayConfiguration`s from the extension point in their spec. Dedicated guides will guide you to through these kinds of setup.

## {{site.konnect_short_name}} Control Plane reference

`KonnectExtension` can be attached to {{site.konnect_short_name}} `ControlPlane`s of type Hybrid or KIC. This reference can be performed in two different ways: via {{site.konnect_short_name}} ID or via Kubernetes object reference to an in cluster `KonnectGatewayControlPlane`.

### Reference by {{site.konnect_short_name}} ID

The {{site.konnect_short_name}} Control Plane can be referenced by its ID, without having any `KonnectGatewayControlPlane` resource deployed in the cluster. The Control Plane ID can be fetched by the {{site.konnect_short_name}} UI, in the Control Plane page. With this configuration, the `KonnectExtension` object requires to have the `konnect.configuration.authref` field set, as follows in the snippet below:

```yaml
spec:
  konnect:
    controlPlane:
      ref:
        type: konnectID
        konnectID: a6554c4c-79a6-4db7-b7a4-201c0cf746ba # The Konnect controlPlane ID
    configuration:
      authRef:
        name: konnect-api-auth # Reference to the KonnectAPIAuthConfiguration object
```

The `authRef.name` fields refers to an object of type [`KonnectAPIAuthConfiguration`](/operator/reference/custom-resources/#konnectapiauthconfiguration) that needs to exist in the same namespace as the `KonnectExtension`. Such objects contains all the data (server, token, etc.) to interact with konnect.

### Reference By Kubernetes object

Alternatively, the `KonnectExtension` can reference an object in the cluster. This reference allows to attach the `DataPlane`s to the {{site.konnect_short_name}} Control Plane via a local object [(a.k.a. `KonnectGatewayControlPlane`)](/operator/reference/custom-resources/#konnectgatewaycontrolplane). When this type of reference is used, the `KonnectAPIAuthConfiguration` data is inferred by the `KonnectGatewayControlPlane` objects. For this reason, it's not possible to set the `konnect.configuration.authref` field in this scenario.

```yaml
spec:
  konnect:
    controlPlane:
      ref:
        type: konnectNamespacedRef
        konnectNamespacedRef:
          name: gateway-control-plane # The KonnectGatewayControlPlane resource name
```

## Data Plane authentication

The `DataPlane`, in order to be configured in {{site.konnect_short_name}}, needs a client certificate. This certificate can be manually created and managed by the user, or automatically provisioned by {{ site.operator_product_name }}.

### Manual certificate provisioning

In order to manually create and set up a certificate to be used for Konnect `DataPlane`s, you can perform type the following commands:

1. Generate a new certificate and key:

    ```bash
    openssl req -new -x509 -nodes -newkey rsa:2048 -subj "/CN=kongdp/C=US" -keyout ./tls.key -out ./tls.crt
    ```

1. Create a Kubernetes secret that contains the previously created certificate:

    ```bash
    kubectl create secret tls konnect-client-tls --cert=./tls.crt --key=./tls.key
    ```

1. Label the secret to tell {{ site.operator_product_name }} to reconcile it:

    ```bash
    kubectl label secret konnect-client-tls konghq.com/konnect-dp-cert=true
    ```

Once the secret containing your certificate has been created in the cluster, you can set up your `KonnectExtension` as follows:

```yaml
spec:
  clientAuth:
    certificateSecret:
      provisioning: Manual
        secretRef:
          name: konnect-client-tls # The name of the secret containing your certificate
```

### Automatic certificate provisioning

Alternatively, you can leave the certificate provisioning and management to {{ site.operator_product_name }}, which will take care of creating a new certificate, write it into a Kubernetes `Secret` and manage the `Secret`'s lifecycle on behalf of you. To do so, you can configure a `KonnectExtension` as follows:

```yaml
spec:
  clientAuth:
    certificateSecret:
      provisioning: Automatic
```

or you can just leave the `spec.clientAuth` field empty, and the automatic provisioning will be used as the default value.

## Set DataPlane labels

Multiple labels can be configured to the {{site.konnect_short_name}} `DataPlane` via the following field:

```yaml
spec:
  konnect:
    dataPlane:
      foo: bar
      foo2: bar2
```

Please note that the amount of labels that can be set on `DataPlane`s via `KonnectExtension` is limited to 5.
