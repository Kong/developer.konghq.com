---
title: Kong Academy Connectivity Issues
content_type: support
description: Steps to troubleshoot a Kong Academy learner who cannot reach the login page or lab interfaces at education.konghq.com.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why can't a Kong Academy learner reach the login page or lab interfaces?
  a: |
    This is usually caused by a corporate VPN, a corporate browser policy, or a firewall/ad blocker blocking one of Kong Academy's third-party domains or ports (Strigo, LearnUpon, and related services). Confirm the learner's system meets the stated requirements, and check whether LearnUpon or Strigo are reporting an outage.

    If the issue persists after ruling these out, contact learn@konghq.com with a description of the issue, reproduction steps, screenshots, and a HAR file.
related_resources:
  - text: Kong Academy login page
    url: https://education.konghq.com/
  - text: Strigo system requirements test
    url: https://app.strigo.io/system-test
  - text: LearnUpon system requirements
    url: https://support.learnupon.com/hc/en-us/articles/360003608797-LearnUpon-system-requirements
  - text: LearnUpon LMS status
    url: https://www.learnupon.net
  - text: Strigo VLH status
    url: https://status.strigo.io
  - text: Generating a HAR file for troubleshooting
    url: https://support.zendesk.com/hc/en-us/articles/4408828867098-Generating-a-HAR-file-for-troubleshooting
---

## Problem

The learner is not able to see the login page for Kong Academy or is not able to see lab interfaces other than the terminal.

## Solution

The root cause could be:

- Corporate VPN: Try to reproduce the issue without being on the corporate VPN
- Corporate Browser Policies: Try reproducing the issue without a corporate-managed browser
- Corporate Firewall or AdBlocker:

  Make sure the following domains are not blocked:

  `*.cloudfront.net`, `*.firebase.com`, `*.firebaseio.com`, `*.googleapis.com`, `*.gstatic.com`, `*.learnerresources.s3.amazonaws.com`, `*.learnupon.com`, `*.lmspowered.com`, `*.opentok.com`, `*.pixelpaper.io`, `*.stream-io-api.com`, `*.strigo.io`, `*.tokbox.com`, `*.wistia.com`, `*.wistia.net`

  Make sure the following ports are not blocked on `*.strigo.io`:

  <!--vale off -->
  {% table %}
  columns:
    - title: Port
      key: port
    - title: Protocol
      key: protocol
    - title: App
      key: app
  rows:
    - port: "443"
      protocol: TCP/UDP
      app: Konnect CP
    - port: "3000"
      protocol: HTTP/HTTPS
      app: Grafana
    - port: "8000"
      protocol: HTTP
      app: Gateway DP, Konnect DP
    - port: "8001"
      protocol: HTTP
      app: Gateway Admin API
    - port: "8002"
      protocol: HTTP
      app: Kong Manager GUI
    - port: "8003"
      protocol: HTTP
      app: Dev Portal
    - port: "8004"
      protocol: HTTP
      app: Dev Portal Files
    - port: "8005"
      protocol: TCP
      app: Gateway Hybrid CP
    - port: "8006"
      protocol: TCP
      app: Gateway Hybrid CP
    - port: "8071"
      protocol: TCP/UDP
      app: Konnect Auditing
    - port: "8080"
      protocol: HTTP/HTTPS
      app: Mockbin
    - port: "8443"
      protocol: HTTPS
      app: Gateway DP, Konnect DP
    - port: "8444"
      protocol: HTTPS
      app: Gateway Admin API
    - port: "8445"
      protocol: HTTPS
      app: Kong Manager GUI
    - port: "8446"
      protocol: HTTPS
      app: Dev Portal
    - port: "8447"
      protocol: HTTPS
      app: Dev Portal Files
    - port: "9090"
      protocol: HTTP/HTTPS
      app: Prometheus GUI/API
    - port: "9100"
      protocol: HTTP/HTTPS
      app: Prometheus Node Exporter
    - port: "9115"
      protocol: HTTP/HTTPS
      app: Prometheus Mode Exporter
  {% endtable %}
  <!--vale on -->

- Unmet requirements: Confirm requirements are met using the Strigo system requirements test and the LearnUpon system requirements documentation.

- Server-side Issues: Check the status of LearnUpon LMS and Strigo VLH.

If you still observe the issue in your browser and you have ruled out the above causes, don't hesitate to get in touch with us at learn@konghq.com, and supply a description of the issue, steps taken to remedy, screenshots, and a HAR file capturing the reproduction of the issue in your web browser.

For guidance, see Generating a HAR file for troubleshooting.
