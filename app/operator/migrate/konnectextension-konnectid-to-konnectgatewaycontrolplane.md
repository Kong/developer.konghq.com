---
title: Migrate KonnectExtension from konnectID to KonnectGatewayControlPlane
description: Learn how to migrate your KonnectExtension resources to KonnectGatewayControlPlane before upgrading to KO 2.0.0.
content_type: reference
layout: reference
products:
  - operator
breadcrumbs:
  - /operator/
related_resources:
  - text: Migrating from {{site.gateway_operator_product_name}} 1.6.x to {{site.operator_product_name}} 2.0.0
    url: /operator/migrate/migrate-1.6.x-2.0.0/
  - text: Migrate Konnect DataPlanes from {{site.operator_product_name}} 1.4 to 1.5
    url: /operator/konnect/reference/migrate-1.4-1.5/
---


In {{ site.operator_product_name }} 2.0.0, the `konnectID` field has been **removed** from the `KonnectExtension` resource. If you are using the `konnectID` field in your `KonnectExtension`, you must migrate.

If you are using `konnectID`, you must update your manifests to use the new `konnectgatewaycontrolplane` reference before upgrading. This is a required step to ensure a smooth migration and avoid breaking changes.

{:.warning}
> **Disclaimer**: This migration guide assumes you are running {{site.operator_product_name}} (KGO) version 1.6.3. If you are using an earlier version, upgrade to 1.6.3 before proceeding.

## Migration Steps


1. **Locate Your KonnectExtension Resource Using `konnectID`**

    Find your `KonnectExtension` manifest that uses the `konnectID` field. It will look similar to the following
    
    ```yaml
    kind: KonnectExtension
    apiVersion: konnect.konghq.com/v1alpha1
    metadata:
    	 name: my-konnect-config
    	 namespace: kong
    spec:
    	 konnect:
    		 controlPlane:
    			 ref:
    				 type: konnectID
    				 konnectID: 6f7c4caa-XXXX-XXXX-XXXX-XXXXXXXXXXXX
    	 configuration:
    		 authRef:
    			 name: my-konnect-api-auth
    ```

2. **Create a KonnectGatewayControlPlane in Mirror Mode**

    Next, create a `KonnectGatewayControlPlane` resource in your cluster that mirrors the same Konnect control plane you previously referenced with `konnectID`. This enables the new reference type required by KO 2.0.

     Example manifest:
     ```yaml
     kind: KonnectGatewayControlPlane
     apiVersion: konnect.konghq.com/v1alpha1
     metadata:
    	 name: gateway-control-plane
    	 namespace: kong
     spec:
    	 source: Mirror
    	 mirror:
    		 konnect:
    			 id: 6f7c4caa-XXXX-XXXX-XXXX-XXXXXXXXXXXX
    	 konnect:
    		 authRef:
    			 name: konnect-api-auth
    ```
 
3. **Verify KonnectGatewayControlPlane Reconciliation**

    After applying the resource, check that the operator has reconciled the `KonnectGatewayControlPlane` correctly by running:

    ```bash
    kubectl get konnectgatewaycontrolplanes.konnect.konghq.com -n kong
    ```

    You should see output similar to:

    ```
    NAME                    PROGRAMMED   ID                                     ORGID
    gateway-control-plane   True         6f7c4caa-XXXX-XXXX-XXXX-XXXXXXXXXXXX   82dc54ec-XXXX-XXXX-XXXX-XXXXXXXXXXXX 
    ```
 
 4. **Create a New KonnectExtension Referencing the KonnectGatewayControlPlane**
 
     Because the `ref` field in the `KonnectExtension` resource is immutable, you cannot update the existing resource to reference the new control plane. Instead, you must create a new `KonnectExtension` that references the `KonnectGatewayControlPlane` you created in the previous step.
    
     Example manifest:
     ```yaml
     kind: KonnectExtension
     apiVersion: konnect.konghq.com/v1alpha1
     metadata:
    	 name: my-konnect-config-1
    	 namespace: kong
     spec:
    	 konnect:
    		 controlPlane:
    			 ref:
    				 type: konnectNamespacedRef
    				 konnectNamespacedRef:
    					 name: gateway-control-plane
     ```
    
     Apply the new resource:
     ```bash
     kubectl apply -f <your-new-konnectextension-file>.yaml
     ```
    
     Verify that the new extension is programmed:
     ```bash
     kubectl get konnectextensions.konnect.konghq.com -n kong
     ```
     You should see output similar to:
     ```
     NAME                  READY
     my-konnect-config     True
     my-konnect-config-1   True
     ```
     You will see both the old and new extensions listed. The new one should be ready before proceeding.
 
5. **Update the Dataplane Resource to Reference the New KonnectExtension**

    Update your DataPlane resource to reference the newly created `KonnectExtension` (`my-konnect-config-1`).

    **Before:**
    ```yaml
    ...
    spec:
    	extensions:
    	- kind: KonnectExtension
    		name: my-konnect-config
    		group: konnect.konghq.com
    ...
    ```

    **After:**
    ```yaml
    ...
    spec:
    	extensions:
    	- kind: KonnectExtension
    		name: my-konnect-config-1
    		group: konnect.konghq.com
    ...
    ```

    This change ensures your DataPlane is now using the new KonnectExtension and is compatible with the upgraded control plane. 

    Once you update the DataPlane resource, the operator will perform a rolling update. A new DataPlane pod will be created referencing the new KonnectExtension. When the new pod is ready, the old pod will be removed automatically. You can observe this transition in your Konnect control plane UI or by watching the pods in your namespace:

    ```bash
    kubectl get pods -n kong
    ```

    This ensures zero downtime and a smooth migration to the new configuration.

6. **Clean Up the Old KonnectExtension**

    After confirming that your DataPlane is running successfully with the new KonnectExtension, you can safely remove the old `KonnectExtension` instance that was using the deprecated `konnectID` field:
    
    ```bash
    kubectl delete konnectextensions.konnect.konghq.com -n kong my-konnect-config
    ```
