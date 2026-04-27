---
title: 'Configure the {{site.mesh_product_name}} CNI'
description: 'Install and configure {{site.mesh_product_name}} CNI to enable transparent proxying without requiring privileged init containers.'

content_type: reference
layout: reference

products:
  - mesh
breadcrumbs:
  - /mesh/

tags:
  - kubernetes
  - network

min_version:
  mesh: '2.9'

related_resources:
  - text: Mesh DNS
    url: '/mesh/dns/'
  - text: Transparent proxying
    url: '/mesh/transparent-proxying/'
  - text: Kubernetes annotations and labels
    url: /mesh/annotations/
---

For traffic to flow through {{site.mesh_product_name}}, all inbound and outbound traffic for a service must pass through its sidecar proxy.
The recommended way of accomplishing this is via [transparent proxying](/mesh/transparent-proxying/).

On Kubernetes, this is handled automatically by the `kuma-init` init container, but it requires elevated privileges. The {{site.mesh_product_name}} CNI is an alternative that removes this requirement from every `Pod` in the mesh, which can make security compliance easier.

{:.info}
> The CNI `DaemonSet` itself requires elevated privileges because it
> writes executables to the host filesystem as `root`.

Install the CNI using either
[kumactl](/mesh/#install-kong-mesh) or [Helm](https://helm.sh/).
The default settings are optimized for OpenShift with Multus. To use {{site.mesh_product_name}} CNI in other environments, set the configuration parameters shown in the relevant section below.

{:.warning}
> {{site.mesh_product_name}} CNI applies `NetworkAttachmentDefinitions` to applications in any namespace with `kuma.io/sidecar-injection` label.
> To apply `NetworkAttachmentDefinitions` to applications not in a Mesh, add the label `kuma.io/sidecar-injection` with the value `disabled` to the namespace.

## Installation

Select the section for your environment below.

### Cilium

Use the following settings to install {{site.mesh_product_name}} CNI in a Cilium-managed cluster.

{% cpinstall cilium %}
cni.enabled=true
cni.chained=true
cni.netDir=/etc/cni/net.d
cni.binDir=/opt/cni/bin
cni.confName=05-cilium.conflist
{% endcpinstall %}

{:.warning}
> You need to set the Cilium config value `cni-exclusive`
> or the corresponding Helm chart value `cni.exclusive` to `false`
> in order to use Cilium and {{site.mesh_product_name}} together.
> This is necessary starting with the release of Cilium v1.14.

{:.warning}
> For installing {{site.mesh_product_name}} CNI with Cilium on GKE, you should follow the [Google - GKE](#google---gke) section.

{:.warning}
> For Cilium versions < 1.14 you should use `{{site.set_flag_values_prefix}}cni.confName=05-cilium.conf` as this has changed
> for versions starting from [Cilium 1.14](https://docs.cilium.io/en/v1.14/operations/upgrade/#id2).

### Calico

Use the following settings to install {{site.mesh_product_name}} CNI in a Calico-managed cluster.

{% cpinstall calico %}
cni.enabled=true
cni.chained=true
cni.netDir=/etc/cni/net.d
cni.binDir=/opt/cni/bin
cni.confName=10-calico.conflist
{% endcpinstall %}

{:.warning}
> For installing {{site.mesh_product_name}} CNI with Calico on GKE, you should follow the [Google - GKE](#google---gke) section.

### K3D with Flannel

Use the following settings to install {{site.mesh_product_name}} CNI on K3D with Flannel.

{% cpinstall k3d %}
cni.enabled=true
cni.chained=true
cni.netDir=/var/lib/rancher/k3s/agent/etc/cni/net.d
cni.binDir=/bin
cni.confName=10-flannel.conflist
{% endcpinstall %}

### Kind

Use the following settings to install {{site.mesh_product_name}} CNI on a Kind cluster.

{% cpinstall kind %}
cni.enabled=true
cni.chained=true
cni.netDir=/etc/cni/net.d
cni.binDir=/opt/cni/bin
cni.confName=10-kindnet.conflist
{% endcpinstall %}

### Azure

Use the following settings to install {{site.mesh_product_name}} CNI on Azure Kubernetes Service (AKS).

{% cpinstall azure %}
cni.enabled=true
cni.chained=true
cni.netDir=/etc/cni/net.d
cni.binDir=/opt/cni/bin
cni.confName=10-azure.conflist
{% endcpinstall %}

### Azure Overlay

Use the following settings to install {{site.mesh_product_name}} CNI on AKS with Azure CNI Overlay networking.

{% cpinstall azure_overlay %}
cni.enabled=true
cni.chained=true
cni.netDir=/etc/cni/net.d
cni.binDir=/opt/cni/bin
cni.confName=15-azure-swift-overlay.conflist
{% endcpinstall %}

### AWS - EKS

Use the following settings to install {{site.mesh_product_name}} CNI on Amazon EKS.

{% cpinstall aws-eks %}
cni.enabled=true
cni.chained=true
cni.netDir=/etc/cni/net.d
cni.binDir=/opt/cni/bin
cni.confName=10-aws.conflist
controlPlane.envVars.KUMA_RUNTIME_KUBERNETES_INJECTOR_SIDECAR_CONTAINER_IP_FAMILY_MODE=ipv4
{% endcpinstall %}

{:.info}
> Add `KUMA_RUNTIME_KUBERNETES_INJECTOR_SIDECAR_CONTAINER_IP_FAMILY_MODE=ipv4` as EKS has IPv6 disabled by default.

### Google - GKE

To install {{site.mesh_product_name}} CNI on GKE, [enable network-policy](https://cloud.google.com/kubernetes-engine/docs/how-to/network-policy) in your cluster first (for existing clusters, this redeploys the nodes).

Define the variable `CNI_CONF_NAME` by your CNI, like:
- `export CNI_CONF_NAME=05-cilium.conflist` for Cilium
- `export CNI_CONF_NAME=10-calico.conflist` for GKE Dataplane V1
- `export CNI_CONF_NAME=10-gke-ptp.conflist` for GKE Dataplane V2

{% cpinstall google-gke %}
cni.enabled=true
cni.chained=true
cni.netDir=/etc/cni/net.d
cni.binDir=/home/kubernetes/bin
cni.confName=${CNI_CONF_NAME}
{% endcpinstall %}

### OpenShift 3.11

To install {{site.mesh_product_name}} CNI on OpenShift 3.11, configure admission webhooks and grant the CNI service account the required privileges.

1. Follow the instructions in [OpenShift 3.11 installation](/mesh/single-zone/)
   to get the `MutatingAdmissionWebhook` and `ValidatingAdmissionWebhook` enabled (this is required for regular {{site.mesh_product_name}} installation).

2. You need to grant privileged permission to kuma-cni service account:

```shell
oc adm policy add-scc-to-user privileged -z kuma-cni -n kube-system
```

{% cpinstall openshift-3 %}
cni.enabled=true
cni.containerSecurityContext.privileged=true
{% endcpinstall %}

### OpenShift 4

Use the following settings to install {{site.mesh_product_name}} CNI on OpenShift 4.

{% cpinstall openshift-4 %}
cni.enabled=true
cni.containerSecurityContext.privileged=true
{% endcpinstall %}

## {{site.mesh_product_name}} CNI taint controller

To prevent a race condition ([see issue](https://github.com/kumahq/kuma/issues/4560)), the taint controller taints new nodes with `NoSchedule` until the CNI DaemonSet is running and ready, then removes the taint to allow pod scheduling.

To disable the taint controller, use the following env variable:

```
KUMA_RUNTIME_KUBERNETES_NODE_TAINT_CONTROLLER_ENABLED="false"
```

## Merbridge CNI with eBPF

To install Merbridge CNI with eBPF, append the following options to your install command:

{:.warning}
> To use Merbridge CNI with eBPF your environment has to use `Kernel >= 5.7`
> and have `cgroup2` available

```
--set ... \
--set "{{site.set_flag_values_prefix}}cni.enabled=true" \
--set "{{site.set_flag_values_prefix}}experimental.ebpf.enabled=true"
```

## {{site.mesh_product_name}} CNI logs

Logs of CNI components are available via `kubectl logs`.

To enable debug-level logging, set the `CNI_LOG_LEVEL` environment variable to `debug` on the `{{site.mesh_product_name_path}}-cni` DaemonSet. Note that editing the DaemonSet restarts the CNI pods, during which mesh-enabled application pods cannot start or stop. Avoid this in production unless approved.

{:.warning}
> eBPF CNI currently doesn't have support for exposing its logs.

## {{site.mesh_product_name}} CNI architecture

The CNI DaemonSet `{{site.mesh_product_name_path}}-cni` consists of two components:

1. a CNI installer
2. a CNI binary

The components interact as follows:

{% mermaid %}
flowchart LR
 subgraph s1["conflist"]
        n2["existing-CNIs"]
        n3["kuma-cni"]
  end
 subgraph s2["application pod"]
        n4["kuma-sidecar"]
        n5["app-container"]
  end
    A["installer"] -- copy binary and setup conf --> n3
    n3 -- configure iptables --> n4
{% endmermaid %}

The CNI installer copies CNI binary `kuma-cni` to the CNI directory on the host. When chained, the installer also sets up chaining for `kuma-cni` in CNI conflist file, and when chaining is disabled, the binary `kuma-cni` is invoked explicitly as per pod manifest. When correctly installed, the CNI binary `kuma-cni` will be invoked by Kubernetes when a mesh-enabled application pod is being created so iptables rules required by the `kuma-sidecar` container inside the pod are properly set up.

When chained, if the CNI conflist file is unexpectedly changed causing `kuma-cni` to be excluded, the installer immediately detects it and restarts itself so the chaining installation re-runs and CNI functionalities heal automatically.
