Before applying any policies, take a few minutes to confirm where the moving parts of your mesh live. This grounds the concepts from the Learn section in commands you can re-run any time you're not sure what's deployed.

### Step 1: Confirm the Control Plane is up

{% navtabs "verify-cp" %}
{% navtab "Kubernetes" %}
List the Control Plane pods:

```bash
kubectl get pods -n kong-mesh-system
```

You should see a `kong-mesh-control-plane-*` pod in `Running` state. In a multi-zone deployment, the Global CP runs under the same namespace name but in a separate cluster.
{% endnavtab %}
{% navtab "Universal" %}
Confirm `kumactl` is pointed at a reachable Control Plane:

```bash
kumactl config control-planes list
```

The active CP is marked with `*`. Switch with `kumactl config control-planes switch --name <cp>` if needed.
{% endnavtab %}
{% endnavtabs %}

### Step 2: Inspect the default Mesh

The `Mesh` resource is the top-level object you'll edit in the next step. It's a Global CP–only resource.

{% navtabs "inspect-mesh" %}
{% navtab "Kubernetes (Global CP)" %}
```bash
kubectl get meshes
kubectl get mesh default -o yaml
```
{% endnavtab %}
{% navtab "Universal (Global CP)" %}
```bash
kumactl get meshes
kumactl get mesh default -o yaml
```
{% endnavtab %}
{% endnavtabs %}

Notice the `spec` is essentially empty — there's no `mtls` block yet. You'll add one in Step 2.

### Step 3: List the policies that are already there

Even on a fresh install, some default policies exist (typically an `allow-all` `MeshTrafficPermission`):

{% navtabs "list-policies" %}
{% navtab "Kubernetes" %}
```bash
kubectl get meshtrafficpermissions -A
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
kumactl get meshtrafficpermissions --mesh default
```
{% endnavtab %}
{% endnavtabs %}

Note where each policy lives — in particular, that infrastructure-level resources are in `kong-mesh-system`, not in application namespaces.

### Step 4: Find a sidecar

Pick any namespace with mesh-injected workloads and inspect a pod to confirm the Envoy sidecar is attached:

```bash
kubectl get pods -n kong-air-production
kubectl describe pod -n kong-air-production <pod-name> | grep -A2 "kuma-sidecar"
```

You should see a second container named `kuma-sidecar` alongside your application container. That sidecar is the Data Plane proxy you'll be configuring with `targetRef` policies in the next steps.

{% tip %}
If no namespace has `kuma.io/sidecar-injection: enabled` (Kubernetes) or no Dataplanes are registered (Universal), pause here and follow the [{{site.mesh_product_name}} installation guide](/mesh/install/) before moving on — every later step assumes at least one mesh-injected service.
{% endtip %}

### What you did

- Confirmed the Control Plane is running and `kumactl`/`kubectl` is talking to it.
- Inspected the default `Mesh` resource — empty `mtls`, ready to be configured.
- Listed the existing `MeshTrafficPermission` policies and noticed where they live.
- Verified at least one workload has a `kuma-sidecar` container injected.

In Step 2 you'll enable mTLS on the default Mesh and replace the permissive baseline with a zero-trust default-deny posture.
