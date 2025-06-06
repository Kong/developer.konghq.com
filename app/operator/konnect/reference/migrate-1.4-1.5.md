---
title: Migrate Konnect DataPlanes from {{ site.operator_product_name }} 1.4 to 1.5
description: "How do I migrate from {{ site.operator_product_name }} 1.4 to 1.5, taking in to account breaking changes?"
content_type: reference
layout: reference
products:
  - operator
breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect
  - index: operator
    group: Konnect
    section: Reference

---

This document helps to migrate from the `gateway-operator.konghq.com` to the `konnect.konghq.com` `KonnectExtension`.

1. Label the certificate `Secret`:

    ```bash
    kubectl label secret -n kong konnect-client-tls konghq.com/konnect-dp-cert=true
    ```

1. Install new kubernetes-configuration CRDs:

    ```bash
    kustomize build https://github.com/kong/kubernetes-configuration/crd/gateway-operator | kubectl apply --server-side -f -
    ```

    <!-- Requires https://github.com/Kong/docs.konghq.com/pull/8588 to merge -->
    To verify version compatibility with kubernetes-configuration CRDs, please consult the [version compatibility table](/operator/reference/version-compatibility/#kubernetes-configuration-crds).

    {:.info}
    > Note: In case CRDs were installed via `helm` you might need to force conflicts:

    ```bash
    kustomize build https://github.com/kong/kubernetes-configuration/crd/gateway-operator | kubectl apply --server-side --force-conflicts -f -
    ```


1. Upgrade to new controller version (e.g. set the `image.tag` in `values.yaml` to `v1.5.0`)

1. Create:

    1. `KonnectAPIAuthConfiguration` with your Konnect API token ([create one here](https://cloud.konghq.com/global/account/tokens)), for example:

        ```bash
        echo '
        kind: KonnectAPIAuthConfiguration
        apiVersion: konnect.konghq.com/v1alpha1
        metadata:
          name: konnect-api-auth
          namespace: kong
        spec:
          type: token
          token: kpat_XXXXXXXXX
          serverURL: us.api.konghq.com' | kubectl apply -f -
        ```

    1. New `KonnectExtension` using the `konnect.konghq.com` API group and reference the Konnect CP by KonnectID.

        For example, the following `KonnectExtension` from 1.4 (using the `gateway-operator.konghq.com` API group):

        ```yaml
        kind: KonnectExtension
        apiVersion: gateway-operator.konghq.com/v1alpha1
        metadata:
          name: example-konnect-config
          namespace: kong
        spec:
          controlPlaneRef:
            type: konnectID
            konnectID: <CP_ID>
          controlPlaneRegion: <REGION> # This will be inferred in 1.5+ using the Konnect API
          serverHostname: <HOSTNAME>   # This will be inferred in 1.5+ using the Konnect API
          konnectControlPlaneAPIAuthConfiguration:
            clusterCertificateSecretRef:
              name: konnect-client-tls
        ```

        Would translate into following `KonnectExtension` in 1.5 (using the `konnect.konghq.com` API group):

        ```yaml
        kind: KonnectExtension
        apiVersion: konnect.konghq.com/v1alpha1
        metadata:
          name: example-konnect-config
          namespace: kong
        spec:
          konnect:
            controlPlane:
              ref:
                type: konnectID
                konnectID: a6554c4c-79a6-4db7-b7a4-201c0cf746ba # The Konnect controlPlane ID
            configuration:
              authRef:
                name: konnect-api-auth # Reference to the KonnectAPIAuthConfiguration object
          clientAuth:
            certificateSecret:
              provisioning: Manual
              secretRef:
                name: konnect-client-tls
        ```

1. Ensure that your `DataPlane`, `ControlPlane` and `GatewayConfiguration` objects use the new extension: by verifying the `extensions` field in the spec:

    ```yaml
    spec:
      extensions:
      - kind: KonnectExtension
        name: my-konnect-config
        group: konnect.konghq.com # Ensure that group matches this value.
    ```

1. Remove the finalizer from the old extension:

    ```bash
    kubectl patch konnectextensions.gateway-operator.konghq.com example-konnect-config -n kong -p '{"metadata":{"finalizers":null}}' --type=merge
    ```

1. Delete the old `gateway-operator.konghq.com` `KonnectExtension`.
