---
title: "Kong Ingress Controller: Ingress with a particular route host name fails due to invalid value"
content_type: support
description: Kong Ingress Controller rejects an Ingress `host` value containing an underscore because Kubernetes enforces RFC 1123 hostname rules.
products:
  - gateway
  - kic
works_on:
  - on-prem
  - konnect
tldr:
  q: "Why does Kong Ingress Controller reject an Ingress with a \"spec.rules[0].host: Invalid value\" error?"
  a: |
    Kubernetes enforces RFC 1123 hostname rules on the Ingress `host` field, which don't allow underscores. Replace any underscore in the hostname with a hyphen so the value is a valid FQDN, and the Ingress will be accepted.
related_resources: []
---

## Problem

I am using Kong Gateway on Kubernetes with the Kong Ingress Controller. However when I try to add a new route / ingress, I receive the following error:

```

The Ingress "{ingressName}" is invalid: spec.rules[0].host: Invalid value: "{hostName}": a lowercase RFC 1123 subdomain must consist of lower case alphanumeric characters, '-' or '.', and must start and end with an alphanumeric character (e.g. 'example.com', regex used for validation is '[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*')
```

I'm using the following Ingress values in my deployment when I get the error above:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
 name: example
 namespace: example-app
 annotations:
  konghq.com/protocols: https
  konghq.com/https-redirect-status-code: '308'
  konghq.com/strip-path: 'true'
  konghq.com/preserve-host: 'false'
spec:
 ingressClassName: kong
 rules:
  - host: hostname_api.example.com
 paths:
  - path: /examplePath
 pathType: ImplementationSpecific
 backend:
  service:
   name: example-svc
   port: 
    number: 8080
```

## Cause

This is expected behavior. The root cause of the error message using the example Ingress declaration is due to the use of an underscore in the `Host` field. It's important to note that this is not a specific error from Kong; rather, it's a validation error provided by the Kubernetes platform as it scrutinizes the Ingress data during deployment. Many platforms beyond Kubernetes adhere to these rules too, as DNS itself does not allow underscores in subdomain host names.

Per the documented Kubernetes Ingress Spec Rules, the "host" is considered to be a fully-qualified domain name (FQDN), and therefore must comply to FQDN naming rules which includes a specific set of characters that are allowed in a host name and rejecting all other characters from the host name which includes underscores. Included below is a snippet of the relevant RFC for convenience:

A host identified by a registered name is a sequence of characters usually intended for lookup within a locally defined host or service name registry, though the URI's scheme-specific semantics may require that a specific registry (or fixed name table) be used instead. The most common name registry mechanism is the Domain Name System (DNS). A registered name intended for lookup in the DNS uses the syntax defined in Section 3.5 of [RFC1034] and Section 2.1 of [RFC1123]. Such a name consists of a sequence of domain labels separated by ".", each domain label starting and ending with an alphanumeric character and possibly also containing "-" characters.

## Solution

The `Host` value must comply with the RFC as required by the Kubernetes platform. In the example provided, simply change the underscore to a hyphen instead and this will then meet the requirements of RFC 1123. Ultimately, the `Host` value must only consist of lowercase alphanumeric characters, hyphens, and dots per the error message, and anything else will not meet the RFC requirements and will thus be rejected by the Kubernetes platform.
