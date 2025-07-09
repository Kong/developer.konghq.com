---
title: Set up message encryption for {{site.event_gateway}}
short_title: Automatic message encryption
content_type: how_to
breadcrumbs:
  - /event-gateway/

permalink: /event-gateway/get-started/encryption/

series:
  id: event-gateway-get-started
  position: 4

beta: true

products:
    - event-gateway

works_on:
    - konnect

tags:
    - get-started
    - event-gateway
    - kafka

description: Configure {{site.event_gateway}} for automatic message encryption and decryption using symmetric key encryption.


tldr: 
  q: How do I encrypt or decrypt Kafka messages?
  a: | 
    This example demonstrates how to configure {{site.event_gateway}} for automatic message encryption and decryption using symmetric key encryption.

tools:
    - konnect-api
  
prereqs:
  skip_product: true

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg

automated_tests: false
related_resources:
  - text: "{{site.event_gateway_short}} configuration schema"
    url: /api/event-gateway/knep/
  - text: Event Gateway
    url: /event-gateway/

faqs:
  - q: Why am I getting Kafka message encryption errors?
    a: |
      If you're getting encryption errors, check the following:
      * Verify that the key is correctly base64 encoded
      * Ensure that the key is exactly 16 bytes (128 bits) before base64 encoding
  - q: Why am I getting Kafka message decryption errors?
    a: |
      If you're getting decryption errors, check the following:
      * Confirm that the same key is used in both produce and consume policies
      * Verify that messages were produced through the proxy
---

## Security considerations

When using key encryption, be aware of the following:
* The encryption key is stored in plain text in the configuration file
* In production environments, use secure key management solutions
* The example uses `network_mode: host` for simplicity; adjust for production
* Messages are encrypted at rest in Kafka
* Only consumers through the proxy can decrypt messages

## Generate an encryption key

```sh
cat <<EOF > generate_key.sh
#!/bin/sh
# Generate 16 random bytes and encode to base64
if command -v openssl >/dev/null 2>&1; then
    # OpenSSL method (most systems)
    openssl rand -base64 16
elif command -v dd >/dev/null 2>&1 && [ -f /dev/urandom ]; then
    # Fallback using dd and urandom
    dd if=/dev/urandom bs=16 count=1 2>/dev/null | base64
else
    echo "Error: Neither openssl nor dd with /dev/urandom available" >&2
    exit 1
fi
EOF
```

Run the script:
```sh
sh ./generate_key.sh
```

Export the key:
```
KNEP_KEY='YOUR-GENERATED-KEY'
```

## Configure 

```yaml
backend_clusters:
  - name: kafka-localhost
    bootstrap_servers:
      - localhost:9092
      - localhost:9093
      - localhost:9094

virtual_clusters:
  - name: team-a
    backend_cluster_name: kafka-localhost
    route_by:
      type: port
      port:
        min_broker_id: 1
    authentication:
      - type: sasl_oauth_bearer
        sasl_oauth_bearer:
          jwks:
            endpoint: http://localhost:8080/realms/kafka-realm/protocol/openid-connect/certs
            timeout: "1s"
        mediation:
          type: anonymous
    topic_rewrite:
      type: prefix
      prefix:
        value: a-
  - name: team-b
    backend_cluster_name: kafka-localhost
    route_by:
      type: port
      port:
        offset: 10000
        min_broker_id: 1
    authentication:
      - type: anonymous
        mediation:
          type: anonymous
    topic_rewrite:
      type: prefix
      prefix:
        value: b-
    consume_policies:
      - policies:
          - type: policy
            policy:
              name: decrypt
              type: decrypt
              decrypt:
                failure:
                  mode: error
                decrypt:
                  - type: value
                key_sources:
                  - type: key_source
                    key_source:                
                      type: static
                      name: inline-key
                      static:
                        - id: "static://key-0"
                          key:
                            type: bytes
                            bytes:
                              value: "${KNEP_KEY}"
    produce_policies:
      - policies:
          - type: policy
            policy:
              name: encrypt 
              type: encrypt
              encrypt:
                failure: 
                  mode: error
                encrypt:
                  - type: value
                    id: "static://key-0"
                key_sources:
                  - type: key_source
                    key_source:                
                      type: static
                      name: inline-key
                      static:
                        - id: "static://key-0"
                          key:
                            type: bytes
                            bytes:
                              value: "${KNEP_KEY}"

listeners:
  port:
    - listen_address: 0.0.0.0
      listen_port_start: 19092
```

This setup provides:
* Automatic encryption of messages during production
* Automatic decryption of messages during consumption
* Symmetric key encryption using a 128-bit key
* Transparent encryption/decryption (clients don't need to handle encryption)


## Validate

Produce an encrypted message through the proxy:
```sh
echo "secret message" | kafkactl -c knep produce my-topic
```

Consume the message through the proxy:

```sh
kafkactl -c knep consume my-topic
```

The output will show the decrypted message.

Now try consuming the message directly through Kafka:
```sh
kafkactl -c default consume my-topic
```

This time, the message will remain encrypted.