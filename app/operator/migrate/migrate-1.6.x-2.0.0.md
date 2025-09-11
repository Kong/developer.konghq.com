---
title: "Migrating from {{site.operator_product_name}} 1.6.x to Kong Operator 2.0.0"
description: "Complete migration guide from {{site.operator_product_name}} (KGO) 1.6.x to Kong Operator (KO) 2.0.0."
content_type: reference
layout: reference
products:
  - operator
breadcrumbs:
  - /operator/
works_on:
  - on-prem
  - konnect
tags:
  - migration
  - upgrade

related_resources:
  - text: "KonnectExtension Migration Prerequisites"
    url: /operator/migrate/konnectextension-konnectid-to-konnectgatewaycontrolplane/
  - text: "Kong Operator Changelog"
    url: /operator/changelog/
  - text: "Version Compatibility"
    url: /operator/reference/version-compatibility/

---

Kong Operator (KO) 2.0.0 represents a major version upgrade from {{site.operator_product_name}} (KGO) 1.6.x, introducing significant architectural improvements, enhanced Kubernetes-native features, and breaking changes that require careful migration planning.

## Prerequisites

Before starting the migration, ensure you:

1. **Backup your current configuration**

2. **Verify current operator version**:
   ```bash
   helm list -n kong-system
   ```

3. **Check for deprecated konnectID field** (if using KonnectExtensions):
   ```bash
   kubectl get konnectextensions --all-namespaces -o yaml | grep -A 5 -B 5 konnectID
   ```

   {:.warning}
   > **Important**: If this command returns any results, you **must** migrate these KonnectExtensions before upgrading. Follow the [KonnectExtension Migration Guide](/operator/migrate/konnectextension-konnectid-to-konnectgatewaycontrolplane/) first.

4. **Access to Kubernetes cluster** with admin privileges

5. **Verify cert-manager is installed** (required for conversion webhooks):

   {:.info}
   > **Note**: Kong Operator 2.0.0 uses conversion webhooks that require TLS certificates managed by cert-manager. If cert-manager is not installed, follow the [cert-manager installation guide](https://cert-manager.io/docs/installation/) before proceeding.

## Upgrade Kong Operator to 2.0.0

The upgrade process requires several manual steps due to breaking changes in certificate management and CRD structure. Follow these steps carefully:

### Step 1: Uninstall the Existing KGO Release

First, uninstall the current {{site.operator_product_name}} release:

```bash
helm uninstall kgo -n kong-system
```

### Step 2: Label the Secret

To ensure the {{site.operator_product_name}} can properly reconcile the Secrets in your cluster, they need to be labeled with `konghq.com/secret=true`.

This allows efficient listing of Secrets and prevents ingesting those that are irrelvent from Kong configuration standpoint.

This includes the CA certificate secret. To label it as described above it you can run the following command:

```bash
kubectl label secrets -n kong-system kong-operator-ca konghq.com/secret=true
```

### Step 3: Install Kong Operator 2.0.0

Install the new Kong Operator using Helm:

```bash
helm repo update kong
helm upgrade --install kong-operator kong/kong-operator \
  -n kong-system \
  --create-namespace \
  --take-ownership \
  --set env.ENABLE_CONTROLLER_KONNECT=true \
  --set ko-crds.enabled=true \
  --set global.conversionWebhook.enabled=true \
  --set global.conversionWebhook.certManager.enabled=true 
```

{:.info}
> **Note**: The `--take-ownership` flag is required if CRDs or other resources were previously installed or managed by another tool (such as kubectl or a previous Helm release). This ensures Helm can properly manage and upgrade those resources as part of the new release.

### Step 4: Verify the installation

Verify that Kong Operator 2.0.0 is running correctly.

1. Check the Kong Operator deployment:
   ```bash
   kubectl get pod -n kong-system
   ```

1. Check Kong Operator logs:
    ```sh
    kubectl logs -n kong-system -l app=kong-operator-kong-operator
    ```
