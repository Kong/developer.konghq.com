---
title: PostgreSQL TLS configuration reference
content_type: reference
description: 'Reference for configuring {{site.base_gateway}} to use TLS or mTLS when connecting to PostgreSQL.'
permalink: /gateway/postgresql-tls-reference/
layout: reference
products:
  - gateway
works_on:
  - on-prem
  - konnect
tags:
  - database
  - tls
faqs:
  - q: "What should I do if I see `could not accept SSL connection: wrong version number`?"
    a: |
      This usually means the client and server have incompatible TLS versions. Verify the PostgreSQL-supported versions using `pg_config --configure` and set a compatible version (like TLSv1.2 or higher) in the `kong.conf` using `pg_ssl_version`.

  - q: "How do I fix `could not load server certificate file errors` in PostgreSQL?"
    a: |
      Ensure the `ssl_cert_file` parameter in `postgresql.conf` points to an existing certificate file. By default, the file should be named `server.crt` and placed in the data directory.

  - q: What does `certificate authentication failed` for user mean?
    a: |
      This occurs when the common name (CN) of the client certificate does not match the PostgreSQL username. Configure username mapping in `pg_ident.conf` to resolve the mismatch.

  - q: Why does {{site.base_gateway}} say `connection requires a valid client certificate`?
    a: |
      This means PostgreSQL is enforcing mTLS, but {{site.base_gateway}} is not presenting a valid certificate. Ensure that `pg_ssl_cert` and `pg_ssl_cert_key` are set correctly in `kong.conf`.

  - q: How do I correct private key permission errors in PostgreSQL?
    a: |
      The key file must be owned by the database user and set to `0600`, or by root with `0640`. Adjust using `chmod 0600` or `chmod 0640` accordingly.

---


TLS (Transport Layer Security) provides a secure communication channel between {{site.base_gateway}} and PostgreSQL. When configured correctly, TLS ensures encrypted traffic, verifies authenticity, and helps maintain data integrity.

Mutual TLS (mTLS) enhances this by requiring both the client {{site.base_gateway}} and the PostgreSQL server to authenticate each other. This approach further reduces the risk of unauthorized access by validating the identities at both ends of the connection.

Using TLS and mTLS for database communication introduces benefits such as:

* **Encryption**: Protects data in transit from being intercepted.
* **Authentication**: Verifies both the server and client identities.
* **Integrity**: Prevents tampering during transmission.

However, enabling TLS or mTLS does add operational complexity. Proper configuration requires valid certificates, matching protocol versions, and secure file permissions.

{{site.base_gateway}} supports TLS and mTLS when connecting to PostgreSQL and provides configuration options to control verification depth, trusted certificate authorities, and client certificate authentication.

PostgreSQL must be compiled or installed with TLS support. In mTLS setups, the server must also validate client certificates, typically by matching certificate metadata with database access rules.


## PostgreSQL requirements
<!--vale off-->
{% table %}
columns:
  - title: Requirement
    key: requirement
  - title: Description
    key: description
  - title: Required For
    key: required_for
rows:
  - requirement: "`ssl = on`"
    description: Enables SSL/TLS connections in PostgreSQL.
    required_for: All TLS setups

  - requirement: "`ssl_cert_file`"
    description: Path to the server certificate file (`.crt`).
    required_for: TLS and mTLS

  - requirement: "`ssl_key_file`"
    description: Path to the server private key file (`.key`).
    required_for: TLS and mTLS

  - requirement: "`ssl_ca_file`"
    description: Path to the trusted Certificate Authority chain file.
    required_for: mTLS

  - requirement: "`ssl_crl_file`"
    description: Path to the certificate revocation list (CRL).
    required_for: Optional validation in mTLS

  - requirement: "`pg_ssl = on`"
    description: Enables SSL support for PostgreSQL connections in Kong Gateway.
    required_for: All TLS setups

  - requirement: "`pg_ssl_required = on`"
    description: Forces Kong Gateway to require SSL when connecting to PostgreSQL.
    required_for: All TLS setups

  - requirement: "`pg_ssl_verify = on`"
    description: Enables verification of the server certificate.
    required_for: TLS and mTLS

  - requirement: "`pg_ssl_version`"
    description: TLS protocol version to use (e.g., `tlsv1_2`).
    required_for: TLS and mTLS

  - requirement: "`lua_ssl_trusted_certificate`"
    description: Path to trusted CA certificates used for verification.
    required_for: TLS and mTLS

  - requirement: "`lua_ssl_verify_depth`"
    description: Verification depth for certificate chains.
    required_for: TLS and mTLS

  - requirement: "`pg_ssl_cert`"
    description: Path to client certificate file.
    required_for: mTLS

  - requirement: "`pg_ssl_cert_key`"
    description: Path to client private key file.
    required_for: mTLS
{% endtable %}
<!--vale on-->

## Certificates

[Certificates](/gateway/entities/certificate/) can be generated with OpenSSL. The most secure setups use an intermediate CA chain.

Self-signed certificates can be used for testing but are not recommended for production.

### Intermediate Certificate Chain

In a secure TLS setup, certificate authorities may include an intermediate CA between the root CA and the server or client certificate. This chain strengthens trust and is a common production setup.

To configure:

* Generate a root CA certificate to serve as the ultimate trust anchor.
* Issue an intermediate certificate signed by the root CA.
* Use the intermediate CA to sign server and client certificates.
* Assemble the certificate chain by appending the intermediate and root certificates in order.
* Ensure PostgreSQL and {{site.base_gateway}} are configured to trust the appropriate CA certificates.

This approach enhances security by keeping the root CA offline and delegating trust to intermediates.



### Root-Only Certificate Chain

In this simpler setup, the root CA directly signs both server and client certificates. This reduces complexity but can increase risk.

To configure:

* Generate a root CA certificate and private key.
* Use the root CA to sign the server and client certificates.
* Trust is established by distributing the root CA certificate to both PostgreSQL and {{site.base_gateway}}.

This setup is easier but lacks the layered security of intermediate chains.



### Self-Signed Certificates

Self-signed certificates are useful for local testing or development, but should not be used in production.

To configure:

* Generate a self-signed server certificate and private key.
* Generate a self-signed client certificate and private key.
* Configure PostgreSQL and {{site.base_gateway}} to trust these certificates directly.

Self-signed certificates do not chain to a CA, so each system must explicitly trust the individual certs.

