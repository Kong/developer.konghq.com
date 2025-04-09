---
title: Debugging {{ site.kic_product_name }}
short_title: Debug logs, traces & profiles

description: |
  How do I enable debug logs and capture network traffic to debug?

content_type: reference
layout: reference

breadcrumbs:
  - /kubernetes-ingress-controller/
  - index: kubernetes-ingress-controller
    section: Troubleshooting

products:
  - kic

works_on:
  - on-prem
  - konnect

---

If {{ site.kic_product_name }} is behaving in a way that you don't expect, sometimes you need to turn up the logging to figure things out.

## Enable debug logs

To customize the log level of {{ site.kic_product_name }}, set the `CONTROLLER_LOG_LEVEL` environment variable:

```bash
kubectl set env -n kong deployment/kong-controller CONTROLLER_LOG_LEVEL="debug"
```

Alternatively, you can set this value in your `values.yaml` file:

```yaml
controller:
  ingressController:
    env:
      log_level: debug
```

To view logs, use `kubectl logs`:

```bash
kubectl logs -n kong deployments/kong-controller
```

## Inspecting network traffic with a tcpdump sidecar

Inspecting network traffic allows you to review traffic between the ingress controller and Kong admin API and/or between the Kong proxy and upstream applications. You can use this in situations where logged information does not provide you sufficient data on the contents of requests and you wish to see exactly what was sent over the network.

Although you cannot install and use tcpdump within the controller or Kong containers, you can add a tcpdump sidecar to your Pod's containers. The sidecar will be able to sniff traffic from other containers in the Pod. You can edit your Deployment (to add the sidecar to all managed Pods) or a single Pod and add the following under the `containers` section of the Pod spec:

```yaml
- name: tcpdump
  securityContext:
    runAsUser: 0
  image: corfr/tcpdump
  command:
    - /bin/sleep
    - infinity
```

```bash
kubectl patch --type=json -n kong deployments.apps ingress-kong -p='[{
  "op":"add",
  "path":"/spec/template/spec/containers/-",
  "value":{
    "name":"tcpdump",
    "securityContext":{
        "runAsUser":0
    },
    "image":"corfr/tcpdump",
    "command":["/bin/sleep","infinity"]
  }
}]'
```

If you are using the Kong Helm chart, you can alternately add this to the `sidecarContainers` section of values.yaml.

Once the sidecar is running, you can use `kubectl exec -it POD_NAME -c tcpdump` and run a capture. For example, to capture traffic between the controller and Kong admin API:

```bash
tcpdump -npi any -s0 -w /tmp/capture.pcap host 127.0.0.1 and port 8001
```

or between Kong and an upstream application with endpoints `10.0.0.50` and
`10.0.0.51`:

```bash
tcpdump -npi any -s0 -w /tmp/capture.pcap host 10.0.0.50 or host 10.0.0.51
```

Once you've replicated the issue, you can stop the capture, exit the container, and use `kubectl cp` to download the capture from the tcpdump container to a local system for review with [Wireshark](https://www.wireshark.org/).

Note that you will typically need to temporarily disable TLS to inspect application-layer traffic. If you have access to the server's private keys you can [decrypt TLS](https://wiki.wireshark.org/TLS#TLS_Decryption), though this does not work if the session uses an ephemeral cipher (neither the controller nor Kong proxy have support for dumping session secrets).

## Gathering profiling data

The controller provides access to [the Golang profiler](https://pkg.go.dev/net/http/pprof), which provides diagnostic information on memory and CPU consumption within the program.

To enable profiling and access it, set `CONTROLLER_PROFILING=true` in the controller container environment, wait for the Deployment to restart, run `kubectl port-forward <POD_NAME> 10256:10256`, and visit `http://localhost:10256/debug/pprof/`.

To enable profiling via Helm, set the following in your `values.yaml` file:

```yaml
controller:
  ingressController:
    env:
      profiling: "true"
```