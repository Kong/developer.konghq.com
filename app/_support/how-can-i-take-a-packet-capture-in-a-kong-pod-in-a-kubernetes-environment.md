---
title: Taking a packet capture in a Kong pod in a Kubernetes environment
content_type: support
description: "Add a sidecar container running a `tcpdump` image to the Kong pod to capture packet traffic in a Kubernetes environment where the standard Kong image doesn't include `tcpdump` or root access."
products:
  - kic
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How can I take a packet capture in a Kong pod in a Kubernetes environment?
  a: |
    Add a sidecar container based on a `tcpdump` image to the Kong pod (via Helm's `sidecarContainers` values), then `kubectl exec` into that container to run `tcpdump` against the traffic you're interested in, and `kubectl cp` the resulting `.pcap` file out for analysis.
---

## Overview

There are certain situations where it is crucial to get a packet capture of TCP traffic that reaches Kong nodes but the standard Kong images do not have tcpdump installed, and we can not access the Kong nodes with root access. For example, we want to understand why mTLS handshakes are not working or what response a Kong node gets from an upstream or IdP endpoint when the error log does not provide enough information. What is a good way to do a packet capture?

## Steps

A valuable way to take a packet capture in a Kubernetes environment is to add an additional sideCar container to the kong pod which contains the a tcpdump image.

For example you can add the following to a Kong Helm values.yaml file to add the "tcpdump" container to an existing pod with a Kong "Proxy" container (and a Kong Ingress-Controller container):

```yaml

deployment:
  kong:
    enabled: true
  sidecarContainers:
  - name: tcpdump
    securityContext:
      runAsUser: 0
    image: corfr/tcpdump
    command:
      - /bin/sleep
      - infinity
```

- Once you upgrade the helm deployment, the additional container should get deployed with the tcpdump utility. You should be able to access it with something like this:

```bash

kubectl -n <yournamespace> exec -it <yourkongpod> -c tcpdump /bin/sh
```

- In the container, you should be able to capture the tcp traffic against whatever host/port you are interested in using something like the following command:

```bash

tcpdump -npi any -As0 -w /tmp/packet.pcap host <relevantHostIpOrName> and port <relevantPort>
```

- Then copy the packet.pcap onto your local machine for further analysis or to make available to Kong Support you can use the following command:

```bash

kubectl cp -n <yournamespace> <yourkongpod>:/tmp/packet.pcap ./packet.pcap -c tcpdump
```
