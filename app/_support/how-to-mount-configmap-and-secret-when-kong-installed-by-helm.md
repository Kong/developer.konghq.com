---
title: How to mount configmap and secret when kong installed by helm
content_type: support
published: false
description: Steps to mount `ConfigMaps` and `Secrets` as folders or files in Kong pods using `extraConfigMaps` and `extraSecrets` in the Kong Helm chart values.
products:
  - kic
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How do I mount ConfigMaps and Secrets as folders or files in Kong pods installed with the Helm chart?
  a: |
    Create the `ConfigMap` or `Secret` with `kubectl`, then reference it under `extraConfigMaps` or `extraSecrets` in the Kong Helm chart values (with an optional `subPath` to mount a single file instead of a folder), and reinstall or upgrade the Helm release. See the FAQs below for a full walkthrough and multi-resource examples.
faqs:
  - q: How to mount a `configmap` to a folder in the pod?
    a: |
      step 1: create a configmap from a file

      ```bash
      kubectl create configmap <configmap-name> --from-file=</path/to/file> -n <kong-namespace>
      ```

      step 2: add extraConfigMaps section in helm chart like below

      ```yaml
      extraConfigMaps:
      - name: <configmap-name>
        mountPath: </folder/path/to/mount/in/pod> (e.g /test)
      ```

      step 3: re-install /upgrade kong helm chart

      * Please notice the whole folder mount in the pod will be overwritten by the configmap
  - q: How to mount a `configmap` to a file in the pod?
    a: |
      step 1: create a configmap from a file

      ```bash
      kubectl create configmap <configmap-name> --from-file=</path/to/file> -n <kong-namespace>
      ```

      step 2: add extraConfigMaps section in helm chart like below

      ```yaml
      extraConfigMaps:
      - name: <configmap-name>
        mountPath: </file/path/to/mount/in/pod> (e.g /test/a.txt)
        subPath: </file/name/to/mount/in/pod> (e.g a.txt)
      ```

      step 3: re-install /upgrade kong helm chart
  - q: How to mount a `secret` to a folder in the pod?
    a: |
      step 1: create a secret from a file

      ```bash
      kubectl create secret generic <secret-name> --from-file=</path/to/file> -n <kong-namespace>
      ```

      step 2: add extraSecrets section in helm chart like below

      ```yaml
      extraSecrets:
      - name: <secret-name>
        mountPath: </folder/path/to/mount/in/pod> (e.g /test)
      ```

      step 3: re-install /upgrade kong helm chart

      * Please notice the whole folder mount in the pod will be overwritten by the secret
  - q: How to mount a `secret` to a file in the pod?
    a: |
      step 1: create a secret from a file

      ```bash
      kubectl create secret generic <secret-name> --from-file=</path/to/file> -n <kong-namespace>
      ```

      step 2: add extraSecrets section in helm chart like below

      ```yaml
      extraSecrets:
      - name: <secret-name>
        mountPath: </file/path/to/mount/in/pod> (e.g /test/a.txt)
        subPath: </file/name/to/mount/in/pod> (e.g a.txt)
      ```

      step 3: re-install /upgrade kong helm chart
  - q: Is it possible to mount multiple `configmaps` or `secrets` in the pod?
    a: |
      Yes, you could write multiple extraConfigMaps in helm chart like below

      ```yaml
      extraConfigMaps:
      - name: <configmap-name1>
        mountPath: </file/path/to/mount/in/pod> (e.g /test/a.txt)
        subPath: </file/name/to/mount/in/pod> (e.g a.txt)
      - name: <configmap-name2>
        mountPath: </file/path/to/mount/in/pod> (e.g /test/b.txt)
        subPath: </file/name/to/mount/in/pod> (e.g b.txt)
      ```

      you could write multiple extraSecrets in helm chart like below

      ```yaml
      extraSecrets:
      - name: <secret-name1>
        mountPath: </file/path/to/mount/in/pod> (e.g /test/a.txt)
        subPath: </file/name/to/mount/in/pod> (e.g a.txt)
      - name: <secret-name2>
        mountPath: </file/path/to/mount/in/pod> (e.g /test/b.txt)
        subPath: </file/name/to/mount/in/pod> (e.g b.txt)
      ```
---

## Overview

Kong pods can mount `ConfigMaps` and `Secrets` as folders or files when Kong is installed with the Helm chart, including mounting multiple `ConfigMaps` or `Secrets` at once. See the FAQs below for step-by-step instructions.
