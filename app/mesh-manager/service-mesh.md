---
title: Configure a Mesh global Control Plane with the Kubernetes demo app
content_type: reference
description: 'Set up a global Control Plane in {{site.konnect_short_name}}, add a zone, and deploy the Kubernetes demo app to test your {{site.mesh_product_name}} mesh.'
layout: reference
breadcrumbs:
  - /mesh-manager/
products:
  - mesh
works_on:
  - konnect
tags:
  - mesh-manager
  - service-mesh
---

Using Mesh Manager, you can create global Control Planes to manage your {{site.mesh_product_name}} meshes. This guide explains how to configure a global Control Plane and then install the Kubernetes demo app to test out the {{site.mesh_product_name}} interface in {{site.konnect_short_name}}.

## Prerequisites

* A Kubernetes cluster with [load balancer service capabilities](https://kubernetes.io/docs/concepts/services-networking/service/#loadbalancer)
* `kubectl` installed and configured
* [The latest version of {{site.mesh_product_name}}](/mesh/#install-kong-mesh)

## Create a global Control Plane in {{site.konnect_short_name}}

Before you can add services or apply configurations, you must create a global Control Plane.

1. In [**Mesh Manager**](https://cloud.konghq.com/mesh-manager), click **New Global Control Plane**.
1. Name the Control Plane `example-cp` and click **Save**.

The global Control Plane is now created but has no functionality until you connect a zone.

## Create a zone in the global Control Plane

After creating the global Control Plane, add a zone to connect services and receive configuration updates.

1. In the `example-cp` Control Plane, click **Create Zone**.
1. Enter `zone-1` as the name, then click **Create Zone & generate token**.

    {:.info}
    > The zone name must use lowercase alphanumeric characters or hyphens, and start and end with an alphanumeric character.

1. Follow the Helm and token setup instructions in the UI. Once the zone is running, it will appear in Mesh Manager.

You now have a minimal {{site.mesh_product_name}} mesh. The next step is to add services.

## Add services to your mesh

To test your mesh, deploy the Kubernetes demo app:

```bash
kubectl apply -f https://raw.githubusercontent.com/kumahq/kuma-counter-demo/master/demo.yaml
kubectl wait -n kuma-demo --for=condition=ready pod --selector=app=demo-app --timeout=90s
```

This creates:

* `demo-app`: a counter web app on port 5000
* `redis`: the backing data store

To see these services:

1. Open **Mesh Manager**, select `example-cp`, and click **Meshes**.
1. Click **Default**, then go to the **Services** tab.

## Configure `kumactl` to connect to the global Control Plane

{:.info}
> Because the mesh is deployed on Kubernetes, `kumactl` is read-only. You manage resources using `kubectl`. Still, it's best practice to configure `kumactl` for visibility and diagnostics.

1. In [**Mesh Manager**](https://cloud.konghq.com/mesh-manager), select `example-cp`.
1. From the **Actions** menu, choose **Configure kumactl** and follow the steps.
1. Verify the demo services are running:

   ```bash
   kumactl get dataplanes
   ```

You should see two data planes: `demo-app` and `redis`.

See the [`kumactl` command reference](/mesh/cli/#kumactl) for more information.

## Conclusion

You've successfully:

* Created a global Control Plane in {{site.konnect_short_name}}
* Added a zone
* Deployed demo services
* Connected `kumactl` to your Control Plane

## Next steps

Try [enabling traffic permissions](/mesh/policies/meshtrafficpermission/) on your demo services to explore {{site.mesh_product_name}}'s policy features.
