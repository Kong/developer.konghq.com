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
tags: 
  - policy
works_on:
  - konnect

# schema:
#     api: event-gateway/
#     path: /schemas/

# api_specs:
#     - konnect/event-gateway

products:
    - event-gateway
api_specs:
    - event-gateway/knep
layout: gateway_entity

schema:
    api: event-gateway/knep
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

Authentication on the backend cluster defines how the proxy connects to the backend for capturing metadata (topics, consumer groups, and so on).

The backend cluster supports multiple authentication methods and can mediate authentication between clients and backend clusters. 
See [Virtual cluster authentication](/event-gateway/entities/virtual-cluster/#authentication) to learn more.

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
