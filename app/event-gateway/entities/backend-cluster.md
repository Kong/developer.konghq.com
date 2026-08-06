---
title: "Backend clusters"
content_type: reference

description: |
    Backend clusters represent target Kafka clusters proxies by {{site.event_gateway}}.
related_resources:
  - text: "{{site.event_gateway}} Policy Hub"
    url: /event-gateway/policies/
  - text: "Policies"
    url: /event-gateway/entities/policy/
  - text: "Virtual clusters"
    url: /event-gateway/entities/virtual-cluster/
  - text: "Listeners"
    url: /event-gateway/entities/listener/

tools:
    - konnect-api
    - terraform
    - kongctl
tags:
  - policy
works_on:
  - konnect

products:
    - event-gateway
api_specs:
    - konnect/event-gateway
layout: gateway_entity

schema:
    api: konnect/event-gateway
    path: /schemas/BackendCluster

breadcrumbs:
  - /event-gateway/
  - /event-gateway/entities/
---

## What is a backend cluster?

A backend cluster is an abstraction of a real Kafka cluster. It stores the connection and configuration details required for {{site.event_gateway}} to proxy traffic to Kafka.

Multiple Kafka clusters can be proxied through a single {{site.event_gateway}}. The Event Gateway control plane manages information such as:

* Authentication credentials for connecting to Kafka clusters
* TLS verification preferences
* Metadata refresh intervals for fetching cluster information

{% include_cached /knep/entities-diagram.md entity="D" %}

## Authentication

Authentication on the backend cluster defines the credentials the {{site.event_gateway_short}} uses when connecting to Kafka to fetch cluster metadata, such as topic and partition information.
The supported types reflect what your Kafka cluster accepts.

{:.info}
> **Note**: These credentials aren't used to represent individual client actions.
> For `passthrough` and `validate_forward` mediation, each client authenticates directly to Kafka using their own credentials for their connection.

Backend clusters support the following auth methods:

{% table %}
columns:
  - title: "Auth method (`authentication.type`)"
    key: auth
  - title: Description
    key: description
  - title: "Credential mediation types (`authentication.mediation`)"
    key: credential
rows:
  - auth: "Anonymous"
    description: "Doesn't require clients to provide any authentication when connecting to the proxy."
    credential: None
  - auth: "SASL/PLAIN"
    description: |
      Requires clients to provide a username and password.
      <br><br>
      Accepts a hardcoded list of usernames and passwords, either as strings or environment variables.
      <br><br>
      See [Authenticate Event Gateway connections to Kafka using SASL/PLAIN](/event-gateway/configure-sasl-plain-backend-cluster-auth/).
    credential: |
      `passthrough`, `terminate`
  - auth: "SASL/SCRAM-SHA-256"
    description: |
      Requires clients to provide a username and password using SCRAM-SHA-256 hashing.
    credential: |
      `passthrough`
  - auth: "SASL/SCRAM-SHA-512"
    description: |
      Requires clients to provide a username and password using SCRAM-SHA-512 hashing.
    credential: |
      `passthrough`
{% endtable %}

Depending on what your Kafka cluster supports, you'll need to configure authentication on the associated virtual cluster:
* If your Kafka cluster only accepts SASL/PLAIN or SASL/SCRAM credentials, configure [`terminate` mediation on the virtual cluster](/event-gateway/entities/virtual-cluster/#credential-mediation) so the {{site.event_gateway_short}} translates client credentials into the backend's accepted mechanism.
* If your backend Kafka cluster supports SASL/OAUTHBEARER natively, use [`passthrough` or `validate_forward` mediation](/event-gateway/entities/virtual-cluster/#credential-mediation) on the virtual cluster.
In that case, the client's OAuth bearer token is forwarded directly to the backend, and the backend cluster entity doesn't need to store separate credentials.

## Set up a backend cluster

{% entity_example %}
type: backend_cluster
data:
  name: example-backend-cluster
  bootstrap_servers:
    - host:9092
  authentication:
    type: anonymous
  insecure_allow_anonymous_virtual_cluster_auth: true
  tls:
    insecure_skip_verify: false
{% endentity_example %}

## Schema

{% entity_schema %}
