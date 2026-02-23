This document guides you through the process of upgrading Kong Mesh.

First, check if a section named `Upgrade to x.y.z` exists,
with `x.y.z` being the version you are planning to upgrade to.

Make sure to also check the upgrade notes for the matching version of [Kuma](https://kuma.io/docs/latest/production/upgrades-tuning/upgrades).

## Upgrade to `2.14.x`

## Upgrade to `2.13.x`

### AWS IAM workload label validation for MeshIdentity

Starting with Kong Mesh `2.13.x`, AWS IAM role tags are validated against dataplane metadata labels (not inbound tags). When a `MeshIdentity` uses the `kuma.io/workload` label in its SPIFFE ID path template, the IAM role must include a matching `kuma.io/workload` tag.

**When this applies:**

This validation is only enforced when a `MeshIdentity` resource exists for the mesh AND its SPIFFE ID path template references the `kuma.io/workload` label (e.g., `{{ label "kuma.io/workload" }}`).

**Migration steps:**

1. For each Mesh with a `MeshIdentity` that uses `kuma.io/workload` in its SPIFFE ID path, add the `kuma.io/workload` tag to IAM roles:
   ```
   kuma.io/workload: <workload-name>
   ```

2. Ensure dataplanes have matching `kuma.io/workload` in metadata labels:
   - **Kubernetes**: Add to Pod labels (automatically synced to dataplane metadata)
   - **Universal**: Add to dataplane metadata labels:
     ```yaml
     type: Dataplane
     mesh: default
     name: dp-1
     labels:
       kuma.io/workload: <workload-name>
     networking:
       address: 127.0.0.1
       inbound:
         - port: 8080
           tags:
             kuma.io/service: backend
     ```

**Note:** Meshes without `MeshIdentity` resources or MeshIdentities that don't use `kuma.io/workload` in their SPIFFE ID path are not affected.

### OPA using `dynamicconfig` instead of xDS server

Starting with Kong Mesh `2.13.x`, the Open Policy Agent (OPA) integration uses the same mechanism for dynamic configuration as DNS and MeshMetrics.
This is a completely transparent change for users.

However, this will not work with the legacy `OPAPolicy` and only its replacement `MeshOPA` resources is supported.
If you are using `OPAPolicy`, two choices:

1. (recommended) Migrate to `MeshOPA` resources. `TargetRef` policies are mature and this is the recommended path forward.
2. Disable `dynconfig` for OPA by setting: `KMESH_OPA_EXPERIMENTAL_USE_DYNAMIC_CONFIG=false` in the environment variables of the data plane.

## Upgrade to `2.11.x`

### Helm upgrade with `--reuse-values` and `namespaceAllowList`

If you upgrade to `2.11.8` (or earlier `2.11.x` patch versions) using Helm with the `--reuse-values` flag, the upgrade may fail with a template error related to `namespaceAllowList`.

**Workaround:** Add the following to your `values.yaml` file before upgrading:

```yaml
namespaceAllowList: []
```

This issue is resolved in version `2.11.9` and later.

### Introduce an option to skip RBAC creation

By default, we create all RBAC resources required for the mesh to function properly. Since `2.11.x`, it's possible to skip the creation of `ClusterRole`, `ClusterRoleBinding`, `Role`, and `RoleBinding`. We introduced two flags:

* `kuma.skipRBAC`: Disables the creation of all RBAC resources (CNI and control plane).
* `kuma.controlPlane.skipClusterRoleCreation`: Disables the creation of `ClusterRole` and `ClusterRoleBinding` resources for the control plane only.

> [!WARNING]
> Before disabling automatic creation, ensure that the necessary RBAC resources are already in place, as the mesh components will not work correctly without them.

### Reduce the permissions of the `ClusterRole` by moving cert-manager permissions to a `Role`

During installation, we create a `ClusterRole` with permissions for Kong Mesh resources and cert-manager. We’ve identified that cluster-scoped access to cert-manager is not necessary, so we’ve moved those permissions to a separate `Role`, bound by a `RoleBinding` in the system namespace only. This change should not affect your deployment.

### Windows support is removed

Running Kong Mesh on Windows is no longer supported. If you are using Windows, please migrate to a Linux-based environment.

## Upgrade to `2.10.x`

### CP tokens are removed

Control Plane Tokens were deprecated in 2.0.x.
They are now removed and only zone tokens are supported to auth to zonal control-planes to global.
To generate and use zone tokens checkout the dedicated [docs](https://docs.konghq.com/mesh/latest/features/kds-auth/).

## Upgrade to `2.7.x`

### RBAC

A new access type: `VIEW_CONTROL_PLANE_METADATA` has been added to the RBAC configuration which restricts access to `/config`.
If you want to leave the access to `/config` unrestricted, you need to add `VIEW_CONTROL_PLANE_METADATA` to the rules of your `admin` `AccessRole`.

### ECS

The configuration for AWS IAM data plane authentication has changed slightly
because of the removal of configuration options
`KUMA_DP_SERVER_AUTH_*` and `dpServer.auth.*` (see Kuma `UPGRADE.md`).

Instead of control plane configuration like:

```
            - Name: KUMA_DP_SERVER_AUTH_TYPE
              Value: aws-iam
            - Name: KUMA_DP_SERVER_AUTH_USE_TOKEN_PATH
              Value: "true"
```

you'll need:

```
            - Name: KUMA_DP_SERVER_AUTHN_DP_PROXY_TYPE
              Value: aws-iam
            - Name: KUMA_DP_SERVER_AUTHN_ZONE_PROXY_TYPE
              Value: aws-iam
            - Name: KUMA_DP_SERVER_AUTHN_ENABLE_RELOADABLE_TOKENS
              Value: "true"

```

See [Kong/kong-mesh-ecs#40](https://github.com/Kong/kong-mesh-ecs/pull/40) for an example.

## Upgrade to `2.0.x`

Control Plane Tokens are deprecated. It will be removed in a future release.
You can use the Zone Token instead to authenticate any zonal control plane.
