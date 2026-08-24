---
title: "Kong Mesh: 'admission webhook \"validator.kuma-admission.kuma.io\" denied the request: access denied' error when the default AccessRole or AccessRoleBinding is missing or too restrictive"
content_type: support
description: "{{site.mesh_product_name}} denies valid users from creating resources when the default `AccessRole` and `AccessRoleBinding` are missing or too restrictive; recreating them and the validating webhook resolves the access-denied error."
products:
  - mesh
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: "Why does creating a Kong Mesh resource fail with an 'admission webhook ... denied the request: access denied' error even though my user has access?"
  a: |
    This happens when the default `AccessRole` and `AccessRoleBinding` have been modified too restrictively or don't exist, so the `kuma-admission` webhook rejects the request even for users with sufficient Kubernetes RBAC access. Back up and delete the `kong-mesh-validating-webhook-configuration` webhook, re-create the default `AccessRole`/`AccessRoleBinding`, then re-apply the webhook to restore access.
---

## Problem

When attempting to create a new resource we are receiving the below error despite my user being part of the `system:masters` & `system:authenticated` groups.

```
Error from server: error when creating "mesh.yaml": admission webhook "validator.kuma-admission.kuma.io" denied the request: access denied: user "arn:aws:iam::12345:role/NonProd_ServiceMesh_DevUsers/system:masters,system:authenticated" cannot access the resource
```

I have also confirmed my user has access to creating the resource, in this case, a new mesh. What is causing this?

```bash
kubectl auth can-i create mesh
yes
```

## Solution

This issue can occur when the default `AccessRole` and `AccessRoleBinding` have either been modified in an overly restrictive manner or do not exist.

If you do not have another user with a different `AccessRole`/`AccessRoleBinding` associated you will need to modify the webhook to unblock yourself.

Note: As always, it is important to test this process in lower environments before attempting in production.

1. IMPORTANT: Backup the existing webhook config before proceeding

   ```bash
   kubectl get validatingwebhookconfigurations.admissionregistration.k8s.io kong-mesh-validating-webhook-configuration -oyaml > webhook.yaml
   ```

2. Delete the webhook

   ```bash
   k delete -f webhook.yaml
   ```

3. Re-create the `AccessRole` and/or `AccessRoleBinding` (depending on what is missing)

   AccessRole

   ```bash
   echo "
   apiVersion: v1
   items:
   - apiVersion: kuma.io/v1alpha1
     kind: AccessRole
     metadata:
       name: admin
     spec:
       rules:
       - access:
         - CREATE
         - UPDATE
         - DELETE
         - GENERATE_DATAPLANE_TOKEN
         - GENERATE_USER_TOKEN
         - GENERATE_ZONE_CP_TOKEN
         - GENERATE_ZONE_TOKEN
         - VIEW_CONFIG_DUMP
         - VIEW_STATS
         - VIEW_CLUSTERS
   kind: List
   metadata:
     resourceVersion: ''
   " | kubectl apply -f -
   ```

   AccessRoleBinding

   ```bash
   echo "
   apiVersion: v1
   items:
   - apiVersion: kuma.io/v1alpha1
     kind: AccessRoleBinding
     metadata:
       name: default
     spec:
       roles:
       - admin
       subjects:
       - name: mesh-system:authenticated
         type: Group
       - name: mesh-system:unauthenticated
         type: Group
       - name: system:authenticated
         type: Group
       - name: system:unauthenticated
         type: Group
   kind: List
   metadata:
     resourceVersion: ''
   " | kubectl apply -f -
   ```

4. Re-create the webhook

   ```bash
   kubectl apply -f webhook.yaml
   ```

5. Confirm you can now remove resources

   ```bash
   kubectl delete mesh gruber
   mesh.kuma.io "gruber" deleted
   ```
