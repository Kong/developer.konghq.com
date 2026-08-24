---
title: How to debug the Control Plane/DataPlane web socket communication
content_type: support
description: Use stunnel to terminate TLS on the Control Plane/Data Plane WebSocket connection and tcpdump to capture the resulting plaintext traffic, so you can inspect the declarative configuration payload sent over `cluster_listen`.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I debug the Control Plane/Data Plane WebSocket communication in a hybrid Kong Gateway deployment?
  a: |
    Use `stunnel` to terminate TLS on the CP/DP `cluster_listen` WebSocket connection as a man-in-the-middle proxy, and `tcpdump` to capture the resulting plaintext traffic. Inspect the captured packets (e.g. in Wireshark) to extract the gzipped declarative configuration JSON that the CP sends to each DP.
related_resources: []
---

## Overview

When using a hybrid installation, the Control Plane and the Data Plane utilize a Secure Web Socket for communication. This traffic is encrypted and not observable using tools such as `tcpdump`. How can the actual communication content be observed?

## Steps

For this example, we will assume that the default (Debian-based) Kong Gateway images are being used and that the Hybrid installation is using shared certificates. This is the simplest Hybrid deployment architecture, but the same principles can be used for PKI mode.

When a DP starts, it opens a Web Socket to the CP and the CP pushes the configuration to the DP. This is done via a Web Socket connection on the `cluster_listen` port (8005). To view this traffic, we are going to use `stunnel` to setup a MITM attack and `tcpdump` to capture the plain text traffic. The example also captures traffic on the CP as this will capture all traffic for all DP nodes. You could also setup the capture on the DP node if you only want to capture traffic from a single node.

1. Configure the CP to listen on a non-default port for the `cluster_listen` port. In our example, we are using `docker-compose` so have a line below to use port 48005. There is no need to expose this port externally, as we will be using `stunnel` to forward traffic from the standard port (8005) to this custom port.

   ```yaml

   KONG_CLUSTER_LISTEN: "0.0.0.0:48005"
   ```

2. On the CP, install `stunnel` and `tcpdump`

   ```bash

   apt-get update
   apt-get install -y stunnel4 tcpdump
   ```

3. Create a `stunnel` configuration file;

   ```bash

   echo "debug = 3
   foreground = no
   pid =

   [server]
   client = no
   cert = /tmp/hybrid/cluster.crt
   key = /tmp/hybrid/cluster.key
   accept = 0.0.0.0:8005
   connect = 127.0.0.1:58005

   [client]
   client = yes
   cert = /tmp/hybrid/cluster.crt
   key = /tmp/hybrid/cluster.key
   accept = 127.0.0.1:58005
   connect = 0.0.0.0:48005" > stunnel-mitm-proxy.conf
   ```

   This configuration will start a `stunnel` server listener on port 8005. This is the port that the DP will be connecting to. The configuration uses the shared Hybrid cluster certificate pair for this listen port and forwards traffic as plain text to port 58005 from the client section.

   The client is listening on port 58005 and forwards traffic to the local port that Kong is using for the `cluster_listen` port (48005)

4. Start `stunnel`

   ```bash

   stunnel stunnel-mitm-proxy.conf
   ```

5. Start a `tcpdump` running on the plain text port

   ```bash

   tcpdump -s 0 -i any -w /tmp/cluster.pcap port 58005
   ```

6. Start the DP. This will connect to port 8005 on the CP and `stunnel` will accept the connection and forward to itself as plain text before forwading to the `cluster_listen` port

7. Wait for the DP to have downloaded the configuration (check the `/clustering/status` endpoint)

8. Once the DP has the configuration, you can stop the `tcpdump` and copy the `/tmp/cluster.pcap` file to your local machine

When the DP connects to the CP, it sends a json object with details of the plugins it has installed and their versions. You can see this in the screenshot below;

The CP verifies that the DP has the required plugins of the correct versions to ensure that the entity sync can succeed. If this check passes, then the CP sends a gzipped json file with the declarative configuration;

To see what is in the zipped archive, it is necessary to extract the content. To do this, right click on the Data for the TCP frame and select "Export Packet Bytes...".

Save the file locally (you will need to use a `.bin` extension for the file name, for example `temp.json.bin`).

Unzip the file (if using `gunzip`, then you will need to use the `-S` parameter to allow the `.bin` extension)

```bash

gunzip -S .bin temp.json.bin
```

Check the start of the json payload;

```bash

head -c250 temp.json
```

You now have a copy of the declarative configuration json file that the CP sends to the DP. The DP will save this file in `/usr/local/kong/config.cache.json.gz`
